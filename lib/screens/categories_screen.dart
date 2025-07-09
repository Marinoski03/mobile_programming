// lib/screens/categories_screen.dart

import 'package:flutter/material.dart'; // Fondamentale per i widget Flutter
import '../helpers/trip_database_helper.dart'; // Per interagire con il database
import 'package:travel_diary_app/screens/search_screen.dart'; // Assicurati che il percorso sia corretto

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  // Mappa per contare i viaggi per categoria, inizializzata vuota
  Map<String, int> _categoryCounts = {};

  // Future per gestire lo stato di caricamento dei dati iniziali
  late Future<void> _loadCategoriesFuture;

  @override
  void initState() {
    super.initState();
    // Inizializza il Future che caricherà i dati quando la schermata viene creata
    _loadCategoriesFuture = _loadCategoryCounts();
  }

  // Metodo asincrono per caricare e calcolare i conteggi delle categorie dal database
  Future<void> _loadCategoryCounts() async {
    // Recupera tutti i viaggi dal database usando il TripDatabaseHelper
    final allTrips = await TripDatabaseHelper.instance.getAllTrips();

    // Reset della mappa dei conteggi per un nuovo calcolo
    final Map<String, int> counts = {};

    // Itera su tutti i viaggi recuperati e aggiorna i conteggi per categoria
    for (var trip in allTrips) {
      counts.update(trip.category, (value) => value + 1, ifAbsent: () => 1);
    }

    // Aggiorna lo stato del widget per ricostruire l'UI con i nuovi conteggi
    // Questo è importante per visualizzare i dati dopo che sono stati caricati
    setState(() {
      _categoryCounts = counts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorie Viaggi'),
        actions: [
          // Pulsante per ricaricare manualmente le categorie (utile per il debugging o aggiornamenti)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _loadCategoriesFuture =
                    _loadCategoryCounts(); // Ricarica i dati
              });
            },
            tooltip: 'Aggiorna categorie',
          ),
        ],
      ),
      // FutureBuilder per gestire i diversi stati del caricamento asincrono dei dati
      body: FutureBuilder<void>(
        future: _loadCategoriesFuture, // Il Future che gestisce il caricamento
        builder: (context, snapshot) {
          // Mostra un indicatore di caricamento mentre i dati sono in attesa
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Mostra un messaggio di errore se il caricamento fallisce
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Errore nel caricamento delle categorie: ${snapshot.error}',
              ),
            );
          }

          // Quando i dati sono stati caricati, costruisce l'interfaccia utente
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Riepilogo per categoria:',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                // Se non ci sono categorie (o viaggi), mostra un messaggio all'utente
                _categoryCounts.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text(
                            'Nessuna categoria trovata. Aggiungi dei viaggi per vederle qui.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : Expanded(
                        // Lista scrollabile delle categorie e dei loro conteggi
                        child: ListView.builder(
                          itemCount: _categoryCounts.length,
                          itemBuilder: (context, index) {
                            final category = _categoryCounts.keys.elementAt(
                              index,
                            );
                            final count = _categoryCounts[category];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                leading: const Icon(Icons.folder_open),
                                title: Text(category),
                                trailing: Text('$count viaggi'),
                                onTap: () {
                                  // Naviga alla SearchScreen filtrando per la categoria selezionata
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
                // Il pulsante per aggiungere nuove categorie è stato rimosso in questa schermata
                // perché le categorie sono derivate dai viaggi esistenti nel database.
                // Se vuoi un elenco predefinito o la possibilità di aggiungerle a prescindere,
                // la logica andrebbe gestita in un altro punto dell'applicazione.
              ],
            ),
          );
        },
      ),
    );
  }
}
