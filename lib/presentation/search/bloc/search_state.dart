import 'package:spotify/domain/entities/song_entity.dart';

abstract class SearchState {}

class SearchInitial extends SearchState {}

class SearchLoading extends SearchState {}

class SearchLoaded extends SearchState {
  final List<SongEntity> songs;
  SearchLoaded({required this.songs});
}

class SearchError extends SearchState {
  final String message;
  SearchError({required this.message});
}

