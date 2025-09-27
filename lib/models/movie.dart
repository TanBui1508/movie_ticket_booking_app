// lib/models/movie.dart

class Movie {
  final int id;
  final String title;
  final String overview;
  final String posterPath;
  final String backdropPath;
  final double voteAverage;
  final List<int> genreIds;
  final DateTime? releaseDate;

  Movie({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.voteAverage,
    required this.genreIds,
    required this.releaseDate,
  });

  // Factory constructor để tạo một đối tượng Movie từ JSON
  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'],
      title: json['title'],
      overview: json['overview'],
      // Thêm URL cơ bản vào trước đường dẫn ảnh
      posterPath: 'https://image.tmdb.org/t/p/w500${json['poster_path']}',
      backdropPath: 'https://image.tmdb.org/t/p/w500${json['backdrop_path']}',
      // Chuyển đổi vote_average từ num sang double
      voteAverage: (json['vote_average'] as num).toDouble(),
      // Chuyển đổi List<dynamic> từ JSON thành List<int>
      genreIds: List<int>.from(json['genre_ids']),
      // Parse chuỗi ngày tháng thành đối tượng DateTime
      // Thêm kiểm tra null để tránh lỗi nếu dữ liệu rỗng
      releaseDate: json['release_date'] != null && json['release_date'].isNotEmpty
          ? DateTime.parse(json['release_date'])
          : null,
    );
  }
}