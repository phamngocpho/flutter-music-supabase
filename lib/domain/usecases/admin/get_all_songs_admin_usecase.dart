import 'package:dartz/dartz.dart';
import 'package:spotify/core/usecase/base_usecase.dart';
import 'package:spotify/domain/repositories/admin_repository.dart';
import 'package:spotify/service_locator.dart';

class GetAllSongsAdminUseCase implements UseCase<Either, dynamic> {
  @override
  Future<Either> call({params}) async {
    return await sl<AdminRepository>().getAllSongs();
  }
}

