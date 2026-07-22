class PromptPreset {
  const PromptPreset({
    required this.id,
    required this.title,
    required this.content,
    this.description = '',
    this.trigger = '',
    this.scope = '',
    this.enabled = true,
    this.sortOrder = 0,
  });

  final int id;
  final String title;
  final String content;
  final String description;
  final String trigger;
  final String scope;
  final bool enabled;
  final int sortOrder;

  factory PromptPreset.fromApi(Map<String, dynamic> json) {
    final idRaw = json['id'];
    final id = idRaw is int ? idRaw : int.tryParse('$idRaw') ?? 0;
    return PromptPreset(
      id: id,
      title: '${json['title'] ?? ''}',
      content: '${json['content'] ?? ''}',
      description: '${json['description'] ?? ''}',
      trigger: '${json['trigger'] ?? ''}',
      scope: '${json['scope'] ?? ''}',
      enabled: json['enabled'] != false,
      sortOrder: json['sortOrder'] is int
          ? json['sortOrder'] as int
          : int.tryParse('${json['sortOrder'] ?? 0}') ?? 0,
    );
  }
}
