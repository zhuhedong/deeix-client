// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'llm_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LlmModel {

 String get platformModelName; String get vendor; String get description; String get icon; int get sortOrder; String? get capabilitiesJSON; String? get kindsJSON; String? get protocolsJSON; bool get isFree; String? get pricingSummary;@JsonKey(includeFromJson: false, includeToJson: false) List<String> get capabilityTags;
/// Create a copy of LlmModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LlmModelCopyWith<LlmModel> get copyWith => _$LlmModelCopyWithImpl<LlmModel>(this as LlmModel, _$identity);

  /// Serializes this LlmModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LlmModel&&(identical(other.platformModelName, platformModelName) || other.platformModelName == platformModelName)&&(identical(other.vendor, vendor) || other.vendor == vendor)&&(identical(other.description, description) || other.description == description)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.capabilitiesJSON, capabilitiesJSON) || other.capabilitiesJSON == capabilitiesJSON)&&(identical(other.kindsJSON, kindsJSON) || other.kindsJSON == kindsJSON)&&(identical(other.protocolsJSON, protocolsJSON) || other.protocolsJSON == protocolsJSON)&&(identical(other.isFree, isFree) || other.isFree == isFree)&&(identical(other.pricingSummary, pricingSummary) || other.pricingSummary == pricingSummary)&&const DeepCollectionEquality().equals(other.capabilityTags, capabilityTags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,platformModelName,vendor,description,icon,sortOrder,capabilitiesJSON,kindsJSON,protocolsJSON,isFree,pricingSummary,const DeepCollectionEquality().hash(capabilityTags));

@override
String toString() {
  return 'LlmModel(platformModelName: $platformModelName, vendor: $vendor, description: $description, icon: $icon, sortOrder: $sortOrder, capabilitiesJSON: $capabilitiesJSON, kindsJSON: $kindsJSON, protocolsJSON: $protocolsJSON, isFree: $isFree, pricingSummary: $pricingSummary, capabilityTags: $capabilityTags)';
}


}

