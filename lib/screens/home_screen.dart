// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/trip.dart';
import '../helpers/trip_database_helper.dart';
import 'add_edit_trip_screen.dart';
import 'analysis_screen.dart';
import 'categories_screen.dart';
import 'search_screen.dart';
import 'trip_detail_screen.dart';
import '../utils/app_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Trip> _trips = [];
  List<Trip> _favoriteTrips = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshTrips();
    });
  }

  Future<void> _refreshTrips() async {
    final trips = await TripDatabaseHelper.instance.getAllTrips();
    setState(() {
      _trips = trips;
      _favoriteTrips = trips.where((trip) => trip.isFavorite).toList();
      _trips.sort((a, b) => b.endDate.compareTo(a.endDate));
    });
  }

  Future<void> _navigateToScreen(BuildContext context, Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (ctx) => screen));
    _refreshTrips();
  }

  String _sanitizeImagePath(String path) {
    return path.replaceAll('["', '').replaceAll('"]', '').replaceAll('"', '');
  }

  Widget _buildImageWidget(String imageUrl, {double? width, double? height, BoxFit? fit, BorderRadius? borderRadius}) {
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
        placeholder: (context, url) =>
        const Center(child: CircularProgressIndicator(color: AppData.silverLakeBlue)), // Loading indicator color
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
              debugPrint('Errore caricamento file locale: $imageUrl, Errore: ${snapshot.error ?? "File non trovato"}');
              return _buildErrorPlaceholder(width: width, height: height);
            } else {
              return Image.file(
                File(imageUrl),
                width: width,
                height: height,
                fit: fit ?? BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Errore caricamento Image.file: $imageUrl, Errore: $error');
                  return _buildErrorPlaceholder(width: width, height: height);
                },
              );
            }
          }
          return const Center(child: CircularProgressIndicator(color: AppData.silverLakeBlue)); // Loading indicator color
        },
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius, child: imageWidget);
    }
    return imageWidget;
  }

  Widget _buildErrorPlaceholder({double? width, double? height}) {
    return Container(
      width: width,
      height: height,
      color: AppData.antiFlashWhite.withOpacity(0.3), // Error placeholder background color
      child: Icon(Icons.image_not_supported, color: AppData.charcoal.withOpacity(0.6), size: (width ?? 50) / 2), // Error icon color
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'I Miei Viaggi',
          style: TextStyle(
              color: AppData.antiFlashWhite), // AppBar title text color
        ),
        backgroundColor: Colors.transparent, // AppBar background color
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.category,
                color: AppData.antiFlashWhite), // Icon color
            onPressed: () =>
                _navigateToScreen(context, const CategoriesScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.search,
                color: AppData.antiFlashWhite), // Icon color
            onPressed: () => _navigateToScreen(context, const SearchScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart,
                color: AppData.antiFlashWhite), // Icon color
            onPressed: () => _navigateToScreen(context, const AnalysisScreen()),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppData.silverLakeBlue.withOpacity(0.7), // Gradient start color
              AppData.charcoal.withOpacity(0.9) // Gradient end color
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: _trips.isEmpty && _favoriteTrips.isEmpty
              ? Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Nessun viaggio aggiunto ancora. Tocca il "+" per iniziare!',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppData.antiFlashWhite
                        .withOpacity(0.7)), // Text color
              ),
            ),
          )
              : SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ultimi viaggi aggiunti',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppData.antiFlashWhite, // Section title color
                  ),
                ),
                const SizedBox(height: 10),
                _trips.isEmpty
                    ? Center(
                  child: Text(
                    'Nessun viaggio trovato.',
                    style: TextStyle(
                        color: AppData.antiFlashWhite
                            .withOpacity(0.7)), // Text color
                  ),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _trips.length > 3 ? 3 : _trips.length,
                  itemBuilder: (context, index) {
                    final trip = _trips[index];
                    final String coverImageUrl = trip.imageUrls.isNotEmpty ? _sanitizeImagePath(trip.imageUrls.first) : 'assets/images/default_trip_cover.png';
                    return Card(
                      color: AppData.antiFlashWhite, // Card background color
                      margin: const EdgeInsets.symmetric(
                        vertical: 8.0,
                      ),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () => _navigateToScreen(
                          context,
                          TripDetailScreen(trip: trip),
                        ),
                        child: Row(
                          children: [
                            _buildImageWidget(
                              coverImageUrl,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              borderRadius:
                              BorderRadius.circular(8.0),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
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
                                        fontWeight:
                                        FontWeight.bold,
                                        color: AppData
                                            .charcoal, // Trip title color
                                      ),
                                      maxLines: 1,
                                      overflow:
                                      TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      trip.location,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium
                                          ?.copyWith(
                                          color: AppData.charcoal
                                              .withOpacity(
                                              0.8)), // Location text color
                                      maxLines: 1,
                                      overflow:
                                      TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${DateFormat('dd/MM/yyyy').format(trip.startDate)} - ${DateFormat('dd/MM/yyyy').format(trip.endDate)}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.copyWith(
                                          color: AppData
                                              .silverLakeBlue), // Dates text color
                                    ),
                                    if (trip.isFavorite ||
                                        trip.toBeRepeated)
                                      Padding(
                                        padding:
                                        const EdgeInsets.only(
                                          top: 8.0,
                                        ),
                                        child: Row(
                                          children: [
                                            if (trip.isFavorite)
                                              Container(
                                                padding:
                                                const EdgeInsets
                                                    .symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration:
                                                BoxDecoration(
                                                  color: Colors
                                                      .amber
                                                      .shade700,
                                                  borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                    15,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.star,
                                                      color: AppData
                                                          .antiFlashWhite, // Favorite icon color
                                                      size: 16,
                                                    ),
                                                    const SizedBox(
                                                        width: 4),
                                                    Text(
                                                      'Preferito',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .labelSmall
                                                          ?.copyWith(
                                                        color: AppData
                                                            .antiFlashWhite, // Favorite text color
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            const SizedBox(width: 8),
                                            if (trip.toBeRepeated)
                                              Container(
                                                padding:
                                                const EdgeInsets
                                                    .symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration:
                                                BoxDecoration(
                                                  color: AppData
                                                      .cerise, // To be repeated background color
                                                  borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                    15,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.repeat,
                                                      color: AppData
                                                          .antiFlashWhite, // To be repeated icon color
                                                      size: 16,
                                                    ),
                                                    const SizedBox(
                                                        width: 4),
                                                    Text(
                                                      'Da ripetere',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .labelSmall
                                                          ?.copyWith(
                                                        color: AppData
                                                            .antiFlashWhite, // To be repeated text color
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'Viaggi preferiti',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppData.antiFlashWhite, // Section title color
                  ),
                ),
                const SizedBox(height: 10),
                _favoriteTrips.isEmpty
                    ? Center(
                  child: Text(
                    'Nessun viaggio preferito trovato.',
                    style: TextStyle(
                        color: AppData.antiFlashWhite
                            .withOpacity(0.7)), // Text color
                  ),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _favoriteTrips.length > 3
                      ? 3
                      : _favoriteTrips.length,
                  itemBuilder: (context, index) {
                    final trip = _favoriteTrips[index];
                    final String coverImageUrl = trip.imageUrls.isNotEmpty ? _sanitizeImagePath(trip.imageUrls.first) : 'assets/images/default_trip_cover.png';
                    return Card(
                      color: AppData.antiFlashWhite, // Card background color
                      margin: const EdgeInsets.symmetric(
                        vertical: 8.0,
                      ),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () => _navigateToScreen(
                          context,
                          TripDetailScreen(trip: trip),
                        ),
                        child: Row(
                          children: [
                            _buildImageWidget(
                              coverImageUrl,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              borderRadius:
                              BorderRadius.circular(8.0),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
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
                                        fontWeight:
                                        FontWeight.bold,
                                        color: AppData
                                            .charcoal, // Trip title color
                                      ),
                                      maxLines: 1,
                                      overflow:
                                      TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      trip.location,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium
                                          ?.copyWith(
                                          color: AppData.charcoal
                                              .withOpacity(
                                              0.8)), // Location text color
                                      maxLines: 1,
                                      overflow:
                                      TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${DateFormat('dd/MM/yyyy').format(trip.startDate)} - ${DateFormat('dd/MM/yyyy').format(trip.endDate)}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.copyWith(
                                          color: AppData
                                              .silverLakeBlue), // Dates text color
                                    ),
                                    if (trip.isFavorite ||
                                        trip.toBeRepeated)
                                      Padding(
                                        padding:
                                        const EdgeInsets.only(
                                          top: 8.0,
                                        ),
                                        child: Row(
                                          children: [
                                            if (trip.isFavorite)
                                              Container(
                                                padding:
                                                const EdgeInsets
                                                    .symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration:
                                                BoxDecoration(
                                                  color: Colors
                                                      .amber
                                                      .shade700,
                                                  borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                    15,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.star,
                                                      color: AppData
                                                          .antiFlashWhite, // Favorite icon color
                                                      size: 16,
                                                    ),
                                                    const SizedBox(
                                                        width: 4),
                                                    Text(
                                                      'Preferito',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .labelSmall
                                                          ?.copyWith(
                                                        color: AppData
                                                            .antiFlashWhite, // Favorite text color
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            const SizedBox(width: 8),
                                            if (trip.toBeRepeated)
                                              Container(
                                                padding:
                                                const EdgeInsets
                                                    .symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration:
                                                BoxDecoration(
                                                  color: AppData
                                                      .cerise, // To be repeated background color
                                                  borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                    15,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.repeat,
                                                      color: AppData
                                                          .antiFlashWhite, // To be repeated icon color
                                                      size: 16,
                                                    ),
                                                    const SizedBox(
                                                        width: 4),
                                                    Text(
                                                      'Da ripetere',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .labelSmall
                                                          ?.copyWith(
                                                        color: AppData
                                                            .antiFlashWhite, // To be repeated text color
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToScreen(context, const AddEditTripScreen()),
        icon: const Icon(Icons.add),
        label: const Text('Aggiungi Viaggio'),
        // Colori FAB aggiornati
        backgroundColor: AppData.antiFlashWhite, // FAB background color
        foregroundColor: AppData.silverLakeBlue, // FAB foreground color
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}