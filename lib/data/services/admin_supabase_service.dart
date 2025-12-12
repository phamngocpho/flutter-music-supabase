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

  // Helper function to sanitize file names
  String _sanitizeFileName(String fileName) {
    // Map of Vietnamese characters to their non-accented equivalents
    const vietnameseMap = {
      'á': 'a', 'à': 'a', 'ả': 'a', 'ã': 'a', 'ạ': 'a',
      'ă': 'a', 'ắ': 'a', 'ằ': 'a', 'ẳ': 'a', 'ẵ': 'a', 'ặ': 'a',
      'â': 'a', 'ấ': 'a', 'ầ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ậ': 'a',
      'é': 'e', 'è': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ẹ': 'e',
      'ê': 'e', 'ế': 'e', 'ề': 'e', 'ể': 'e', 'ễ': 'e', 'ệ': 'e',
      'í': 'i', 'ì': 'i', 'ỉ': 'i', 'ĩ': 'i', 'ị': 'i',
      'ó': 'o', 'ò': 'o', 'ỏ': 'o', 'õ': 'o', 'ọ': 'o',
      'ô': 'o', 'ố': 'o', 'ồ': 'o', 'ổ': 'o', 'ỗ': 'o', 'ộ': 'o',
      'ơ': 'o', 'ớ': 'o', 'ờ': 'o', 'ở': 'o', 'ỡ': 'o', 'ợ': 'o',
      'ú': 'u', 'ù': 'u', 'ủ': 'u', 'ũ': 'u', 'ụ': 'u',
      'ư': 'u', 'ứ': 'u', 'ừ': 'u', 'ử': 'u', 'ữ': 'u', 'ự': 'u',
      'ý': 'y', 'ỳ': 'y', 'ỷ': 'y', 'ỹ': 'y', 'ỵ': 'y',
      'đ': 'd',
      'Á': 'A', 'À': 'A', 'Ả': 'A', 'Ã': 'A', 'Ạ': 'A',
      'Ă': 'A', 'Ắ': 'A', 'Ằ': 'A', 'Ẳ': 'A', 'Ẵ': 'A', 'Ặ': 'A',
      'Â': 'A', 'Ấ': 'A', 'Ầ': 'A', 'Ẩ': 'A', 'Ẫ': 'A', 'Ậ': 'A',
      'É': 'E', 'È': 'E', 'Ẻ': 'E', 'Ẽ': 'E', 'Ẹ': 'E',
      'Ê': 'E', 'Ế': 'E', 'Ề': 'E', 'Ể': 'E', 'Ễ': 'E', 'Ệ': 'E',
      'Í': 'I', 'Ì': 'I', 'Ỉ': 'I', 'Ĩ': 'I', 'Ị': 'I',
      'Ó': 'O', 'Ò': 'O', 'Ỏ': 'O', 'Õ': 'O', 'Ọ': 'O',
      'Ô': 'O', 'Ố': 'O', 'Ồ': 'O', 'Ổ': 'O', 'Ỗ': 'O', 'Ộ': 'O',
      'Ơ': 'O', 'Ớ': 'O', 'Ờ': 'O', 'Ở': 'O', 'Ỡ': 'O', 'Ợ': 'O',
      'Ú': 'U', 'Ù': 'U', 'Ủ': 'U', 'Ũ': 'U', 'Ụ': 'U',
      'Ư': 'U', 'Ứ': 'U', 'Ừ': 'U', 'Ử': 'U', 'Ữ': 'U', 'Ự': 'U',
      'Ý': 'Y', 'Ỳ': 'Y', 'Ỷ': 'Y', 'Ỹ': 'Y', 'Ỵ': 'Y',
      'Đ': 'D',
    };

    String sanitized = fileName;

    // Replace Vietnamese characters
    vietnameseMap.forEach((key, value) {
      sanitized = sanitized.replaceAll(key, value);
    });

    // Replace spaces with underscores
    sanitized = sanitized.replaceAll(' ', '_');

    // Remove any special characters except dots, underscores, and hyphens
    sanitized = sanitized.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '');

    // Remove multiple consecutive underscores
    sanitized = sanitized.replaceAll(RegExp(r'_+'), '_');

    return sanitized;
  }

  @override
  Future<Either<String, String>> uploadSongFile(Uint8List fileBytes, String fileName) async {
    try {
      // Generate unique file name with sanitized original name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final sanitizedName = _sanitizeFileName(fileName);
      final uniqueFileName = '${timestamp}_$sanitizedName';

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
      // Generate unique file name with sanitized original name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final sanitizedName = _sanitizeFileName(fileName);
      final uniqueFileName = 'lyrics_${timestamp}_$sanitizedName';

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

