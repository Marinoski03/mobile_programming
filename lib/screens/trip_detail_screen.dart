// lib/screens/trip_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io'; // Per File (necessario per Image.file se mostri immagini locali)
// import 'package:image_picker/image_picker.dart'; // Rimuovi questo import se non usi ImagePicker qui

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
  late String
  _coverImageUrl; // Variabile per memorizzare l'URL dell'immagine di copertina

  @override
  void initState() {
    super.initState();
    _currentTrip = widget.trip;
    _setCoverImage(); // Imposta l'immagine di copertina iniziale
    _refreshTripDetails(); // Assicurati che i dettagli siano aggiornati all'apertura
  }

  // >>> INIZIO DEL METODO _setCoverImage MANCANTE <<<
  // Metodo per impostare l'immagine di copertina, inclusi i casi di fallback
  void _setCoverImage() {
    if (_currentTrip.imageUrls.isNotEmpty) {
      // Se ci sono URL di immagini nel viaggio, prendi la prima come copertina
      _coverImageUrl = _currentTrip.imageUrls.first;
    } else {
      // Altrimenti, usa l'immagine di default basata sul continente o l'immagine "Generale"
      _coverImageUrl =
          AppData.continentImages[_currentTrip.continent] ??
          AppData.continentImages['Generale']!;
    }
  }
  // >>> FINE DEL METODO _setCoverImage MANCANTE <<<

  // Metodo per ricaricare i dettagli del viaggio dal database
  Future<void> _refreshTripDetails() async {
    try {
      final updatedTrip = await TripDatabaseHelper.instance.getTripById(
        _currentTrip.id!,
      );
      if (mounted) {
        // Manteniamo mounted per sicurezza
        setState(() {
          _currentTrip = updatedTrip;
          _setCoverImage(); // Aggiorna l'immagine di copertina dopo il refresh
        });
      }
    } catch (e) {
      print('Errore durante il ricaricamento del viaggio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossibile ricaricare i dettagli del viaggio: $e'),
          ),
        );
      }
    }
  }

  // Metodo per gestire l'eliminazione del viaggio
  void _deleteTrip() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Conferma Eliminazione'),
        content: const Text('Sei sicuro di voler eliminare questo viaggio?'),
        actions: <Widget>[
          TextButton(
            child: const Text('Annulla'),
            onPressed: () {
              Navigator.of(ctx).pop(false);
            },
          ),
          TextButton(
            child: const Text('Elimina', style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.of(ctx).pop(true);
            },
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await TripDatabaseHelper.instance.deleteTrip(_currentTrip.id!);
        if (mounted) {
          Navigator.of(
            context,
          ).pop(true); // Indica che il viaggio è stato eliminato
        }
      } catch (e) {
        print('Errore durante l\'eliminazione del viaggio: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Errore durante l\'eliminazione: $e')),
          );
        }
      }
    }
  }

  // Metodo per navigare alla schermata di modifica
  void _editTrip() async {
    final updatedTrip = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => AddEditTripScreen(trip: _currentTrip),
      ),
    );

    if (updatedTrip != null && mounted) {
      setState(() {
        _currentTrip = updatedTrip as Trip; // Assicurati il tipo
        _setCoverImage(); // Aggiorna l'immagine di copertina
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          _currentTrip.title,
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
            icon: Icon(
              _currentTrip.isFavorite ? Icons.star : Icons.star_border,
              color: Colors.white,
            ),
            onPressed: () async {
              // Inverti lo stato di preferito e aggiorna il DB
              final updatedTrip = _currentTrip.copy(
                isFavorite: !_currentTrip.isFavorite,
              );
              try {
                await TripDatabaseHelper.instance.updateTrip(updatedTrip);
                setState(() {
                  _currentTrip = updatedTrip;
                });
              } catch (e) {
                print('Errore nell\'aggiornare lo stato di preferito: $e');
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: _editTrip,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: _deleteTrip,
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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Immagine di copertina del viaggio
                Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      // Gestisce sia percorsi di file che asset
                      image: _coverImageUrl.startsWith('assets/')
                          ? AssetImage(_coverImageUrl)
                          : FileImage(File(_coverImageUrl)) as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
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
                      const SizedBox(height: 5),
                      Text(
                        '${DateFormat('dd/MM/yyyy').format(_currentTrip.startDate)} - ${DateFormat('dd/MM/yyyy').format(_currentTrip.endDate)}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          _currentTrip.isFavorite
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade700,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Preferito',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink(), // Non mostrare nulla se non è preferito
                          const SizedBox(width: 10), // Spazio tra i bottoni

                          _currentTrip.toBeRepeated
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade700,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.repeat,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Segna da ripetere',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink(), // Non mostrare nulla se non è da ripetere
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Categoria: ${_currentTrip.category}',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Note personali:',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        _currentTrip.notes.isNotEmpty
                            ? _currentTrip.notes
                            : 'Nessuna nota aggiunta.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Galleria immagini:',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _currentTrip.imageUrls.isNotEmpty
                          ? SizedBox(
                              height: 120, // Altezza fissa per la galleria
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _currentTrip.imageUrls.length,
                                itemBuilder: (ctx, index) {
                                  final imageUrl =
                                      _currentTrip.imageUrls[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.file(
                                        File(imageUrl),
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          print(
                                            'Errore caricamento immagine viaggio: $imageUrl, Errore: $error',
                                          );
                                          return Container(
                                            width: 120,
                                            height: 120,
                                            color: Colors.grey[600],
                                            child: const Icon(
                                              Icons.broken_image,
                                              color: Colors.white70,
                                              size: 50,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : Text(
                              'Nessuna immagine specifica aggiunta per questo viaggio.',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: Colors.white70),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
