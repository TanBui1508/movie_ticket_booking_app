// lib/models/credits.dart
class Credits {
  final List<CastMember> cast;
  final CrewMember? director;

  Credits({required this.cast, this.director});

  factory Credits.fromJson(Map<String, dynamic> json) {
    final List<dynamic> castData = json['cast'] ?? [];
    final List<dynamic> crewData = json['crew'] ?? [];

    CrewMember? director;
    try {
      director = crewData
          .map((crew) => CrewMember.fromJson(crew))
          .firstWhere((crew) => crew.job == 'Director');
    } catch (e) {
      director = null;
    }

    return Credits(
      cast: castData.map((c) => CastMember.fromJson(c)).toList(),
      director: director,
    );
  }
}

class CastMember {
  final String name;
  final String profilePath;
  CastMember({required this.name, required this.profilePath});

  factory CastMember.fromJson(Map<String, dynamic> json) {
    return CastMember(
      name: json['name'] ?? 'N/A',
      profilePath: json['profile_path'] != null
          ? 'https://image.tmdb.org/t/p/w200${json['profile_path']}'
          : '',
    );
  }
}

class CrewMember {
  final String name;
  final String job;
  CrewMember({required this.name, required this.job});

  factory CrewMember.fromJson(Map<String, dynamic> json) {
    return CrewMember(
      name: json['name'] ?? 'N/A',
      job: json['job'] ?? '',
    );
  }
}