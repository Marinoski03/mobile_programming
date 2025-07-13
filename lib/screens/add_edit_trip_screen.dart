// lib/screens/add_edit_trip_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

import '../models/trip.dart';
import '../helpers/trip_database_helper.dart';
import '../utils/app_data.dart'; 

class AddEditTripScreen extends StatefulWidget {
  final Trip? trip;

  const AddEditTripScreen({super.key, this.trip});

  @override
  State<AddEditTripScreen> createState() => _AddEditTripScreenState();
}

class _AddEditTripScreenState extends State<AddEditTripScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late String _selectedLocation;
  late DateTime _startDate;
  late DateTime _endDate;
  late String _category;
  late String _notes;
  late bool _isFavorite;
  late bool _toBeRepeated;

  final List<String> _newImagePaths = [];
  final List<String> _existingImageUrls = [];

  final TextEditingController _locationSearchController = TextEditingController();
  List<dynamic> _locationSuggestions = [];
  Timer? _debounce;

  String _sanitizeImagePath(String path) {
    return path.replaceAll('["', '').replaceAll('"]', '').replaceAll('"', '');
  }

  @override
  void initState() {
    super.initState();
    if (widget.trip != null) {
      _title = widget.trip!.title;
      _selectedLocation = widget.trip!.location;
      _locationSearchController.text = widget.trip!.location;
      _startDate = widget.trip!.startDate;
      _endDate = widget.trip!.endDate;
      _category = widget.trip!.category;
      _notes = widget.trip!.notes;
      _isFavorite = widget.trip!.isFavorite;
      _toBeRepeated = widget.trip!.toBeRepeated;
      
      for (String url in widget.trip!.imageUrls) {
        _existingImageUrls.add(_sanitizeImagePath(url));
      }
    } else {
      _title = '';
      _selectedLocation = '';
      _locationSearchController.text = '';
      _startDate = DateTime.now();
      _endDate = DateTime.now().add(const Duration(days: 7));
      _category = AppData.categories.first;
      _notes = '';
      _isFavorite = false;
      _toBeRepeated = false;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _locationSearchController.dispose();
    super.dispose();
  }

  void _presentDatePicker(bool isStart) {
    showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    ).then((pickedDate) {
      if (pickedDate == null) {
        return;
      }
      setState(() {
        if (isStart) {
          _startDate = pickedDate;
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate.add(const Duration(days: 7));
          }
        } else {
          _endDate = pickedDate;
          if (_endDate.isBefore(_startDate)) {
            _startDate = _endDate.subtract(const Duration(days: 7));
          }
        }
      });
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(
      imageQuality: 70,
      maxWidth: 1000,
    );

    if (pickedFiles.isEmpty) {
      return;
    }

    final appDir = await getApplicationDocumentsDirectory();
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }

    List<String> tempSavedPaths = [];

    for (XFile xFile in pickedFiles) {
      try {
        final File imageFile = File(xFile.path);

        if (!await imageFile.exists()) {
          debugPrint('DEBUG - File temporaneo non trovato: ${imageFile.path}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Immagine selezionata temporanea non trovata, riprova.'),
              ),
            );
          }
          continue;
        }

        final String fileName = '${DateTime.now().microsecondsSinceEpoch}_${p.basename(imageFile.path)}';
        final String savedPath = p.join(appDir.path, fileName);

        final newFile = await imageFile.copy(savedPath);
        tempSavedPaths.add(newFile.path);
        debugPrint('DEBUG - Immagine copiata e salvata in: ${newFile.path}');
      } catch (e) {
        debugPrint('Errore durante la copia dell\'immagine ${xFile.path}: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Errore durante la copia di un\'immagine: $e'),
            ),
          );
        }
      }
    }

    if (mounted) {
      setState(() {
        _newImagePaths.addAll(tempSavedPaths);
      });
    }
  }

  void _removeImage(int index, {bool isExisting = false}) {
    setState(() {
      if (isExisting) {
        _existingImageUrls.removeAt(index);
      } else {
        _newImagePaths.removeAt(index);
      }
    });
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _locationSuggestions = [];
        });
      }
      return;
    }

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=${Uri.encodeQueryComponent(query)}&format=json&addressdetails=1&limit=5',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);
        if (mounted) {
          setState(() {
            _locationSuggestions = results;
          });
        }
      } else {
        debugPrint('Nominatim API error: ${response.statusCode}');
        if (mounted) {
          setState(() {
            _locationSuggestions = [];
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching location suggestions: $e');
      if (mounted) {
        setState(() {
          _locationSuggestions = [];
        });
      }
    }
  }

  void _onLocationSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchLocation(query);
    });
  }

  void _selectLocationSuggestion(Map<String, dynamic> suggestion) {
    setState(() {
      _selectedLocation = suggestion['display_name'] ?? '';
      _locationSearchController.text = suggestion['display_name'] ?? '';
      _locationSuggestions = [];
    });
  }

  void _saveTrip() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_selectedLocation.isEmpty && _locationSearchController.text.isNotEmpty) {
        _selectedLocation = _locationSearchController.text;
      } else if (_locationSearchController.text.isEmpty) {
        _selectedLocation = 'Nessuna Nazione';
      }

      final List<String> allImageUrls = List.from(_existingImageUrls);
      allImageUrls.addAll(_newImagePaths);

      final newTrip = Trip(
        id: widget.trip?.id,
        title: _title,
        location: _selectedLocation,
        startDate: _startDate,
        endDate: _endDate,
        category: _category,
        notes: _notes,
        imageUrls: allImageUrls,
        isFavorite: _isFavorite,
        toBeRepeated: _toBeRepeated,
      );

      debugPrint('DEBUG - Percorsi immagini finali: $allImageUrls');

      try {
        if (widget.trip == null) {
          await TripDatabaseHelper.instance.insertTrip(newTrip);
        } else {
          await TripDatabaseHelper.instance.updateTrip(newTrip);
        }
        if (mounted) {
          Navigator.of(context).pop(newTrip);
        }
      } catch (e) {
        debugPrint('Errore durante il salvataggio del viaggio nel DB: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Errore durante il salvataggio: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppData.antiFlashWhite,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          widget.trip == null ? 'Aggiungi Viaggio' : 'Modifica Viaggio',
          style: const TextStyle(color: AppData.antiFlashWhite),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppData.antiFlashWhite),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: AppData.antiFlashWhite),
            onPressed: _saveTrip,
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppData.silverLakeBlue.withOpacity(0.7),
              AppData.charcoal.withOpacity(0.9)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    initialValue: _title,
                    decoration: InputDecoration(
                      labelText: 'Titolo del Viaggio',
                      labelStyle: TextStyle(color: AppData.antiFlashWhite.withOpacity(0.7)),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppData.antiFlashWhite.withOpacity(0.5)),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: AppData.antiFlashWhite),
                      ),
                    ),
                    style: const TextStyle(color: AppData.antiFlashWhite),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Inserisci un titolo per il viaggio';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _title = value ?? '';
                    },
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _locationSearchController,
                    decoration: InputDecoration(
                      labelText: 'Cerca Nazione / Città',
                      labelStyle: const TextStyle(color: AppData.antiFlashWhite),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppData.antiFlashWhite.withOpacity(0.5)),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: AppData.antiFlashWhite),
                      ),
                      suffixIcon: _locationSearchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: AppData.antiFlashWhite.withOpacity(0.7),
                              ),
                              onPressed: () {
                                setState(() {
                                  _locationSearchController.clear();
                                  _selectedLocation = '';
                                  _locationSuggestions = [];
                                });
                              },
                            )
                          : null,
                    ),
                    style: const TextStyle(color: AppData.antiFlashWhite),
                    onChanged: _onLocationSearchChanged,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Inserisci una nazione o città';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _selectedLocation = value ?? '';
                    },
                  ),
                  
                  if (_locationSuggestions.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: AppData.charcoal.withOpacity(0.8), 
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _locationSuggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = _locationSuggestions[index];
                          return ListTile(
                            title: Text(
                              suggestion['display_name'] ?? '',
                              style: const TextStyle(color: AppData.antiFlashWhite), 
                            ),
                            onTap: () => _selectLocationSuggestion(suggestion),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Data Inizio e Fine
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _presentDatePicker(true),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Data Inizio',
                              labelStyle: TextStyle(color: AppData.antiFlashWhite.withOpacity(0.7)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide(color: AppData.antiFlashWhite.withOpacity(0.5)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide(color: AppData.antiFlashWhite.withOpacity(0.5)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: const BorderSide(color: AppData.antiFlashWhite),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('dd/MM/yyyy').format(_startDate),
                                  style: const TextStyle(color: AppData.antiFlashWhite),
                                ),
                                const Icon(Icons.calendar_today, color: AppData.antiFlashWhite),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () => _presentDatePicker(false),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Data Fine',
                              labelStyle: TextStyle(color: AppData.antiFlashWhite.withOpacity(0.7)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide(color: AppData.antiFlashWhite.withOpacity(0.5)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide(color: AppData.antiFlashWhite.withOpacity(0.5)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: const BorderSide(color: AppData.antiFlashWhite),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('dd/MM/yyyy').format(_endDate),
                                  style: const TextStyle(color: AppData.antiFlashWhite),
                                ),
                                const Icon(Icons.calendar_today, color: AppData.antiFlashWhite),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Dropdown Categoria
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Categoria',
                      labelStyle: TextStyle(color: AppData.antiFlashWhite.withOpacity(0.7)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: AppData.antiFlashWhite.withOpacity(0.5)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: AppData.antiFlashWhite.withOpacity(0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: const BorderSide(color: AppData.antiFlashWhite),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _category,
                        dropdownColor: AppData.charcoal.withOpacity(0.9), // SFONDO DROPDOWN
                        icon: const Icon(Icons.arrow_drop_down, color: AppData.antiFlashWhite),
                        style: const TextStyle(color: AppData.antiFlashWhite, fontSize: 16),
                        onChanged: (String? newValue) {
                          setState(() {
                            _category = newValue!;
                          });
                        },
                        items: AppData.categories.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Campo Note
                  TextFormField(
                    initialValue: _notes,
                    decoration: InputDecoration(
                      labelText: 'Note Personali',
                      labelStyle: TextStyle(color: AppData.antiFlashWhite.withOpacity(0.7)),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppData.antiFlashWhite.withOpacity(0.5)),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: AppData.antiFlashWhite),
                      ),
                    ),
                    style: const TextStyle(color: AppData.antiFlashWhite),
                    maxLines: 3,
                    onSaved: (value) {
                      _notes = value ?? '';
                    },
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Icon(
                        _isFavorite ? Icons.star : Icons.star_border,
                        color: _isFavorite ? AppData.cerise : AppData.antiFlashWhite.withOpacity(0.7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Aggiungi ai preferiti',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppData.antiFlashWhite, 
                        ),
                      ),
                      Switch(
                        value: _isFavorite,
                        onChanged: (bool value) {
                          setState(() {
                            _isFavorite = value;
                          });
                        },
                        activeColor: AppData.cerise,
                        inactiveThumbColor: AppData.charcoal.withOpacity(0.5),
                        inactiveTrackColor: AppData.charcoal.withOpacity(0.7),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Icon(
                        _toBeRepeated ? Icons.repeat_on : Icons.repeat,
                        color: _toBeRepeated ? AppData.cerise : AppData.antiFlashWhite.withOpacity(0.7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Segna da ripetere',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppData.antiFlashWhite, 
                        ),
                      ),
                      Switch(
                        value: _toBeRepeated,
                        onChanged: (bool value) {
                          setState(() {
                            _toBeRepeated = value;
                          });
                        },
                        activeColor: AppData.cerise,
                        inactiveThumbColor: AppData.charcoal.withOpacity(0.5),
                        inactiveTrackColor: AppData.charcoal.withOpacity(0.7),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Immagini del viaggio:',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppData.antiFlashWhite, 
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Immagini esistenti
                        if (_existingImageUrls.isNotEmpty) ...[
                          Text(
                            'Foto già caricate:',
                            style: TextStyle(
                              color: AppData.antiFlashWhite.withOpacity(0.7), 
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _existingImageUrls.length,
                              itemBuilder: (ctx, index) {
                                final String sanitizedImageUrl = _sanitizeImagePath(_existingImageUrls[index]);
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.file(
                                          File(sanitizedImageUrl),
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            debugPrint('DEBUG - Errore caricamento immagine esistente: $sanitizedImageUrl, Errore: $error');
                                            return Container(
                                              width: 100,
                                              height: 100,
                                              color: AppData.charcoal.withOpacity(0.6), 
                                              child: Icon(
                                                Icons.broken_image,
                                                color: AppData.antiFlashWhite.withOpacity(0.7), 
                                                size: 40,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: GestureDetector(
                                          onTap: () => _removeImage(index, isExisting: true),
                                          child: const CircleAvatar(
                                            radius: 12,
                                            backgroundColor: Colors.red, 
                                            child: Icon(
                                              Icons.close,
                                              color: AppData.antiFlashWhite, 
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],

                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.add_a_photo, color: AppData.antiFlashWhite), 
                          label: const Text(
                            'Aggiungi Nuove Foto dalla Galleria',
                            style: TextStyle(color: AppData.antiFlashWhite), 
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppData.silverLakeBlue, 
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Nuove immagini selezionate
                        if (_newImagePaths.isNotEmpty)
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _newImagePaths.length,
                              itemBuilder: (ctx, index) {
                                final String sanitizedImageUrl = _sanitizeImagePath(_newImagePaths[index]);
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.file(
                                          File(sanitizedImageUrl),
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            debugPrint('DEBUG - Errore caricamento nuova immagine: $sanitizedImageUrl, Errore: $error');
                                            return Container(
                                              width: 100,
                                              height: 100,
                                              color: AppData.charcoal.withOpacity(0.6),
                                              child: Icon(
                                                Icons.broken_image,
                                                color: AppData.antiFlashWhite.withOpacity(0.7),
                                                size: 40,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: GestureDetector(
                                          onTap: () => _removeImage(index),
                                          child: const CircleAvatar(
                                            radius: 12,
                                            backgroundColor: Colors.red,
                                            child: Icon(
                                              Icons.close,
                                              color: AppData.antiFlashWhite,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}