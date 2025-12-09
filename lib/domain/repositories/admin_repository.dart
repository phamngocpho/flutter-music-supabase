import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:spotify/data/models/song_request.dart';

abstract class AdminRepository {
  Future<Either> getAllSongs();
  Future<Either> addSong(CreateSongRequest request);
  Future<Either> updateSong(UpdateSongRequest request);
  Future<Either> deleteSong(String songId);
  Future<Either<String, String>> uploadSongFile(Uint8List fileBytes, String fileName);
  Future<Either<String, String>> uploadCoverImage(Uint8List fileBytes, String fileName);
  bool isAdmin(String email);
}

