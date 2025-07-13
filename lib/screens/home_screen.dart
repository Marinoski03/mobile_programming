// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/trip.dart';
import '../helpers/trip_database_helper.dart';
import 'add_edit_trip_screen.dart';
import 'analysis_screen.dart';
import 'categories_screen.dart';
import 'search_screen.dart';
import 'trip_detail_screen.dart';
// Assicurati che AppData sia importato per i placeholder

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Trip> _trips = [];
  List<Trip> _favoriteTrips = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshTrips();
    });
  }

  Future<void> _refreshTrips() async {
    final trips = await TripDatabaseHelper.instance.getAllTrips();
    setState(() {
      _trips = trips;
      _favoriteTrips = trips.where((trip) => trip.isFavorite).toList();
      _trips.sort((a, b) => b.endDate.compareTo(a.endDate));
    });
  }

  Future<void> _navigateToScreen(BuildContext context, Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (ctx) => screen));
    _refreshTrips(); // Aggiorna i viaggi dopo essere tornato da una schermata
  }

  // Helper per ottenere l'ImageProvider corretto, simile a TripDetailScreen

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,

      appBar: AppBar(
        title: const Text(
          'I Miei Viaggi',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.category, color: Colors.white),
            onPressed: () =>
                _navigateToScreen(context, const CategoriesScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => _navigateToScreen(context, const SearchScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Colors.white),
            onPressed: () => _navigateToScreen(context, const AnalysisScreen()),
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
          child: _trips.isEmpty && _favoriteTrips.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Nessun viaggio aggiunto ancora. Tocca il "+" per iniziare!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ultimi viaggi aggiunti',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 10),
                      _trips.isEmpty
                          ? const Center(
                              child: Text(
                                'Nessun viaggio trovato.',
                                style: TextStyle(color: Colors.white70),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _trips.length > 3 ? 3 : _trips.length,
                              itemBuilder: (context, index) {
                                final trip = _trips[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: InkWell(
                                    onTap: () => _navigateToScreen(
                                      context,
                                      TripDetailScreen(trip: trip),
                                    ),
                                    child: Row(
                                      // Usa una Row per l'immagine a sinistra e il testo a destra
                                      children: [
                                        // Sezione Contenuto Testuale
                                        Expanded(
                                          // Permette alla colonna del testo di occupare lo spazio rimanente
                                          child: Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  trip.title,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleLarge
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                  maxLines:
                                                      1, // Limita a una riga
                                                  overflow: TextOverflow
                                                      .ellipsis, // Aggiunge "..."
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  trip.location,
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.titleMedium,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${DateFormat('dd/MM/yyyy').format(trip.startDate)} - ${DateFormat('dd/MM/yyyy').format(trip.endDate)}',
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.bodyMedium,
                                                ),
                                                // *** INIZIO MODIFICA: AGGIUNTA BADGE ***
                                                if (trip.isFavorite ||
                                                    trip.toBeRepeated) // Mostra questa riga solo se almeno una condizione è vera
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 8.0,
                                                        ), // Spazio sopra i badge
                                                    child: Row(
                                                      children: [
                                                        if (trip.isFavorite)
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 8,
                                                                  vertical: 4,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color: Colors
                                                                  .amber
                                                                  .shade700, // Colore per "Preferito"
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    15,
                                                                  ),
                                                            ),
                                                            child: Row(
                                                              children: [
                                                                const Icon(
                                                                  Icons.star,
                                                                  color: Colors
                                                                      .white,
                                                                  size: 16,
                                                                ),
                                                                const SizedBox(
                                                                  width: 4,
                                                                ),
                                                                Text(
                                                                  'Preferito',
                                                                  style: Theme.of(context)
                                                                      .textTheme
                                                                      .bodySmall
                                                                      ?.copyWith(
                                                                        color: Colors
                                                                            .white,
                                                                      ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ), // Spazio tra i badge
                                                        if (trip.toBeRepeated)
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 8,
                                                                  vertical: 4,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color: Colors
                                                                  .green
                                                                  .shade700, // Colore per "Da ripetere"
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    15,
                                                                  ),
                                                            ),
                                                            child: Row(
                                                              children: [
                                                                const Icon(
                                                                  Icons.repeat,
                                                                  color: Colors
                                                                      .white,
                                                                  size: 16,
                                                                ),
                                                                const SizedBox(
                                                                  width: 4,
                                                                ),
                                                                Text(
                                                                  'Da ripetere',
                                                                  style: Theme.of(context)
                                                                      .textTheme
                                                                      .bodySmall
                                                                      ?.copyWith(
                                                                        color: Colors
                                                                            .white,
                                                                      ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                // *** FINE MODIFICA: AGGIUNTA BADGE ***
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                      const SizedBox(height: 30),

                      Text(
                        'Destinazioni preferite',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 10),
                      _favoriteTrips.isEmpty
                          ? const Center(
                              child: Text(
                                'Nessuna destinazione preferita ancora. Aggiungi un viaggio ai preferiti!',
                                style: TextStyle(color: Colors.white70),
                              ),
                            )
                          : SizedBox(
                              height: 180,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _favoriteTrips.length,
                                itemBuilder: (context, index) {
                                  final trip = _favoriteTrips[index];

                                  return GestureDetector(
                                    onTap: () => _navigateToScreen(
                                      context,
                                      TripDetailScreen(trip: trip),
                                    ),
                                    child: Container(
                                      width: 150,
                                      margin: const EdgeInsets.only(right: 15),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor,
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  trip.title,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  trip.location,
                                                  style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToScreen(
          context,
          const AddEditTripScreen(),
        ), // MODIFICATO: Aggiunto 'const' se la schermata è const
        icon: const Icon(Icons.add),
        label: const Text('Aggiungi Viaggio'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue.shade700,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // Modifica qui: aggiungi parametri opzionali per altezza e larghezza
}
