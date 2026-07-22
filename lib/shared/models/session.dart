class ActiveSession {
  const ActiveSession({
    required this.sessionID,
    this.current = false,
    this.deviceLabel = '',
    this.deviceName = '',
    this.deviceType = '',
    this.browserName = '',
    this.osName = '',
    this.clientIP = '',
    this.locationLabel = '',
    this.lastSeenAt,
    this.createdAt,
  });

  final String sessionID;
  final bool current;
  final String deviceLabel;
  final String deviceName;
  final String deviceType;
  final String browserName;
  final String osName;
  final String clientIP;
  final String locationLabel;
  final DateTime? lastSeenAt;
  final DateTime? createdAt;

  String get displayTitle {
    final label = deviceLabel.trim().isNotEmpty
        ? deviceLabel
        : [
            if (browserName.isNotEmpty) browserName,
            if (osName.isNotEmpty) osName,
            if (deviceType.isNotEmpty) deviceType,
          ].join(' · ');
    return label.isEmpty ? sessionID : label;
  }

  factory ActiveSession.fromApi(Map<String, dynamic> json) {
    DateTime? t(dynamic v) {
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
      return null;
    }

    return ActiveSession(
      sessionID: '${json['sessionID'] ?? json['session_id'] ?? ''}',
      current: json['current'] == true,
      deviceLabel: '${json['deviceLabel'] ?? ''}',
      deviceName: '${json['deviceName'] ?? ''}',
      deviceType: '${json['deviceType'] ?? ''}',
      browserName: '${json['browserName'] ?? ''}',
      osName: '${json['osName'] ?? ''}',
      clientIP: '${json['clientIP'] ?? ''}',
      locationLabel: '${json['locationLabel'] ?? ''}',
      lastSeenAt: t(json['lastSeenAt']),
      createdAt: t(json['createdAt']),
    );
  }
}
