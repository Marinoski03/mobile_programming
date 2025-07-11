// lib/screens/home_screen.dart

import 'package:flutter/material.dart'; // Importa Material Design per i widget
import 'package:intl/intl.dart'; // Per la formattazione delle date

// Importa le dipendenze locali
import '../models/trip.dart';
import '../helpers/trip_database_helper.dart';
import 'add_edit_trip_screen.dart';
import 'analysis_screen.dart';
import 'categories_screen.dart';
import 'search_screen.dart';
import 'trip_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Trip> _trips = []; // Lista di viaggi recuperati dal database
  List<Trip> _favoriteTrips = []; // Lista di viaggi preferiti

  @override
  void initState() {
    super.initState();
    // Recupera i dati dal database all'avvio e ogni volta che la schermata è visibile
    // Usa addPostFrameCallback per assicurarsi che il contesto sia disponibile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshTrips();
    });
  }

  // Funzione per aggiornare la lista dei viaggi dal database
  Future<void> _refreshTrips() async {
    final trips = await TripDatabaseHelper.instance.getAllTrips();
    setState(() {
      _trips = trips;
      _favoriteTrips = trips.where((trip) => trip.isFavorite).toList();
      // Ordina i viaggi per data di fine decrescente (i più recenti in cima)
      _trips.sort((a, b) => b.endDate.compareTo(a.endDate));
    });
  }

  // Metodo per navigare a una schermata e ricaricare i dati al ritorno
  Future<void> _navigateToScreen(BuildContext context, Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (ctx) => screen));
    _refreshTrips(); // Aggiorna la lista al ritorno dalla schermata
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('I Miei Viaggi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () =>
                _navigateToScreen(context, const CategoriesScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _navigateToScreen(context, const SearchScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => _navigateToScreen(context, const AnalysisScreen()),
          ),
        ],
      ),
      body: _trips.isEmpty && _favoriteTrips.isEmpty
          ? const Center(
              child: Text(
                'Nessun viaggio aggiunto ancora. Tocca il "+" per iniziare!',
                textAlign: TextAlign.center,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sezione "Ultimi viaggi aggiunti"
                  Text(
                    'Ultimi viaggi aggiunti',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Se non ci sono viaggi, mostra un messaggio specifico
                  _trips.isEmpty
                      ? const Center(child: Text('Nessun viaggio trovato.'))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics:
                              const NeverScrollableScrollPhysics(), // Impedisce lo scroll del ListView nidificato
                          itemCount: _trips.length > 3
                              ? 3
                              : _trips.length, // Mostra solo gli ultimi 3
                          itemBuilder: (context, index) {
                            final trip = _trips[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                onTap: () => _navigateToScreen(
                                  context,
                                  TripDetailScreen(trip: trip),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
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
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        trip.location,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${DateFormat('dd/MM/yyyy').format(trip.startDate)} - ${DateFormat('dd/MM/yyyy').format(trip.endDate)}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
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
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _favoriteTrips.isEmpty
                      ? const Center(
                          child: Text(
                            'Nessuna destinazione preferita ancora. Aggiungi un viaggio ai preferiti!',
                          ),
                        )
                      : SizedBox(
                          height: 180, // Altezza fissa per la lista orizzontale
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
                                    color: Theme.of(
                                      context,
                                    ).cardColor, // Usa il colore della card del tema
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
                                      ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(12),
                                            ),
                                        // Gestione dell'immagine con fallback
                                        child:
                                            (trip.imageUrls.isNotEmpty &&
                                                trip.imageUrls.first.isNotEmpty)
                                            ? Image.network(
                                                trip.imageUrls.first,
                                                height: 100,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) =>
                                                        _buildNoImagePlaceholder(),
                                              )
                                            : _buildNoImagePlaceholder(),
                                      ),
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
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              trip.location,
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12,
                                              ),
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
        onPressed: () => _navigateToScreen(context, const AddEditTripScreen()),
        icon: const Icon(Icons.add),
        label: const Text('Aggiungi Viaggio'),
      ),
    );
  }

  // Widget helper per l'immagine di fallback
  Widget _buildNoImagePlaceholder() {
    return Container(
      height: 100,
      width: double.infinity,
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.image_not_supported,
          color: Colors.grey[600],
          size: 50,
        ),
      ),
    );
  }
}
