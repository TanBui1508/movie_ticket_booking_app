import 'package:cloud_firestore/cloud_firestore.dart';

class Movie {
  final String? id;
  final String title;
  final String posterUrl;
  final String bannerUrl;
  final List<String> genres;
  final int duration;
  final double rating;
  final DateTime releaseDate;
  final String language;
  final String description;
  final String trailerUrl;
  final bool isNowShowing;
  final DateTime createdAt;
  final String manufacturer;
  final String director;
  final List<String> actors;

  Movie({
    this.id,
    required this.title,
    required this.posterUrl,
    required this.bannerUrl,
    required this.genres,
    required this.duration,
    required this.rating,
    required this.releaseDate,
    required this.language,
    required this.description,
    required this.trailerUrl,
    required this.isNowShowing,
    required this.createdAt,
    required this.manufacturer,
    required this.director,
    required this.actors,
  });

  // Giúp chuyển đổi Timestamp an toàn
  static DateTime _safeParseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    // Dùng cho JSON (từ cache/nhúng) nếu nó là String
    if (timestamp is String) {
      return DateTime.tryParse(timestamp) ?? DateTime.now();
    }
    return DateTime.now();
  }

  // Tạo Movie từ một Map (JSON)
  factory Movie.fromJson(String? id, Map<String, dynamic> data) {
    return Movie(
      id: id,
      title: data['title'] ?? '',
      posterUrl: data['posterUrl'] ?? '',
      bannerUrl: data['bannerUrl'] ?? '',
      genres: List<String>.from(data['genres'] ?? []),
      duration: data['duration'] ?? 0,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      releaseDate: _safeParseTimestamp(data['releaseDate']),
      language: data['language'] ?? '',
      description: data['description'] ?? '',
      trailerUrl: data['trailerUrl'] ?? '',
      isNowShowing: data['isNowShowing'] ?? false,
      createdAt: _safeParseTimestamp(data['createdAt']),
      manufacturer: data['manufacturer'] ?? '',
      director: data['director'] ?? '',
      actors: List<String>.from(data['actors'] ?? []),
    );
  }

  // Gọi .fromJson
  factory Movie.fromFirestore(DocumentSnapshot doc) {
    return Movie.fromJson(doc.id, doc.data() as Map<String, dynamic>);
  }

  // Chuyển Movie thành Map (JSON) để nhúng
  Map<String, dynamic> toJson() {
    return {
      'id': id, 
      'title': title,
      'posterUrl': posterUrl,
      'bannerUrl': bannerUrl,
      'genres': genres,
      'duration': duration,
      'rating': rating,
      'releaseDate': Timestamp.fromDate(releaseDate),
      'language': language,
      'description': description,
      'trailerUrl': trailerUrl,
      'isNowShowing': isNowShowing,
      'createdAt': Timestamp.fromDate(createdAt),
      'manufacturer': manufacturer,
      'director': director,
      'actors': actors,
    };
  }

  Map<String, dynamic> toFirestore() {
    final map = toJson();
    map.remove('id'); // Xóa 'id' vì nó là tên document
    return map;
  }
}