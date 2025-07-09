// lib/models/trip.dart

class Trip {
  int? id; // Cambiato da String a int? per supportare SQLite
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
    this.id, // ID opzionale
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
    int? id,
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

  // Metodo per convertire un Trip in una mappa (per il database)
  Map<String, dynamic> toMap() {
    return {
      'id': id, // SQLite accetta null per autoincrement
      'title': title,
      'location': location,
      'startDate': startDate.toIso8601String(), // Salva come stringa ISO 8601
      'endDate': endDate.toIso8601String(), // Salva come stringa ISO 8601
      'description': description,
      'imageUrls': imageUrls.join(
        ',',
      ), // Serializza come stringa separata da virgole
      'isFavorite': isFavorite
          ? 1
          : 0, // Converti boolean in intero (1 per true, 0 per false)
      'toRepeat': toRepeat
          ? 1
          : 0, // Converti boolean in intero (1 per true, 0 per false)
      'category': category,
    };
  }

  // Metodo per creare un Trip da una mappa (dal database)
  factory Trip.fromMap(Map<String, dynamic> map) {
    // Funzione helper per il parsing sicuro delle date
    DateTime _parseDate(dynamic dateString, {DateTime? fallbackDate}) {
      if (dateString is String && dateString.isNotEmpty) {
        try {
          return DateTime.parse(dateString);
        } catch (e) {
          // Logga l'errore per il debugging
          print('Errore di parsing data: "$dateString" - $e');
        }
      }
      // Ritorna una data di fallback (es. data corrente o una data specifica)
      return fallbackDate ?? DateTime.now();
    }

    return Trip(
      id: map['id'], // SQLite restituisce un int
      title: map['title'],
      location: map['location'],
      startDate: _parseDate(map['startDate']), // Usa la funzione helper
      endDate: _parseDate(map['endDate']), // Usa la funzione helper
      description:
          map['description'] ??
          '', // Se 'description' è null, usa una stringa vuota
      imageUrls:
          map['imageUrls'] != null && (map['imageUrls'] as String).isNotEmpty
          ? (map['imageUrls'] as String).split(
              ',',
            ) // Assicurati sia String prima dello split
          : [],
      isFavorite: map['isFavorite'] == 1, // Converti intero in boolean
      toRepeat: map['toRepeat'] == 1, // Converti intero in boolean
      category:
          map['category'] ?? 'Generale', // Se 'category' è null, usa 'Generale'
    );
  }
}
