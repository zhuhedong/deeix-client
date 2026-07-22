class McpTool {
  const McpTool({
    required this.id,
    required this.name,
    this.displayName = '',
    this.description = '',
    this.serverName = '',
    this.status = '',
  });

  final int id;
  final String name;
  final String displayName;
  final String description;
  final String serverName;
  final String status;

  String get label => displayName.trim().isNotEmpty ? displayName : name;

  factory McpTool.fromApi(Map<String, dynamic> json) {
    final idRaw = json['id'];
    final id = idRaw is int ? idRaw : int.tryParse('$idRaw') ?? 0;
    return McpTool(
      id: id,
      name: '${json['name'] ?? ''}',
      displayName: '${json['displayName'] ?? ''}',
      description: '${json['description'] ?? ''}',
      serverName: '${json['serverName'] ?? ''}',
      status: '${json['status'] ?? ''}',
    );
  }
}
