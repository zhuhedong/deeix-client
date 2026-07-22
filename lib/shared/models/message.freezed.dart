// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChatMessage {

 String get id; int? get serverMessageID; MessageRole get role; String get content; String get contentType; String? get runID; String? get status; String? get platformModelName; DateTime? get createdAt; bool get isStreaming; String? get error; String get thinking; String? get processStatus; String? get toolSummary; String? get myFeedback;/// Branch tree: parent user/assistant publicID.
 String? get parentPublicID;/// Branch source (e.g. regenerated-from) publicID.
 String? get sourcePublicID;/// `default` | `retry` | `edit`
 String? get branchReason;/// Compact RAG / retrieval summary for the process panel.
 String? get ragSummary;/// File OCR / embedding progress note from stream events.
 String? get fileProcMessage;@JsonKey(includeFromJson: false, includeToJson: false) List<String> get ragSources;@JsonKey(includeFromJson: false, includeToJson: false) List<MessageAttachment> get attachments;
/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatMessageCopyWith<ChatMessage> get copyWith => _$ChatMessageCopyWithImpl<ChatMessage>(this as ChatMessage, _$identity);

  /// Serializes this ChatMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.serverMessageID, serverMessageID) || other.serverMessageID == serverMessageID)&&(identical(other.role, role) || other.role == role)&&(identical(other.content, content) || other.content == content)&&(identical(other.contentType, contentType) || other.contentType == contentType)&&(identical(other.runID, runID) || other.runID == runID)&&(identical(other.status, status) || other.status == status)&&(identical(other.platformModelName, platformModelName) || other.platformModelName == platformModelName)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.isStreaming, isStreaming) || other.isStreaming == isStreaming)&&(identical(other.error, error) || other.error == error)&&(identical(other.thinking, thinking) || other.thinking == thinking)&&(identical(other.processStatus, processStatus) || other.processStatus == processStatus)&&(identical(other.toolSummary, toolSummary) || other.toolSummary == toolSummary)&&(identical(other.myFeedback, myFeedback) || other.myFeedback == myFeedback)&&(identical(other.parentPublicID, parentPublicID) || other.parentPublicID == parentPublicID)&&(identical(other.sourcePublicID, sourcePublicID) || other.sourcePublicID == sourcePublicID)&&(identical(other.branchReason, branchReason) || other.branchReason == branchReason)&&(identical(other.ragSummary, ragSummary) || other.ragSummary == ragSummary)&&(identical(other.fileProcMessage, fileProcMessage) || other.fileProcMessage == fileProcMessage)&&const DeepCollectionEquality().equals(other.ragSources, ragSources)&&const DeepCollectionEquality().equals(other.attachments, attachments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,serverMessageID,role,content,contentType,runID,status,platformModelName,createdAt,isStreaming,error,thinking,processStatus,toolSummary,myFeedback,parentPublicID,sourcePublicID,branchReason,ragSummary,fileProcMessage,const DeepCollectionEquality().hash(ragSources),const DeepCollectionEquality().hash(attachments)]);

@override
String toString() {
  return 'ChatMessage(id: $id, serverMessageID: $serverMessageID, role: $role, content: $content, contentType: $contentType, runID: $runID, status: $status, platformModelName: $platformModelName, createdAt: $createdAt, isStreaming: $isStreaming, error: $error, thinking: $thinking, processStatus: $processStatus, toolSummary: $toolSummary, myFeedback: $myFeedback, parentPublicID: $parentPublicID, sourcePublicID: $sourcePublicID, branchReason: $branchReason, ragSummary: $ragSummary, fileProcMessage: $fileProcMessage, ragSources: $ragSources, attachments: $attachments)';
}


}

