// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_object.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FileObject _$FileObjectFromJson(Map<String, dynamic> json) => _FileObject(
  fileID: json['fileID'] as String,
  fileName: json['fileName'] as String? ?? '',
  mimeType: json['mimeType'] as String? ?? '',
  sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
  status: json['status'] as String? ?? '',
  fileCategory: json['fileCategory'] as String? ?? '',
  purpose: json['purpose'] as String?,
  processingReady: json['processingReady'] as bool? ?? false,
  processingStatus: json['processingStatus'] as String? ?? '',
  extractStatus: json['extractStatus'] as String? ?? '',
  embedStatus: json['embedStatus'] as String? ?? '',
  processingErrorMessage: json['processingErrorMessage'] as String?,
);

Map<String, dynamic> _$FileObjectToJson(_FileObject instance) =>
    <String, dynamic>{
      'fileID': instance.fileID,
      'fileName': instance.fileName,
      'mimeType': instance.mimeType,
      'sizeBytes': instance.sizeBytes,
      'status': instance.status,
      'fileCategory': instance.fileCategory,
      'purpose': instance.purpose,
      'processingReady': instance.processingReady,
      'processingStatus': instance.processingStatus,
      'extractStatus': instance.extractStatus,
      'embedStatus': instance.embedStatus,
      'processingErrorMessage': instance.processingErrorMessage,
    };
