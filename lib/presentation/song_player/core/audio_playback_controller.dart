import 'dart:async';
import 'audio_stream_handler.dart';

/// Custom audio playback controller with manual state management
class AudioPlaybackController {
  final AudioStreamHandler streamHandler;

  // Playback state
  PlaybackState _state = PlaybackState.idle;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  // Stream controllers
  final _stateController = StreamController<PlaybackState>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _bufferingController = StreamController<bool>.broadcast();

  // Playback control
  Timer? _progressTimer;
  bool _isBuffering = false;

  // Playback speed
  double _playbackSpeed = 1.0;

  AudioPlaybackController({required this.streamHandler});

  /// Get playback state stream
  Stream<PlaybackState> get stateStream => _stateController.stream;

  /// Get position stream
  Stream<Duration> get positionStream => _positionController.stream;

  /// Get buffering stream
  Stream<bool> get bufferingStream => _bufferingController.stream;

  /// Current playback state
  PlaybackState get state => _state;

  /// Current position
  Duration get position => _position;

  /// Total duration
  Duration get duration => _duration;

  /// Is currently playing
  bool get isPlaying => _state == PlaybackState.playing;

  /// Is buffering
  bool get isBuffering => _isBuffering;

  /// Initialize and prepare for playback
  Future<void> initialize() async {
    _updateState(PlaybackState.loading);

    try {
      // Start streaming in background
      streamHandler.startStreaming();

      // Wait for minimum buffer
      _setBuffering(true);

      // Listen to chunks for duration calculation
      int totalChunks = 0;
      final subscription = streamHandler.chunkStream.listen((chunk) {
        totalChunks++;

        // Estimate duration based on chunk count and bitrate
        // Assuming average MP3 bitrate of 128kbps
        _duration = Duration(
          seconds: (totalChunks * AudioStreamHandler.chunkSize * 8) ~/ (128 * 1024)
        );
      });

      // Wait for minimum buffer
      while (!streamHandler.hasMinimumBuffer) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      _setBuffering(false);
      _updateState(PlaybackState.ready);

      // Cancel subscription after initial buffer
      await Future.delayed(const Duration(milliseconds: 500));
      subscription.cancel();

    } catch (e) {
      print('Initialization error: $e');
      _updateState(PlaybackState.error);
    }
  }

  /// Start playback
  Future<void> play() async {
    if (_state == PlaybackState.idle || _state == PlaybackState.loading) {
      await initialize();
    }

    if (_state != PlaybackState.ready && _state != PlaybackState.paused) {
      return;
    }

    _updateState(PlaybackState.playing);
    _startProgressTimer();
  }

  /// Pause playback
  void pause() {
    if (_state != PlaybackState.playing) return;

    _updateState(PlaybackState.paused);
    _stopProgressTimer();
    streamHandler.pauseStreaming();
  }

  /// Stop playback and reset
  void stop() {
    _stopProgressTimer();
    streamHandler.stopStreaming();
    _position = Duration.zero;
    _positionController.add(_position);
    _updateState(PlaybackState.idle);
  }

  /// Seek to specific position
  Future<void> seek(Duration position) async {
    if (position < Duration.zero || position > _duration) {
      return;
    }

    final wasPlaying = _state == PlaybackState.playing;

    // Pause during seek
    if (wasPlaying) {
      _stopProgressTimer();
    }

    _setBuffering(true);

    // Calculate seek position
    _position = position;
    _positionController.add(_position);

    // Simulate seeking delay (in real implementation, would restart stream from position)
    await Future.delayed(const Duration(milliseconds: 300));

    _setBuffering(false);

    // Resume if was playing
    if (wasPlaying) {
      _startProgressTimer();
    }
  }

  /// Set playback speed
  void setSpeed(double speed) {
    _playbackSpeed = speed.clamp(0.5, 2.0);

    // Restart timer with new speed if playing
    if (_state == PlaybackState.playing) {
      _stopProgressTimer();
      _startProgressTimer();
    }
  }

  /// Start progress timer to update position
  void _startProgressTimer() {
    _stopProgressTimer();

    // Update position every 100ms based on playback speed
    _progressTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) {
        if (_state == PlaybackState.playing) {
          _position += Duration(milliseconds: (100 * _playbackSpeed).toInt());

          // Check if reached end
          if (_position >= _duration) {
            _position = _duration;
            _updateState(PlaybackState.completed);
            _stopProgressTimer();
          }

          _positionController.add(_position);

          // Check buffer status
          _checkBufferHealth();
        }
      },
    );
  }

  /// Stop progress timer
  void _stopProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  /// Check if buffer is healthy
  void _checkBufferHealth() {
    // Calculate expected position based on download progress
    final downloadProgress = streamHandler.bufferPercentage;
    final downloadedPosition = _duration * downloadProgress;

    // If we're close to downloaded edge, buffer
    if (_position >= downloadedPosition * 0.9) {
      _setBuffering(true);
    } else if (_isBuffering && _position < downloadedPosition * 0.8) {
      _setBuffering(false);
    }
  }

  /// Update playback state
  void _updateState(PlaybackState newState) {
    _state = newState;
    _stateController.add(_state);
  }

  /// Set buffering state
  void _setBuffering(bool buffering) {
    _isBuffering = buffering;
    _bufferingController.add(_isBuffering);
  }

  /// Dispose resources
  void dispose() {
    _stopProgressTimer();
    streamHandler.dispose();
    _stateController.close();
    _positionController.close();
    _bufferingController.close();
  }
}

/// Playback states
enum PlaybackState {
  idle,       // Not initialized
  loading,    // Loading audio
  ready,      // Ready to play
  playing,    // Currently playing
  paused,     // Paused
  completed,  // Playback completed
  error,      // Error occurred
}

