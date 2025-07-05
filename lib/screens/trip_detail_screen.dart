import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/trip.dart';
import 'add_edit_trip_screen.dart';

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
  }

  void _toggleFavorite() {
    setState(() {
      _currentTrip = _currentTrip.copyWith(isFavorite: !_currentTrip.isFavorite);
      // Aggiorna anche il dummyTrips per riflettere il cambiamento
      final index = dummyTrips.indexWhere((t) => t.id == _currentTrip.id);
      if (index != -1) {
        dummyTrips[index] = _currentTrip;
      }
    });
  }

  void _toggleToRepeat() {
    setState(() {
      _currentTrip = _currentTrip.copyWith(toRepeat: !_currentTrip.toRepeat);
      // Aggiorna anche il dummyTrips per riflettere il cambiamento
      final index = dummyTrips.indexWhere((t) => t.id == _currentTrip.id);
      if (index != -1) {
        dummyTrips[index] = _currentTrip;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTrip.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updatedTrip = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditTripScreen(trip: _currentTrip),
                ),
              );
              if (updatedTrip != null && updatedTrip is Trip) {
                setState(() {
                  _currentTrip = updatedTrip;
                  // Aggiorna il dummyTrips con il viaggio modificato
                  final index = dummyTrips.indexWhere((t) => t.id == updatedTrip.id);
                  if (index != -1) {
                    dummyTrips[index] = updatedTrip;
                  }
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              // Mostra un dialogo di conferma prima di eliminare
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Conferma Eliminazione'),
                    content: const Text('Sei sicuro di voler eliminare questo viaggio?'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Annulla'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: const Text('Elimina', style: TextStyle(color: Colors.red)),
                        onPressed: () {
                          dummyTrips.removeWhere((trip) => trip.id == _currentTrip.id);
                          Navigator.of(context).pop(); // Chiudi il dialogo
                          Navigator.of(context).pop(); // Torna alla schermata precedente
                        },
                      ),
                    ],
                  );
                },
              );
            },
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
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              '${DateFormat('dd/MM/yyyy').format(_currentTrip.startDate)} - ${DateFormat('dd/MM/yyyy').format(_currentTrip.endDate)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ActionChip(
                  avatar: Icon(_currentTrip.isFavorite ? Icons.star : Icons.star_border),
                  label: Text(_currentTrip.isFavorite ? 'Preferito' : 'Aggiungi ai preferiti'),
                  onPressed: _toggleFavorite,
                ),
                const SizedBox(width: 10),
                ActionChip(
                  avatar: Icon(_currentTrip.toRepeat ? Icons.repeat_on : Icons.repeat),
                  label: Text(_currentTrip.toRepeat ? 'Da ripetere' : 'Segna da ripetere'),
                  onPressed: _toggleToRepeat,
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _currentTrip.description.isNotEmpty ? _currentTrip.description : 'Nessuna nota aggiunta.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Text(
              'Immagini del viaggio:',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _currentTrip.imageUrls.isEmpty
                ? const Text('Nessuna immagine aggiunta.')
                : SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _currentTrip.imageUrls.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 10.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              _currentTrip.imageUrls[index],
                              width: 150,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 150,
                                height: 200,
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image, color: Colors.grey),
                              ),
                            ),
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
}