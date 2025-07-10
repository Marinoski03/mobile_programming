// lib/screens/trip_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io'; // Per File
import 'package:image_picker/image_picker.dart'; // Per XFile, se la userai per la selezione immagini qui

import '../models/trip.dart';
import '../helpers/trip_database_helper.dart';
import 'add_edit_trip_screen.dart'; // Per la navigazione alla schermata di modifica
import '../utils/app_data.dart'; // Per AppData.continentImages

class TripDetailScreen extends StatefulWidget {
  final Trip trip;

  const TripDetailScreen({super.key, required this.trip});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  late Trip _currentTrip;

  @override
  void initState() {
    super.initState();
    _currentTrip = widget.trip;
    _refreshTripDetails(); // Assicurati che i dettagli siano aggiornati all'apertura
  }

  // Metodo per ricaricare i dettagli del viaggio dal database
  Future<void> _refreshTripDetails() async {
    final updatedTrip = await TripDatabaseHelper.instance.getTripById(
      _currentTrip.id!,
    );
    if (updatedTrip != null && mounted) {
      setState(() {
        _currentTrip = updatedTrip;
      });
    }
  }

  Future<void> _navigateToEditScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditTripScreen(
          trip: _currentTrip,
        ), // Passa il viaggio per la modifica
      ),
    );
    _refreshTripDetails(); // Aggiorna i dettagli al ritorno dalla modifica
  }

  Future<void> _toggleFavorite() async {
    final updatedTrip = _currentTrip.copy(isFavorite: !_currentTrip.isFavorite);
    await TripDatabaseHelper.instance.updateTrip(updatedTrip);
    _refreshTripDetails(); // Aggiorna UI e database
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updatedTrip.isFavorite
                ? 'Viaggio aggiunto ai preferiti!'
                : 'Viaggio rimosso dai preferiti.',
          ),
        ),
      );
    }
  }

  Future<void> _toggleRepeat() async {
    final updatedTrip = _currentTrip.copy(
      toBeRepeated: !_currentTrip.toBeRepeated,
    );
    await TripDatabaseHelper.instance.updateTrip(updatedTrip);
    _refreshTripDetails(); // Aggiorna UI e database
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updatedTrip.toBeRepeated
                ? 'Viaggio segnato da ripetere!'
                : 'Viaggio rimosso da "da ripetere".',
          ),
        ),
      );
    }
  }

  Future<void> _deleteTrip() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma eliminazione'),
        content: const Text('Sei sicuro di voler eliminare questo viaggio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await TripDatabaseHelper.instance.deleteTrip(_currentTrip.id!);
      if (mounted) {
        Navigator.of(
          context,
        ).pop(true); // Ritorna true per indicare eliminazione
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Viaggio eliminato con successo!')),
        );
      }
    }
  }

  // Helper per ottenere l'ImageProvider corretto
  ImageProvider _getImageProvider(String imageUrl) {
    if (imageUrl.startsWith('assets/')) {
      return AssetImage(imageUrl);
    } else if (imageUrl.startsWith('/data/') ||
        imageUrl.startsWith('file://')) {
      final file = File(imageUrl.replaceFirst('file://', ''));
      if (file.existsSync()) {
        return FileImage(file);
      } else {
        print(
          'DEBUG - TripDetailScreen: File immagine locale non trovato: $imageUrl',
        );
        // Fallback a immagine del continente o generica
        return AssetImage(
          AppData.continentImages[_currentTrip
                  .continent] ?? // <--- CORREZIONE QUI
              AppData.continentImages['Generale'] ?? // <--- CORREZIONE QUI
              'assets/images/default_trip.jpg', // Fallback finale
        );
      }
    } else {
      // Per URL web o altri casi non riconosciuti, usa un fallback generico
      return AssetImage(
        AppData.continentImages[_currentTrip
                .continent] ?? // <--- CORREZIONE QUI
            AppData.continentImages['Generale'] ?? // <--- CORREZIONE QUI
            'assets/images/default_trip.jpg', // Fallback finale
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determina l'URL dell'immagine di copertina
    final String coverImageUrl = _currentTrip.imageUrls.isNotEmpty
        ? _currentTrip.imageUrls.first
        : AppData.continentImages[_currentTrip
                  .continent] ?? // <--- CORREZIONE QUI
              AppData.continentImages['Generale'] ?? // <--- CORREZIONE QUI
              'assets/images/default_trip.jpg'; // Fallback finale

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: _navigateToEditScreen,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: _deleteTrip,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ShaderMask(
                  shaderCallback: (rect) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black],
                    ).createShader(
                      Rect.fromLTRB(0, 0, rect.width, rect.height),
                    );
                  },
                  blendMode: BlendMode.dstIn,
                  child: Image(
                    image: _getImageProvider(coverImageUrl), // Usa l'helper
                    height: 300,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print('DEBUG - Error loading cover image: $error');
                      return Container(
                        height: 300,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.error, color: Colors.red, size: 50),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentTrip.location,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '${DateFormat('dd/MM/yyyy').format(_currentTrip.startDate)} - ${DateFormat('dd/MM/yyyy').format(_currentTrip.endDate)}',
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _toggleFavorite,
                        icon: Icon(
                          _currentTrip.isFavorite
                              ? Icons.star
                              : Icons.star_border,
                          color: _currentTrip.isFavorite ? Colors.amber : null,
                        ),
                        label: Text(
                          _currentTrip.isFavorite ? 'Preferito' : 'Preferito',
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _toggleRepeat,
                        icon: Icon(
                          _currentTrip.toBeRepeated
                              ? Icons.repeat_on
                              : Icons.repeat,
                          color: _currentTrip.toBeRepeated ? Colors.blue : null,
                        ),
                        label: Text(
                          _currentTrip.toBeRepeated
                              ? 'Segnato da ripetere'
                              : 'Segna da ripetere',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Categoria: ${_currentTrip.category}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Note personali:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _currentTrip.notes.isNotEmpty
                        ? _currentTrip.notes
                        : 'Nessuna nota aggiunta.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Galleria immagini:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _currentTrip.imageUrls.isEmpty
                      ? Center(
                          child: Text(
                            'Nessuna immagine specifica aggiunta per questo viaggio.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8.0,
                                mainAxisSpacing: 8.0,
                              ),
                          itemCount: _currentTrip.imageUrls.length,
                          itemBuilder: (context, index) {
                            final imageUrl = _currentTrip.imageUrls[index];
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image(
                                // Usa Image widget
                                image: _getImageProvider(
                                  imageUrl,
                                ), // Passa solo imageUrl qui
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  print(
                                    'DEBUG - Errore caricamento immagine galleria: $error',
                                  );
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: Icon(
                                        Icons.error,
                                        color: Colors.red,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
