import '../../shared/models/message.dart';

/// Client-side Markdown transcript export (pure Dart, no Flutter deps).
String messagesToMarkdown(List<ChatMessage> messages) {
  final buf = StringBuffer();
  for (final m in messages) {
    final role = switch (m.role) {
      MessageRole.user => 'User',
      MessageRole.assistant => 'Assistant',
      MessageRole.system => 'System',
      MessageRole.tool => 'Tool',
      MessageRole.unknown => 'Message',
    };
    buf.writeln('### $role');
    if (m.thinking.isNotEmpty) {
      buf.writeln('<details><summary>Thinking</summary>\n');
      buf.writeln(m.thinking);
      buf.writeln('\n</details>\n');
    }
    buf.writeln(m.content);
    buf.writeln();
  }
  return buf.toString();
}