/// @nodoc
abstract mixin class $ChatMessageCopyWith<$Res>  {
  factory $ChatMessageCopyWith(ChatMessage value, $Res Function(ChatMessage) _then) = _$ChatMessageCopyWithImpl;
@useResult
$Res call({
 String id, int? serverMessageID, MessageRole role, String content, String contentType, String? runID, String? status, String? platformModelName, DateTime? createdAt, bool isStreaming, String? error, String thinking, String? processStatus, String? toolSummary, String? myFeedback, String? parentPublicID, String? sourcePublicID, String? branchReason, String? ragSummary, String? fileProcMessage,@JsonKey(includeFromJson: false, includeToJson: false) List<String> ragSources,@JsonKey(includeFromJson: false, includeToJson: false) List<MessageAttachment> attachments
});




}
/// @nodoc
class _$ChatMessageCopyWithImpl<$Res>
    implements $ChatMessageCopyWith<$Res> {
  _$ChatMessageCopyWithImpl(this._self, this._then);

  final ChatMessage _self;
  final $Res Function(ChatMessage) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? serverMessageID = freezed,Object? role = null,Object? content = null,Object? contentType = null,Object? runID = freezed,Object? status = freezed,Object? platformModelName = freezed,Object? createdAt = freezed,Object? isStreaming = null,Object? error = freezed,Object? thinking = null,Object? processStatus = freezed,Object? toolSummary = freezed,Object? myFeedback = freezed,Object? parentPublicID = freezed,Object? sourcePublicID = freezed,Object? branchReason = freezed,Object? ragSummary = freezed,Object? fileProcMessage = freezed,Object? ragSources = null,Object? attachments = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,serverMessageID: freezed == serverMessageID ? _self.serverMessageID : serverMessageID // ignore: cast_nullable_to_non_nullable
as int?,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as MessageRole,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,contentType: null == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String,runID: freezed == runID ? _self.runID : runID // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,platformModelName: freezed == platformModelName ? _self.platformModelName : platformModelName // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isStreaming: null == isStreaming ? _self.isStreaming : isStreaming // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,thinking: null == thinking ? _self.thinking : thinking // ignore: cast_nullable_to_non_nullable
as String,processStatus: freezed == processStatus ? _self.processStatus : processStatus // ignore: cast_nullable_to_non_nullable
as String?,toolSummary: freezed == toolSummary ? _self.toolSummary : toolSummary // ignore: cast_nullable_to_non_nullable
as String?,myFeedback: freezed == myFeedback ? _self.myFeedback : myFeedback // ignore: cast_nullable_to_non_nullable
as String?,parentPublicID: freezed == parentPublicID ? _self.parentPublicID : parentPublicID // ignore: cast_nullable_to_non_nullable
as String?,sourcePublicID: freezed == sourcePublicID ? _self.sourcePublicID : sourcePublicID // ignore: cast_nullable_to_non_nullable
as String?,branchReason: freezed == branchReason ? _self.branchReason : branchReason // ignore: cast_nullable_to_non_nullable
as String?,ragSummary: freezed == ragSummary ? _self.ragSummary : ragSummary // ignore: cast_nullable_to_non_nullable
as String?,fileProcMessage: freezed == fileProcMessage ? _self.fileProcMessage : fileProcMessage // ignore: cast_nullable_to_non_nullable
as String?,ragSources: null == ragSources ? _self.ragSources : ragSources // ignore: cast_nullable_to_non_nullable
as List<String>,attachments: null == attachments ? _self.attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<MessageAttachment>,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatMessage].
extension ChatMessagePatterns on ChatMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatMessage value)  $default,){
final _that = this;
switch (_that) {
case _ChatMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatMessage value)?  $default,){
final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int? serverMessageID,  MessageRole role,  String content,  String contentType,  String? runID,  String? status,  String? platformModelName,  DateTime? createdAt,  bool isStreaming,  String? error,  String thinking,  String? processStatus,  String? toolSummary,  String? myFeedback,  String? parentPublicID,  String? sourcePublicID,  String? branchReason,  String? ragSummary,  String? fileProcMessage, @JsonKey(includeFromJson: false, includeToJson: false)  List<String> ragSources, @JsonKey(includeFromJson: false, includeToJson: false)  List<MessageAttachment> attachments)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
return $default(_that.id,_that.serverMessageID,_that.role,_that.content,_that.contentType,_that.runID,_that.status,_that.platformModelName,_that.createdAt,_that.isStreaming,_that.error,_that.thinking,_that.processStatus,_that.toolSummary,_that.myFeedback,_that.parentPublicID,_that.sourcePublicID,_that.branchReason,_that.ragSummary,_that.fileProcMessage,_that.ragSources,_that.attachments);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int? serverMessageID,  MessageRole role,  String content,  String contentType,  String? runID,  String? status,  String? platformModelName,  DateTime? createdAt,  bool isStreaming,  String? error,  String thinking,  String? processStatus,  String? toolSummary,  String? myFeedback,  String? parentPublicID,  String? sourcePublicID,  String? branchReason,  String? ragSummary,  String? fileProcMessage, @JsonKey(includeFromJson: false, includeToJson: false)  List<String> ragSources, @JsonKey(includeFromJson: false, includeToJson: false)  List<MessageAttachment> attachments)  $default,) {final _that = this;
switch (_that) {
case _ChatMessage():
return $default(_that.id,_that.serverMessageID,_that.role,_that.content,_that.contentType,_that.runID,_that.status,_that.platformModelName,_that.createdAt,_that.isStreaming,_that.error,_that.thinking,_that.processStatus,_that.toolSummary,_that.myFeedback,_that.parentPublicID,_that.sourcePublicID,_that.branchReason,_that.ragSummary,_that.fileProcMessage,_that.ragSources,_that.attachments);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int? serverMessageID,  MessageRole role,  String content,  String contentType,  String? runID,  String? status,  String? platformModelName,  DateTime? createdAt,  bool isStreaming,  String? error,  String thinking,  String? processStatus,  String? toolSummary,  String? myFeedback,  String? parentPublicID,  String? sourcePublicID,  String? branchReason,  String? ragSummary,  String? fileProcMessage, @JsonKey(includeFromJson: false, includeToJson: false)  List<String> ragSources, @JsonKey(includeFromJson: false, includeToJson: false)  List<MessageAttachment> attachments)?  $default,) {final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
return $default(_that.id,_that.serverMessageID,_that.role,_that.content,_that.contentType,_that.runID,_that.status,_that.platformModelName,_that.createdAt,_that.isStreaming,_that.error,_that.thinking,_that.processStatus,_that.toolSummary,_that.myFeedback,_that.parentPublicID,_that.sourcePublicID,_that.branchReason,_that.ragSummary,_that.fileProcMessage,_that.ragSources,_that.attachments);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatMessage implements ChatMessage {
  const _ChatMessage({required this.id, this.serverMessageID, required this.role, this.content = '', this.contentType = 'text', this.runID, this.status, this.platformModelName, this.createdAt, this.isStreaming = false, this.error, this.thinking = '', this.processStatus, this.toolSummary, this.myFeedback, this.parentPublicID, this.sourcePublicID, this.branchReason, this.ragSummary, this.fileProcMessage, @JsonKey(includeFromJson: false, includeToJson: false) final  List<String> ragSources = const <String>[], @JsonKey(includeFromJson: false, includeToJson: false) final  List<MessageAttachment> attachments = const <MessageAttachment>[]}): _ragSources = ragSources,_attachments = attachments;
  factory _ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);

@override final  String id;
@override final  int? serverMessageID;
@override final  MessageRole role;
@override@JsonKey() final  String content;
@override@JsonKey() final  String contentType;
@override final  String? runID;
@override final  String? status;
@override final  String? platformModelName;
@override final  DateTime? createdAt;
@override@JsonKey() final  bool isStreaming;
@override final  String? error;
@override@JsonKey() final  String thinking;
@override final  String? processStatus;
@override final  String? toolSummary;
@override final  String? myFeedback;
/// Branch tree: parent user/assistant publicID.
@override final  String? parentPublicID;
/// Branch source (e.g. regenerated-from) publicID.
@override final  String? sourcePublicID;
/// `default` | `retry` | `edit`
@override final  String? branchReason;
/// Compact RAG / retrieval summary for the process panel.
@override final  String? ragSummary;
/// File OCR / embedding progress note from stream events.
@override final  String? fileProcMessage;
 final  List<String> _ragSources;
@override@JsonKey(includeFromJson: false, includeToJson: false) List<String> get ragSources {
  if (_ragSources is EqualUnmodifiableListView) return _ragSources;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ragSources);
}

 final  List<MessageAttachment> _attachments;
