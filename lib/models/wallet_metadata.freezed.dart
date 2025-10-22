// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wallet_metadata.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WalletMetadata {

/// Unique wallet identifier (derived from mnemonic hash)
 String get id;/// User-friendly wallet name
 String get name;/// Network this wallet operates on (mainnet/regtest)
 String get network;// Stored as string for JSON serialization
/// When the wallet was created
 DateTime get createdAt;/// Whether user has confirmed they backed up the mnemonic
/// This flag is set to true only after user completes backup verification
 bool get isBackedUp;/// Last time this wallet was used
 DateTime? get lastUsedAt;
/// Create a copy of WalletMetadata
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalletMetadataCopyWith<WalletMetadata> get copyWith => _$WalletMetadataCopyWithImpl<WalletMetadata>(this as WalletMetadata, _$identity);

  /// Serializes this WalletMetadata to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalletMetadata&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.network, network) || other.network == network)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.isBackedUp, isBackedUp) || other.isBackedUp == isBackedUp)&&(identical(other.lastUsedAt, lastUsedAt) || other.lastUsedAt == lastUsedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,network,createdAt,isBackedUp,lastUsedAt);

@override
String toString() {
  return 'WalletMetadata(id: $id, name: $name, network: $network, createdAt: $createdAt, isBackedUp: $isBackedUp, lastUsedAt: $lastUsedAt)';
}


}

/// @nodoc
abstract mixin class $WalletMetadataCopyWith<$Res>  {
  factory $WalletMetadataCopyWith(WalletMetadata value, $Res Function(WalletMetadata) _then) = _$WalletMetadataCopyWithImpl;
@useResult
$Res call({
 String id, String name, String network, DateTime createdAt, bool isBackedUp, DateTime? lastUsedAt
});




}
/// @nodoc
class _$WalletMetadataCopyWithImpl<$Res>
    implements $WalletMetadataCopyWith<$Res> {
  _$WalletMetadataCopyWithImpl(this._self, this._then);

  final WalletMetadata _self;
  final $Res Function(WalletMetadata) _then;

/// Create a copy of WalletMetadata
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? network = null,Object? createdAt = null,Object? isBackedUp = null,Object? lastUsedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,network: null == network ? _self.network : network // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,isBackedUp: null == isBackedUp ? _self.isBackedUp : isBackedUp // ignore: cast_nullable_to_non_nullable
as bool,lastUsedAt: freezed == lastUsedAt ? _self.lastUsedAt : lastUsedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [WalletMetadata].
extension WalletMetadataPatterns on WalletMetadata {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WalletMetadata value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WalletMetadata() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WalletMetadata value)  $default,){
final _that = this;
switch (_that) {
case _WalletMetadata():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WalletMetadata value)?  $default,){
final _that = this;
switch (_that) {
case _WalletMetadata() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String network,  DateTime createdAt,  bool isBackedUp,  DateTime? lastUsedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WalletMetadata() when $default != null:
return $default(_that.id,_that.name,_that.network,_that.createdAt,_that.isBackedUp,_that.lastUsedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String network,  DateTime createdAt,  bool isBackedUp,  DateTime? lastUsedAt)  $default,) {final _that = this;
switch (_that) {
case _WalletMetadata():
return $default(_that.id,_that.name,_that.network,_that.createdAt,_that.isBackedUp,_that.lastUsedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String network,  DateTime createdAt,  bool isBackedUp,  DateTime? lastUsedAt)?  $default,) {final _that = this;
switch (_that) {
case _WalletMetadata() when $default != null:
return $default(_that.id,_that.name,_that.network,_that.createdAt,_that.isBackedUp,_that.lastUsedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WalletMetadata implements WalletMetadata {
  const _WalletMetadata({required this.id, required this.name, required this.network, required this.createdAt, this.isBackedUp = false, this.lastUsedAt});
  factory _WalletMetadata.fromJson(Map<String, dynamic> json) => _$WalletMetadataFromJson(json);

/// Unique wallet identifier (derived from mnemonic hash)
@override final  String id;
/// User-friendly wallet name
@override final  String name;
/// Network this wallet operates on (mainnet/regtest)
@override final  String network;
// Stored as string for JSON serialization
/// When the wallet was created
@override final  DateTime createdAt;
/// Whether user has confirmed they backed up the mnemonic
/// This flag is set to true only after user completes backup verification
@override@JsonKey() final  bool isBackedUp;
/// Last time this wallet was used
@override final  DateTime? lastUsedAt;

/// Create a copy of WalletMetadata
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WalletMetadataCopyWith<_WalletMetadata> get copyWith => __$WalletMetadataCopyWithImpl<_WalletMetadata>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WalletMetadataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WalletMetadata&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.network, network) || other.network == network)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.isBackedUp, isBackedUp) || other.isBackedUp == isBackedUp)&&(identical(other.lastUsedAt, lastUsedAt) || other.lastUsedAt == lastUsedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,network,createdAt,isBackedUp,lastUsedAt);

@override
String toString() {
  return 'WalletMetadata(id: $id, name: $name, network: $network, createdAt: $createdAt, isBackedUp: $isBackedUp, lastUsedAt: $lastUsedAt)';
}


}

/// @nodoc
abstract mixin class _$WalletMetadataCopyWith<$Res> implements $WalletMetadataCopyWith<$Res> {
  factory _$WalletMetadataCopyWith(_WalletMetadata value, $Res Function(_WalletMetadata) _then) = __$WalletMetadataCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String network, DateTime createdAt, bool isBackedUp, DateTime? lastUsedAt
});




}
/// @nodoc
class __$WalletMetadataCopyWithImpl<$Res>
    implements _$WalletMetadataCopyWith<$Res> {
  __$WalletMetadataCopyWithImpl(this._self, this._then);

  final _WalletMetadata _self;
  final $Res Function(_WalletMetadata) _then;

/// Create a copy of WalletMetadata
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? network = null,Object? createdAt = null,Object? isBackedUp = null,Object? lastUsedAt = freezed,}) {
  return _then(_WalletMetadata(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,network: null == network ? _self.network : network // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,isBackedUp: null == isBackedUp ? _self.isBackedUp : isBackedUp // ignore: cast_nullable_to_non_nullable
as bool,lastUsedAt: freezed == lastUsedAt ? _self.lastUsedAt : lastUsedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
