// lib/screens/search_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:travel_diary_app/screens/trip_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Per il caching delle immagini

import '../models/trip.dart';
import '../helpers/trip_database_helper.dart';

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

  // Lista delle categorie che verrà popolata dinamicamente dal database
  final List<String> _categories = ['Tutte']; // Inizializza con 'Tutte'

  bool _isLoadingCategories = true; // Stato per il caricamento delle categorie

  @override
  void initState() {
    super.initState();
    _loadCategoriesAndPerformSearch(); // Carica le categorie e poi esegue la ricerca
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Nuovo metodo per caricare le categorie dal database
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
      uniqueCategories.sort(); // Ordina le categorie alfabeticamente

      setState(() {
        _categories.clear();
        _categories.add('Tutte'); // Aggiungi sempre l'opzione "Tutte"
        _categories.addAll(uniqueCategories);

        // Se è stata passata una categoria iniziale, la imposta se valida
        if (widget.initialCategory != null &&
            _categories.contains(widget.initialCategory)) {
          _selectedCategoryFilter = widget.initialCategory!;
        } else {
          _selectedCategoryFilter =
              'Tutte'; // Assicurati che sia un valore valido
        }
      });
    } catch (e) {
      print('Errore nel caricamento delle categorie: $e'); // Logga l'errore
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore nel caricamento delle categorie: $e')),
      );
    } finally {
      setState(() {
        _isLoadingCategories = false;
      });
      _performSearch(); // Esegui la ricerca solo dopo aver caricato le categorie
    }
  }

  Future<void> _performSearch() async {
    // Recupera i viaggi dal database
    final trips = await TripDatabaseHelper.instance.getAllTrips();

    // Applica i filtri
    setState(() {
      _searchResults = trips.where((trip) {
        final query = _searchController.text.toLowerCase();
        final matchesTitle = trip.title.toLowerCase().contains(query);
        final matchesLocation = trip.location.toLowerCase().contains(query);

        final matchesCategory =
            _selectedCategoryFilter == 'Tutte' ||
            trip.category.toLowerCase() ==
                _selectedCategoryFilter
                    .toLowerCase(); // Confronto case-insensitive

        // Controllo per le date, assicurati che la data del viaggio sia all'interno del range del filtro
        final matchesStartDate =
            _startDateFilter == null ||
            (trip.startDate.isAtSameMomentAs(_startDateFilter!) ||
                trip.startDate.isAfter(_startDateFilter!));

        // Il filtro endDate dovrebbe includere il giorno selezionato fino alla fine del giorno
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
        _performSearch(); // Ricarica i risultati con il nuovo filtro data
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategoryFilter = 'Tutte';
      _startDateFilter = null;
      _endDateFilter = null;
      _performSearch(); // Ricarica i risultati senza filtri
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cerca Viaggi')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Campo di ricerca testuale
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
                    _performSearch(); // Esegui ricerca con campo vuoto
                  },
                ),
              ),
              onChanged: (value) =>
                  _performSearch(), // Filtra ad ogni digitazione
            ),
            const SizedBox(height: 16),
            // Filtro per Categoria
            Row(
              children: [
                Expanded(
                  child: _isLoadingCategories
                      ? const Center(
                          child: CircularProgressIndicator(),
                        ) // Mostra caricamento categorie
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
                              _performSearch(); // Esegui ricerca con nuovo filtro categoria
                            });
                          },
                        ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Filtri per Data Inizio e Data Fine
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    // Usa GestureDetector per un'area più ampia cliccabile
                    onTap: () => _selectDateFilter(context, true),
                    child: AbsorbPointer(
                      // Impedisce che il TextField riceva il focus
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
                    // Usa GestureDetector per un'area più ampia cliccabile
                    onTap: () => _selectDateFilter(context, false),
                    child: AbsorbPointer(
                      // Impedisce che il TextField riceva il focus
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
            // Pulsante per cancellare tutti i filtri
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.filter_alt_off),
                label: const Text('Cancella Filtri'),
              ),
            ),
            const SizedBox(height: 16),
            // Risultati della ricerca
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
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () async {
                              await Navigator.push(
                                // Aggiungi await per aggiornare al ritorno
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      TripDetailScreen(trip: trip),
                                ),
                              );
                              _performSearch(); // Riesegui la ricerca al ritorno (se un viaggio è stato modificato)
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
                                  // Anteprima immagine (opzionale, se vuoi mostrarla nei risultati)
                                  if (trip.imageUrls.isNotEmpty &&
                                      trip.imageUrls.first.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          8.0,
                                        ),
                                        child: CachedNetworkImage(
                                          imageUrl: trip.imageUrls.first,
                                          height: 80,
                                          width: 120,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              Container(
                                                height: 80,
                                                width: 120,
                                                color: Colors.grey[200],
                                                child: const Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                ),
                                              ),
                                          errorWidget: (context, url, error) =>
                                              _buildImageErrorPlaceholderSmall(),
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

  // Widget helper per il placeholder in caso di errore immagine (versione piccola)
  Widget _buildImageErrorPlaceholderSmall() {
    return Container(
      width: 120,
      height: 80,
      color: Colors.grey[300],
      child: const Icon(Icons.broken_image, color: Colors.grey, size: 30),
    );
  }
}