@override@JsonKey(includeFromJson: false, includeToJson: false) List<MessageAttachment> get attachments {
  if (_attachments is EqualUnmodifiableListView) return _attachments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_attachments);
}


/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatMessageCopyWith<_ChatMessage> get copyWith => __$ChatMessageCopyWithImpl<_ChatMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.serverMessageID, serverMessageID) || other.serverMessageID == serverMessageID)&&(identical(other.role, role) || other.role == role)&&(identical(other.content, content) || other.content == content)&&(identical(other.contentType, contentType) || other.contentType == contentType)&&(identical(other.runID, runID) || other.runID == runID)&&(identical(other.status, status) || other.status == status)&&(identical(other.platformModelName, platformModelName) || other.platformModelName == platformModelName)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.isStreaming, isStreaming) || other.isStreaming == isStreaming)&&(identical(other.error, error) || other.error == error)&&(identical(other.thinking, thinking) || other.thinking == thinking)&&(identical(other.processStatus, processStatus) || other.processStatus == processStatus)&&(identical(other.toolSummary, toolSummary) || other.toolSummary == toolSummary)&&(identical(other.myFeedback, myFeedback) || other.myFeedback == myFeedback)&&(identical(other.parentPublicID, parentPublicID) || other.parentPublicID == parentPublicID)&&(identical(other.sourcePublicID, sourcePublicID) || other.sourcePublicID == sourcePublicID)&&(identical(other.branchReason, branchReason) || other.branchReason == branchReason)&&(identical(other.ragSummary, ragSummary) || other.ragSummary == ragSummary)&&(identical(other.fileProcMessage, fileProcMessage) || other.fileProcMessage == fileProcMessage)&&const DeepCollectionEquality().equals(other._ragSources, _ragSources)&&const DeepCollectionEquality().equals(other._attachments, _attachments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,serverMessageID,role,content,contentType,runID,status,platformModelName,createdAt,isStreaming,error,thinking,processStatus,toolSummary,myFeedback,parentPublicID,sourcePublicID,branchReason,ragSummary,fileProcMessage,const DeepCollectionEquality().hash(_ragSources),const DeepCollectionEquality().hash(_attachments)]);

