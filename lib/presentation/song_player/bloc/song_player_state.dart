abstract class SongPlayerState {}

class SongPlayerLoading extends SongPlayerState {}

class SongPlayerLoaded extends SongPlayerState {
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final bool isBuffering;

  SongPlayerLoaded({
    required this.position,
    required this.duration,
    required this.isPlaying,
    this.isBuffering = false,
  });
}

class SongPlayerFailure extends SongPlayerState {
  final String message;

  SongPlayerFailure({this.message = 'An error occurred'});
}
