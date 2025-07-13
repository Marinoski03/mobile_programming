// lib/screens/trip_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/trip.dart';
import '../helpers/trip_database_helper.dart';
import 'add_edit_trip_screen.dart';
import '../utils/app_data.dart';

class TripDetailScreen extends StatefulWidget {
  final Trip trip;

  const TripDetailScreen({super.key, required this.trip});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  late Trip _currentTrip;
  String? _coverImageUrl; // Reso nullable per gestire l'assenza di immagini

  @override
  void initState() {
    super.initState();
    _currentTrip = widget.trip;
    _setCoverImage();
    _refreshTripDetails();
  }

  // Modificato: Imposta _coverImageUrl a null se non ci sono immagini
  void _setCoverImage() {
    if (_currentTrip.imageUrls.isNotEmpty) {
      _coverImageUrl = _sanitizeImagePath(_currentTrip.imageUrls.first);
    } else {
      _coverImageUrl = null; // Nessuna immagine se la lista è vuota
    }
  }

  String _sanitizeImagePath(String path) {
    return path.replaceAll('["', '').replaceAll('"]', '').replaceAll('"', '');
  }

  Future<void> _refreshTripDetails() async {
    final updatedTrip = await TripDatabaseHelper.instance.getTripById(
      _currentTrip.id!,
    );
    if (updatedTrip != null) {
      setState(() {
        _currentTrip = updatedTrip;
        _setCoverImage();
      });
    }
  }