@override
String toString() {
  return 'ChatMessage(id: $id, serverMessageID: $serverMessageID, role: $role, content: $content, contentType: $contentType, runID: $runID, status: $status, platformModelName: $platformModelName, createdAt: $createdAt, isStreaming: $isStreaming, error: $error, thinking: $thinking, processStatus: $processStatus, toolSummary: $toolSummary, myFeedback: $myFeedback, parentPublicID: $parentPublicID, sourcePublicID: $sourcePublicID, branchReason: $branchReason, ragSummary: $ragSummary, fileProcMessage: $fileProcMessage, ragSources: $ragSources, attachments: $attachments)';
}


}

/// @nodoc
abstract mixin class _$ChatMessageCopyWith<$Res> implements $ChatMessageCopyWith<$Res> {
  factory _$ChatMessageCopyWith(_ChatMessage value, $Res Function(_ChatMessage) _then) = __$ChatMessageCopyWithImpl;
@override @useResult
$Res call({
 String id, int? serverMessageID, MessageRole role, String content, String contentType, String? runID, String? status, String? platformModelName, DateTime? createdAt, bool isStreaming, String? error, String thinking, String? processStatus, String? toolSummary, String? myFeedback, String? parentPublicID, String? sourcePublicID, String? branchReason, String? ragSummary, String? fileProcMessage,@JsonKey(includeFromJson: false, includeToJson: false) List<String> ragSources,@JsonKey(includeFromJson: false, includeToJson: false) List<MessageAttachment> attachments
});




}
/// @nodoc
class __$ChatMessageCopyWithImpl<$Res>
    implements _$ChatMessageCopyWith<$Res> {
  __$ChatMessageCopyWithImpl(this._self, this._then);

  final _ChatMessage _self;
  final $Res Function(_ChatMessage) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? serverMessageID = freezed,Object? role = null,Object? content = null,Object? contentType = null,Object? runID = freezed,Object? status = freezed,Object? platformModelName = freezed,Object? createdAt = freezed,Object? isStreaming = null,Object? error = freezed,Object? thinking = null,Object? processStatus = freezed,Object? toolSummary = freezed,Object? myFeedback = freezed,Object? parentPublicID = freezed,Object? sourcePublicID = freezed,Object? branchReason = freezed,Object? ragSummary = freezed,Object? fileProcMessage = freezed,Object? ragSources = null,Object? attachments = null,}) {
  return _then(_ChatMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,serverMessageID: freezed == serverMessageID ? _self.serverMessageID : serverMessageID // ignore: cast_nullable_to_non_nullable
as int?,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as MessageRole,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,contentType: null == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String,runID: freezed == runID ? _self.runID : runID // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,platformModelName: freezed == platformModelName ? _self.platformModelName : platformModelName // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isStreaming: null == isStreaming ? _self.isStreaming : isStreaming // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,thinking: null == thinking ? _self.thinking : thinking // ignore: cast_nullable_to_non_nullable
as String,processStatus: freezed == processStatus ? _self.processStatus : processStatus // ignore: cast_nullable_to_non_nullable
as String?,toolSummary: freezed == toolSummary ? _self.toolSummary : toolSummary // ignore: cast_nullable_to_non_nullable
as String?,myFeedback: freezed == myFeedback ? _self.myFeedback : myFeedback // ignore: cast_nullable_to_non_nullable
as String?,parentPublicID: freezed == parentPublicID ? _self.parentPublicID : parentPublicID // ignore: cast_nullable_to_non_nullable
as String?,sourcePublicID: freezed == sourcePublicID ? _self.sourcePublicID : sourcePublicID // ignore: cast_nullable_to_non_nullable
as String?,branchReason: freezed == branchReason ? _self.branchReason : branchReason // ignore: cast_nullable_to_non_nullable
as String?,ragSummary: freezed == ragSummary ? _self.ragSummary : ragSummary // ignore: cast_nullable_to_non_nullable
as String?,fileProcMessage: freezed == fileProcMessage ? _self.fileProcMessage : fileProcMessage // ignore: cast_nullable_to_non_nullable
as String?,ragSources: null == ragSources ? _self._ragSources : ragSources // ignore: cast_nullable_to_non_nullable
as List<String>,attachments: null == attachments ? _self._attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<MessageAttachment>,
  ));
}


}

// dart format on
