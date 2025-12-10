class CreateSongRequest {
  final String title;
  final String artist;
  final num duration;
  final DateTime releaseDate;
  final String url;
  final String? coverUrl;
  final String? genre;
  final String? lyricsUrl;

  CreateSongRequest({
    required this.title,
    required this.artist,
    required this.duration,
    required this.releaseDate,
    required this.url,
    this.coverUrl,
    this.genre,
    this.lyricsUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'artist': artist,
      'duration': duration,
      'releaseDate': releaseDate.toIso8601String(),
      'url': url,
      'coverUrl': coverUrl,
      'genre': genre,
      'lyricsUrl': lyricsUrl,
    };
  }
}

class UpdateSongRequest {
  final String id;
  final String title;
  final String artist;
  final num duration;
  final DateTime releaseDate;
  final String url;
  final String? coverUrl;
  final String? genre;
  final String? lyricsUrl;

  UpdateSongRequest({
    required this.id,
    required this.title,
    required this.artist,
    required this.duration,
    required this.releaseDate,
    required this.url,
    this.coverUrl,
    this.genre,
    this.lyricsUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'artist': artist,
      'duration': duration,
      'releaseDate': releaseDate.toIso8601String(),
      'url': url,
      'coverUrl': coverUrl,
      'genre': genre,
      'lyricsUrl': lyricsUrl,
    };
  }
}

