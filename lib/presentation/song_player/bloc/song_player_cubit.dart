import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:spotify/presentation/song_player/bloc/song_player_state.dart';
import 'package:spotify/presentation/song_player/core/audio_stream_handler.dart';
import 'package:spotify/presentation/song_player/core/audio_playback_controller.dart';

class SongPlayerCubit extends Cubit<SongPlayerState> {
  // Custom audio components for manual handling
  AudioStreamHandler? _streamHandler;
  AudioPlaybackController? _playbackController;

  // Fallback to just_audio for actual decoding (since manual decode is complex)
  final AudioPlayer _audioPlayer = AudioPlayer();

  Duration _songDuration = Duration.zero;
  Duration _songPosition = Duration.zero;
  bool _isPlaying = false;
  bool _isBuffering = false;
  double _currentVolume = 0.5; // Default volume at 50%

  // Stream subscriptions for proper cleanup
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<PlaybackState>? _stateSubscription;
  StreamSubscription<bool>? _bufferingSubscription;

  SongPlayerCubit() : super(SongPlayerLoading());

  // Getter for current volume
  double get currentVolume => _currentVolume;

  /// Load and prepare audio from URL with custom streaming
  Future<void> loadSong(String url) async {
    if (url.isEmpty) {
      _handleError('Invalid URL provided');
      return;
    }

    try {
      emit(SongPlayerLoading());

      // Clean up previous resources
      await _cleanup();

      // Initialize custom stream handler
      _streamHandler = AudioStreamHandler(url: url);
      _playbackController = AudioPlaybackController(
        streamHandler: _streamHandler!,
      );

      // Set up stream listeners for custom controller
      _setupCustomStreamListeners();

      // Also load with just_audio for actual playback (decode part)
      await _audioPlayer.setUrl(url);

      // Initialize custom playback controller
      await _playbackController!.initialize();

      // Get duration from audio player
      _songDuration = _audioPlayer.duration ?? Duration.zero;

      _emitLoadedState();

      print('Song loaded successfully with custom streaming');
    } catch (e) {
      _handleError('Failed to load song: $e');
    }
  }

  /// Set up listeners for custom playback controller
  void _setupCustomStreamListeners() {
    // Listen to position from custom controller
    _positionSubscription = _playbackController!.positionStream.listen(
      (position) {
        _songPosition = position;
        _emitLoadedState();
      },
      onError: (error) {
        _handleError('Position stream error: $error');
      },
    );

    // Listen to playback state from custom controller
    _stateSubscription = _playbackController!.stateStream.listen(
      (state) {
        _isPlaying = state == PlaybackState.playing;

        // Sync with actual audio player
        if (_isPlaying && !_audioPlayer.playing) {
          _audioPlayer.play();
        } else if (!_isPlaying && _audioPlayer.playing) {
          _audioPlayer.pause();
        }

        _emitLoadedState();
      },
      onError: (error) {
        _handleError('State stream error: $error');
      },
    );

    // Listen to buffering state
    _bufferingSubscription = _playbackController!.bufferingStream.listen(
      (buffering) {
        _isBuffering = buffering;
        _emitLoadedState();
      },
      onError: (error) {
        _handleError('Buffering stream error: $error');
      },
    );

    // Also monitor stream handler progress
    _streamHandler!.downloadProgress.listen((progress) {
      print('Download progress: ${(progress * 100).toStringAsFixed(1)}%');
    });
  }

  /// Emit loaded state with current playback information
  void _emitLoadedState() {
    if (!isClosed) {
      emit(SongPlayerLoaded(
        position: _songPosition,
        duration: _songDuration,
        isPlaying: _isPlaying,
        isBuffering: _isBuffering,
      ));
    }
  }

  /// Handle errors and emit failure state
  void _handleError(String errorMessage) {
    print('SongPlayerCubit Error: $errorMessage');
    if (!isClosed) {
      emit(SongPlayerFailure(message: errorMessage));
    }
  }

