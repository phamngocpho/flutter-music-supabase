import 'package:spotify/core/usecase/base_usecase.dart';
import 'package:spotify/domain/repositories/song_repository.dart';

import '../../service_locator.dart';

class IsFavoriteSongUseCase implements UseCase<bool, String> {
  @override
  Future<bool> call({String? params}) async {
    return await sl<SongsRepository>().isFavoriteSong(params!);
  }
}

