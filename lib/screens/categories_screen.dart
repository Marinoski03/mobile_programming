// lib/screens/categories_screen.dart

import 'package:flutter/material.dart';
import '../helpers/trip_database_helper.dart';
import 'package:travel_diary_app/screens/search_screen.dart';
import '../utils/app_data.dart'; // Importa AppData per i colori

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  // Rimosse le definizioni di colore locali, useremo direttamente AppData

  Map<String, int> _categoryCounts = {};
  late Future<void> _loadCategoriesFuture;

  @override
  void initState() {
    super.initState();
    _loadCategoriesFuture = _loadCategoryCounts();
  }

  Future<void> _loadCategoryCounts() async {
    final allTrips = await TripDatabaseHelper.instance.getAllTrips();
    final Map<String, int> counts = {};

    for (var trip in allTrips) {
      counts.update(trip.category, (value) => value + 1, ifAbsent: () => 1);
    }

    setState(() {
      _categoryCounts = counts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Extend the body behind the AppBar for the gradient effect
      extendBodyBehindAppBar: true,
      // Set scaffold background to transparent as the Container will draw the gradient
      backgroundColor: Colors.transparent,

      appBar: AppBar(
        // Make AppBar transparent and remove elevation
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Categorie Viaggi',
          style: TextStyle(
            color: AppData.antiFlashWhite, // Colore testo aggiornato
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: AppData.antiFlashWhite, // Colore icona aggiornato
            onPressed: () {
              setState(() {
                _loadCategoriesFuture = _loadCategoryCounts();
              });
            },
            tooltip: 'Aggiorna categorie',
          ),
        ],
      ),
      // Use a Container with a LinearGradient for the background
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            // Gradiente con colori AppData
            colors: [
              AppData.silverLakeBlue.withOpacity(0.7),
              AppData.charcoal.withOpacity(0.9)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          // SafeArea to avoid content overlapping status bar, etc.
          child: FutureBuilder<void>(
            future: _loadCategoriesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        AppData.antiFlashWhite), // Colore aggiornato
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Errore nel caricamento delle categorie: ${snapshot.error}',
                    style: const TextStyle(
                        color: AppData.antiFlashWhite), // Colore testo aggiornato
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Riepilogo per categoria:',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppData.antiFlashWhite, // Colore testo aggiornato
                      ),
                    ),
                    const SizedBox(height: 10),
                    _categoryCounts.isEmpty
                        ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text(
                          'Nessuna categoria trovata. Aggiungi dei viaggi per vederle qui.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppData
                                  .antiFlashWhite), // Colore testo aggiornato
                        ),
                      ),
                    )
                        : Expanded(
                      child: ListView.builder(
                        itemCount: _categoryCounts.length,
                        itemBuilder: (context, index) {
                          final category =
                          _categoryCounts.keys.elementAt(
                            index,
                          );
                          final count = _categoryCounts[category];
                          return Card(
                            // Colore Card aggiornato
                            color: AppData.antiFlashWhite,
                            margin: const EdgeInsets.symmetric(
                                vertical: 8.0),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12), // Adjusted to 12
                              side: BorderSide(
                                  color: AppData.silverLakeBlue.withOpacity(0.5), // Colore bordo aggiornato
                                  width: 1),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.folder_open,
                                  color: AppData.silverLakeBlue), // Colore icona aggiornato
                              title: Text(
                                category,
                                style: const TextStyle(
                                  color: AppData.charcoal, // Colore testo aggiornato
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              trailing: Text(
                                '$count viaggi',
                                style: TextStyle(
                                  color: AppData.silverLakeBlue, // Colore testo aggiornato
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SearchScreen(
                                      initialCategory: category,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}