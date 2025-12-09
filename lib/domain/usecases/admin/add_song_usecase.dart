import 'package:dartz/dartz.dart';
import 'package:spotify/core/usecase/base_usecase.dart';
import 'package:spotify/data/models/song_request.dart';
import 'package:spotify/domain/repositories/admin_repository.dart';
import 'package:spotify/service_locator.dart';

class AddSongUseCase implements UseCase<Either, CreateSongRequest> {
  @override
  Future<Either> call({CreateSongRequest? params}) async {
    return await sl<AdminRepository>().addSong(params!);
  }
}

