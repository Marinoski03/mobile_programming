// lib/screens/trip_detail_screen.dart

import 'package:flutter/material.dart'; // Importa Material Design
import 'package:intl/intl.dart'; // Per la formattazione delle date
import 'package:cached_network_image/cached_network_image.dart'; // Per il caching delle immagini

import '../models/trip.dart';
import '../helpers/trip_database_helper.dart';
import '../screens/add_edit_trip_screen.dart';

class TripDetailScreen extends StatefulWidget {
  final Trip trip;

  const TripDetailScreen({super.key, required this.trip});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  late Trip _currentTrip; // Il viaggio attualmente visualizzato e modificabile
  bool _isSaving =
      false; // Stato per indicare se un'operazione di salvataggio è in corso

  @override
  void initState() {
    super.initState();
    _currentTrip = widget.trip;
  }

  // Metodo per gestire il toggle di preferito
  void _toggleFavorite() async {
    if (_isSaving) return; // Evita clic multipli rapidi
    setState(() {
      _isSaving = true; // Inizia l'operazione di salvataggio
      _currentTrip = _currentTrip.copyWith(
        isFavorite: !_currentTrip.isFavorite,
      );
    });
    try {
      await TripDatabaseHelper.instance.updateTrip(_currentTrip);
    } catch (e) {
      // Gestisci l'errore (es. mostra una SnackBar)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante l\'aggiornamento: $e')),
      );
      // Ripristina lo stato precedente se l'aggiornamento fallisce
      setState(() {
        _currentTrip = _currentTrip.copyWith(
          isFavorite: !_currentTrip.isFavorite,
        );
      });
    } finally {
      setState(() {
        _isSaving = false; // Termina l'operazione di salvataggio
      });
    }
  }

  // Metodo per gestire il toggle di "da ripetere"
  void _toggleToRepeat() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _currentTrip = _currentTrip.copyWith(toRepeat: !_currentTrip.toRepeat);
    });
    try {
      await TripDatabaseHelper.instance.updateTrip(_currentTrip);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante l\'aggiornamento: $e')),
      );
      setState(() {
        _currentTrip = _currentTrip.copyWith(toRepeat: !_currentTrip.toRepeat);
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // Metodo per eliminare un viaggio
  void _deleteTrip() async {
    if (_isSaving) return; // Impedisce eliminazioni multiple

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Conferma Eliminazione'),
          content: const Text(
            'Sei sicuro di voler eliminare questo viaggio? Questa azione è irreversibile.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annulla'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Elimina', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop(); // Chiudi il dialogo di conferma

                if (_currentTrip.id == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Impossibile eliminare: ID viaggio non trovato.',
                      ),
                    ),
                  );
                  return;
                }

                setState(() {
                  _isSaving =
                      true; // Imposta lo stato di salvataggio per bloccare l'UI
                });

                try {
                  await TripDatabaseHelper.instance.deleteTrip(
                    _currentTrip.id!,
                  );
                  // Mostra un feedback positivo
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Viaggio eliminato con successo!'),
                    ),
                  );
                  Navigator.of(
                    context,
                  ).pop(); // Torna alla schermata precedente (es. HomeScreen)
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Errore durante l\'eliminazione: $e'),
                    ),
                  );
                } finally {
                  setState(() {
                    _isSaving = false; // Resetta lo stato di salvataggio
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTrip.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            // Disabilita il pulsante modifica durante il salvataggio
            onPressed: _isSaving
                ? null
                : () async {
                    final updatedTrip = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddEditTripScreen(trip: _currentTrip),
                      ),
                    );
                    if (updatedTrip != null && updatedTrip is Trip) {
                      setState(() {
                        _currentTrip =
                            updatedTrip; // Aggiorna il viaggio visualizzato
                      });
                      // Aggiorna il database con il viaggio modificato
                      await TripDatabaseHelper.instance.updateTrip(updatedTrip);
                    }
                  },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            // Disabilita il pulsante elimina durante il salvataggio
            onPressed: _isSaving ? null : _deleteTrip,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentTrip.location,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              '${DateFormat('dd/MM/yyyy').format(_currentTrip.startDate)} - ${DateFormat('dd/MM/yyyy').format(_currentTrip.endDate)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // ActionChip per Preferito
                ActionChip(
                  avatar: Icon(
                    _currentTrip.isFavorite ? Icons.star : Icons.star_border,
                    color: _currentTrip.isFavorite
                        ? Colors.amber
                        : null, // Colore per preferito
                  ),
                  label: Text(
                    _currentTrip.isFavorite
                        ? 'Preferito'
                        : 'Aggiungi ai preferiti',
                  ),
                  onPressed: _isSaving
                      ? null
                      : _toggleFavorite, // Disabilita durante il salvataggio
                ),
                const SizedBox(width: 10),
                // ActionChip per Da Ripetere
                ActionChip(
                  avatar: Icon(
                    _currentTrip.toRepeat ? Icons.repeat_on : Icons.repeat,
                    color: _currentTrip.toRepeat
                        ? Theme.of(context).primaryColor
                        : null, // Colore per da ripetere
                  ),
                  label: Text(
                    _currentTrip.toRepeat ? 'Da ripetere' : 'Segna da ripetere',
                  ),
                  onPressed: _isSaving
                      ? null
                      : _toggleToRepeat, // Disabilita durante il salvataggio
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Categoria: ${_currentTrip.category}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Note personali:',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _currentTrip.description.isNotEmpty
                  ? _currentTrip.description
                  : 'Nessuna nota aggiunta.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Text(
              'Immagini del viaggio:',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Mostra un messaggio se non ci sono immagini
            _currentTrip.imageUrls.isEmpty
                ? const Text('Nessuna immagine aggiunta.')
                : SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _currentTrip.imageUrls.length,
                      itemBuilder: (context, index) {
                        final imageUrl = _currentTrip.imageUrls[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 10.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child:
                                (imageUrl
                                    .isNotEmpty) // Controlla che l'URL non sia vuoto
                                ? CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    width: 150,
                                    height: 200,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      width: 150,
                                      height: 200,
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        _buildImageErrorPlaceholder(),
                                  )
                                : _buildImageErrorPlaceholder(), // Placeholder se l'URL è vuoto
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  // Widget helper per il placeholder in caso di errore immagine
  Widget _buildImageErrorPlaceholder() {
    return Container(
      width: 150,
      height: 200,
      color: Colors.grey[300],
      child: const Icon(Icons.broken_image, color: Colors.grey, size: 50),
    );
  }
}
