class Trip {
  String id;
  String title;
  String location;
  DateTime startDate;
  DateTime endDate;
  String description;
  List<String> imageUrls; // URL delle immagini o percorsi locali
  bool isFavorite;
  bool toRepeat;
  String category; // Es: "Cultura", "Natura", "Relax"

  Trip({
    required this.id,
    required this.title,
    required this.location,
    required this.startDate,
    required this.endDate,
    this.description = '',
    this.imageUrls = const [],
    this.isFavorite = false,
    this.toRepeat = false,
    this.category = 'Generale',
  });

  // Metodo per creare una copia modificabile del viaggio
  Trip copyWith({
    String? id,
    String? title,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
    List<String>? imageUrls,
    bool? isFavorite,
    bool? toRepeat,
    String? category,
  }) {
    return Trip(
      id: id ?? this.id,
      title: title ?? this.title,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      isFavorite: isFavorite ?? this.isFavorite,
      toRepeat: toRepeat ?? this.toRepeat,
      category: category ?? this.category,
    );
  }
}

// Dati di esempio (in memoria per ora)
List<Trip> dummyTrips = [
  Trip(
    id: '1',
    title: 'Vacanza a Roma',
    location: 'Roma, Italia',
    startDate: DateTime(2023, 6, 10),
    endDate: DateTime(2023, 6, 17),
    description: 'Un viaggio indimenticabile nella capitale italiana, tra storia e buon cibo.',
    imageUrls: ['https://placehold.co/600x400/FF0000/FFFFFF?text=Roma1', 'https://placehold.co/600x400/00FF00/FFFFFF?text=Roma2'],
    isFavorite: true,
    category: 'Cultura',
  ),
  Trip(
    id: '2',
    title: 'Trekking Dolomiti',
    location: 'Cortina d\'Ampezzo, Italia',
    startDate: DateTime(2024, 8, 5),
    endDate: DateTime(2024, 8, 12),
    description: 'Escursioni mozzafiato tra le vette delle Dolomiti.',
    imageUrls: ['https://placehold.co/600x400/0000FF/FFFFFF?text=Dolomiti1'],
    toRepeat: true,
    category: 'Natura',
  ),
  Trip(
    id: '3',
    title: 'Relax in Sardegna',
    location: 'Costa Smeralda, Italia',
    startDate: DateTime(2023, 7, 20),
    endDate: DateTime(2023, 7, 27),
    description: 'Sette giorni di puro relax sulle spiagge della Sardegna.',
    imageUrls: [],
    category: 'Relax',
  ),
];