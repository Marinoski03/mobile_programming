// lib/models/trip.dart

class Trip {
  final int? id;
  final String title;
  final String location;
  final DateTime startDate;
  final DateTime endDate;
  final String notes;
  final String category;
  final bool isFavorite;
  final bool toBeRepeated;
  final List<String> imageUrls;

  Trip({
    this.id,
    required this.title,
    required this.location,
    required this.startDate,
    required this.endDate,
    this.notes = '',
    required this.category,
    this.isFavorite = false,
    this.toBeRepeated = false,
    this.imageUrls = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'notes': notes,
      'category': category,
      'isFavorite': isFavorite ? 1 : 0,
      'toBeRepeated': toBeRepeated ? 1 : 0,
      'imageUrls': imageUrls.join(','),
    };
  }

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
      toBeRepeated: (map['toBeRepeated'] as int) == 1,
      imageUrls: (map['imageUrls'] as String)
          .split(',')
          .where((url) => url.isNotEmpty)
          .toList(),
    );
  }

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
    bool? toBeRepeated,
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
      toBeRepeated: toBeRepeated ?? this.toBeRepeated,
      imageUrls: imageUrls ?? this.imageUrls,
    );
  }

  @override
  String toString() {
    return 'Trip{id: $id, title: $title, location: $location, startDate: $startDate, endDate: $endDate, notes: $notes, category: $category, isFavorite: $isFavorite, toBeRepeated: $toBeRepeated, imageUrls: $imageUrls}';
  }
}
