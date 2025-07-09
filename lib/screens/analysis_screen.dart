// lib/screens/analysis_screen.dart (o dove si trova la tua AnalysisScreen)

import 'package:flutter/material.dart'; // Importazione essenziale per i widget Flutter
import '../helpers/trip_database_helper.dart';
import '../models/trip.dart'; // Importa la classe Trip

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analisi Viaggi')),
      body: FutureBuilder<List<Trip>>(
        future: TripDatabaseHelper.instance.getAllTrips(),
        builder: (context, snapshot) {
          // Stato di caricamento
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Stato di errore
          if (snapshot.hasError) {
            return Center(
              child: Text('Errore nel caricamento dei dati: ${snapshot.error}'),
            );
          }

          // Nessun dato disponibile
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Nessun viaggio trovato per l\'analisi.'),
            );
          }

          final trips = snapshot.data!;
          final totalTrips = trips.length;

          // Calcolo delle statistiche
          Map<String, int> tripsByCategory = {};
          for (var trip in trips) {
            tripsByCategory.update(
              trip.category,
              (value) => value + 1,
              ifAbsent: () => 1,
            );
          }

          Map<int, int> tripsByYear = {};
          for (var trip in trips) {
            final year = trip.startDate.year;
            tripsByYear.update(year, (value) => value + 1, ifAbsent: () => 1);
          }

          double averageTripsPerYear = 0;
          if (tripsByYear.isNotEmpty) {
            final totalYears = tripsByYear.keys.length;
            final sumTrips = tripsByYear.values.fold(
              0,
              (sum, count) => sum + count,
            );
            averageTripsPerYear = sumTrips / totalYears;
          }

          // Visualizzazione delle statistiche
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statistiche dei Viaggi',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),

                // Numero totale di viaggi
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Numero totale di viaggi:',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '$totalTrips',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Viaggi per categoria
                Text(
                  'Viaggi per Categoria:',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                ...tripsByCategory.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key),
                        Text('${entry.value} viaggi'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Viaggi per Anno
                Text(
                  'Viaggi per Anno:',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                ...tripsByYear.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${entry.key}'),
                        Text('${entry.value} viaggi'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Media viaggi per anno
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Media viaggi per anno:',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          averageTripsPerYear.toStringAsFixed(
                            1,
                          ), // Formatta a 1 decimale
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
