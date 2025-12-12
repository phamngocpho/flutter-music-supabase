import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:spotify/core/utils/lrc_parser.dart';

class LyricsDisplay extends StatefulWidget {
  final String lyricsUrl;
  final Duration currentPosition;

  const LyricsDisplay({
    Key? key,
    required this.lyricsUrl,
    required this.currentPosition,
  }) : super(key: key);

  @override
  State<LyricsDisplay> createState() => _LyricsDisplayState();
}

class _LyricsDisplayState extends State<LyricsDisplay> {
  List<LrcLine> _lrcLines = [];
  bool _isLoading = true;
  String _error = '';
  final ScrollController _scrollController = ScrollController();
  int _currentIndex = 0;

  // Chiều cao cố định cho mỗi dòng lyrics
  static const double _itemHeight = 60.0;

  @override
  void initState() {
    super.initState();
    _loadLyrics();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLyrics() async {
    try {
      final response = await http.get(Uri.parse(widget.lyricsUrl));
      if (response.statusCode == 200) {
        // Explicitly decode as UTF-8 to handle Vietnamese characters
        final lrcContent = utf8.decode(response.bodyBytes);
        setState(() {
          _lrcLines = LrcParser.parse(lrcContent);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load lyrics';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  void didUpdateWidget(LyricsDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPosition != widget.currentPosition) {
      final newIndex = LrcParser.findCurrentLineIndex(_lrcLines, widget.currentPosition);

      if (newIndex != _currentIndex && newIndex >= 0) {
        setState(() {
          _currentIndex = newIndex;
        });
        // Scroll ngay lập tức khi có dòng mới
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToCenter(newIndex);
        });
      }
    }
  }

  void _scrollToCenter(int index) {
    if (!_scrollController.hasClients || _lrcLines.isEmpty) return;

    // Tính offset để dòng hiện tại nằm chính giữa màn hình
    final targetOffset = index * _itemHeight;

    // Clamp để đảm bảo không scroll quá giới hạn
    final clampedOffset = targetOffset.clamp(
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );

    _scrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Text(
          _error,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (_lrcLines.isEmpty) {
      return const Center(
        child: Text(
          'No lyrics available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Padding để có thể scroll dòng đầu/cuối vào giữa
        final verticalPadding = (constraints.maxHeight - _itemHeight) / 2;

        return ListView.builder(
          controller: _scrollController,
          itemCount: _lrcLines.length,
          padding: EdgeInsets.symmetric(
            vertical: verticalPadding,
            horizontal: 16,
          ),
          itemBuilder: (context, index) {
            final isActive = index == _currentIndex;
            final distance = (index - _currentIndex).abs();
            final opacity = isActive ? 1.0 : (1.0 - (distance * 0.18)).clamp(0.25, 0.6);

            return SizedBox(
              height: _itemHeight,
              child: Center(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    fontSize: isActive ? 22 : 16,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: Colors.white.withValues(alpha: opacity),
                    height: 1.4,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _lrcLines[index].lyrics,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

