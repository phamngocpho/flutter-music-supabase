import 'package:get_it/get_it.dart';
import 'package:spotify/data/repositories/auth_repository_impl.dart';
import 'package:spotify/data/repositories/admin_repository_impl.dart';
import 'package:spotify/data/services/auth_supabase_service.dart';
import 'package:spotify/data/services/admin_supabase_service.dart';
import 'package:spotify/domain/repositories/auth_repository.dart';
import 'package:spotify/domain/repositories/admin_repository.dart';
import 'package:spotify/domain/usecases/get_user_usecase.dart';
import 'package:spotify/domain/usecases/signup_usecase.dart';
import 'package:spotify/domain/usecases/add_or_remove_favorite_song_usecase.dart';
import 'package:spotify/domain/usecases/get_favorite_songs_usecase.dart';
import 'package:spotify/domain/usecases/get_news_songs_usecase.dart';
import 'package:spotify/domain/usecases/get_playlist_usecase.dart';
import 'package:spotify/domain/usecases/is_favorite_song_usecase.dart';
import 'package:spotify/domain/usecases/admin/add_song_usecase.dart';
import 'package:spotify/domain/usecases/admin/update_song_usecase.dart';
import 'package:spotify/domain/usecases/admin/delete_song_usecase.dart';
import 'package:spotify/domain/usecases/admin/get_all_songs_admin_usecase.dart';
import 'package:spotify/domain/usecases/admin/check_admin_usecase.dart';
import 'package:spotify/domain/usecases/admin/upload_song_file_usecase.dart';

import 'data/repositories/song_repository_impl.dart';
import 'data/services/song_supabase_service.dart';
import 'domain/repositories/song_repository.dart';
import 'domain/usecases/signin_usecase.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  sl.registerSingleton<AuthSupabaseService>(
    AuthSupabaseServiceImpl()
  );

  sl.registerSingleton<SongSupabaseService>(
    SongSupabaseServiceImpl()
  );

  sl.registerSingleton<AuthRepository>(
    AuthRepositoryImpl()
  );

  sl.registerSingleton<SongsRepository>(
    SongRepositoryImpl()
  );

  sl.registerSingleton<SignupUseCase>(
    SignupUseCase()
  );

  sl.registerSingleton<SigninUseCase>(
    SigninUseCase()
  );

  sl.registerSingleton<GetNewsSongsUseCase>(
    GetNewsSongsUseCase()
  );

  sl.registerSingleton<GetPlayListUseCase>(
    GetPlayListUseCase()
  );

  sl.registerSingleton<AddOrRemoveFavoriteSongUseCase>(
    AddOrRemoveFavoriteSongUseCase()
  );

  sl.registerSingleton<IsFavoriteSongUseCase>(
    IsFavoriteSongUseCase()
  );

  sl.registerSingleton<GetUserUseCase>(
    GetUserUseCase()
  );

  sl.registerSingleton<GetFavoriteSongsUseCase>(
    GetFavoriteSongsUseCase()
  );

  // Admin dependencies
  sl.registerSingleton<AdminSupabaseService>(
    AdminSupabaseServiceImpl()
  );

  sl.registerSingleton<AdminRepository>(
    AdminRepositoryImpl()
  );

  sl.registerSingleton<GetAllSongsAdminUseCase>(
    GetAllSongsAdminUseCase()
  );

  sl.registerSingleton<AddSongUseCase>(
    AddSongUseCase()
  );

  sl.registerSingleton<UpdateSongUseCase>(
    UpdateSongUseCase()
  );

  sl.registerSingleton<DeleteSongUseCase>(
    DeleteSongUseCase()
  );

  sl.registerSingleton<CheckAdminUseCase>(
    CheckAdminUseCase()
  );

  sl.registerSingleton<UploadSongFileUseCase>(
    UploadSongFileUseCase()
  );
}