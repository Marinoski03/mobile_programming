// lib/screens/add_edit_trip_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

import '../models/trip.dart';
import '../helpers/trip_database_helper.dart';
import '../utils/app_data.dart'; // Importa AppData

class AddEditTripScreen extends StatefulWidget {
  final Trip? trip; // Trip è ora opzionale per la creazione

  const AddEditTripScreen({super.key, this.trip});

  @override
  State<AddEditTripScreen> createState() => _AddEditTripScreenState(); // <-- CORRETTO: Restituisce _AddEditTripScreenState
}

class _AddEditTripScreenState extends State<AddEditTripScreen> {
  // <-- CORRETTO: Il nome della classe State è _AddEditTripScreenState
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late String _selectedContinent;
  late String _selectedLocation;
  late DateTime _startDate;
  late DateTime _endDate;
  late String _category;
  late String _notes;
  late bool _isFavorite;
  late bool _toBeRepeated; // Già corretto in precedenza
  // ... il resto del codice rimane invariato

  // Modificato: _newImagePaths conterrà i percorsi delle nuove immagini salvate
  final List<String> _newImagePaths = [];
  // Modificato: _existingImageUrls conterrà gli URL delle immagini esistenti dal DB
  final List<String> _existingImageUrls = [];

  final List<String> _categories = [
    'Generale',
    'Cultura',
    'Natura',
    'Relax',
    'Avventura',
    'Lavoro',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.trip != null) {
      _title = widget.trip!.title;
      _selectedContinent = widget.trip!.continent;
      _selectedLocation = widget.trip!.location;
      _startDate = widget.trip!.startDate;
      _endDate = widget.trip!.endDate;
      _category = widget.trip!.category;
      _notes = widget.trip!.notes;
      _isFavorite = widget.trip!.isFavorite;
      _toBeRepeated = widget.trip!.toBeRepeated; // <--- CORRETTO
      // Inizializza le immagini esistenti dal viaggio (sono già percorsi permanenti)
      _existingImageUrls.addAll(widget.trip!.imageUrls);
    } else {
      _title = '';
      _selectedContinent = AppData.continents.first;
      _selectedLocation = AppData
          .countriesByContinent[_selectedContinent]!
          .first; // Assicurati che non sia vuoto
      _startDate = DateTime.now();
      _endDate = DateTime.now().add(const Duration(days: 7));
      // Usa la prima categoria da AppData.categories
      _category = AppData.categories.first;
      _notes = '';
      _isFavorite = false;
      _toBeRepeated = false; // <--- CORRETTO
    }
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

  // --- METODO AGGIORNATO PER SELEZIONARE E COPIARE SUBITO LE IMMAGINI ---
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(
      imageQuality: 70,
      maxWidth: 1000,
    );

    if (pickedFiles.isEmpty) {
      return; // Nessuna immagine selezionata
    }

