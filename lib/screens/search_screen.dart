// lib/screens/search_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:travel_diary_app/screens/trip_detail_screen.dart';
import 'dart:io'; // Import per File
import 'package:cached_network_image/cached_network_image.dart'; // Import per CachedNetworkImage

import '../models/trip.dart';
import '../helpers/trip_database_helper.dart';
import '../utils/app_data.dart';

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
          .map((trip) => trip.category.trim())
          .toSet()
          .toList();
      uniqueCategories.sort();

      setState(() {
        _categories.clear();
        _categories.add('Tutte');
        _categories.addAll(uniqueCategories);

        if (widget.initialCategory != null) {
          final sanitizedInitialCategory = widget.initialCategory!.trim();
          if (_categories.contains(sanitizedInitialCategory)) {
            _selectedCategoryFilter = sanitizedInitialCategory;
          } else {
            _selectedCategoryFilter = 'Tutte';
          }
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
            trip.category.trim().toLowerCase() ==
                _selectedCategoryFilter.trim().toLowerCase();

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
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: AppData.silverLakeBlue,
              onPrimary: AppData.antiFlashWhite,
              surface: AppData.antiFlashWhite,
              onSurface: AppData.charcoal,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppData.silverLakeBlue,
              ),
            ),
          ),
          child: child!,
        );
      },
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

  // Widget per visualizzare l'immagine o un placeholder vuoto
  Widget _buildImageWidget(
    String? imageUrl, {
    double? width,
    double? height,
    BoxFit? fit,
    BorderRadius? borderRadius,
  }) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppData.antiFlashWhite.withOpacity(
            0.5,
          ), // Sfondo molto chiaro per lo spazio vuoto
          borderRadius: borderRadius ?? BorderRadius.zero,
          border: Border.all(
            color: AppData.charcoal.withOpacity(0.1),
          ), // Bordo sottile
        ),
      );
    }

    Widget imageWidget;
    if (imageUrl.startsWith('assets/')) {
      imageWidget = Image.asset(
        imageUrl,
        width: width,
        height: height,
        fit: fit ?? BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Errore caricamento asset: $imageUrl, Errore: $error');
          return _buildErrorPlaceholder(width: width, height: height);
        },
      );
    } else if (imageUrl.startsWith('http://') ||
        imageUrl.startsWith('https://')) {
      imageWidget = CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit ?? BoxFit.cover,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(color: AppData.silverLakeBlue),
        ),
        errorWidget: (context, url, error) {
          debugPrint('Errore caricamento network: $url, Errore: $error');
          return _buildErrorPlaceholder(width: width, height: height);
        },
      );
    } else {
      imageWidget = FutureBuilder<bool>(
        future: File(imageUrl).exists(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError || !(snapshot.data ?? false)) {
              debugPrint(
                'Errore caricamento file locale: $imageUrl, Errore: ${snapshot.error ?? "File non trovato"}',
              );
              return _buildErrorPlaceholder(width: width, height: height);
            } else {
              return Image.file(
                File(imageUrl),
                width: width,
                height: height,
                fit: fit ?? BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint(
                    'Errore caricamento Image.file: $imageUrl, Errore: $error',
                  );
                  return _buildErrorPlaceholder(width: width, height: height);
                },
              );
            }
          }
          return const Center(
            child: CircularProgressIndicator(color: AppData.silverLakeBlue),
          );
        },
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius, child: imageWidget);
    }
    return imageWidget;
  }

  // Widget per il placeholder in caso di errore di caricamento immagine
  Widget _buildErrorPlaceholder({double? width, double? height}) {
    return Container(
      width: width,
      height: height,
      color: AppData.antiFlashWhite.withOpacity(0.3),
      child: Icon(
        Icons.image_not_supported,
        color: AppData.charcoal.withOpacity(0.6),
        size: (width ?? 50) / 2,
      ),
    );
  }

  String _sanitizeImagePath(String path) {
    return path.replaceAll('["', '').replaceAll('"]', '').replaceAll('"', '');
  }

  @override
  Widget build(BuildContext context) {
    final InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
      labelStyle: const TextStyle(color: AppData.charcoal),
      hintStyle: TextStyle(color: AppData.charcoal.withOpacity(0.7)),
      prefixIconColor: AppData.silverLakeBlue,
      suffixIconColor: AppData.silverLakeBlue,
      floatingLabelStyle: const TextStyle(color: AppData.silverLakeBlue),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppData.silverLakeBlue.withOpacity(0.5),
          width: 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppData.silverLakeBlue, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppData.cerise, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppData.cerise, width: 2.0),
      ),
      filled: true,
      fillColor: AppData.antiFlashWhite.withOpacity(0.9),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 14.0,
        horizontal: 16.0,
      ),
    );

    return Scaffold(
      backgroundColor: AppData.antiFlashWhite, // Sfondo della home page
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppData.silverLakeBlue, // Colore di sfondo dell'AppBar
        elevation: 0,
        title: const Text(
          'Cerca Viaggi',
          style: TextStyle(
            color: AppData.antiFlashWhite, // Colore della scritta del titolo
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(
          color: AppData.antiFlashWhite, // Colore delle icone nell'AppBar
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Rimosso il BoxDecoration con il gradiente per mostrare lo sfondo silver del Scaffold
        color: AppData
            .antiFlashWhite, // Imposta il colore del Container a antiFlashWhite
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(inputDecorationTheme: inputDecorationTheme),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(
                      color: AppData.charcoal,
                    ), // Input text color
                    decoration: InputDecoration(
                      labelText: 'Cerca per località o titolo',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppData.silverLakeBlue,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: AppData.silverLakeBlue,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch();
                        },
                      ),
                    ),
                    onChanged: (value) => _performSearch(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _isLoadingCategories
                          ? Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppData.silverLakeBlue,
                                ),
                              ),
                            )
                          : Theme(
                              data: Theme.of(context).copyWith(
                                inputDecorationTheme: inputDecorationTheme,
                              ),
                              child: DropdownButtonFormField<String>(
                                value: _selectedCategoryFilter,
                                style: const TextStyle(color: AppData.charcoal),
                                icon: const Icon(
                                  Icons.arrow_drop_down,
                                  color: AppData.silverLakeBlue,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Filtra per Categoria',
                                ),
                                dropdownColor: AppData
                                    .antiFlashWhite, // Sfondo del dropdown
                                items: _categories.map((String category) {
                                  return DropdownMenuItem<String>(
                                    value: category.trim(),
                                    child: Text(
                                      category,
                                      style: const TextStyle(
                                        color: AppData
                                            .charcoal, // Colore testo nel dropdown
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedCategoryFilter = newValue!.trim();
                                    _performSearch();
                                  });
                                },
                              ),
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
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              inputDecorationTheme: inputDecorationTheme,
                            ),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Data Inizio (filtro)',
                                prefixIcon: const Icon(
                                  Icons.calendar_today,
                                  color: AppData.silverLakeBlue,
                                ),
                                suffixIcon: _startDateFilter != null
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.clear,
                                          color: AppData.silverLakeBlue,
                                        ),
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
                                style: const TextStyle(color: AppData.charcoal),
                              ),
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
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              inputDecorationTheme: inputDecorationTheme,
                            ),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Data Fine (filtro)',
                                prefixIcon: const Icon(
                                  Icons.calendar_today,
                                  color: AppData.silverLakeBlue,
                                ),
                                suffixIcon: _endDateFilter != null
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.clear,
                                          color: AppData.silverLakeBlue,
                                        ),
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
                                style: const TextStyle(color: AppData.charcoal),
                              ),
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
                    icon: const Icon(
                      Icons.filter_alt_off,
                      color: AppData.antiFlashWhite, // Icona bianca
                    ),
                    label: const Text(
                      'Cancella Filtri',
                      style: TextStyle(
                        color: AppData.antiFlashWhite,
                      ), // Testo bianco
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppData
                          .antiFlashWhite, // Colore del testo del bottone
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _searchResults.isEmpty
                      ? Center(
                          child: Text(
                            'Nessun risultato trovato per i filtri selezionati.',
                            style: TextStyle(
                              color: AppData.antiFlashWhite.withOpacity(
                                0.7,
                              ), // Colore testo "Nessun risultato"
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final trip = _searchResults[index];
                            final String? coverImageUrl =
                                trip.imageUrls.isNotEmpty
                                ? _sanitizeImagePath(trip.imageUrls.first)
                                : null;
                            return Card(
                              color: AppData
                                  .antiFlashWhite, // Sfondo della Card (bianco)
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: AppData.silverLakeBlue.withOpacity(
                                    0.5,
                                  ), // Bordo della Card
                                  width: 1,
                                ),
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
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    children: [
                                      // Visualizza l'immagine o il placeholder vuoto
                                      _buildImageWidget(
                                        coverImageUrl,
                                        width:
                                            80, // Dimensione immagine nella lista
                                        height: 80,
                                        fit: BoxFit.cover,
                                        borderRadius: BorderRadius.circular(
                                          8.0,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
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
                                                    color: AppData
                                                        .charcoal, // Colore del titolo del viaggio
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              trip.location,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    color: AppData.charcoal
                                                        .withOpacity(
                                                          0.8,
                                                        ), // Colore della località
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${DateFormat('dd/MM/yyyy').format(trip.startDate)} - ${DateFormat('dd/MM/yyyy').format(trip.endDate)}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    color: AppData
                                                        .silverLakeBlue, // Colore delle date
                                                  ),
                                            ),
                                            Text(
                                              'Categoria: ${trip.category}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: AppData
                                                        .silverLakeBlue
                                                        .withOpacity(
                                                          0.8,
                                                        ), // Colore della categoria
                                                  ),
                                            ),
                                          ],
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
        ),
      ),
    );
  }
}