  Future<void> _navigateToEditScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditTripScreen(trip: _currentTrip),
      ),
    );
    _refreshTripDetails();
  }

  Future<void> _confirmDelete() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Conferma Eliminazione',
          style: TextStyle(color: AppData.charcoal), // Colore testo titolo
        ),
        content: const Text(
          'Sei sicuro di voler eliminare questo viaggio?',
          style: TextStyle(color: AppData.charcoal), // Colore testo contenuto
        ),
        backgroundColor: AppData.antiFlashWhite, // Colore sfondo AlertDialog
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Annulla',
              style: TextStyle(color: AppData.silverLakeBlue),
            ), // Colore testo Annulla
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Elimina',
              style: TextStyle(color: AppData.cerise),
            ), // Colore testo Elimina
          ),
        ],
      ),
    );

    if (confirm == true) {
      await TripDatabaseHelper.instance.deleteTrip(_currentTrip.id!);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppData.antiFlashWhite, // Sfondo della Scaffold
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            backgroundColor: AppData
                .antiFlashWhite, // Colore di sfondo dell'AppBar cambiato a antiFlashWhite
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(
                left: 16.0,
                bottom: 16.0,
                right: 16.0,
              ),
              centerTitle: false,
              title: Text(
                _currentTrip.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppData
                      .charcoal, // Colore del titolo nella AppBar cambiato a charcoal
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: const Offset(1.0, 1.0),
                      blurRadius: 3.0,
                      color: AppData.antiFlashWhite.withOpacity(
                        0.5,
                      ), // Colore ombra del titolo
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              background: _buildCoverImage(
                _coverImageUrl,
              ), // Passa l'URL (potrebbe essere null)
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.edit,
                  color: AppData
                      .charcoal, // Colore icona modifica cambiato a charcoal
                ),
                onPressed: _navigateToEditScreen,
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete,
                  color: AppData
                      .charcoal, // Colore icona elimina cambiato a charcoal
                ),
                onPressed: _confirmDelete,
              ),
            ],
            iconTheme: const IconThemeData(
              color: AppData
                  .charcoal, // Colore delle icone nell'AppBar cambiato a charcoal
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                      context,
                      Icons.location_on,
                      'Località:',
                      _currentTrip.location,
                    ),
                    _buildDetailRow(
                      context,
                      Icons.date_range,
                      'Date:',
                      '${DateFormat('dd/MM/yyyy').format(_currentTrip.startDate)} - ${DateFormat('dd/MM/yyyy').format(_currentTrip.endDate)}',
                    ),
                    _buildDetailRow(
                      context,
                      Icons.category,
                      'Categoria:',
                      _currentTrip.category,
                    ),
                    _buildDetailRow(
                      context,
                      Icons.notes,
                      'Note:',
                      _currentTrip.notes.isNotEmpty
                          ? _currentTrip.notes
                          : 'Nessuna nota aggiunta.',
                    ),
                    _buildDetailRow(
                      context,
                      _currentTrip.isFavorite ? Icons.star : Icons.star_border,
                      'Preferito:',
                      _currentTrip.isFavorite ? 'Sì' : 'No',
                      iconColor: _currentTrip.isFavorite
                          ? Colors.amber
                          : null, // Colore icona preferito (giallo)
                    ),
                    _buildDetailRow(
                      context,
                      _currentTrip.toBeRepeated
                          ? Icons.repeat_on
                          : Icons.repeat,
                      'Da ripetere:',
                      _currentTrip.toBeRepeated ? 'Sì' : 'No',
                      iconColor: _currentTrip.toBeRepeated
                          ? AppData.cerise
                          : null, // Colore icona da ripetere (cerise)
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Galleria Immagini',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppData
                                .charcoal, // Colore del titolo della galleria
                          ),
                    ),
                    const SizedBox(height: 10),
                    _currentTrip.imageUrls.isEmpty
                        ? Center(
                            child: Text(
                              'Nessuna immagine aggiunta a questo viaggio.',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: AppData.charcoal.withOpacity(
                                      0.7,
                                    ), // Colore del testo "Nessuna immagine"
                                  ),
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
                            itemBuilder: (context, idx) {
                              final imageUrl = _sanitizeImagePath(
                                _currentTrip.imageUrls[idx],
                              );
                              return GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => Dialog(
                                      backgroundColor: Colors
                                          .transparent, // Sfondo del Dialog trasparente
                                      child: Stack(
                                        children: [
                                          _buildGalleryImage(imageUrl),
                                          Positioned(
                                            top: 10,
                                            right: 10,
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.close,
                                                color: AppData.antiFlashWhite,
                                              ), // Colore icona chiudi
                                              onPressed: () =>
                                                  Navigator.of(ctx).pop(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: _buildGalleryImage(imageUrl),
                                ),
                              );
                            },
                          ),
                    const SizedBox(height: 80),
                  ],
                ),
              );
            }, childCount: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: iconColor ?? AppData.silverLakeBlue,
          ), // Colore icona di default
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppData.charcoal, // Colore etichetta
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppData.charcoal.withOpacity(0.8), // Colore valore
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        color: AppData.antiFlashWhite.withOpacity(
          0.5,
        ), // Sfondo molto chiaro per lo spazio vuoto
        child: Center(
          child: Icon(
            Icons.image_not_supported,
            color: AppData.charcoal.withOpacity(0.3), // Icona molto sbiadita
            size: 80,
          ),
        ),
      );
    }

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
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(color: AppData.silverLakeBlue),
        ), // Colore indicatore di caricamento
        errorWidget: (context, url, error) {
          debugPrint(
            'Errore caricamento network copertina: $url, Errore: $error',
          );
          return _buildErrorPlaceholder();
        },
      );
    } else {
      return FutureBuilder<bool>(
        future: File(imageUrl).exists(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError || !(snapshot.data ?? false)) {
              debugPrint(
                'Errore caricamento file locale copertina: $imageUrl, Errore: ${snapshot.error ?? "File non trovato"}',
              );
              return _buildErrorPlaceholder();
            } else {
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
          return const Center(
            child: CircularProgressIndicator(color: AppData.silverLakeBlue),
          ); // Colore indicatore di caricamento
        },
      );
    }
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: AppData.charcoal.withOpacity(0.8), // Sfondo placeholder errore
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              color: AppData.antiFlashWhite.withOpacity(
                0.7,
              ), // Icona placeholder errore
              size: 60,
            ),
            const SizedBox(height: 8),
            Text(
              'Immagine non trovata',
              style: TextStyle(
                color: AppData.antiFlashWhite.withOpacity(0.7),
                fontSize: 16,
              ), // Testo placeholder errore
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryImage(String imageUrl) {
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
        errorBuilder: (context, error, stackTrace) {
          debugPrint(
            'Errore caricamento asset galleria: $imageUrl, Errore: $error',
          );
          return _buildGalleryErrorPlaceholder();
        },
      );
    } else if (imageUrl.startsWith('http://') ||
        imageUrl.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(color: AppData.silverLakeBlue),
        ), // Colore indicatore di caricamento
        errorWidget: (context, url, error) {
          debugPrint(
            'Errore caricamento network galleria: $url, Errore: $error',
          );
          return _buildGalleryErrorPlaceholder();
        },
      );
    } else {
      return FutureBuilder<bool>(
        future: File(imageUrl).exists(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError || !(snapshot.data ?? false)) {
              debugPrint(
                'Errore caricamento file locale galleria: $imageUrl, Errore: ${snapshot.error ?? "File non trovato"}',
              );
              return _buildGalleryErrorPlaceholder();
            } else {
              return Image.file(
                File(imageUrl),
                fit: BoxFit.cover,
                width: 120,
                height: 120,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint(
                    'Errore caricamento Image.file galleria: $imageUrl, Errore: $error',
                  );
                  return _buildGalleryErrorPlaceholder();
                },
              );
            }
          }
          return const Center(
            child: CircularProgressIndicator(color: AppData.silverLakeBlue),
          ); // Colore indicatore di caricamento
        },
      );
    }
  }

  Widget _buildGalleryErrorPlaceholder() {
    return Container(
      width: 120,
      height: 120,
      color: AppData.charcoal.withOpacity(
        0.6,
      ), // Sfondo placeholder errore galleria
      child: Center(
        child: Icon(
          Icons.image_not_supported,
          color: AppData.antiFlashWhite.withOpacity(
            0.7,
          ), // Icona placeholder errore galleria
          size: 40,
        ),
      ),
    );
  }
}
