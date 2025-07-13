// lib/screens/trip_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io'; // Per File (necessario per Image.file se mostri immagini locali)
import 'package:cached_network_image/cached_network_image.dart'; // Import per gestire immagini di rete

import '../models/trip.dart';
import '../helpers/trip_database_helper.dart';
import 'add_edit_trip_screen.dart'; // Per la navigazione alla schermata di modifica
import '../utils/app_data.dart'; // Importa AppData per i colori

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
      _coverImageUrl = _sanitizeImagePath(_currentTrip.imageUrls.first);
    } else {
      // Imposta un'immagine di fallback se non ci sono URL
      _coverImageUrl = 'assets/images/default_trip_cover.png'; // Assicurati che questo percorso esista!
    }
  }

  // Funzione per pulire il percorso dell'immagine
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
        setState(() {
          _currentTrip = updatedTrip;
          _setCoverImage(); // Aggiorna l'immagine di copertina dopo il refresh
        });
      }
    } catch (e) {
      debugPrint('Errore durante il ricaricamento del viaggio: $e');
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
        // Colori dell'AlertDialog (sfondo e testo) come da palette
        backgroundColor: AppData.antiFlashWhite,
        title: const Text(
          'Conferma Eliminazione',
          style: TextStyle(color: AppData.charcoal),
        ),
        content: const Text(
          'Sei sicuro di voler eliminare questo viaggio?',
          style: TextStyle(color: AppData.charcoal),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text(
              'Annulla',
              style: TextStyle(color: AppData.silverLakeBlue),
            ),
            onPressed: () {
              Navigator.of(ctx).pop(false);
            },
          ),
          TextButton(
            // Colore del testo "Elimina" aggiornato a AppData.cerise
            child: const Text('Elimina', style: TextStyle(color: AppData.cerise)),
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
        debugPrint('Errore durante l\'eliminazione del viaggio: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Errore durante l\'eliminazione: $e',
                style: const TextStyle(color: AppData.antiFlashWhite),
              ),
              backgroundColor: AppData.errorRed,
            ),
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
      backgroundColor: Colors.transparent, // Lo sfondo sarà gestito dal Container sottostante
      appBar: AppBar(
        title: Text(
          _currentTrip.title,
          // Colore del titolo aggiornato a AppData.antiFlashWhite
          style: const TextStyle(color: AppData.antiFlashWhite),
        ),
        backgroundColor: Colors.transparent, // Mantenuta trasparente per il gradiente
        elevation: 0,
        leading: IconButton(
          // Colore dell'icona indietro aggiornato a AppData.antiFlashWhite
          icon: const Icon(Icons.arrow_back, color: AppData.antiFlashWhite),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              _currentTrip.isFavorite ? Icons.star : Icons.star_border,
              // Colore dell'icona preferito aggiornato a AppData.antiFlashWhite
              color: AppData.antiFlashWhite,
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
                debugPrint('Errore nell\'aggiornare lo stato di preferito: $e');
              }
            },
          ),
          IconButton(
            // Colore dell'icona modifica aggiornato a AppData.antiFlashWhite
            icon: const Icon(Icons.edit, color: AppData.antiFlashWhite),
            onPressed: _editTrip,
          ),
          IconButton(
            // Colore dell'icona elimina aggiornato a AppData.antiFlashWhite
            icon: const Icon(Icons.delete, color: AppData.antiFlashWhite),
            onPressed: _deleteTrip,
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          // Colori del gradiente aggiornati con AppData
          gradient: LinearGradient(
            colors: [AppData.silverLakeBlue.withOpacity(0.7), AppData.charcoal.withOpacity(0.9)],
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
                        // Colore dell'ombra aggiornato a AppData.charcoal
                        color: AppData.charcoal.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    child: _buildCoverImageWidget(_coverImageUrl),
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
                              // Colore del testo aggiornato a AppData.antiFlashWhite
                              color: AppData.antiFlashWhite,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${DateFormat('dd/MM/yyyy').format(_currentTrip.startDate)} - ${DateFormat('dd/MM/yyyy').format(_currentTrip.endDate)}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: AppData.antiFlashWhite.withOpacity(0.7)), // Colore aggiornato
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
                                    // Colore del badge Preferito aggiornato a AppData.cerise
                                    color: AppData.cerise,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      // Colore dell'icona stella aggiornato a AppData.antiFlashWhite
                                      const Icon(
                                        Icons.star,
                                        color: AppData.antiFlashWhite,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Preferito',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(color: AppData.antiFlashWhite), // Colore testo badge aggiornato
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink(),
                          const SizedBox(width: 10),

                          _currentTrip.toBeRepeated
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    // Colore del badge "Segna da ripetere" aggiornato a AppData.charcoal
                                    color: AppData.charcoal,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      // Colore dell'icona repeat aggiornato a AppData.antiFlashWhite
                                      const Icon(
                                        Icons.repeat,
                                        color: AppData.antiFlashWhite,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Segna da ripetere',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(color: AppData.antiFlashWhite), // Colore testo badge aggiornato
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Categoria: ${_currentTrip.category}',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(color: AppData.antiFlashWhite), // Colore testo aggiornato
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Note personali:',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppData.antiFlashWhite, // Colore testo aggiornato
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        _currentTrip.notes.isNotEmpty
                            ? _currentTrip.notes
                            : 'Nessuna nota aggiunta.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: AppData.antiFlashWhite.withOpacity(0.7)), // Colore testo aggiornato
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Galleria immagini:',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppData.antiFlashWhite, // Colore testo aggiornato
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
                                  final String rawImageUrl =
                                      _currentTrip.imageUrls[index];
                                  final String imageUrl = _sanitizeImagePath(
                                    rawImageUrl,
                                  );

                                  Widget imageWidget;
                                  if (imageUrl.startsWith('assets/')) {
                                    imageWidget = Image.asset(
                                      imageUrl,
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        debugPrint(
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
                                      placeholder: (context, url) => Center(
                                        child: CircularProgressIndicator(
                                          // Colore indicatore aggiornato
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                              AppData.antiFlashWhite),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) {
                                        debugPrint(
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
                                            // Il file non esiste o c'è stato un errore
                                            debugPrint(
                                              'Errore caricamento file locale galleria: $imageUrl, Errore: ${snapshot.error ?? "File non trovato"}',
                                            );
                                            return _buildGalleryErrorPlaceholder();
                                          } else {
                                            // Il file esiste, caricalo
                                            return Image.file(
                                              File(imageUrl),
                                              width: 120,
                                              height: 120,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    debugPrint(
                                                      'Errore caricamento Image.file galleria: $imageUrl, Errore: $error',
                                                    );
                                                    return _buildGalleryErrorPlaceholder();
                                                  },
                                            );
                                          }
                                        }
                                        // Mentre aspettiamo, mostra un indicatore di caricamento
                                        return Center(
                                          child: CircularProgressIndicator(
                                            // Colore indicatore aggiornato
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                                AppData.antiFlashWhite),
                                          ),
                                        );
                                      },
                                    );
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: imageWidget,
                                    ),
                                  );
                                },
                              ),
                            )
                          : Text(
                              'Nessuna immagine specifica aggiunta per questo viaggio.',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: AppData.antiFlashWhite.withOpacity(0.7)), // Colore testo aggiornato
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

  // Per gestire i diversi tipi di URL per l'immagine di copertina
  Widget _buildCoverImageWidget(String imageUrl) {
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint(
            'Errore caricamento asset copertina: $imageUrl, Errore: $error',
          );
          return _buildErrorPlaceholder();
        },
      );
    } else if (imageUrl.startsWith('http://') ||
        imageUrl.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Center(
          child: CircularProgressIndicator(
            // Colore indicatore aggiornato
            valueColor: AlwaysStoppedAnimation<Color>(AppData.antiFlashWhite),
          ),
        ),
        errorWidget: (context, url, error) {
          debugPrint('Errore caricamento network copertina: $url, Errore: $error');
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
              debugPrint(
                'Errore caricamento file locale copertina: $imageUrl, Errore: ${snapshot.error ?? "File non trovato"}',
              );
              return _buildErrorPlaceholder();
            } else {
              // Il file esiste, caricalo
              return Image.file(
                File(imageUrl),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint(
                    'Errore caricamento Image.file copertina: $imageUrl, Errore: $error',
                  );
                  return _buildErrorPlaceholder();
                },
              );
            }
          }
          // Mentre aspettiamo, mostra un indicatore di caricamento
          return Center(
            child: CircularProgressIndicator(
              // Colore indicatore aggiornato
              valueColor: AlwaysStoppedAnimation<Color>(AppData.antiFlashWhite),
            ),
          );
        },
      );
    }
  }

  // Piccolo widget di utility per il placeholder in caso di errore (copertina)
  Widget _buildErrorPlaceholder() {
    return Container(
      // Sfondo aggiornato a AppData.charcoal con opacità
      color: AppData.charcoal.withOpacity(0.9),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Colore dell'icona aggiornato a AppData.antiFlashWhite con opacità
            Icon(Icons.image_not_supported, color: AppData.antiFlashWhite.withOpacity(0.7), size: 60),
            const SizedBox(height: 8),
            // Colore del testo aggiornato a AppData.antiFlashWhite con opacità
            Text(
              'Immagine non trovata',
              style: TextStyle(color: AppData.antiFlashWhite.withOpacity(0.7), fontSize: 16),
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
      // Sfondo aggiornato a AppData.charcoal con opacità
      color: AppData.charcoal.withOpacity(0.8),
      // Colore dell'icona aggiornato a AppData.antiFlashWhite con opacità
      child: Icon(Icons.broken_image, color: AppData.antiFlashWhite.withOpacity(0.7), size: 50),
    );
  }
}