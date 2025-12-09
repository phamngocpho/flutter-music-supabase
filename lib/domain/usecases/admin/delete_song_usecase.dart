import 'package:dartz/dartz.dart';
import 'package:spotify/core/usecase/base_usecase.dart';
import 'package:spotify/domain/repositories/admin_repository.dart';
import 'package:spotify/service_locator.dart';

class DeleteSongUseCase implements UseCase<Either, String> {
  @override
  Future<Either> call({String? params}) async {
    return await sl<AdminRepository>().deleteSong(params!);
  }
}

