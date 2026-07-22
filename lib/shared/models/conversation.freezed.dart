// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'conversation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Conversation {

/// API path id — ConversationResponse.publicID
 String get publicID; String? get title; String? get model; String? get status; bool get isStarred; int? get messageCount; DateTime? get updatedAt; DateTime? get createdAt; String? get projectID; String? get projectName;
/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversationCopyWith<Conversation> get copyWith => _$ConversationCopyWithImpl<Conversation>(this as Conversation, _$identity);

  /// Serializes this Conversation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Conversation&&(identical(other.publicID, publicID) || other.publicID == publicID)&&(identical(other.title, title) || other.title == title)&&(identical(other.model, model) || other.model == model)&&(identical(other.status, status) || other.status == status)&&(identical(other.isStarred, isStarred) || other.isStarred == isStarred)&&(identical(other.messageCount, messageCount) || other.messageCount == messageCount)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.projectID, projectID) || other.projectID == projectID)&&(identical(other.projectName, projectName) || other.projectName == projectName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,publicID,title,model,status,isStarred,messageCount,updatedAt,createdAt,projectID,projectName);

@override
String toString() {
  return 'Conversation(publicID: $publicID, title: $title, model: $model, status: $status, isStarred: $isStarred, messageCount: $messageCount, updatedAt: $updatedAt, createdAt: $createdAt, projectID: $projectID, projectName: $projectName)';
}


}

/// @nodoc
abstract mixin class $ConversationCopyWith<$Res>  {
  factory $ConversationCopyWith(Conversation value, $Res Function(Conversation) _then) = _$ConversationCopyWithImpl;
@useResult
$Res call({
 String publicID, String? title, String? model, String? status, bool isStarred, int? messageCount, DateTime? updatedAt, DateTime? createdAt, String? projectID, String? projectName
});




}
/// @nodoc
class _$ConversationCopyWithImpl<$Res>
    implements $ConversationCopyWith<$Res> {
  _$ConversationCopyWithImpl(this._self, this._then);

  final Conversation _self;
  final $Res Function(Conversation) _then;

/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? publicID = null,Object? title = freezed,Object? model = freezed,Object? status = freezed,Object? isStarred = null,Object? messageCount = freezed,Object? updatedAt = freezed,Object? createdAt = freezed,Object? projectID = freezed,Object? projectName = freezed,}) {
  return _then(_self.copyWith(
publicID: null == publicID ? _self.publicID : publicID // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,isStarred: null == isStarred ? _self.isStarred : isStarred // ignore: cast_nullable_to_non_nullable
as bool,messageCount: freezed == messageCount ? _self.messageCount : messageCount // ignore: cast_nullable_to_non_nullable
as int?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,projectID: freezed == projectID ? _self.projectID : projectID // ignore: cast_nullable_to_non_nullable
as String?,projectName: freezed == projectName ? _self.projectName : projectName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Conversation].
extension ConversationPatterns on Conversation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Conversation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Conversation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Conversation value)  $default,){
final _that = this;
switch (_that) {
case _Conversation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Conversation value)?  $default,){
final _that = this;
switch (_that) {
case _Conversation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String publicID,  String? title,  String? model,  String? status,  bool isStarred,  int? messageCount,  DateTime? updatedAt,  DateTime? createdAt,  String? projectID,  String? projectName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Conversation() when $default != null:
return $default(_that.publicID,_that.title,_that.model,_that.status,_that.isStarred,_that.messageCount,_that.updatedAt,_that.createdAt,_that.projectID,_that.projectName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String publicID,  String? title,  String? model,  String? status,  bool isStarred,  int? messageCount,  DateTime? updatedAt,  DateTime? createdAt,  String? projectID,  String? projectName)  $default,) {final _that = this;
switch (_that) {
case _Conversation():
return $default(_that.publicID,_that.title,_that.model,_that.status,_that.isStarred,_that.messageCount,_that.updatedAt,_that.createdAt,_that.projectID,_that.projectName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String publicID,  String? title,  String? model,  String? status,  bool isStarred,  int? messageCount,  DateTime? updatedAt,  DateTime? createdAt,  String? projectID,  String? projectName)?  $default,) {final _that = this;
switch (_that) {
case _Conversation() when $default != null:
return $default(_that.publicID,_that.title,_that.model,_that.status,_that.isStarred,_that.messageCount,_that.updatedAt,_that.createdAt,_that.projectID,_that.projectName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Conversation extends Conversation {
  const _Conversation({required this.publicID, this.title, this.model, this.status, this.isStarred = false, this.messageCount, this.updatedAt, this.createdAt, this.projectID, this.projectName}): super._();
  factory _Conversation.fromJson(Map<String, dynamic> json) => _$ConversationFromJson(json);

/// API path id — ConversationResponse.publicID
@override final  String publicID;
@override final  String? title;
@override final  String? model;
@override final  String? status;
@override@JsonKey() final  bool isStarred;
@override final  int? messageCount;
@override final  DateTime? updatedAt;
@override final  DateTime? createdAt;
@override final  String? projectID;
@override final  String? projectName;

/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversationCopyWith<_Conversation> get copyWith => __$ConversationCopyWithImpl<_Conversation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ConversationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Conversation&&(identical(other.publicID, publicID) || other.publicID == publicID)&&(identical(other.title, title) || other.title == title)&&(identical(other.model, model) || other.model == model)&&(identical(other.status, status) || other.status == status)&&(identical(other.isStarred, isStarred) || other.isStarred == isStarred)&&(identical(other.messageCount, messageCount) || other.messageCount == messageCount)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.projectID, projectID) || other.projectID == projectID)&&(identical(other.projectName, projectName) || other.projectName == projectName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,publicID,title,model,status,isStarred,messageCount,updatedAt,createdAt,projectID,projectName);

@override
String toString() {
  return 'Conversation(publicID: $publicID, title: $title, model: $model, status: $status, isStarred: $isStarred, messageCount: $messageCount, updatedAt: $updatedAt, createdAt: $createdAt, projectID: $projectID, projectName: $projectName)';
}


}

/// @nodoc
abstract mixin class _$ConversationCopyWith<$Res> implements $ConversationCopyWith<$Res> {
  factory _$ConversationCopyWith(_Conversation value, $Res Function(_Conversation) _then) = __$ConversationCopyWithImpl;
@override @useResult
$Res call({
 String publicID, String? title, String? model, String? status, bool isStarred, int? messageCount, DateTime? updatedAt, DateTime? createdAt, String? projectID, String? projectName
});




}
/// @nodoc
class __$ConversationCopyWithImpl<$Res>
    implements _$ConversationCopyWith<$Res> {
  __$ConversationCopyWithImpl(this._self, this._then);

  final _Conversation _self;
  final $Res Function(_Conversation) _then;

/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? publicID = null,Object? title = freezed,Object? model = freezed,Object? status = freezed,Object? isStarred = null,Object? messageCount = freezed,Object? updatedAt = freezed,Object? createdAt = freezed,Object? projectID = freezed,Object? projectName = freezed,}) {
  return _then(_Conversation(
publicID: null == publicID ? _self.publicID : publicID // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,model: freezed == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,isStarred: null == isStarred ? _self.isStarred : isStarred // ignore: cast_nullable_to_non_nullable
as bool,messageCount: freezed == messageCount ? _self.messageCount : messageCount // ignore: cast_nullable_to_non_nullable
as int?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,projectID: freezed == projectID ? _self.projectID : projectID // ignore: cast_nullable_to_non_nullable
as String?,projectName: freezed == projectName ? _self.projectName : projectName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
