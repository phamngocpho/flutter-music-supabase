class SongEntity {
  final String title;
  final String artist;
  final num duration;
  final DateTime releaseDate;
  final bool isFavorite;
  final String songId;
  final String url;

  SongEntity({
    required this.title,
    required this.artist,
    required this.duration,
    required this.releaseDate,
    required this.isFavorite,
    required this.songId,
    required this.url
  });
}