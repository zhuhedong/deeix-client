import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'llm_model.freezed.dart';
part 'llm_model.g.dart';

@freezed
abstract class LlmModel with _$LlmModel {
  const factory LlmModel({
    required String platformModelName,
    @Default('') String vendor,
    @Default('') String description,
    @Default('') String icon,
    @Default(0) int sortOrder,
    String? capabilitiesJSON,
    String? kindsJSON,
    String? protocolsJSON,
    @Default(false) bool isFree,
    String? pricingSummary,
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default(<String>[])
    List<String> capabilityTags,
  }) = _LlmModel;

  factory LlmModel.fromJson(Map<String, dynamic> json) =>
      _$LlmModelFromJson(json);

  factory LlmModel.fromApi(Map<String, dynamic> json) {
    final capsJson = json['capabilitiesJSON'] as String?;
    final tags = <String>[];
    if (capsJson != null && capsJson.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(capsJson);
        if (decoded is Map) {
          decoded.forEach((k, v) {
            if (v == true) tags.add('$k');
          });
        } else if (decoded is List) {
          tags.addAll(decoded.map((e) => '$e'));
        }
      } catch (_) {
        if (capsJson.length < 80) tags.add(capsJson);
      }
    }

    String? pricingSummary;
    var isFree = false;
    final pricing = json['pricing'];
    if (pricing is Map) {
      isFree = pricing['isFree'] == true;
      final mode = '${pricing['mode'] ?? ''}';
      final input = pricing['inputUSDPerMTokens'];
      final output = pricing['outputUSDPerMTokens'];
      if (isFree) {
        pricingSummary = 'Free';
      } else if (input != null || output != null) {
        pricingSummary =
            'in ${input ?? '-'} / out ${output ?? '-'} USD/M${mode.isEmpty ? '' : ' ($mode)'}';
      } else if (mode.isNotEmpty) {
        pricingSummary = mode;
      }
    }

    return LlmModel(
      platformModelName: '${json['platformModelName'] ?? ''}',
      vendor: '${json['vendor'] ?? ''}',
      description: '${json['description'] ?? ''}',
      icon: '${json['icon'] ?? ''}',
      sortOrder: json['sortOrder'] is int
          ? json['sortOrder'] as int
          : int.tryParse('${json['sortOrder'] ?? 0}') ?? 0,
      capabilitiesJSON: capsJson,
      kindsJSON: json['kindsJSON'] as String?,
      protocolsJSON: json['protocolsJSON'] as String?,
      isFree: isFree,
      pricingSummary: pricingSummary,
      capabilityTags: tags,
    );
  }

  const LlmModel._();

  String get displayName {
    final name = platformModelName.trim();
    return name.isEmpty ? 'Unknown model' : name;
  }
}
