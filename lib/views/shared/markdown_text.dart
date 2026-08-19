import 'package:flutter/material.dart';

/// Renderiza Markdown básico (`**negrita**` y listas `- `) que llega del backend.
class MarkdownText extends StatelessWidget {
  const MarkdownText({
    super.key,
    required this.data,
    this.style,
  });

  final String data;
  final TextStyle? style;

  static final _boldPattern = RegExp(r'\*\*(.+?)\*\*');
  static final _listPrefix = RegExp(r'^\s*[-*]\s+');

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    final lines = data.split('\n');
    final hasList = lines.any(_listPrefix.hasMatch);

    if (!hasList) {
      return Text.rich(
        TextSpan(style: baseStyle, children: _inlineSpans(data, baseStyle)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < lines.length; i++) _buildLine(lines[i], baseStyle),
      ],
    );
  }

  Widget _buildLine(String line, TextStyle baseStyle) {
    if (line.isEmpty) {
      return const SizedBox(height: 8);
    }

    final listMatch = _listPrefix.firstMatch(line);
    if (listMatch != null) {
      final body = line.substring(listMatch.end);
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('•  ', style: baseStyle.copyWith(fontWeight: FontWeight.w700)),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: baseStyle,
                  children: _inlineSpans(body, baseStyle),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Text.rich(
      TextSpan(style: baseStyle, children: _inlineSpans(line, baseStyle)),
    );
  }

  static List<InlineSpan> _inlineSpans(String text, TextStyle baseStyle) {
    final spans = <InlineSpan>[];
    var cursor = 0;

    for (final match in _boldPattern.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: baseStyle.copyWith(fontWeight: FontWeight.w800),
        ),
      );
      cursor = match.end;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }
    if (spans.isEmpty) {
      spans.add(TextSpan(text: text));
    }
    return spans;
  }
}
