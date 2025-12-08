import 'dart:async';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Custom audio stream handler that manages downloading and buffering
class AudioStreamHandler {
  final String url;

  // Streaming state
  StreamController<AudioChunk>? _chunkController;
  StreamController<double>? _downloadProgressController;

  // Buffer management
  final List<AudioChunk> _buffer = [];
  int _totalBytes = 0;
  int _downloadedBytes = 0;
  bool _isDownloading = false;
  bool _isPaused = false;

  // Chunk configuration
  static const int chunkSize = 64 * 1024; // 64KB per chunk
  static const int minBufferChunks = 5; // Minimum chunks before playback

  AudioStreamHandler({required this.url});

  /// Get stream of audio chunks
  Stream<AudioChunk> get chunkStream {
    _chunkController ??= StreamController<AudioChunk>.broadcast();
    return _chunkController!.stream;
  }

  /// Get download progress stream (0.0 to 1.0)
  Stream<double> get downloadProgress {
    _downloadProgressController ??= StreamController<double>.broadcast();
    return _downloadProgressController!.stream;
  }

  /// Start streaming audio data
  Future<void> startStreaming() async {
    if (_isDownloading) return;

    _isDownloading = true;
    _isPaused = false;

    try {
      // Create HTTP client for streaming
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(url));

      // Send request and get streaming response
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Failed to load audio: ${response.statusCode}');
      }

      // Get total content length
      _totalBytes = response.contentLength ?? 0;

      // Process stream in chunks
      await _processAudioStream(response.stream);

    } catch (e) {
      print('AudioStreamHandler Error: $e');
      _chunkController?.addError(e);
    } finally {
      _isDownloading = false;
    }
  }

  /// Process incoming audio stream
  Future<void> _processAudioStream(Stream<List<int>> stream) async {
    int chunkIndex = 0;
    List<int> currentChunk = [];

    await for (final data in stream) {
      // Check if paused
      while (_isPaused && _isDownloading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      if (!_isDownloading) break;

      currentChunk.addAll(data);
      _downloadedBytes += data.length;

      // Emit progress
      if (_totalBytes > 0) {
        final progress = _downloadedBytes / _totalBytes;
        _downloadProgressController?.add(progress);
      }

      // When chunk is full, emit it
      while (currentChunk.length >= chunkSize) {
        final chunkData = Uint8List.fromList(
          currentChunk.sublist(0, chunkSize)
        );
        currentChunk = currentChunk.sublist(chunkSize);

        final chunk = AudioChunk(
          index: chunkIndex++,
          data: chunkData,
          timestamp: Duration(
            milliseconds: (chunkIndex * chunkSize * 8) ~/ 128 // Estimate for 128kbps
          ),
        );

        _buffer.add(chunk);
        _chunkController?.add(chunk);
      }
    }

    // Emit remaining data as final chunk
    if (currentChunk.isNotEmpty) {
      final chunk = AudioChunk(
        index: chunkIndex,
        data: Uint8List.fromList(currentChunk),
        timestamp: Duration(
          milliseconds: (chunkIndex * chunkSize * 8) ~/ 128
        ),
      );

      _buffer.add(chunk);
      _chunkController?.add(chunk);
    }
  }

  /// Pause streaming (stops downloading)
  void pauseStreaming() {
    _isPaused = true;
  }

  /// Resume streaming
  void resumeStreaming() {
    _isPaused = false;
  }

  /// Stop streaming and clear buffer
  void stopStreaming() {
    _isDownloading = false;
    _isPaused = false;
    _buffer.clear();
    _downloadedBytes = 0;
  }

  /// Get buffered chunks count
  int get bufferedChunks => _buffer.length;

  /// Check if minimum buffer is available
  bool get hasMinimumBuffer => _buffer.length >= minBufferChunks;

  /// Get buffer percentage
  double get bufferPercentage {
    if (_totalBytes == 0) return 0.0;
    return _downloadedBytes / _totalBytes;
  }

  /// Dispose resources
  void dispose() {
    _isDownloading = false;
    _chunkController?.close();
    _downloadProgressController?.close();
    _buffer.clear();
  }
}

/// Represents a chunk of audio data
class AudioChunk {
  final int index;
  final Uint8List data;
  final Duration timestamp;

  AudioChunk({
    required this.index,
    required this.data,
    required this.timestamp,
  });

  int get size => data.length;
}

