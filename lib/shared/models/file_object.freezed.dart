// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'file_object.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FileObject {

 String get fileID; String get fileName; String get mimeType; int get sizeBytes; String get status; String get fileCategory; String? get purpose; bool get processingReady; String get processingStatus; String get extractStatus; String get embedStatus; String? get processingErrorMessage;
/// Create a copy of FileObject
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FileObjectCopyWith<FileObject> get copyWith => _$FileObjectCopyWithImpl<FileObject>(this as FileObject, _$identity);

  /// Serializes this FileObject to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FileObject&&(identical(other.fileID, fileID) || other.fileID == fileID)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.status, status) || other.status == status)&&(identical(other.fileCategory, fileCategory) || other.fileCategory == fileCategory)&&(identical(other.purpose, purpose) || other.purpose == purpose)&&(identical(other.processingReady, processingReady) || other.processingReady == processingReady)&&(identical(other.processingStatus, processingStatus) || other.processingStatus == processingStatus)&&(identical(other.extractStatus, extractStatus) || other.extractStatus == extractStatus)&&(identical(other.embedStatus, embedStatus) || other.embedStatus == embedStatus)&&(identical(other.processingErrorMessage, processingErrorMessage) || other.processingErrorMessage == processingErrorMessage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fileID,fileName,mimeType,sizeBytes,status,fileCategory,purpose,processingReady,processingStatus,extractStatus,embedStatus,processingErrorMessage);

@override
String toString() {
  return 'FileObject(fileID: $fileID, fileName: $fileName, mimeType: $mimeType, sizeBytes: $sizeBytes, status: $status, fileCategory: $fileCategory, purpose: $purpose, processingReady: $processingReady, processingStatus: $processingStatus, extractStatus: $extractStatus, embedStatus: $embedStatus, processingErrorMessage: $processingErrorMessage)';
}


}

