import 'package:dartz/dartz.dart';
import 'package:spotify/core/usecase/base_usecase.dart';
import 'package:spotify/data/models/song_request.dart';
import 'package:spotify/domain/repositories/admin_repository.dart';
import 'package:spotify/service_locator.dart';

class UpdateSongUseCase implements UseCase<Either, UpdateSongRequest> {
  @override
  Future<Either> call({UpdateSongRequest? params}) async {
    return await sl<AdminRepository>().updateSong(params!);
  }
}