  /// Play or pause the current song
  void playOrPauseSong() {
    if (_isPlaying) {
      pauseSong();
    } else {
      playSong();
    }
  }

  /// Play the song using custom controller
  Future<void> playSong() async {
    try {
      if (_playbackController != null) {
        await _playbackController!.play();
      } else {
        await _audioPlayer.play();
      }
      _isPlaying = true;
      _emitLoadedState();
    } catch (e) {
      _handleError('Failed to play song: $e');
    }
  }

  /// Pause the song using custom controller
  Future<void> pauseSong() async {
    try {
      if (_playbackController != null) {
        _playbackController!.pause();
      } else {
        await _audioPlayer.pause();
      }
      _isPlaying = false;
      _emitLoadedState();
    } catch (e) {
      _handleError('Failed to pause song: $e');
    }
  }

  /// Stop the song and reset position
  Future<void> stopSong() async {
    try {
      if (_playbackController != null) {
        _playbackController!.stop();
      }
      await _audioPlayer.stop();
      await _audioPlayer.seek(Duration.zero);
      _isPlaying = false;
      _songPosition = Duration.zero;
      _emitLoadedState();
    } catch (e) {
      _handleError('Failed to stop song: $e');
    }
  }

  /// Seek to a specific position using custom seek algorithm
  Future<void> seekToPosition(Duration position) async {
    try {
      if (position < Duration.zero || position > _songDuration) {
        _handleError('Invalid seek position');
        return;
      }
      
      // Use custom seek implementation
      if (_playbackController != null) {
        await _playbackController!.seek(position);
      }

      // Also seek in actual player
      await _audioPlayer.seek(position);

      _songPosition = position;
      _emitLoadedState();
    } catch (e) {
      _handleError('Failed to seek: $e');
    }
  }

  /// Skip forward by a specific duration (e.g., 10 seconds)
  Future<void> skipForward({Duration duration = const Duration(seconds: 10)}) async {
    final newPosition = _songPosition + duration;
    final targetPosition = newPosition > _songDuration ? _songDuration : newPosition;
    await seekToPosition(targetPosition);
  }

  /// Skip backward by a specific duration (e.g., 10 seconds)
  Future<void> skipBackward({Duration duration = const Duration(seconds: 10)}) async {
    final newPosition = _songPosition - duration;
    final targetPosition = newPosition < Duration.zero ? Duration.zero : newPosition;
    await seekToPosition(targetPosition);
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    try {
      final clampedVolume = volume.clamp(0.0, 1.0);
      _currentVolume = clampedVolume; // Save the volume value
      await _audioPlayer.setVolume(clampedVolume);
    } catch (e) {
      _handleError('Failed to set volume: $e');
    }
  }

  /// Set playback speed using custom controller
  Future<void> setSpeed(double speed) async {
    try {
      final clampedSpeed = speed.clamp(0.5, 2.0);

      if (_playbackController != null) {
        _playbackController!.setSpeed(clampedSpeed);
      }

      await _audioPlayer.setSpeed(clampedSpeed);
    } catch (e) {
      _handleError('Failed to set speed: $e');
    }
  }

  /// Get current playback position
  Duration get currentPosition => _songPosition;

  /// Get total duration
  Duration get totalDuration => _songDuration;

  /// Check if audio is currently playing
  bool get isPlaying => _isPlaying;

  /// Check if audio is buffering
  bool get isBuffering => _isBuffering;

  /// Clean up resources
  Future<void> _cleanup() async {
    await _positionSubscription?.cancel();
    await _stateSubscription?.cancel();
    await _bufferingSubscription?.cancel();

    _playbackController?.dispose();
    _streamHandler?.dispose();

    _playbackController = null;
    _streamHandler = null;
  }

  @override
  Future<void> close() async {
    await _cleanup();
    await _audioPlayer.dispose();
    return super.close();
  }
}