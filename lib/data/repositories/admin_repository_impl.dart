import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:spotify/data/models/song_request.dart';
import 'package:spotify/data/services/admin_supabase_service.dart';
import 'package:spotify/domain/repositories/admin_repository.dart';
import 'package:spotify/service_locator.dart';

class AdminRepositoryImpl extends AdminRepository {
  @override
  Future<Either> getAllSongs() async {
    return await sl<AdminSupabaseService>().getAllSongs();
  }

  @override
  Future<Either> addSong(CreateSongRequest request) async {
    return await sl<AdminSupabaseService>().addSong(request);
  }

  @override
  Future<Either> updateSong(UpdateSongRequest request) async {
    return await sl<AdminSupabaseService>().updateSong(request);
  }

  @override
  Future<Either> deleteSong(String songId) async {
    return await sl<AdminSupabaseService>().deleteSong(songId);
  }

  @override
  Future<Either<String, String>> uploadSongFile(Uint8List fileBytes, String fileName) async {
    return await sl<AdminSupabaseService>().uploadSongFile(fileBytes, fileName);
  }

  @override
  bool isAdmin(String email) {
    return sl<AdminSupabaseService>().isAdmin(email);
  }
}

