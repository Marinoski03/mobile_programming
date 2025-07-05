import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/trip.dart';

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

  final List<String> _categories = ['Tutte', 'Generale', 'Cultura', 'Natura', 'Relax', 'Avventura', 'Lavoro'];

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null && _categories.contains(widget.initialCategory)) {
      _selectedCategoryFilter = widget.initialCategory!;
    }
    _performSearch(); // Esegui la ricerca iniziale
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    setState(() {
      _searchResults = dummyTrips.where((trip) {
        final query = _searchController.text.toLowerCase();
        final matchesTitle = trip.title.toLowerCase().contains(query);
        final matchesLocation = trip.location.toLowerCase().contains(query);

        final matchesCategory = _selectedCategoryFilter == 'Tutte' || trip.category == _selectedCategoryFilter;

        final matchesStartDate = _startDateFilter == null ||
            trip.startDate.isAfter(_startDateFilter!.subtract(const Duration(days: 1)));
        final matchesEndDate = _endDateFilter == null ||
            trip.endDate.isBefore(_endDateFilter!.add(const Duration(days: 1)));

        return (matchesTitle || matchesLocation) && matchesCategory && matchesStartDate && matchesEndDate;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cerca Viaggi'),
      ),
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
                  child: DropdownButtonFormField<String>(
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
                  child: InkWell(
                    onTap: () => _selectDateFilter(context, true),
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
                      child: Text(_startDateFilter == null ? 'Seleziona data' : DateFormat('dd/MM/yyyy').format(_startDateFilter!)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDateFilter(context, false),
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
                      child: Text(_endDateFilter == null ? 'Seleziona data' : DateFormat('dd/MM/yyyy').format(_endDateFilter!)),
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
                  ? const Center(child: Text('Nessun risultato trovato.'))
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final trip = _searchResults[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TripDetailScreen(trip: trip),
                                ),
                              );
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
                                  Text(
                                    'Categoria: ${trip.category}',
                                    style: Theme.of(context).textTheme.bodySmall,
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
}