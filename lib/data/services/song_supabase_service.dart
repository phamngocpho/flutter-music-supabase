import 'package:dartz/dartz.dart';
import 'package:spotify/data/models/song_model.dart';
import 'package:spotify/domain/entities/song_entity.dart';
import 'package:spotify/domain/usecases/is_favorite_song_usecase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../service_locator.dart';

abstract class SongSupabaseService {
  Future<Either> getNewsSongs();
  Future<Either> getPlayList();
  Future<Either> addOrRemoveFavoriteSong(String songId);
  Future<bool> isFavoriteSong(String songId);
  Future<Either> getUserFavoriteSongs();
  Future<Either> searchSongs(String query);
}

class SongSupabaseServiceImpl extends SongSupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<Either> getNewsSongs() async {
    try {
      List<SongEntity> songs = [];
      var data = await _supabase
        .from('Songs')
        .select()
        .order('releaseDate', ascending: false)
        .limit(3);

      for (var element in data) {
        var songModel = SongModel.fromJson(element);
        bool isFavorite = await sl<IsFavoriteSongUseCase>().call(
          params: element['id'].toString()
        );
        songModel.isFavorite = isFavorite;
        songModel.songId = element['id'].toString();
        songs.add(songModel.toEntity());
      }
      return Right(songs);
    } catch (e) {
      print(e);
      return const Left('An error occurred, Please try again.');
    }
  }

  @override
  Future<Either> getPlayList() async {
    try {
      List<SongEntity> songs = [];
      var data = await _supabase
        .from('Songs')
        .select()
        .order('releaseDate', ascending: false);

      for (var element in data) {
        var songModel = SongModel.fromJson(element);
        bool isFavorite = await sl<IsFavoriteSongUseCase>().call(
          params: element['id'].toString()
        );
        songModel.isFavorite = isFavorite;
        songModel.songId = element['id'].toString();
        songs.add(songModel.toEntity());
      }
      return Right(songs);
    } catch (e) {
      print(e);
      return const Left('An error occurred, Please try again.');
    }
  }

  @override
  Future<Either> addOrRemoveFavoriteSong(String songId) async {
    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        return const Left('User not authenticated');
      }

      late bool isFavorite;
      String uId = user.id;

      var favoriteSongs = await _supabase
        .from('Favorites')
        .select()
        .eq('user_id', uId)
        .eq('song_id', songId);

      if(favoriteSongs.isNotEmpty) {
        await _supabase
          .from('Favorites')
          .delete()
          .eq('user_id', uId)
          .eq('song_id', songId);
        isFavorite = false;
      } else {
        await _supabase
          .from('Favorites')
          .insert({
            'user_id': uId,
            'song_id': songId,
            'added_date': DateTime.now().toIso8601String()
          });
        isFavorite = true;
      }
      return Right(isFavorite);
    } catch(e) {
      print(e);
      return const Left('An error occurred');
    }
  }

  @override
  Future<bool> isFavoriteSong(String songId) async {
    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        return false;
      }

      String uId = user.id;

      var favoriteSongs = await _supabase
        .from('Favorites')
        .select()
        .eq('user_id', uId)
        .eq('song_id', songId);

      if(favoriteSongs.isNotEmpty) {
        return true;
      } else {
        return false;
      }
    } catch(e) {
      print(e);
      return false;
    }
  }

  @override
  Future<Either> getUserFavoriteSongs() async {
    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        return const Left('User not authenticated');
      }

      List<SongEntity> favoriteSongs = [];
      String uId = user.id;

      var favoritesSnapshot = await _supabase
        .from('Favorites')
        .select('song_id')
        .eq('user_id', uId);

      for (var element in favoritesSnapshot) {
        String songId = element['song_id'].toString();

        var song = await _supabase
          .from('Songs')
          .select()
          .eq('id', songId)
          .single();

        SongModel songModel = SongModel.fromJson(song);
        songModel.isFavorite = true;
        songModel.songId = songId;
        favoriteSongs.add(songModel.toEntity());
      }

      return Right(favoriteSongs);
    } catch (e) {
      print(e);
      return const Left('An error occurred');
    }
  }

  @override
  Future<Either> searchSongs(String query) async {
    try {
      if (query.isEmpty) {
        return Right(<SongEntity>[]);
      }

      List<SongEntity> songs = [];
      
      // Tìm kiếm theo title và artist (case-insensitive)
      var data = await _supabase
        .from('Songs')
        .select()
        .or('title.ilike.%$query%,artist.ilike.%$query%')
        .order('releaseDate', ascending: false);

      for (var element in data) {
        var songModel = SongModel.fromJson(element);
        bool isFavorite = await sl<IsFavoriteSongUseCase>().call(
          params: element['id'].toString()
        );
        songModel.isFavorite = isFavorite;
        songModel.songId = element['id'].toString();
        songs.add(songModel.toEntity());
      }

      return Right(songs);
    } catch (e) {
      print(e);
      return const Left('An error occurred while searching. Please try again.');
    }
  }
}