    final appDir = await getApplicationDocumentsDirectory();
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }

    List<String> tempSavedPaths =
        []; // Per tenere traccia dei percorsi delle immagini appena salvate

    for (XFile xFile in pickedFiles) {
      try {
        final File imageFile = File(xFile.path);

        // Controllo robusto: verifica che il file temporaneo esista prima di copiarlo
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
          continue; // Salta questo file e passa al successivo
        }

        // Genera un nome di file univoco
        final String fileName =
            '${DateTime.now().microsecondsSinceEpoch}_${p.basename(imageFile.path)}';
        final String savedPath = p.join(appDir.path, fileName);

        // Copia il file nella directory permanente dell'app
        final newFile = await imageFile.copy(savedPath);
        tempSavedPaths.add(newFile.path); // Aggiungi il percorso permanente
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
      _newImagePaths.addAll(
        tempSavedPaths,
      ); // Aggiunge i percorsi delle nuove immagini già salvate
    });
  }

  // Metodo per rimuovere un'immagine (sia nuova che esistente)
  void _removeImage(int index, {bool isExisting = false}) {
    setState(() {
      if (isExisting) {
        // Rimuovi la dichiarazione della variabile, non è più necessaria
        // final String imageUrlToRemove = _existingImageUrls[index]; // RIMUOVI QUESTA RIGA
        _existingImageUrls.removeAt(index);
        // Assicurati che TUTTA la logica di eliminazione fisica sia rimossa o commentata
        // (le righe che iniziavano con 'if (imageUrlToRemove.startsWith...')
      } else {
        // Rimuovi la dichiarazione della variabile, non è più necessaria
        // final String imagePathToRemove = _newImagePaths[index]; // RIMUOVI QUESTA RIGA
        _newImagePaths.removeAt(index);
        // Assicurati che TUTTA la logica di eliminazione fisica sia rimossa o commentata
        // (le righe che iniziavano con 'try { File(imagePathToRemove).deleteSync()...')
      }
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != (isStartDate ? _startDate : _endDate)) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate.add(
              const Duration(days: 7),
            ); // Assicura che la data di fine sia dopo l'inizio
          }
        } else {
          _endDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _startDate = _endDate.subtract(
              const Duration(days: 7),
            ); // Assicura che la data di inizio sia prima della fine
          }
        }
      });
    }
  }

  void _saveTrip() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Combina immagini esistenti e nuove immagini già salvate
      final List<String> allImageUrls = List.from(_existingImageUrls);
      allImageUrls.addAll(
        _newImagePaths,
      ); // Aggiunge i percorsi permanenti delle nuove immagini

      final newTrip = Trip(
        id: widget.trip?.id,
        title: _title,
        location: _selectedLocation,
        continent: _selectedContinent,
        startDate: _startDate,
        endDate: _endDate,
        category: _category,
        notes: _notes,
        imageUrls: allImageUrls, // Ora contiene solo percorsi permanenti
        isFavorite: _isFavorite,
        toBeRepeated:
            _toBeRepeated, // <--- CORRETTO: da _toRepeat a _toBeRepeated
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
    List<String> countriesForSelectedContinent =
        AppData.countriesByContinent[_selectedContinent] ?? [];
    if (!countriesForSelectedContinent.contains(_selectedLocation) &&
        countriesForSelectedContinent.isNotEmpty) {
      _selectedLocation = countriesForSelectedContinent.first;
    } else if (countriesForSelectedContinent.isEmpty) {
      _selectedLocation = 'Nessuna Nazione';
    }

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

                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Continente',
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
                        value: _selectedContinent,
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
                            _selectedContinent = newValue!;
                            _selectedLocation =
                                AppData
                                    .countriesByContinent[_selectedContinent]!
                                    .isNotEmpty
                                ? AppData
                                      .countriesByContinent[_selectedContinent]!
                                      .first
                                : 'Nessuna Nazione';
                          });
                        },
                        items: AppData.continents.map<DropdownMenuItem<String>>(
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

                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Nazione',
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
                        value: _selectedLocation,
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
                            _selectedLocation = newValue!;
                          });
                        },
                        items: countriesForSelectedContinent
                            .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            })
                            .toList(),
                      ),
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

                  // Dropdown per la Categoria (ora usa AppData.categories)
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
                        // ***** USA AppData.categories QUI *****
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
                        _toBeRepeated
                            ? Icons.repeat_on
                            : Icons.repeat, // <--- CORRETTO
                        color: _toBeRepeated
                            ? Colors.greenAccent
                            : Colors.white70, // <--- CORRETTO
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Segna da ripetere',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(color: Colors.white),
                      ),
                      Switch(
                        value: _toBeRepeated, // <--- CORRETTO
                        onChanged: (bool value) {
                          setState(() {
                            _toBeRepeated = value; // <--- CORRETTO
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

                        // Galleria di immagini ESISTENTI (se in modalità modifica)
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
                                final imageUrl = _existingImageUrls[index];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.file(
                                          // Usa Image.file per percorsi locali
                                          File(imageUrl),
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                print(
                                                  'DEBUG - Errore caricamento immagine esistente in anteprima: $imageUrl, Errore: $error',
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

                        // Pulsante per aggiungere immagini
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

                        // Anteprime delle NUOVE immagini selezionate (già salvate temporaneamente)
                        if (_newImagePaths.isNotEmpty)
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _newImagePaths.length,
                              itemBuilder: (ctx, index) {
                                final imageUrl =
                                    _newImagePaths[index]; // Percorso dell'immagine
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.file(
                                          File(
                                            imageUrl,
                                          ), // Visualizza il file locale
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                print(
                                                  'DEBUG - Errore caricamento nuova immagine in anteprima: $imageUrl, Errore: $error',
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
                                          ), // Rimuove dalla lista delle nuove
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
                        const SizedBox(height: 80), // Spazio per il FAB
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
