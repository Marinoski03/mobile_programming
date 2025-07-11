// lib/screens/trip_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io'; // Per File (necessario per Image.file se mostri immagini locali)
import 'package:cached_network_image/cached_network_image.dart'; // NUOVO: Import per gestire immagini di rete

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
  late String _coverImageUrl; // Variabile per memorizzare l'URL dell'immagine di copertina

  @override
  void initState() {
    super.initState();
    _currentTrip = widget.trip;
    _setCoverImage(); // Imposta l'immagine di copertina iniziale
    _refreshTripDetails(); // Assicurati che i dettagli siano aggiornati all'apertura
  }

  // Metodo per impostare l'immagine di copertina, inclusi i casi di fallback
  void _setCoverImage() {
    if (_currentTrip.imageUrls.isNotEmpty) {
      // Se ci sono URL di immagini nel viaggio, prendi la prima come copertina
      // SANITIZZA IL PERCORSO QUI ANCHE PER LA COPERTINA
      _coverImageUrl = _sanitizeImagePath(_currentTrip.imageUrls.first);
    } else {
      // Altrimenti, usa l'immagine di default basata sul continente o l'immagine "Generale"
      _coverImageUrl =
          AppData.continentImages[_currentTrip.continent] ??
          AppData.continentImages['Generale']!;
    }
  }

  // NUOVO METODO: Funzione per pulire il percorso dell'immagine
  String _sanitizeImagePath(String path) {
    // Rimuove [" e "] all'inizio e alla fine e qualsiasi altra virgoletta doppia.
    return path.replaceAll('["', '').replaceAll('"]', '').replaceAll('"', '');
  }

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
          Navigator.of(context).pop(true); // Indica che il viaggio è stato eliminato
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
                  child: ClipRRect( // Aggiunto ClipRRect per applicare il border radius all'immagine stessa
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    child: _buildCoverImageWidget(_coverImageUrl), // Usa il nuovo metodo di costruzione
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
                                  final String rawImageUrl = _currentTrip.imageUrls[index];
                                  // SANITIZZA IL PERCORSO QUI
                                  final String imageUrl = _sanitizeImagePath(rawImageUrl);

                                  Widget imageWidget;
                                  if (imageUrl.startsWith('assets/')) {
                                    imageWidget = Image.asset(
                                      imageUrl,
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        print(
                                          'Errore caricamento asset galleria: $imageUrl, Errore: $error',
                                        );
                                        return _buildGalleryErrorPlaceholder();
                                      },
                                    );
                                  } else if (imageUrl.startsWith('http://') ||
                                      imageUrl.startsWith('https://')) {
                                    imageWidget = CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                      errorWidget: (context, url, error) {
                                        print(
                                          'Errore caricamento network galleria: $url, Errore: $error',
                                        );
                                        return _buildGalleryErrorPlaceholder();
                                      },
                                    );
                                  } else {
                                    // Presumi sia un percorso di file locale
                                    imageWidget = FutureBuilder<bool>(
                                      future: File(imageUrl).exists(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.done) {
                                          if (snapshot.hasError ||
                                              !(snapshot.data ?? false)) {
                                            print(
                                              'Errore caricamento file locale galleria: $imageUrl, Errore: ${snapshot.error ?? "File non trovato"}',
                                            );
                                            return _buildGalleryErrorPlaceholder();
                                          } else {
                                            return Image.file(
                                              File(imageUrl),
                                              width: 120,
                                              height: 120,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                print(
                                                  'Errore caricamento Image.file galleria: $imageUrl, Errore: $error',
                                                );
                                                return _buildGalleryErrorPlaceholder();
                                              },
                                            );
                                          }
                                        }
                                        return const Center(child: CircularProgressIndicator());
                                      },
                                    );
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: imageWidget, // Usa il widget creato dinamicamente
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

  // NUOVO METODO: Per gestire i diversi tipi di URL per l'immagine di copertina
  Widget _buildCoverImageWidget(String imageUrl) {
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Errore caricamento asset copertina: $imageUrl, Errore: $error');
          return _buildErrorPlaceholder();
        },
      );
    } else if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) =>
            const Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) {
          print('Errore caricamento network copertina: $url, Errore: $error');
          return _buildErrorPlaceholder();
        },
      );
    } else {
      // Consideriamo che sia un percorso di file locale (dal simulatore/dispositivo)
      // Usiamo FutureBuilder per verificare l'esistenza del file
      return FutureBuilder<bool>(
        future: File(imageUrl).exists(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError || !(snapshot.data ?? false)) {
              // Il file non esiste o c'è stato un errore
              print('Errore caricamento file locale copertina: $imageUrl, Errore: ${snapshot.error ?? "File non trovato"}');
              return _buildErrorPlaceholder();
            } else {
              // Il file esiste, caricalo
              return Image.file(
                File(imageUrl),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  print('Errore caricamento Image.file copertina: $imageUrl, Errore: $error');
                  return _buildErrorPlaceholder();
                },
              );
            }
          }
          // Mentre aspettiamo, mostra un indicatore di caricamento
          return const Center(child: CircularProgressIndicator());
        },
      );
    }
  }

  // Piccolo widget di utility per il placeholder in caso di errore (copertina)
  Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.grey[800], // Sfondo scuro per indicare l'errore
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, color: Colors.white70, size: 60),
            SizedBox(height: 8),
            Text(
              'Immagine non trovata',
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Piccolo widget di utility per il placeholder in caso di errore nella galleria
  Widget _buildGalleryErrorPlaceholder() {
    return Container(
      width: 120,
      height: 120,
      color: Colors.grey[700],
      child: const Icon(
        Icons.broken_image,
        color: Colors.white70,
        size: 50,
      ),
    );
  }
}