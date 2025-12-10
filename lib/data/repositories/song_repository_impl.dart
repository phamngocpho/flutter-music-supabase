import 'package:dartz/dartz.dart';
import 'package:spotify/data/services/song_supabase_service.dart';
import 'package:spotify/domain/repositories/song_repository.dart';

import '../../service_locator.dart';

class SongRepositoryImpl extends SongsRepository {
  @override
  Future<Either> getNewsSongs() async {
    return await sl<SongSupabaseService>().getNewsSongs();
  }

  @override
  Future<Either> getPlayList() async {
    return await sl<SongSupabaseService>().getPlayList();
  }

  @override
  Future<Either> addOrRemoveFavoriteSongs(String songId) async {
    return await sl<SongSupabaseService>().addOrRemoveFavoriteSong(songId);
  }

  @override
  Future<bool> isFavoriteSong(String songId) async {
    return await sl<SongSupabaseService>().isFavoriteSong(songId);
  }

  @override
  Future<Either> getUserFavoriteSongs() async {
    return await sl<SongSupabaseService>().getUserFavoriteSongs();
  }

  @override
  Future<Either> searchSongs(String query) async {
    return await sl<SongSupabaseService>().searchSongs(query);
  }
}

