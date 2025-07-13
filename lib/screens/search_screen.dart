// lib/screens/search_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:travel_diary_app/screens/trip_detail_screen.dart';

import '../models/trip.dart';
import '../helpers/trip_database_helper.dart';

class SearchScreen extends StatefulWidget {
  final String? initialCategory;
  const SearchScreen({super.key, this.initialCategory});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // Define colors based on the home_screen palette
  static const Color _gradientStartColor = Colors.blue;
  static const Color _gradientEndColor = Color.fromARGB(
    255,
    13,
    71,
    161,
  ); // A darker blue for consistency
  static const Color _cardBackgroundColor = Colors.white;
  static const Color _textColor =
      Colors.black87; // Darker text for readability on white cards
  static const Color _lightTextColor =
      Colors.white70; // For text on gradient background

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
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: _gradientEndColor, // A darker blue
              onPrimary: Colors.white,
              surface: _cardBackgroundColor, // White background for date picker
              onSurface: _textColor, // Dark text on white
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor:
                    _gradientEndColor, // Color of "OK", "CANCEL" buttons
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

  // Helper per ottenere l'ImageProvider corretto, simile a TripDetailScreen e HomeScreen

  @override
  Widget build(BuildContext context) {
    // Define shared input decoration style
    final InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
      labelStyle: const TextStyle(color: _textColor), // Label text color
      hintStyle: TextStyle(color: _textColor.withOpacity(0.7)),
      prefixIconColor: _gradientEndColor,
      suffixIconColor: _gradientEndColor,
      floatingLabelStyle: const TextStyle(
        color: _gradientEndColor,
      ), // Label when focused
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: _gradientEndColor.withOpacity(0.5),
          width: 1.0,
        ), // Border when not focused
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: _gradientEndColor,
          width: 2.0,
        ), // Border when focused
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2.0),
      ),
      filled: true,
      fillColor: _cardBackgroundColor.withOpacity(
        0.9,
      ), // Slightly transparent white fill
      contentPadding: const EdgeInsets.symmetric(
        vertical: 14.0,
        horizontal: 16.0,
      ),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Cerca Viaggi',
          style: TextStyle(
            color: Colors.white, // White text for AppBar title
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ), // Set back button color to white
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_gradientStartColor, _gradientEndColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Theme(
                  // Apply input decoration theme to TextField
                  data: Theme.of(
                    context,
                  ).copyWith(inputDecorationTheme: inputDecorationTheme),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(
                      color: _textColor,
                    ), // Input text color
                    decoration: InputDecoration(
                      labelText: 'Cerca per località o titolo',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: _gradientEndColor,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear, color: _gradientEndColor),
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
                          ? const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Theme(
                              // Apply input decoration theme to Dropdown
                              data: Theme.of(context).copyWith(
                                inputDecorationTheme: inputDecorationTheme,
                              ),
                              child: DropdownButtonFormField<String>(
                                value: _selectedCategoryFilter,
                                style: const TextStyle(
                                  color: _textColor,
                                ), // Selected item text color
                                icon: const Icon(
                                  Icons.arrow_drop_down,
                                  color: _gradientEndColor,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Filtra per Categoria',
                                ),
                                dropdownColor:
                                    _cardBackgroundColor, // Background of dropdown menu
                                items: _categories.map((String category) {
                                  return DropdownMenuItem<String>(
                                    value: category,
                                    child: Text(
                                      category,
                                      style: const TextStyle(
                                        color: _textColor,
                                      ), // Dropdown menu item text color
                                    ),
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
                            // Apply input decoration theme to Date fields
                            data: Theme.of(context).copyWith(
                              inputDecorationTheme: inputDecorationTheme,
                            ),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Data Inizio (filtro)',
                                prefixIcon: const Icon(
                                  Icons.calendar_today,
                                  color: _gradientEndColor,
                                ),
                                suffixIcon: _startDateFilter != null
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.clear,
                                          color: _gradientEndColor,
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
                                style: const TextStyle(
                                  color: _textColor,
                                ), // Displayed date text color
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
                            // Apply input decoration theme to Date fields
                            data: Theme.of(context).copyWith(
                              inputDecorationTheme: inputDecorationTheme,
                            ),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Data Fine (filtro)',
                                prefixIcon: const Icon(
                                  Icons.calendar_today,
                                  color: _gradientEndColor,
                                ),
                                suffixIcon: _endDateFilter != null
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.clear,
                                          color: _gradientEndColor,
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
                                style: const TextStyle(
                                  color: _textColor,
                                ), // Displayed date text color
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
                      color: Colors.white,
                    ), // White icon
                    label: const Text(
                      'Cancella Filtri',
                      style: TextStyle(color: Colors.white), // White text
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white, // For ripple effect
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _searchResults.isEmpty
                      ? const Center(
                          child: Text(
                            'Nessun risultato trovato per i filtri selezionati.',
                            style: TextStyle(
                              color: _lightTextColor,
                            ), // White text for empty results
                          ),
                        )
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final trip = _searchResults[index];
                            return Card(
                              color:
                                  _cardBackgroundColor, // Card background white
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  12,
                                ), // Consistent rounding
                                side: BorderSide(
                                  color: Colors.blue.shade200,
                                  width: 1,
                                ), // Subtle border
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
                                                    color:
                                                        _textColor, // Dark text for title
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
                                                    color: _textColor.withOpacity(
                                                      0.8,
                                                    ), // Slightly lighter dark
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
                                                    color:
                                                        _gradientEndColor, // Blue for dates
                                                  ),
                                            ),
                                            Text(
                                              'Categoria: ${trip.category}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: _gradientEndColor
                                                        .withOpacity(
                                                          0.8,
                                                        ), // Blue for category
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
