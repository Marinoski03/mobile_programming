// lib/models/trip.dart

class Trip {
  final int?
  id; // ID del viaggio nel database, può essere null per nuovi viaggi
  final String title;
  final String location;
  final DateTime startDate;
  final DateTime endDate;
  final String notes;
  final String category;
  final bool isFavorite;
  final bool
  toBeRepeated; // <--- Nome della proprietà allineato con TripDetailScreen
  final List<String> imageUrls; // Lista di URL delle immagini

  Trip({
    this.id,
    required this.title,
    required this.location,
    required this.startDate,
    required this.endDate,
    this.notes = '',
    required this.category,
    this.isFavorite = false,
    this.toBeRepeated = false, // <--- Inizializzazione della proprietà
    this.imageUrls = const [],
  });

  // Metodo per convertire un Trip in una Map per il database (toMap)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'startDate': startDate.toIso8601String(), // Salva come stringa ISO 8601
      'endDate': endDate.toIso8601String(), // Salva come stringa ISO 8601
      'notes': notes,
      'category': category,
      'isFavorite': isFavorite ? 1 : 0, // SQLite non ha booleani, usa 0 o 1
      'toBeRepeated': toBeRepeated ? 1 : 0, // <--- Gestione per il database
      'imageUrls': imageUrls.join(
        ',',
      ), // Salva gli URL come stringa separata da virgole
    };
  }

  // Metodo per creare un oggetto Trip da una Map (fromMap)
  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id'] as int?,
      title: map['title'] as String,
      location: map['location'] as String,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      notes: map['notes'] as String,
      category: map['category'] as String,
      isFavorite: (map['isFavorite'] as int) == 1,
      toBeRepeated:
          (map['toBeRepeated'] as int) ==
          1, // <--- Gestione per la lettura dal database
      imageUrls: (map['imageUrls'] as String)
          .split(',')
          .where((url) => url.isNotEmpty)
          .toList(), // Converte la stringa in lista
    );
  }

  // Metodo copy per creare una copia modificata di un Trip (copy, non copyWith per coerenza con le chiamate precedenti)
  Trip copy({
    int? id,
    String? title,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
    String? category,
    String? continent,
    bool? isFavorite,
    bool? toBeRepeated, // <--- Parametro nel metodo copy
    List<String>? imageUrls,
  }) {
    return Trip(
      id: id ?? this.id,
      title: title ?? this.title,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      toBeRepeated:
          toBeRepeated ??
          this.toBeRepeated, // <--- Assegnazione nel metodo copy
      imageUrls: imageUrls ?? this.imageUrls,
    );
  }

  @override
  String toString() {
    return 'Trip{id: $id, title: $title, location: $location, startDate: $startDate, endDate: $endDate, notes: $notes, category: $category, isFavorite: $isFavorite, toBeRepeated: $toBeRepeated, imageUrls: $imageUrls}';
  }
}
