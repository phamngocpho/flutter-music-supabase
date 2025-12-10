import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:spotify/domain/repositories/admin_repository.dart';
import 'package:spotify/service_locator.dart';

class UploadLyricsFileUseCase {
  Future<Either<String, String>> call({required Uint8List fileBytes, required String fileName}) async {
    return await sl<AdminRepository>().uploadLyricsFile(fileBytes, fileName);
  }
}

