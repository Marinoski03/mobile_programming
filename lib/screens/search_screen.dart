// lib/screens/search_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:travel_diary_app/screens/trip_detail_screen.dart';
// Rimuovi questo import, non useremo CachedNetworkImage per i percorsi locali
// import 'package:cached_network_image/cached_network_image.dart';

import 'dart:io'; // <--- AGGIUNGI QUESTO IMPORT PER USARE File()
import '../models/trip.dart';
import '../helpers/trip_database_helper.dart';
import '../utils/app_data.dart'; // <--- ASSICURATI DI AVERE QUESTO IMPORT PER AppData

class SearchScreen extends StatefulWidget {
  final String? initialCategory;
  const SearchScreen({super.key, this.initialCategory});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategoryFilter = 'Tutte';
  DateTime? _startDateFilter;
  DateTime? _endDateFilter;
  List<Trip> _searchResults = [];

  final List<String> _categories = ['Tutte'];

  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategoriesAndPerformSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategoriesAndPerformSearch() async {
    setState(() {
      _isLoadingCategories = true;
    });
    try {
      final allTrips = await TripDatabaseHelper.instance.getAllTrips();
      final uniqueCategories = allTrips
          .map((trip) => trip.category)
          .toSet()
          .toList();
      uniqueCategories.sort();

      setState(() {
        _categories.clear();
        _categories.add('Tutte');
        _categories.addAll(uniqueCategories);

        if (widget.initialCategory != null &&
            _categories.contains(widget.initialCategory)) {
          _selectedCategoryFilter = widget.initialCategory!;
        } else {
          _selectedCategoryFilter = 'Tutte';
        }
      });
    } catch (e) {
      print('Errore nel caricamento delle categorie: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore nel caricamento delle categorie: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoadingCategories = false;
      });
      _performSearch();
    }
  }

  Future<void> _performSearch() async {
    final trips = await TripDatabaseHelper.instance.getAllTrips();

    setState(() {
      _searchResults = trips.where((trip) {
        final query = _searchController.text.toLowerCase();
        final matchesTitle = trip.title.toLowerCase().contains(query);
        final matchesLocation = trip.location.toLowerCase().contains(query);

        final matchesCategory =
            _selectedCategoryFilter == 'Tutte' ||
            trip.category.toLowerCase() ==
                _selectedCategoryFilter.toLowerCase();

        final matchesStartDate =
            _startDateFilter == null ||
            (trip.startDate.isAtSameMomentAs(_startDateFilter!) ||
                trip.startDate.isAfter(_startDateFilter!));

        final matchesEndDate =
            _endDateFilter == null ||
            (trip.endDate.isAtSameMomentAs(_endDateFilter!) ||
                trip.endDate.isBefore(_endDateFilter!));

        return (matchesTitle || matchesLocation) &&
            matchesCategory &&
            matchesStartDate &&
            matchesEndDate;
      }).toList();
    });
  }

  Future<void> _selectDateFilter(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDateFilter = picked;
        } else {
          _endDateFilter = picked;
        }
        _performSearch();
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategoryFilter = 'Tutte';
      _startDateFilter = null;
      _endDateFilter = null;
      _performSearch();
    });
  }

  // Helper per ottenere l'ImageProvider corretto, simile a TripDetailScreen e HomeScreen
  ImageProvider _getImageProvider(String imageUrl, String continent) {
    if (imageUrl.startsWith('assets/')) {
      return AssetImage(imageUrl);
    } else if (imageUrl.startsWith('/data/') ||
        imageUrl.startsWith('file://')) {
      final file = File(imageUrl.replaceFirst('file://', ''));
      if (file.existsSync()) {
        return FileImage(file);
      } else {
        print('DEBUG - SearchScreen: File immagine non trovato: $imageUrl');
        // Fallback a immagine continente o default se il file non esiste
        return AssetImage(
          AppData.continentImages[continent] ??
              AppData.continentImages['Generale'] ??
              'assets/images/default_trip.jpg',
        );
      }
    } else {
      // Per ogni altro caso (es. URL web se mai supportati, ma ora fallback a asset)
      return AssetImage(
        AppData.continentImages[continent] ??
            AppData.continentImages['Generale'] ??
            'assets/images/default_trip.jpg',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cerca Viaggi')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Cerca per località o titolo',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch();
                  },
                ),
              ),
              onChanged: (value) => _performSearch(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _isLoadingCategories
                      ? const Center(child: CircularProgressIndicator())
                      : DropdownButtonFormField<String>(
                          value: _selectedCategoryFilter,
                          decoration: const InputDecoration(
                            labelText: 'Filtra per Categoria',
                            border: OutlineInputBorder(),
                          ),
                          items: _categories.map((String category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedCategoryFilter = newValue!;
                              _performSearch();
                            });
                          },
                        ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectDateFilter(context, true),
                    child: AbsorbPointer(
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Data Inizio (filtro)',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.calendar_today),
                          suffixIcon: _startDateFilter != null
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _startDateFilter = null;
                                      _performSearch();
                                    });
                                  },
                                )
                              : null,
                        ),
                        child: Text(
                          _startDateFilter == null
                              ? 'Seleziona data'
                              : DateFormat(
                                  'dd/MM/yyyy',
                                ).format(_startDateFilter!),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectDateFilter(context, false),
                    child: AbsorbPointer(
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Data Fine (filtro)',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.calendar_today),
                          suffixIcon: _endDateFilter != null
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _endDateFilter = null;
                                      _performSearch();
                                    });
                                  },
                                )
                              : null,
                        ),
                        child: Text(
                          _endDateFilter == null
                              ? 'Seleziona data'
                              : DateFormat(
                                  'dd/MM/yyyy',
                                ).format(_endDateFilter!),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.filter_alt_off),
                label: const Text('Cancella Filtri'),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _searchResults.isEmpty
                  ? const Center(
                      child: Text(
                        'Nessun risultato trovato per i filtri selezionati.',
                      ),
                    )
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final trip = _searchResults[index];
                        // Determina l'URL dell'immagine di copertina
                        final String coverImageUrl;
                        if (trip.imageUrls.isNotEmpty) {
                          coverImageUrl = trip.imageUrls.first;
                        } else {
                          // Usa l'immagine del continente o una generica di default
                          coverImageUrl =
                              AppData.continentImages[trip.continent] ??
                              AppData.continentImages['Generale'] ??
                              'assets/images/default_trip.jpg';
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      TripDetailScreen(trip: trip),
                                ),
                              );
                              _performSearch();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    trip.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
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
                                  Text(
                                    'Categoria: ${trip.category}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  // Anteprima immagine (ora usa il metodo _getImageProvider)
                                  if (coverImageUrl
                                      .isNotEmpty) // Mostra solo se c'è un URL da caricare
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          8.0,
                                        ),
                                        child: Image(
                                          // <--- MODIFICATO QUI: Usa Image widget
                                          image: _getImageProvider(
                                            coverImageUrl,
                                            trip.continent,
                                          ),
                                          height: 80,
                                          width: 120,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, url, error) {
                                            print(
                                              'DEBUG - Errore caricamento immagine in SearchScreen: $error',
                                            );
                                            return _buildImageErrorPlaceholderSmall();
                                          },
                                        ),
                                      ),
                                    ),
                                ],
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

  Widget _buildImageErrorPlaceholderSmall() {
    return Container(
      width: 120,
      height: 80,
      color: Colors.grey[300],
      child: const Icon(Icons.broken_image, color: Colors.grey, size: 30),
    );
  }
}
