// lib/screens/analysis_screen.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../helpers/trip_database_helper.dart';
import '../models/trip.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/app_data.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppData.antiFlashWhite, // Scaffold background color
      appBar: AppBar(
        title: const Text(
          'Analisi Viaggi',
          style: TextStyle(
            color: AppData.antiFlashWhite,
          ), // AppBar title text color (mantenuto bianco per contrasto con silverLakeBlue)
        ),
        backgroundColor:
            AppData.silverLakeBlue, // Sfondo dell'AppBar come richiesto
        elevation: 0,
        iconTheme: const IconThemeData(
          color: AppData.antiFlashWhite,
        ), // AppBar icon color (mantenuto bianco)
      ),
      // extendBodyBehindAppBar: true, // Rimosso perché l'AppBar non è più trasparente
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Rimosso il BoxDecoration con il gradiente per mostrare lo sfondo silver del Scaffold
        color: AppData
            .antiFlashWhite, // Imposta il colore del Container a antiFlashWhite
        child: FutureBuilder<List<Trip>>(
          future: TripDatabaseHelper.instance.getAllTrips(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppData.silverLakeBlue,
                ), // Loading indicator color (cambiato per contrasto)
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Errore nel caricamento dei dati: ${snapshot.error}',
                  style: const TextStyle(
                    color: AppData.charcoal,
                  ), // Error text color (cambiato per contrasto)
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  'Nessun viaggio trovato per l\'analisi.',
                  style: TextStyle(
                    color: AppData.charcoal,
                  ), // No data text color (cambiato per contrasto)
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

            Map<String, int> tripsByCountry = {};
            for (var trip in trips) {
              if (trip.location != null && trip.location.isNotEmpty) {
                tripsByCountry.update(
                  trip.location,
                  (value) => value + 1,
                  ifAbsent: () => 1,
                );
              }
            }

            List<PieChartSectionData> pieChartSections = [];
            int totalCategoriesTrips = 0;
            tripsByCategory.forEach((category, count) {
              totalCategoriesTrips += count;
            });

            List<Color> categoryColors = [
              AppData.cerise,
              AppData.silverLakeBlue,
              AppData.charcoal,
              // Add more colors if you have more categories than 3,
              // or define a default fallback color
            ];
            int colorIndex = 0;

            tripsByCategory.forEach((category, count) {
              final double percentage = (count / totalCategoriesTrips) * 100;
              pieChartSections.add(
                PieChartSectionData(
                  color: categoryColors[colorIndex % categoryColors.length],
                  value: count.toDouble(),
                  title: '${category}\n${percentage.toStringAsFixed(1)}%',
                  radius: 80,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppData
                        .antiFlashWhite, // Pie chart section title text color (mantenuto bianco per contrasto con colori categoria)
                  ),
                  badgeWidget: Text(
                    '${count}',
                    style: const TextStyle(
                      color: AppData.antiFlashWhite,
                      fontSize: 10,
                    ), // Pie chart section badge text color (mantenuto bianco)
                  ),
                  badgePositionPercentageOffset: .98,
                ),
              );
              colorIndex++;
            });

            List<BarChartGroupData> barGroups = [];
            final sortedYears = tripsByYear.keys.toList()..sort();
            double maxY = 0;

            for (int i = 0; i < sortedYears.length; i++) {
              final year = sortedYears[i];
              final count = tripsByYear[year]!.toDouble();
              if (count > maxY) {
                maxY = count;
              }
              barGroups.add(
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: count,
                      color: AppData.silverLakeBlue, // Bar chart rod color
                      width: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                  showingTooltipIndicators: [0],
                ),
              );
            }
            maxY = (maxY + (maxY * 0.1)).ceilToDouble();

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Statistiche dei Viaggi',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppData
                            .charcoal, // Section title text color (cambiato per contrasto)
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
                        color: AppData
                            .charcoal, // Category chart title color (cambiato per contrasto)
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    AspectRatio(
                      aspectRatio: 1.3,
                      child: Card(
                        color: AppData.antiFlashWhite.withOpacity(
                          0.8,
                        ), // Chart card background color (cambiato per essere più visibile su sfondo silver)
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        elevation: 5,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: PieChart(
                            PieChartData(
                              sections: pieChartSections,
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                              borderData: FlBorderData(show: false),
                              pieTouchData: PieTouchData(
                                touchCallback:
                                    (FlTouchEvent event, pieTouchResponse) {},
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

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
                        color: AppData
                            .charcoal, // Year chart title color (cambiato per contrasto)
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    AspectRatio(
                      aspectRatio: 1.6,
                      child: Card(
                        color: AppData.antiFlashWhite.withOpacity(
                          0.8,
                        ), // Chart card background color (cambiato per essere più visibile su sfondo silver)
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        elevation: 5,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: maxY,
                              barGroups: barGroups,
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: AppData.charcoal.withOpacity(
                                    0.1,
                                  ), // Grid line color (cambiato per contrasto)
                                  strokeWidth: 1,
                                ),
                              ),
                              borderData: FlBorderData(
                                show: true,
                                border: Border.all(
                                  color: AppData.charcoal.withOpacity(
                                    0.3,
                                  ), // Chart border color (cambiato per contrasto)
                                  width: 1,
                                ),
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      if (value.toInt() < sortedYears.length) {
                                        return Text(
                                          '${sortedYears[value.toInt()]}',
                                          style: const TextStyle(
                                            color: AppData
                                                .charcoal, // X-axis label color (cambiato per contrasto)
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
                                        value.toInt().toString(),
                                        style: const TextStyle(
                                          color: AppData
                                              .charcoal, // Y-axis label color (cambiato per contrasto)
                                          fontSize: 10,
                                        ),
                                      );
                                    },
                                    reservedSize: 30,
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
                                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                    return BarTooltipItem(
                                      'Anno: ${sortedYears[group.x]}\n',
                                      const TextStyle(
                                        color: AppData
                                            .antiFlashWhite, // Tooltip text color (mantenuto bianco su sfondo scuro del tooltip)
                                        fontWeight: FontWeight.bold,
                                      ),
                                      children: <TextSpan>[
                                        TextSpan(
                                          text: '${rod.toY.toInt()} viaggi',
                                          style: const TextStyle(
                                            color: AppData
                                                .antiFlashWhite, // Tooltip text color (mantenuto bianco)
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
        color: AppData.antiFlashWhite.withOpacity(
          0.8,
        ), // Stat card background color (cambiato per essere visibile su sfondo silver)
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: AppData.charcoal.withOpacity(0.3),
        ), // Stat card border color (cambiato per contrasto)
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
                  color: AppData
                      .charcoal, // Stat card label text color (cambiato per contrasto)
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppData
                    .charcoal, // Stat card value text color (cambiato per contrasto)
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
