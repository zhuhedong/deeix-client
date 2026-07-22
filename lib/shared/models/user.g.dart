// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_User _$UserFromJson(Map<String, dynamic> json) => _User(
  id: (json['id'] as num?)?.toInt(),
  publicID: json['publicID'] as String?,
  email: json['email'] as String?,
  username: json['username'] as String?,
  displayName: json['displayName'] as String?,
  avatarURL: json['avatarURL'] as String?,
  role: json['role'] as String?,
  status: json['status'] as String?,
);

Map<String, dynamic> _$UserToJson(_User instance) => <String, dynamic>{
  'id': instance.id,
  'publicID': instance.publicID,
  'email': instance.email,
  'username': instance.username,
  'displayName': instance.displayName,
  'avatarURL': instance.avatarURL,
  'role': instance.role,
  'status': instance.status,
};