/// @nodoc
abstract mixin class $FileObjectCopyWith<$Res>  {
  factory $FileObjectCopyWith(FileObject value, $Res Function(FileObject) _then) = _$FileObjectCopyWithImpl;
@useResult
$Res call({
 String fileID, String fileName, String mimeType, int sizeBytes, String status, String fileCategory, String? purpose, bool processingReady, String processingStatus, String extractStatus, String embedStatus, String? processingErrorMessage
});




}
/// @nodoc
class _$FileObjectCopyWithImpl<$Res>
    implements $FileObjectCopyWith<$Res> {
  _$FileObjectCopyWithImpl(this._self, this._then);

  final FileObject _self;
  final $Res Function(FileObject) _then;

/// Create a copy of FileObject
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fileID = null,Object? fileName = null,Object? mimeType = null,Object? sizeBytes = null,Object? status = null,Object? fileCategory = null,Object? purpose = freezed,Object? processingReady = null,Object? processingStatus = null,Object? extractStatus = null,Object? embedStatus = null,Object? processingErrorMessage = freezed,}) {
  return _then(_self.copyWith(
fileID: null == fileID ? _self.fileID : fileID // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,fileCategory: null == fileCategory ? _self.fileCategory : fileCategory // ignore: cast_nullable_to_non_nullable
as String,purpose: freezed == purpose ? _self.purpose : purpose // ignore: cast_nullable_to_non_nullable
as String?,processingReady: null == processingReady ? _self.processingReady : processingReady // ignore: cast_nullable_to_non_nullable
as bool,processingStatus: null == processingStatus ? _self.processingStatus : processingStatus // ignore: cast_nullable_to_non_nullable
as String,extractStatus: null == extractStatus ? _self.extractStatus : extractStatus // ignore: cast_nullable_to_non_nullable
as String,embedStatus: null == embedStatus ? _self.embedStatus : embedStatus // ignore: cast_nullable_to_non_nullable
as String,processingErrorMessage: freezed == processingErrorMessage ? _self.processingErrorMessage : processingErrorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [FileObject].
extension FileObjectPatterns on FileObject {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FileObject value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FileObject() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FileObject value)  $default,){
final _that = this;
switch (_that) {
case _FileObject():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FileObject value)?  $default,){
final _that = this;
switch (_that) {
case _FileObject() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String fileID,  String fileName,  String mimeType,  int sizeBytes,  String status,  String fileCategory,  String? purpose,  bool processingReady,  String processingStatus,  String extractStatus,  String embedStatus,  String? processingErrorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FileObject() when $default != null:
return $default(_that.fileID,_that.fileName,_that.mimeType,_that.sizeBytes,_that.status,_that.fileCategory,_that.purpose,_that.processingReady,_that.processingStatus,_that.extractStatus,_that.embedStatus,_that.processingErrorMessage);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String fileID,  String fileName,  String mimeType,  int sizeBytes,  String status,  String fileCategory,  String? purpose,  bool processingReady,  String processingStatus,  String extractStatus,  String embedStatus,  String? processingErrorMessage)  $default,) {final _that = this;
switch (_that) {
case _FileObject():
return $default(_that.fileID,_that.fileName,_that.mimeType,_that.sizeBytes,_that.status,_that.fileCategory,_that.purpose,_that.processingReady,_that.processingStatus,_that.extractStatus,_that.embedStatus,_that.processingErrorMessage);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String fileID,  String fileName,  String mimeType,  int sizeBytes,  String status,  String fileCategory,  String? purpose,  bool processingReady,  String processingStatus,  String extractStatus,  String embedStatus,  String? processingErrorMessage)?  $default,) {final _that = this;
switch (_that) {
case _FileObject() when $default != null:
return $default(_that.fileID,_that.fileName,_that.mimeType,_that.sizeBytes,_that.status,_that.fileCategory,_that.purpose,_that.processingReady,_that.processingStatus,_that.extractStatus,_that.embedStatus,_that.processingErrorMessage);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FileObject extends FileObject {
  const _FileObject({required this.fileID, this.fileName = '', this.mimeType = '', this.sizeBytes = 0, this.status = '', this.fileCategory = '', this.purpose, this.processingReady = false, this.processingStatus = '', this.extractStatus = '', this.embedStatus = '', this.processingErrorMessage}): super._();
  factory _FileObject.fromJson(Map<String, dynamic> json) => _$FileObjectFromJson(json);

@override final  String fileID;
@override@JsonKey() final  String fileName;
@override@JsonKey() final  String mimeType;
@override@JsonKey() final  int sizeBytes;
@override@JsonKey() final  String status;
@override@JsonKey() final  String fileCategory;
@override final  String? purpose;
@override@JsonKey() final  bool processingReady;
@override@JsonKey() final  String processingStatus;
@override@JsonKey() final  String extractStatus;
@override@JsonKey() final  String embedStatus;
@override final  String? processingErrorMessage;

/// Create a copy of FileObject
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FileObjectCopyWith<_FileObject> get copyWith => __$FileObjectCopyWithImpl<_FileObject>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FileObjectToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FileObject&&(identical(other.fileID, fileID) || other.fileID == fileID)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.status, status) || other.status == status)&&(identical(other.fileCategory, fileCategory) || other.fileCategory == fileCategory)&&(identical(other.purpose, purpose) || other.purpose == purpose)&&(identical(other.processingReady, processingReady) || other.processingReady == processingReady)&&(identical(other.processingStatus, processingStatus) || other.processingStatus == processingStatus)&&(identical(other.extractStatus, extractStatus) || other.extractStatus == extractStatus)&&(identical(other.embedStatus, embedStatus) || other.embedStatus == embedStatus)&&(identical(other.processingErrorMessage, processingErrorMessage) || other.processingErrorMessage == processingErrorMessage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fileID,fileName,mimeType,sizeBytes,status,fileCategory,purpose,processingReady,processingStatus,extractStatus,embedStatus,processingErrorMessage);

@override
String toString() {
  return 'FileObject(fileID: $fileID, fileName: $fileName, mimeType: $mimeType, sizeBytes: $sizeBytes, status: $status, fileCategory: $fileCategory, purpose: $purpose, processingReady: $processingReady, processingStatus: $processingStatus, extractStatus: $extractStatus, embedStatus: $embedStatus, processingErrorMessage: $processingErrorMessage)';
}


}

/// @nodoc
abstract mixin class _$FileObjectCopyWith<$Res> implements $FileObjectCopyWith<$Res> {
  factory _$FileObjectCopyWith(_FileObject value, $Res Function(_FileObject) _then) = __$FileObjectCopyWithImpl;
@override @useResult
$Res call({
 String fileID, String fileName, String mimeType, int sizeBytes, String status, String fileCategory, String? purpose, bool processingReady, String processingStatus, String extractStatus, String embedStatus, String? processingErrorMessage
});




}
/// @nodoc
class __$FileObjectCopyWithImpl<$Res>
    implements _$FileObjectCopyWith<$Res> {
  __$FileObjectCopyWithImpl(this._self, this._then);

  final _FileObject _self;
  final $Res Function(_FileObject) _then;

/// Create a copy of FileObject
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fileID = null,Object? fileName = null,Object? mimeType = null,Object? sizeBytes = null,Object? status = null,Object? fileCategory = null,Object? purpose = freezed,Object? processingReady = null,Object? processingStatus = null,Object? extractStatus = null,Object? embedStatus = null,Object? processingErrorMessage = freezed,}) {
  return _then(_FileObject(
fileID: null == fileID ? _self.fileID : fileID // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,fileCategory: null == fileCategory ? _self.fileCategory : fileCategory // ignore: cast_nullable_to_non_nullable
as String,purpose: freezed == purpose ? _self.purpose : purpose // ignore: cast_nullable_to_non_nullable
as String?,processingReady: null == processingReady ? _self.processingReady : processingReady // ignore: cast_nullable_to_non_nullable
as bool,processingStatus: null == processingStatus ? _self.processingStatus : processingStatus // ignore: cast_nullable_to_non_nullable
as String,extractStatus: null == extractStatus ? _self.extractStatus : extractStatus // ignore: cast_nullable_to_non_nullable
as String,embedStatus: null == embedStatus ? _self.embedStatus : embedStatus // ignore: cast_nullable_to_non_nullable
as String,processingErrorMessage: freezed == processingErrorMessage ? _self.processingErrorMessage : processingErrorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
