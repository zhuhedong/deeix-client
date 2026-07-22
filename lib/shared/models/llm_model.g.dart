// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'llm_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LlmModel _$LlmModelFromJson(Map<String, dynamic> json) => _LlmModel(
  platformModelName: json['platformModelName'] as String,
  vendor: json['vendor'] as String? ?? '',
  description: json['description'] as String? ?? '',
  icon: json['icon'] as String? ?? '',
  sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
  capabilitiesJSON: json['capabilitiesJSON'] as String?,
  kindsJSON: json['kindsJSON'] as String?,
  protocolsJSON: json['protocolsJSON'] as String?,
  isFree: json['isFree'] as bool? ?? false,
  pricingSummary: json['pricingSummary'] as String?,
);

Map<String, dynamic> _$LlmModelToJson(_LlmModel instance) => <String, dynamic>{
  'platformModelName': instance.platformModelName,
  'vendor': instance.vendor,
  'description': instance.description,
  'icon': instance.icon,
  'sortOrder': instance.sortOrder,
  'capabilitiesJSON': instance.capabilitiesJSON,
  'kindsJSON': instance.kindsJSON,
  'protocolsJSON': instance.protocolsJSON,
  'isFree': instance.isFree,
  'pricingSummary': instance.pricingSummary,
};
