// lib/screens/categories_screen.dart

import 'package:flutter/material.dart';
import '../helpers/trip_database_helper.dart';
import 'package:travel_diary_app/screens/search_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  // Define colors based on the home_screen palette
  static const Color _gradientStartColor = Colors.blue; // Simpler blue for start
  static const Color _gradientEndColor = Color.fromARGB(255, 13, 71, 161); // A darker blue for end
  static const Color _cardBackgroundColor = Colors.white; // Cards remain white
  static const Color _textColorOnCard = Colors.black87; // Dark text on white cards
  static const Color _textColorOnGradient = Colors.white; // White text on blue gradient
  static const Color _iconColor = Color.fromARGB(255, 13, 71, 161); // Dark blue for icons on cards

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
            color: _textColorOnGradient, // Text color on gradient background
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: _textColorOnGradient, // Icon color to match text
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            // Using blue shades similar to HomeScreen
            colors: [_gradientStartColor, _gradientEndColor],
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
                return const Center(
                  // Use _textColorOnGradient for loading indicator on dark gradient
                  child: CircularProgressIndicator(
                    valueColor:
                    AlwaysStoppedAnimation<Color>(_textColorOnGradient),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Errore nel caricamento delle categorie: ${snapshot.error}',
                    style: const TextStyle(
                        color: _textColorOnGradient), // Error text in white
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
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _textColorOnGradient, // Header text in white
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
                              color:
                              _textColorOnGradient), // Empty state text in white
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
                            // Card background remains Anti-flash White for contrast
                            color: _cardBackgroundColor,
                            margin: const EdgeInsets.symmetric(
                                vertical: 8.0),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12), // Adjusted to 12
                              side: BorderSide(
                                  color: Colors.blue.shade200, // Light blue border
                                  width: 1),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.folder_open,
                                  color: _iconColor), // Dark blue for icon
                              title: Text(
                                category,
                                style: const TextStyle(
                                  color: _textColorOnCard, // Dark text for title
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              trailing: Text(
                                '$count viaggi',
                                style: TextStyle(
                                  color: _iconColor, // Dark blue for count text
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