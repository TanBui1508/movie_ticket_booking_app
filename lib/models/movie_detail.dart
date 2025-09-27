// lib/models/movie_detail.dart
import 'package:cinema_app_flutter/models/movie.dart';

class MovieDetail extends Movie {
  final int runtime;
  final String originalLanguage;
  final bool isAdult;
  final String productionCountry;

  MovieDetail({
    required super.id,
    required super.title,
    required super.overview,
    required super.posterPath,
    required super.backdropPath,
    required super.voteAverage,
    required super.genreIds,
    required super.releaseDate,
    required this.runtime,
    required this.originalLanguage, // ✅ Thêm
    required this.isAdult,          // ✅ Thêm
    required this.productionCountry,  // ✅ Thêm
  });

  // ✅ SỬA LẠI HOÀN TOÀN HÀM NÀY
  factory MovieDetail.fromJson(Map<String, dynamic> json) {
    // Lấy danh sách các đối tượng genre từ API
    final List<dynamic> genreList = json['genres'] ?? [];
    // Trích xuất các ID từ danh sách đó
    final List<int> parsedGenreIds =
        genreList.map<int>((genre) => genre['id'] as int).toList();

    // Lấy tên quốc gia sản xuất đầu tiên
    final List<dynamic> countries = json['production_countries'] ?? [];
    final String countryName = countries.isNotEmpty ? countries[0]['name'] : 'N/A';

    return MovieDetail(
      id: json['id'],
      title: json['title'],
      overview: json['overview'],
      posterPath: 'https://image.tmdb.org/t/p/w500${json['poster_path']}',
      // Thêm kiểm tra null cho backdrop_path vì đôi khi nó có thể không có
      backdropPath: json['backdrop_path'] != null
          ? 'https://image.tmdb.org/t/p/w500${json['backdrop_path']}'
          : 'https://image.tmdb.org/t/p/w500${json['poster_path']}', // Dùng poster thay thế nếu không có backdrop
      voteAverage: (json['vote_average'] as num).toDouble(),
      genreIds: parsedGenreIds, // Sử dụng danh sách ID đã được parse
      releaseDate: json['release_date'] != null && json['release_date'].isNotEmpty
          ? DateTime.parse(json['release_date'])
          : null,
      runtime: json['runtime'] ?? 0,
      originalLanguage: (json['original_language'] ?? 'N/A').toUpperCase(), // ✅ Thêm
      isAdult: json['adult'] ?? false, // ✅ Thêm
      productionCountry: countryName, // ✅ Thêm
    );
  }
}