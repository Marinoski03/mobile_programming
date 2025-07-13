// lib/screens/search_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:travel_diary_app/screens/trip_detail_screen.dart';

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

        final matchesStartDate = _startDateFilter == null ||
            (trip.startDate.isAtSameMomentAs(_startDateFilter!) ||
                trip.startDate.isAfter(_startDateFilter!));

        final matchesEndDate = _endDateFilter == null ||
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
                foregroundColor:
                AppData.silverLakeBlue,
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

  @override
  Widget build(BuildContext context) {
    final InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
      labelStyle: const TextStyle(color: AppData.charcoal),
      hintStyle: TextStyle(color: AppData.charcoal.withOpacity(0.7)),
      prefixIconColor: AppData.silverLakeBlue,
      suffixIconColor: AppData.silverLakeBlue,
      floatingLabelStyle: const TextStyle(
        color: AppData.silverLakeBlue,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppData.silverLakeBlue.withOpacity(0.5),
          width: 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppData.silverLakeBlue,
          width: 2.0,
        ),
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
      fillColor: AppData.antiFlashWhite.withOpacity(
        0.9,
      ),
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
            color: AppData.antiFlashWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(
          color: AppData.antiFlashWhite,
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          // Gradiente con colori AppData
          gradient: LinearGradient(
            colors: [
              AppData.silverLakeBlue.withOpacity(0.7),
              AppData.charcoal.withOpacity(0.9)
            ],
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
                        icon:
                        const Icon(Icons.clear, color: AppData.silverLakeBlue),
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
                            AppData.antiFlashWhite,
                          ),
                        ),
                      )
                          : Theme(
                        data: Theme.of(context).copyWith(
                          inputDecorationTheme: inputDecorationTheme,
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedCategoryFilter,
                          style: const TextStyle(
                            color: AppData.charcoal,
                          ),
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: AppData.silverLakeBlue,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Filtra per Categoria',
                          ),
                          dropdownColor:
                          AppData.antiFlashWhite,
                          items: _categories.map((String category) {
                            return DropdownMenuItem<String>(
                              value: category.trim(),
                              child: Text(
                                category,
                                style: const TextStyle(
                                  color: AppData.charcoal,
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
                                style: const TextStyle(
                                  color: AppData.charcoal,
                                ),
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
                                style: const TextStyle(
                                  color: AppData.charcoal,
                                ),
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
                      color: AppData.antiFlashWhite,
                    ), // Icona bianca
                    label: const Text(
                      'Cancella Filtri',
                      style: TextStyle(color: AppData.antiFlashWhite),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppData.antiFlashWhite,
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
                        color: AppData.antiFlashWhite.withOpacity(0.7),
                      ),
                    ),
                  )
                      : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final trip = _searchResults[index];
                      return Card(
                        color:
                        AppData.antiFlashWhite.withOpacity(0.15),
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            12,
                          ), // Consistent rounding
                          side: BorderSide(
                            color: AppData.silverLakeBlue.withOpacity(0.5),
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
                                          AppData.charcoal,
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
                                          color: AppData.charcoal.withOpacity(
                                            0.8,
                                          ),
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
                                          AppData.silverLakeBlue,
                                        ),
                                      ),
                                      Text(
                                        'Categoria: ${trip.category}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                          color: AppData.silverLakeBlue
                                              .withOpacity(
                                            0.8,
                                          ),
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