/// @nodoc
abstract mixin class $LlmModelCopyWith<$Res>  {
  factory $LlmModelCopyWith(LlmModel value, $Res Function(LlmModel) _then) = _$LlmModelCopyWithImpl;
@useResult
$Res call({
 String platformModelName, String vendor, String description, String icon, int sortOrder, String? capabilitiesJSON, String? kindsJSON, String? protocolsJSON, bool isFree, String? pricingSummary,@JsonKey(includeFromJson: false, includeToJson: false) List<String> capabilityTags
});




}
/// @nodoc
class _$LlmModelCopyWithImpl<$Res>
    implements $LlmModelCopyWith<$Res> {
  _$LlmModelCopyWithImpl(this._self, this._then);

  final LlmModel _self;
  final $Res Function(LlmModel) _then;

/// Create a copy of LlmModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? platformModelName = null,Object? vendor = null,Object? description = null,Object? icon = null,Object? sortOrder = null,Object? capabilitiesJSON = freezed,Object? kindsJSON = freezed,Object? protocolsJSON = freezed,Object? isFree = null,Object? pricingSummary = freezed,Object? capabilityTags = null,}) {
  return _then(_self.copyWith(
platformModelName: null == platformModelName ? _self.platformModelName : platformModelName // ignore: cast_nullable_to_non_nullable
as String,vendor: null == vendor ? _self.vendor : vendor // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,capabilitiesJSON: freezed == capabilitiesJSON ? _self.capabilitiesJSON : capabilitiesJSON // ignore: cast_nullable_to_non_nullable
as String?,kindsJSON: freezed == kindsJSON ? _self.kindsJSON : kindsJSON // ignore: cast_nullable_to_non_nullable
as String?,protocolsJSON: freezed == protocolsJSON ? _self.protocolsJSON : protocolsJSON // ignore: cast_nullable_to_non_nullable
as String?,isFree: null == isFree ? _self.isFree : isFree // ignore: cast_nullable_to_non_nullable
as bool,pricingSummary: freezed == pricingSummary ? _self.pricingSummary : pricingSummary // ignore: cast_nullable_to_non_nullable
as String?,capabilityTags: null == capabilityTags ? _self.capabilityTags : capabilityTags // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [LlmModel].
extension LlmModelPatterns on LlmModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LlmModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LlmModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LlmModel value)  $default,){
final _that = this;
switch (_that) {
case _LlmModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LlmModel value)?  $default,){
final _that = this;
switch (_that) {
case _LlmModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String platformModelName,  String vendor,  String description,  String icon,  int sortOrder,  String? capabilitiesJSON,  String? kindsJSON,  String? protocolsJSON,  bool isFree,  String? pricingSummary, @JsonKey(includeFromJson: false, includeToJson: false)  List<String> capabilityTags)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LlmModel() when $default != null:
return $default(_that.platformModelName,_that.vendor,_that.description,_that.icon,_that.sortOrder,_that.capabilitiesJSON,_that.kindsJSON,_that.protocolsJSON,_that.isFree,_that.pricingSummary,_that.capabilityTags);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String platformModelName,  String vendor,  String description,  String icon,  int sortOrder,  String? capabilitiesJSON,  String? kindsJSON,  String? protocolsJSON,  bool isFree,  String? pricingSummary, @JsonKey(includeFromJson: false, includeToJson: false)  List<String> capabilityTags)  $default,) {final _that = this;
switch (_that) {
case _LlmModel():
return $default(_that.platformModelName,_that.vendor,_that.description,_that.icon,_that.sortOrder,_that.capabilitiesJSON,_that.kindsJSON,_that.protocolsJSON,_that.isFree,_that.pricingSummary,_that.capabilityTags);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String platformModelName,  String vendor,  String description,  String icon,  int sortOrder,  String? capabilitiesJSON,  String? kindsJSON,  String? protocolsJSON,  bool isFree,  String? pricingSummary, @JsonKey(includeFromJson: false, includeToJson: false)  List<String> capabilityTags)?  $default,) {final _that = this;
switch (_that) {
case _LlmModel() when $default != null:
return $default(_that.platformModelName,_that.vendor,_that.description,_that.icon,_that.sortOrder,_that.capabilitiesJSON,_that.kindsJSON,_that.protocolsJSON,_that.isFree,_that.pricingSummary,_that.capabilityTags);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LlmModel extends LlmModel {
  const _LlmModel({required this.platformModelName, this.vendor = '', this.description = '', this.icon = '', this.sortOrder = 0, this.capabilitiesJSON, this.kindsJSON, this.protocolsJSON, this.isFree = false, this.pricingSummary, @JsonKey(includeFromJson: false, includeToJson: false) final  List<String> capabilityTags = const <String>[]}): _capabilityTags = capabilityTags,super._();
  factory _LlmModel.fromJson(Map<String, dynamic> json) => _$LlmModelFromJson(json);

@override final  String platformModelName;
@override@JsonKey() final  String vendor;
@override@JsonKey() final  String description;
@override@JsonKey() final  String icon;
@override@JsonKey() final  int sortOrder;
@override final  String? capabilitiesJSON;
@override final  String? kindsJSON;
@override final  String? protocolsJSON;
@override@JsonKey() final  bool isFree;
@override final  String? pricingSummary;
 final  List<String> _capabilityTags;
@override@JsonKey(includeFromJson: false, includeToJson: false) List<String> get capabilityTags {
  if (_capabilityTags is EqualUnmodifiableListView) return _capabilityTags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_capabilityTags);
}


/// Create a copy of LlmModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LlmModelCopyWith<_LlmModel> get copyWith => __$LlmModelCopyWithImpl<_LlmModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LlmModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LlmModel&&(identical(other.platformModelName, platformModelName) || other.platformModelName == platformModelName)&&(identical(other.vendor, vendor) || other.vendor == vendor)&&(identical(other.description, description) || other.description == description)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.capabilitiesJSON, capabilitiesJSON) || other.capabilitiesJSON == capabilitiesJSON)&&(identical(other.kindsJSON, kindsJSON) || other.kindsJSON == kindsJSON)&&(identical(other.protocolsJSON, protocolsJSON) || other.protocolsJSON == protocolsJSON)&&(identical(other.isFree, isFree) || other.isFree == isFree)&&(identical(other.pricingSummary, pricingSummary) || other.pricingSummary == pricingSummary)&&const DeepCollectionEquality().equals(other._capabilityTags, _capabilityTags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,platformModelName,vendor,description,icon,sortOrder,capabilitiesJSON,kindsJSON,protocolsJSON,isFree,pricingSummary,const DeepCollectionEquality().hash(_capabilityTags));

@override
String toString() {
  return 'LlmModel(platformModelName: $platformModelName, vendor: $vendor, description: $description, icon: $icon, sortOrder: $sortOrder, capabilitiesJSON: $capabilitiesJSON, kindsJSON: $kindsJSON, protocolsJSON: $protocolsJSON, isFree: $isFree, pricingSummary: $pricingSummary, capabilityTags: $capabilityTags)';
}


}

/// @nodoc
abstract mixin class _$LlmModelCopyWith<$Res> implements $LlmModelCopyWith<$Res> {
  factory _$LlmModelCopyWith(_LlmModel value, $Res Function(_LlmModel) _then) = __$LlmModelCopyWithImpl;
@override @useResult
$Res call({
 String platformModelName, String vendor, String description, String icon, int sortOrder, String? capabilitiesJSON, String? kindsJSON, String? protocolsJSON, bool isFree, String? pricingSummary,@JsonKey(includeFromJson: false, includeToJson: false) List<String> capabilityTags
});




}
/// @nodoc
class __$LlmModelCopyWithImpl<$Res>
    implements _$LlmModelCopyWith<$Res> {
  __$LlmModelCopyWithImpl(this._self, this._then);

  final _LlmModel _self;
  final $Res Function(_LlmModel) _then;

/// Create a copy of LlmModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? platformModelName = null,Object? vendor = null,Object? description = null,Object? icon = null,Object? sortOrder = null,Object? capabilitiesJSON = freezed,Object? kindsJSON = freezed,Object? protocolsJSON = freezed,Object? isFree = null,Object? pricingSummary = freezed,Object? capabilityTags = null,}) {
  return _then(_LlmModel(
platformModelName: null == platformModelName ? _self.platformModelName : platformModelName // ignore: cast_nullable_to_non_nullable
as String,vendor: null == vendor ? _self.vendor : vendor // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,capabilitiesJSON: freezed == capabilitiesJSON ? _self.capabilitiesJSON : capabilitiesJSON // ignore: cast_nullable_to_non_nullable
as String?,kindsJSON: freezed == kindsJSON ? _self.kindsJSON : kindsJSON // ignore: cast_nullable_to_non_nullable
as String?,protocolsJSON: freezed == protocolsJSON ? _self.protocolsJSON : protocolsJSON // ignore: cast_nullable_to_non_nullable
as String?,isFree: null == isFree ? _self.isFree : isFree // ignore: cast_nullable_to_non_nullable
as bool,pricingSummary: freezed == pricingSummary ? _self.pricingSummary : pricingSummary // ignore: cast_nullable_to_non_nullable
as String?,capabilityTags: null == capabilityTags ? _self._capabilityTags : capabilityTags // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
