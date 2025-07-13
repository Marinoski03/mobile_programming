// lib/screens/add_edit_trip_screen.dart

// lib/screens/add_edit_trip_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'dart:convert'; // Import for JSON decoding
import 'package:http/http.dart' as http; // Import http package
import 'dart:async'; // Import for Timer (debouncing)

import '../models/trip.dart';
import '../helpers/trip_database_helper.dart';
import '../utils/app_data.dart'; // Importa AppData

class AddEditTripScreen extends StatefulWidget {
  final Trip? trip; // Trip è ora opzionale per la creazione

  const AddEditTripScreen({super.key, this.trip});

  @override
  State<AddEditTripScreen> createState() => _AddEditTripScreenState();
}

class _AddEditTripScreenState extends State<AddEditTripScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late String _selectedLocation; // This will be the full selected location name
  late DateTime _startDate;
  late DateTime _endDate;
  late String _category;
  late String _notes;
  late bool _isFavorite;
  late bool _toBeRepeated;

  final List<String> _newImagePaths = [];
  final List<String> _existingImageUrls = [];

  // Nominatim related variables
  TextEditingController _locationSearchController = TextEditingController();
  List<dynamic> _locationSuggestions = [];
  Timer? _debounce;

  // NUOVO METODO: Funzione per pulire il percorso dell'immagine
  String _sanitizeImagePath(String path) {
    // Rimuove [" e "] all'inizio e alla fine e qualsiasi altra virgoletta doppia.
    return path.replaceAll('["', '').replaceAll('"]', '').replaceAll('"', '');
  }

  @override
  void initState() {
    super.initState();
    if (widget.trip != null) {
      _title = widget.trip!.title;
      _selectedLocation = widget.trip!.location;
      _locationSearchController.text =
          widget.trip!.location; // Set initial value for search field
      _startDate = widget.trip!.startDate;
      _endDate = widget.trip!.endDate;
      _category = widget.trip!.category;
      _notes = widget.trip!.notes;
      _isFavorite = widget.trip!.isFavorite;
      _toBeRepeated = widget.trip!.toBeRepeated;
      // Modificato: SANITIZZA I PERCORSI DELLE IMMAGINI ESISTENTI AL CARICAMENTO
      for (String url in widget.trip!.imageUrls) {
        _existingImageUrls.add(_sanitizeImagePath(url));
      }
    } else {
      _title = '';
      _selectedLocation = ''; // Initialize as empty for new trips
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
          print(
            'DEBUG - File temporaneo non trovato, potrebbe essere stato cancellato: ${imageFile.path}',
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Immagine selezionata temporanea non trovata, riprova.',
                ),
              ),
            );
          }
          continue;
        }

        final String fileName =
            '${DateTime.now().microsecondsSinceEpoch}_${p.basename(imageFile.path)}';
        final String savedPath = p.join(appDir.path, fileName);

        final newFile = await imageFile.copy(savedPath);
        // NON SANITIZZARE QUI, IL PATH È GIÀ CORRETTO DA ImagePicker E copy
        tempSavedPaths.add(newFile.path);
        print('DEBUG - Immagine copiata e salvata in: ${newFile.path}');
      } catch (e) {
        print('Errore durante la copia dell\'immagine ${xFile.path}: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Errore durante la copia di un\'immagine: $e'),
            ),
          );
        }
      }
    }

    setState(() {
      _newImagePaths.addAll(tempSavedPaths);
    });
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

  // NEW: Function to search for locations using Nominatim
  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) {
      setState(() {
        _locationSuggestions = [];
      });
      return;
    }

    // Nominatim's free public usage policy requests clients to limit requests to 1 request per second.
    // Ensure you respect their Usage Policy: https://nominatim.org/release-docs/latest/api/Search/
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=5',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          _locationSuggestions = json.decode(response.body);
        });
      } else {
        print('Nominatim API error: ${response.statusCode}');
        setState(() {
          _locationSuggestions = [];
        });
      }
    } catch (e) {
      print('Error fetching location suggestions: $e');
      setState(() {
        _locationSuggestions = [];
      });
    }
  }

  // NEW: Debounce function for location search
  void _onLocationSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchLocation(query);
    });
  }

  // NEW: Function to handle selection of a suggested location
  void _selectLocationSuggestion(Map<String, dynamic> suggestion) {
    setState(() {
      _selectedLocation = suggestion['display_name'];
      _locationSearchController.text = suggestion['display_name'];
      _locationSuggestions = []; // Clear suggestions after selection

      // Attempt to infer continent from addressdetails if available
      // This is a heuristic and might not always be accurate or available
    });
  }

  void _saveTrip() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Ensure _selectedLocation is set from the text controller if no suggestion was explicitly picked
      // This handles cases where the user types but doesn't select from suggestions
      if (_selectedLocation.isEmpty &&
          _locationSearchController.text.isNotEmpty) {
        _selectedLocation = _locationSearchController.text;
      } else if (_locationSearchController.text.isEmpty) {
        _selectedLocation = 'Nessuna Nazione'; // Or handle as validation error
      }

      // I percorsi sono già stati sanitizzati all'inizio (per existing)
      // e sono già puliti da ImagePicker (per new)
      final List<String> allImageUrls = List.from(_existingImageUrls);
      allImageUrls.addAll(_newImagePaths);

      final newTrip = Trip(
        id: widget.trip?.id,
        title: _title,
        location: _selectedLocation, // Use the selected/typed location
        startDate: _startDate,
        endDate: _endDate,
        category: _category,
        notes: _notes,
        imageUrls: allImageUrls,
        isFavorite: _isFavorite,
        toBeRepeated: _toBeRepeated,
      );

      print(
        'DEBUG - Percorsi immagini finali (per DB) prima del POP: $allImageUrls',
      );

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
        print('Errore durante il salvataggio del viaggio nel DB: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore durante il salvataggio: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          widget.trip == null ? 'Aggiungi Viaggio' : 'Modifica Viaggio',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _saveTrip,
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade300, Colors.blue.shade800],
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
                    decoration: const InputDecoration(
                      labelText: 'Titolo del Viaggio',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Inserisci un titolo per il viaggio';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _title = value!;
                    },
                  ),
                  const SizedBox(height: 20),

                  // MODIFIED: Replaced Nazione Dropdown with a TextFormField for Nominatim search
                  TextFormField(
                    controller: _locationSearchController,
                    decoration: InputDecoration(
                      labelText: 'Cerca Nazione / Città',
                      labelStyle: const TextStyle(color: Colors.white70),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      suffixIcon: _locationSearchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.white70,
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
                    style: const TextStyle(color: Colors.white),
                    onChanged:
                        _onLocationSearchChanged, // Call the debounced search function
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Inserisci una nazione o città';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _selectedLocation =
                          value!; // Save the final text in the field
                    },
                  ),
                  // Display search suggestions
                  if (_locationSuggestions.isNotEmpty)
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: 200,
                      ), // Limit height
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _locationSuggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = _locationSuggestions[index];
                          return ListTile(
                            title: Text(
                              suggestion['display_name'],
                              style: const TextStyle(color: Colors.white),
                            ),
                            onTap: () => _selectLocationSuggestion(suggestion),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _presentDatePicker(true),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Data Inizio',
                              labelStyle: const TextStyle(
                                color: Colors.white70,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: const BorderSide(
                                  color: Colors.white54,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: const BorderSide(
                                  color: Colors.white54,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: const BorderSide(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('dd/MM/yyyy').format(_startDate),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                const Icon(
                                  Icons.calendar_today,
                                  color: Colors.white,
                                ),
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
                              labelStyle: const TextStyle(
                                color: Colors.white70,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: const BorderSide(
                                  color: Colors.white54,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: const BorderSide(
                                  color: Colors.white54,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: const BorderSide(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('dd/MM/yyyy').format(_endDate),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                const Icon(
                                  Icons.calendar_today,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Categoria',
                      labelStyle: const TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: const BorderSide(color: Colors.white54),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: const BorderSide(color: Colors.white54),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _category,
                        dropdownColor: Colors.blue.shade700,
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.white,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        onChanged: (String? newValue) {
                          setState(() {
                            _category = newValue!;
                          });
                        },
                        items: AppData.categories.map<DropdownMenuItem<String>>(
                          (String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          },
                        ).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    initialValue: _notes,
                    decoration: const InputDecoration(
                      labelText: 'Note Personali',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    maxLines: 3,
                    onSaved: (value) {
                      _notes = value!;
                    },
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Icon(
                        _isFavorite ? Icons.star : Icons.star_border,
                        color: _isFavorite
                            ? Colors.amberAccent
                            : Colors.white70,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Aggiungi ai preferiti',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(color: Colors.white),
                      ),
                      Switch(
                        value: _isFavorite,
                        onChanged: (bool value) {
                          setState(() {
                            _isFavorite = value;
                          });
                        },
                        activeColor: Colors.amber,
                        inactiveThumbColor: Colors.grey,
                        inactiveTrackColor: Colors.grey.shade700,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Icon(
                        _toBeRepeated ? Icons.repeat_on : Icons.repeat,
                        color: _toBeRepeated
                            ? Colors.greenAccent
                            : Colors.white70,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Segna da ripetere',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(color: Colors.white),
                      ),
                      Switch(
                        value: _toBeRepeated,
                        onChanged: (bool value) {
                          setState(() {
                            _toBeRepeated = value;
                          });
                        },
                        activeColor: Colors.green,
                        inactiveThumbColor: Colors.grey,
                        inactiveTrackColor: Colors.grey.shade700,
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
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 10),

                        if (_existingImageUrls.isNotEmpty) ...[
                          const Text(
                            'Foto già caricate:',
                            style: TextStyle(
                              color: Colors.white70,
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
                                final String sanitizedImageUrl =
                                    _sanitizeImagePath(
                                      _existingImageUrls[index],
                                    );
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
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                print(
                                                  'DEBUG - Errore caricamento immagine esistente in anteprima: $sanitizedImageUrl, Errore: $error',
                                                );
                                                return Container(
                                                  width: 100,
                                                  height: 100,
                                                  color: Colors.grey[600],
                                                  child: const Icon(
                                                    Icons.broken_image,
                                                    color: Colors.white70,
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
                                          onTap: () => _removeImage(
                                            index,
                                            isExisting: true,
                                          ),
                                          child: const CircleAvatar(
                                            radius: 12,
                                            backgroundColor: Colors.red,
                                            child: Icon(
                                              Icons.close,
                                              color: Colors.white,
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
                          icon: const Icon(
                            Icons.add_a_photo,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Aggiungi Nuove Foto dalla Galleria',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        if (_newImagePaths.isNotEmpty)
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _newImagePaths.length,
                              itemBuilder: (ctx, index) {
                                final String sanitizedImageUrl =
                                    _sanitizeImagePath(_newImagePaths[index]);
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
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                print(
                                                  'DEBUG - Errore caricamento nuova immagine in anteprima: $sanitizedImageUrl, Errore: $error',
                                                );
                                                return Container(
                                                  width: 100,
                                                  height: 100,
                                                  color: Colors.grey[600],
                                                  child: const Icon(
                                                    Icons.broken_image,
                                                    color: Colors.white70,
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
                                              color: Colors.white,
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
