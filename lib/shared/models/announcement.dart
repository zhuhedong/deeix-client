class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    this.contentMarkdown = '',
    this.type = 'info',
    this.pinned = false,
    this.priority = 0,
  });

  final int id;
  final String title;
  final String contentMarkdown;
  final String type;
  final bool pinned;
  final int priority;

  factory Announcement.fromApi(Map<String, dynamic> json) {
    final idRaw = json['id'];
    final id = idRaw is int ? idRaw : int.tryParse('$idRaw') ?? 0;
    return Announcement(
      id: id,
      title: '${json['title'] ?? ''}',
      contentMarkdown: '${json['contentMarkdown'] ?? ''}',
      type: '${json['type'] ?? 'info'}',
      pinned: json['pinned'] == true,
      priority: json['priority'] is int
          ? json['priority'] as int
          : int.tryParse('${json['priority'] ?? 0}') ?? 0,
    );
  }
}
