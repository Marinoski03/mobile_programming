// lib/screens/categories_screen.dart

import 'package:flutter/material.dart';
import '../helpers/trip_database_helper.dart';
import 'package:travel_diary_app/screens/search_screen.dart';
import '../utils/app_data.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
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
      // Scaffold background color set to antiFlashWhite
      backgroundColor: AppData.antiFlashWhite,

      // extendBodyBehindAppBar: true, // Rimosso perché l'AppBar non è più trasparente
      appBar: AppBar(
        // AppBar background color set to silverLakeBlue
        backgroundColor: AppData.silverLakeBlue,
        elevation: 0,
        title: const Text(
          'Categorie Viaggi',
          style: TextStyle(
            color: AppData.antiFlashWhite, // AppBar title text color
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: AppData.antiFlashWhite, // Refresh icon color
            onPressed: () {
              setState(() {
                _loadCategoriesFuture = _loadCategoryCounts();
              });
            },
            tooltip: 'Aggiorna categorie',
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Rimosso il BoxDecoration con il gradiente per mostrare lo sfondo silver del Scaffold
        color: AppData
            .antiFlashWhite, // Imposta il colore del Container a antiFlashWhite
        child: SafeArea(
          child: FutureBuilder<void>(
            future: _loadCategoriesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppData.silverLakeBlue,
                    ), // Loading indicator color (cambiato per contrasto)
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Errore nel caricamento delle categorie: ${snapshot.error}',
                    style: const TextStyle(
                      color: AppData.charcoal,
                    ), // Error text color (cambiato per contrasto)
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
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppData
                            .charcoal, // Section title text color (cambiato per contrasto)
                      ),
                    ),
                    const SizedBox(height: 10),
                    _categoryCounts.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Text(
                                'Nessuna categoria trovata. Aggiungi dei viaggi per vederle qui.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppData.charcoal.withOpacity(
                                    0.7,
                                  ), // No data text color (cambiato per contrasto)
                                ),
                              ),
                            ),
                          )
                        : Expanded(
                            child: ListView.builder(
                              itemCount: _categoryCounts.length,
                              itemBuilder: (context, index) {
                                final category = _categoryCounts.keys.elementAt(
                                  index,
                                );
                                final count = _categoryCounts[category];
                                return Card(
                                  // Card background color set to antiFlashWhite
                                  color: AppData.antiFlashWhite,
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: AppData.silverLakeBlue.withOpacity(
                                        0.5,
                                      ), // Card border color
                                      width: 1,
                                    ),
                                  ),
                                  child: ListTile(
                                    leading: const Icon(
                                      Icons.folder_open,
                                      color: AppData.silverLakeBlue,
                                    ), // Leading icon color
                                    title: Text(
                                      category,
                                      style: const TextStyle(
                                        color: AppData
                                            .charcoal, // Title text color on card
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    trailing: Text(
                                      '$count viaggi',
                                      style: TextStyle(
                                        color: AppData
                                            .silverLakeBlue, // Trailing text color
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
