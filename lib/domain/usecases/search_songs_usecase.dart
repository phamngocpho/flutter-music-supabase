import 'package:dartz/dartz.dart';
import 'package:spotify/core/usecase/base_usecase.dart';
import 'package:spotify/domain/repositories/song_repository.dart';

import '../../service_locator.dart';

class SearchSongsUseCase implements UseCase<Either, String> {
  @override
  Future<Either> call({String? params}) async{
    return await sl<SongsRepository>().searchSongs(params!);
  }
}

