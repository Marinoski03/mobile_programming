// lib/screens/analysis_screen.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../helpers/trip_database_helper.dart';
import '../models/trip.dart';
import 'package:fl_chart/fl_chart.dart'; // Importa fl_chart
import '../utils/app_data.dart'; // Importa AppData per i colori

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Sfondo generale dell'app (il "Foglio Bianco")
      backgroundColor: AppData.antiFlashWhite,
      appBar: AppBar(
        title: const Text(
          'Analisi Viaggi',
          style: TextStyle(
              color: AppData.antiFlashWhite), // Colore testo aggiornato
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(
            color: AppData.antiFlashWhite), // Colore icona aggiornato
      ),
      extendBodyBehindAppBar: true, // Questo deve essere TRUE
      body: Container(
        width:
            double.infinity, // Assicura che il Container riempia la larghezza
        height: double.infinity, // Assicura che il Container riempia l'altezza
        decoration: BoxDecoration(
          gradient: LinearGradient(
            // Gradiente con colori Primario e Testo Scuro
            colors: [
              AppData.silverLakeBlue.withOpacity(0.7), // Colore Primario
              AppData.charcoal.withOpacity(0.9) // Testo/Icone Scure
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FutureBuilder<List<Trip>>(
          future: TripDatabaseHelper.instance.getAllTrips(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                    color: AppData.antiFlashWhite), // Colore indicatore aggiornato
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Errore nel caricamento dei dati: ${snapshot.error}',
                  style: const TextStyle(
                      color: AppData.antiFlashWhite), // Colore testo aggiornato
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  'Nessun viaggio trovato per l\'analisi.',
                  style: TextStyle(
                      color: AppData.antiFlashWhite), // Colore testo aggiornato
                ),
              );
            }

            final trips = snapshot.data!;
            final totalTrips = trips.length;

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

            int favourites = 0;
            for (var trip in trips) {
              if (trip.isFavorite) {
                favourites++;
              }
            }

            int repeat = 0;
            for (var trip in trips) {
              if (trip.toBeRepeated) {
                repeat++;
              }
            }

            // Calcolo del paese più visitato (non usato direttamente in grafici qui, ma mantenuto)
            Map<String, int> tripsByCountry = {};
            for (var trip in trips) {
              // ignore: unnecessary_null_comparison // L'ignora può essere rimosso con Dart 3.0+ e null safety forte
              if (trip.location != null && trip.location.isNotEmpty) {
                tripsByCountry.update(
                  trip.location,
                  (value) => value + 1,
                  ifAbsent: () => 1,
                );
              }
            }

            // Dati per il PieChart (Viaggi per Categoria)
            List<PieChartSectionData> pieChartSections = [];
            int totalCategoriesTrips = 0;
            tripsByCategory.forEach((category, count) {
              totalCategoriesTrips += count;
            });

            // Assegna colori per le categorie dalla tua palette definita
            List<Color> categoryColors = [
              AppData.cerise,         // Accento
              AppData.silverLakeBlue, // Primario
              AppData.charcoal,       // Neutro scuro
              AppData.errorRed,       // Se serve un altro colore distintivo
              // Se hai più di 4 categorie, i colori si ripeteranno ciclicamente
            ];
            int colorIndex = 0;

            tripsByCategory.forEach((category, count) {
              final double percentage = (count / totalCategoriesTrips) * 100;
              pieChartSections.add(
                PieChartSectionData(
                  // Colore della sezione dalla tua palette
                  color: categoryColors[colorIndex % categoryColors.length],
                  value: count.toDouble(),
                  title: '${category}\n${percentage.toStringAsFixed(1)}%',
                  radius: 80, // Dimensione della sezione
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppData.antiFlashWhite, // Colore testo aggiornato
                  ),
                  badgeWidget: Text(
                    '${count}',
                    style: const TextStyle(
                        color: AppData.antiFlashWhite,
                        fontSize: 10), // Colore testo badge aggiornato
                  ), // Opzionale: mostra il conteggio
                  badgePositionPercentageOffset: .98,
                ),
              );
              colorIndex++;
            });

            // Dati per il BarChart (Viaggi per Anno)
            List<BarChartGroupData> barGroups = [];
            final sortedYears = tripsByYear.keys.toList()..sort();
            double maxY = 0; // Per determinare l'altezza massima del grafico

            for (int i = 0; i < sortedYears.length; i++) {
              final year = sortedYears[i];
              final count = tripsByYear[year]!.toDouble();
              if (count > maxY) {
                maxY = count;
              }
              barGroups.add(
                BarChartGroupData(
                  x: i, // L'indice sull'asse X
                  barRods: [
                    BarChartRodData(
                      toY: count,
                      // Colore delle barre aggiornato al colore primario
                      color: AppData.silverLakeBlue,
                      width: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                  showingTooltipIndicators: [
                    0,
                  ], // Mostra tooltip per la prima bar rod
                ),
              );
            }
            // Aggiusta maxY per un po' di margine in alto
            maxY = (maxY + (maxY * 0.1)).ceilToDouble();

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Statistiche dei Viaggi',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            color: AppData.antiFlashWhite, // Colore testo aggiornato
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 24),

                    _buildStatCard(
                      context,
                      'Numero totale di viaggi:',
                      '$totalTrips',
                    ),

                    const SizedBox(height: 24),

                    _buildStatCard(
                      context,
                      'Media viaggi per anno:',
                      averageTripsPerYear.toStringAsFixed(1),
                    ),
                    const SizedBox(height: 24),

                    _buildStatCard(context, 'Viaggi da ripetere:', '$repeat'),
                    const SizedBox(height: 24),

                    _buildStatCard(context, 'Viaggi preferiti:', '$favourites'),
                    const SizedBox(height: 24),

                    Text(
                      'Viaggi per Categoria:',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppData.antiFlashWhite, // Colore testo aggiornato
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Grafico a torta per le categorie
                    AspectRatio(
                      aspectRatio: 1.3, // Controllo delle proporzioni
                      child: Card(
                        // Sfondo della Card (Superfici Chiare con opacità)
                        color: AppData.antiFlashWhite
                            .withOpacity(0.15), // Colore card aggiornato
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        elevation: 5,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: PieChart(
                            PieChartData(
                              sections: pieChartSections,
                              sectionsSpace: 2, // Spazio tra le sezioni
                              centerSpaceRadius:
                                  40, // Dimensione del buco centrale
                              borderData: FlBorderData(
                                show: false,
                              ), // Nasconde il bordo
                              // Opzionale: gestisci il tap sulle sezioni
                              pieTouchData: PieTouchData(
                                touchCallback:
                                    (FlTouchEvent event, pieTouchResponse) {
                                      // Puoi aggiungere logica qui per reazioni al tocco
                                    },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Lista testuale delle categorie (mantenuta se serve un dettaglio)
                    ...tripsByCategory.entries.map(
                      (entry) => _buildStatCard(
                        context,
                        entry.key,
                        '${entry.value} viaggi',
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Viaggi per Anno:',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppData.antiFlashWhite, // Colore testo aggiornato
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Grafico a barre per gli anni
                    AspectRatio(
                      aspectRatio: 1.6, // Controllo delle proporzioni
                      child: Card(
                        // Sfondo della Card (Superfici Chiare con opacità)
                        color: AppData.antiFlashWhite
                            .withOpacity(0.15), // Colore card aggiornato
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        elevation: 5,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: maxY, // Altezza massima dell'asse Y
                              barGroups: barGroups,
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (value) =>
                                    FlLine(
                                      color: AppData.antiFlashWhite
                                          .withOpacity(0.1), // Colore griglia aggiornato
                                      strokeWidth: 1,
                                    ),
                              ),
                              borderData: FlBorderData(
                                show: true,
                                border: Border.all(
                                  color: AppData.antiFlashWhite
                                      .withOpacity(0.3), // Colore bordo aggiornato
                                  width: 1,
                                ),
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      // Usa l'indice per ottenere l'anno dal tuo array ordinato
                                      if (value.toInt() < sortedYears.length) {
                                        return Text(
                                          '${sortedYears[value.toInt()]}',
                                          style: const TextStyle(
                                            color: AppData.antiFlashWhite, // Colore testo aggiornato
                                            fontSize: 10,
                                          ),
                                        );
                                      }
                                      return const Text('');
                                    },
                                    reservedSize: 30,
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        value
                                            .toInt()
                                            .toString(), // Mostra solo numeri interi
                                        style: const TextStyle(
                                          color: AppData.antiFlashWhite, // Colore testo aggiornato
                                          fontSize: 10,
                                        ),
                                      );
                                    },
                                    reservedSize: 30, // Spazio per i titoli Y
                                  ),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              barTouchData: BarTouchData(
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipItem:
                                      (group, groupIndex, rod, rodIndex) {
                                        return BarTooltipItem(
                                          'Anno: ${sortedYears[group.x]}\n',
                                          const TextStyle(
                                            color: AppData.antiFlashWhite, // Colore testo aggiornato
                                            fontWeight: FontWeight.bold,
                                          ),
                                          children: <TextSpan>[
                                            TextSpan(
                                              text: '${rod.toY.toInt()} viaggi',
                                              style: const TextStyle(
                                                color: AppData.antiFlashWhite, // Colore testo aggiornato
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Lista testuale degli anni (mantenuta se serve un dettaglio)
                    ...tripsByYear.entries.map(
                      (entry) => _buildStatCard(
                        context,
                        '${entry.key}',
                        '${entry.value} viaggi',
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        // Sfondo semi-trasparente usando il colore primario
        color: AppData.silverLakeBlue.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
            color: AppData.antiFlashWhite
                .withOpacity(0.3)), // Colore bordo aggiornato
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppData.antiFlashWhite, // Colore testo aggiornato
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppData.antiFlashWhite, // Colore testo aggiornato
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}