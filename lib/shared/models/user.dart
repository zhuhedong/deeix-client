import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
abstract class User with _$User {
  const factory User({
    /// Numeric internal id from API.
    int? id,

    /// Public stable id when present.
    String? publicID,
    String? email,
    String? username,
    String? displayName,
    String? avatarURL,
    String? role,
    String? status,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  /// Maps `AuthUserResponse` from login / me.
  factory User.fromApi(Map<String, dynamic> json) {
    // Login returns user nested; me returns { user: ... }.
    Map<String, dynamic> data = json;
    if (json['user'] is Map) {
      data = Map<String, dynamic>.from(json['user'] as Map);
    } else if (json['data'] is Map) {
      final nested = Map<String, dynamic>.from(json['data'] as Map);
      if (nested['user'] is Map) {
        data = Map<String, dynamic>.from(nested['user'] as Map);
      } else {
        data = nested;
      }
    }

    int? asInt(dynamic v) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      return null;
    }

    return User(
      id: asInt(data['id']),
      publicID: data['publicID'] as String?,
      email: data['email'] as String?,
      username: data['username'] as String?,
      displayName: data['displayName'] as String?,
      avatarURL: data['avatarURL'] as String?,
      role: data['role'] as String?,
      status: data['status'] as String?,
    );
  }

  const User._();

  String get displayLabel => displayName?.trim().isNotEmpty == true
      ? displayName!
      : username?.trim().isNotEmpty == true
      ? username!
      : email?.trim().isNotEmpty == true
      ? email!
      : '用户';
}
