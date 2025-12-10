class LrcLine {
  final Duration timestamp;
  final String lyrics;

  LrcLine({required this.timestamp, required this.lyrics});
}

class LrcParser {
  static List<LrcLine> parse(String lrcContent) {
    final lines = lrcContent.split('\n');
    final List<LrcLine> lrcLines = [];

    for (final line in lines) {
      final match = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)').firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final milliseconds = int.parse(match.group(3)!.padRight(3, '0'));
        final lyrics = match.group(4)!.trim();

        final timestamp = Duration(
          minutes: minutes,
          seconds: seconds,
          milliseconds: milliseconds,
        );

        lrcLines.add(LrcLine(timestamp: timestamp, lyrics: lyrics));
      }
    }

    return lrcLines;
  }

  static int findCurrentLineIndex(List<LrcLine> lines, Duration currentPosition) {
    for (int i = lines.length - 1; i >= 0; i--) {
      if (currentPosition >= lines[i].timestamp) {
        return i;
      }
    }
    return -1;
  }
}

