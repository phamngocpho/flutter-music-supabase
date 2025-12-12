import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:spotify/data/models/song_model.dart';
import 'package:spotify/data/models/song_request.dart';
import 'package:spotify/domain/entities/song_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AdminSupabaseService {
  Future<Either> getAllSongs();
  Future<Either> addSong(CreateSongRequest request);
  Future<Either> updateSong(UpdateSongRequest request);
  Future<Either> deleteSong(String songId);
  Future<Either<String, String>> uploadSongFile(Uint8List fileBytes, String fileName);
  Future<Either<String, String>> uploadCoverImage(Uint8List fileBytes, String fileName);
  Future<Either<String, String>> uploadLyricsFile(Uint8List fileBytes, String fileName);
  bool isAdmin(String email);
}

class AdminSupabaseServiceImpl extends AdminSupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Read from environment variables
  String get _adminEmail => dotenv.env['ADMIN_EMAIL'] ?? 'phamngocpho@duck.com';
  String get _storageBucket => dotenv.env['SONGS_BUCKET'] ?? 'songs';
  String get _coverBucket => dotenv.env['COVERS_BUCKET'] ?? 'song-covers';
  String get _lyricsBucket => dotenv.env['LYRICS_BUCKET'] ?? 'lyrics';

  @override
  bool isAdmin(String email) {
    return email.toLowerCase() == _adminEmail.toLowerCase();
  }

  @override
  Future<Either<String, String>> uploadSongFile(Uint8List fileBytes, String fileName) async {
    try {
      // Generate unique file name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${timestamp}_$fileName';

      // Upload file bytes to Supabase Storage
      await _supabase.storage
          .from(_storageBucket)
          .uploadBinary(uniqueFileName, fileBytes);

      // Get public URL
      final publicUrl = _supabase.storage
          .from(_storageBucket)
          .getPublicUrl(uniqueFileName);

      return Right(publicUrl);
    } catch (e) {
      return Left('Failed to upload file: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, String>> uploadCoverImage(Uint8List fileBytes, String fileName) async {
    try {
      // Generate unique file name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = 'cover_$timestamp.jpg';

      // Upload image bytes to Supabase Storage
      await _supabase.storage
          .from(_coverBucket)
          .uploadBinary(
            uniqueFileName,
            fileBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
            ),
          );

      // Get public URL
      final publicUrl = _supabase.storage
          .from(_coverBucket)
          .getPublicUrl(uniqueFileName);

      return Right(publicUrl);
    } catch (e) {
      return Left('Failed to upload cover: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, String>> uploadLyricsFile(Uint8List fileBytes, String fileName) async {
    try {
      // Generate unique file name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = 'lyrics_${timestamp}_$fileName';

      // Upload lyrics file bytes to Supabase Storage with UTF-8 charset
      await _supabase.storage
          .from(_lyricsBucket)
          .uploadBinary(
            uniqueFileName,
            fileBytes,
            fileOptions: const FileOptions(
              contentType: 'text/plain; charset=utf-8',
              upsert: false,
            ),
          );

      // Get public URL
      final publicUrl = _supabase.storage
          .from(_lyricsBucket)
          .getPublicUrl(uniqueFileName);

      return Right(publicUrl);
    } catch (e) {
      return Left('Failed to upload lyrics: ${e.toString()}');
    }
  }

  @override
  Future<Either> getAllSongs() async {
    try {
      List<SongEntity> songs = [];
      var data = await _supabase
          .from('Songs')
          .select()
          .order('releaseDate', ascending: false);

      for (var element in data) {
        var songModel = SongModel.fromJson(element);
        songModel.isFavorite = false;
        songModel.songId = element['id'].toString();
        songs.add(songModel.toEntity());
      }
      return Right(songs);
    } catch (e) {
      return Left('An error occurred: ${e.toString()}');
    }
  }

  @override
  Future<Either> addSong(CreateSongRequest request) async {
    try {
      await _supabase.from('Songs').insert(request.toJson());
      return const Right('Song added successfully');
    } catch (e) {
      return Left('Failed to add song: ${e.toString()}');
    }
  }

  @override
  Future<Either> updateSong(UpdateSongRequest request) async {
    try {
      await _supabase
          .from('Songs')
          .update(request.toJson())
          .eq('id', request.id);
      return const Right('Song updated successfully');
    } catch (e) {
      return Left('Failed to update song: ${e.toString()}');
    }
  }

  @override
  Future<Either> deleteSong(String songId) async {
    try {
      await _supabase.from('Songs').delete().eq('id', songId);
      return const Right('Song deleted successfully');
    } catch (e) {
      return Left('Failed to delete song: ${e.toString()}');
    }
  }
}

