/// Personal model provider ("bring your own key", DEEIX-Chat 0.4.4+).
class ModelProvider {
  const ModelProvider({
    required this.id,
    required this.name,
    this.protocol = '',
    this.baseURL = '',
    this.host = '',
    this.keyHint = '',
    this.models = const [],
    this.status = 'active',
    this.lastError = '',
  });

  final String id;
  final String name;
  final String protocol;
  final String baseURL;
  final String host;
  final String keyHint;
  final List<String> models;
  final String status;
  final String lastError;

  bool get enabled => status == 'active';

  String get statusLabel => switch (status) {
    'active' => '已启用',
    'disabled' => '已停用',
    'suspended' => '已被管理员暂停',
    _ => status,
  };

  factory ModelProvider.fromApi(Map<String, dynamic> json) {
    final models = (json['models'] is List ? json['models'] as List : const [])
        .map((m) => m is Map ? '${m['name'] ?? ''}' : '$m')
        .where((m) => m.isNotEmpty)
        .toList();
    return ModelProvider(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      protocol: '${json['protocol'] ?? ''}',
      baseURL: '${json['baseURL'] ?? ''}',
      host: '${json['host'] ?? ''}',
      keyHint: '${json['keyHint'] ?? ''}',
      models: models,
      status: '${json['status'] ?? 'active'}',
      lastError: '${json['lastError'] ?? ''}',
    );
  }
}

class ModelProviderAccess {
  const ModelProviderAccess({
    this.enabled = false,
    this.maxPerUser = 0,
    this.protocols = const [],
  });

  final bool enabled;
  final int maxPerUser;
  final List<String> protocols;

  factory ModelProviderAccess.fromApi(Map<String, dynamic> json) {
    return ModelProviderAccess(
      enabled: json['enabled'] == true,
      maxPerUser: json['maxPerUser'] is int ? json['maxPerUser'] as int : 0,
      protocols: (json['protocols'] is List ? json['protocols'] as List : [])
          .map((e) => '$e')
          .toList(),
    );
  }
}
