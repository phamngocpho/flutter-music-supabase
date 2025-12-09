import 'package:spotify/domain/entities/song_entity.dart';

class SongModel {
  String? title;
  String? artist;
  num? duration;
  DateTime? releaseDate;
  bool? isFavorite;
  String? songId;
  String? url;
  String? coverUrl;
  String? genre;

  SongModel({
    required this.title,
    required this.artist,
    required this.duration,
    required this.releaseDate,
    required this.isFavorite,
    required this.songId,
    this.url,
    this.coverUrl,
    this.genre,
  });

  SongModel.fromJson(Map<String, dynamic> data) {
    title = data['title'];
    artist = data['artist'];
    duration = data['duration'];
    url = data['url'];
    coverUrl = data['coverUrl'];
    genre = data['genre'];
    releaseDate = data['releaseDate'] != null
      ? DateTime.parse(data['releaseDate'])
      : null;
  }
}

extension SongModelX on SongModel {
  SongEntity toEntity() {
    return SongEntity(
      title: title!,
      artist: artist!,
      duration: duration!,
      releaseDate: releaseDate!,
      isFavorite: isFavorite!,
      songId: songId!,
      url: url ?? '',
      coverUrl: coverUrl,
      genre: genre,
    );
  }
}

