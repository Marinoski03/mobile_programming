import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:travel_diary_app/screens/search_screen.dart';
import 'package:travel_diary_app/screens/trip_detail_screen.dart';

import '../models/trip.dart';
import 'add_edit_trip_screen.dart';
import 'analysis_screen.dart';
import 'categories_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Funzione per aggiornare la lista dei viaggi dopo un'aggiunta/modifica
  void _refreshTrips() {
    setState(() {
      // In un'app reale, qui ricaricheresti i dati dal database
      // Per ora, ricarichiamo semplicemente la lista dummyTrips
      // (che è modificata direttamente dalle altre schermate per semplicità)
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ordina i viaggi per data di fine decrescente (i più recenti in cima)
    dummyTrips.sort((a, b) => b.endDate.compareTo(a.endDate));

    // Estrai i viaggi preferiti
    final favoriteTrips = dummyTrips.where((trip) => trip.isFavorite).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('I Miei Viaggi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CategoriesScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AnalysisScreen()),
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
            // Sezione "Ultimi viaggi aggiunti"
            Text(
              'Ultimi viaggi aggiunti',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            dummyTrips.isEmpty
                ? const Center(child: Text('Nessun viaggio aggiunto ancora.'))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: dummyTrips.length > 3 ? 3 : dummyTrips.length, // Mostra solo gli ultimi 3
                    itemBuilder: (context, index) {
                      final trip = dummyTrips[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: InkWell(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TripDetailScreen(trip: trip),
                              ),
                            );
                            _refreshTrips(); // Aggiorna la lista al ritorno dalla schermata dettaglio
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  trip.title,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  trip.location,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${DateFormat('dd/MM/yyyy').format(trip.startDate)} - ${DateFormat('dd/MM/yyyy').format(trip.endDate)}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 30),

            // Sezione "Destinazioni preferite"
            Text(
              'Destinazioni preferite',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            favoriteTrips.isEmpty
                ? const Center(child: Text('Nessuna destinazione preferita ancora.'))
                : SizedBox(
                    height: 180, // Altezza fissa per la lista orizzontale
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: favoriteTrips.length,
                      itemBuilder: (context, index) {
                        final trip = favoriteTrips[index];
                        return GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TripDetailScreen(trip: trip),
                              ),
                            );
                            _refreshTrips();
                          },
                          child: Container(
                            width: 150,
                            margin: const EdgeInsets.only(right: 15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                  child: Image.network(
                                    trip.imageUrls.isNotEmpty ? trip.imageUrls.first : 'https://placehold.co/150x100/CCCCCC/FFFFFF?text=No+Image',
                                    height: 100,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Image.network(
                                      'https://placehold.co/150x100/CCCCCC/FFFFFF?text=No+Image',
                                      height: 100,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        trip.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        trip.location,
                                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEditTripScreen()),
          );
          _refreshTrips(); // Aggiorna la lista al ritorno dalla schermata di aggiunta
        },
        icon: const Icon(Icons.add),
        label: const Text('Aggiungi Viaggio'),
      ),
    );
  }
}