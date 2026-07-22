class ConversationProject {
  const ConversationProject({
    required this.publicID,
    required this.name,
    this.description = '',
    this.color = '',
    this.icon = '',
    this.status = 'active',
    this.sortOrder = 0,
  });

  final String publicID;
  final String name;
  final String description;
  final String color;
  final String icon;
  final String status;
  final int sortOrder;

  factory ConversationProject.fromApi(Map<String, dynamic> json) {
    return ConversationProject(
      publicID: '${json['publicID'] ?? json['public_id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      description: '${json['description'] ?? ''}',
      color: '${json['color'] ?? ''}',
      icon: '${json['icon'] ?? ''}',
      status: '${json['status'] ?? 'active'}',
      sortOrder: json['sortOrder'] is int
          ? json['sortOrder'] as int
          : int.tryParse('${json['sortOrder'] ?? 0}') ?? 0,
    );
  }
}
