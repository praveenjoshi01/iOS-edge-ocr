// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'image_input.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ImageInput {

 String get filePath; InputSource get source; String? get originalFileName;
/// Create a copy of ImageInput
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImageInputCopyWith<ImageInput> get copyWith => _$ImageInputCopyWithImpl<ImageInput>(this as ImageInput, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImageInput&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.source, source) || other.source == source)&&(identical(other.originalFileName, originalFileName) || other.originalFileName == originalFileName));
}


@override
int get hashCode => Object.hash(runtimeType,filePath,source,originalFileName);

@override
String toString() {
  return 'ImageInput(filePath: $filePath, source: $source, originalFileName: $originalFileName)';
}


}

/// @nodoc
abstract mixin class $ImageInputCopyWith<$Res>  {
  factory $ImageInputCopyWith(ImageInput value, $Res Function(ImageInput) _then) = _$ImageInputCopyWithImpl;
@useResult
$Res call({
 String filePath, InputSource source, String? originalFileName
});




}
/// @nodoc
class _$ImageInputCopyWithImpl<$Res>
    implements $ImageInputCopyWith<$Res> {
  _$ImageInputCopyWithImpl(this._self, this._then);

  final ImageInput _self;
  final $Res Function(ImageInput) _then;

/// Create a copy of ImageInput
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? filePath = null,Object? source = null,Object? originalFileName = freezed,}) {
  return _then(_self.copyWith(
filePath: null == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as InputSource,originalFileName: freezed == originalFileName ? _self.originalFileName : originalFileName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ImageInput].
extension ImageInputPatterns on ImageInput {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ImageInput value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ImageInput() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ImageInput value)  $default,){
final _that = this;
switch (_that) {
case _ImageInput():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ImageInput value)?  $default,){
final _that = this;
switch (_that) {
case _ImageInput() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String filePath,  InputSource source,  String? originalFileName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ImageInput() when $default != null:
return $default(_that.filePath,_that.source,_that.originalFileName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String filePath,  InputSource source,  String? originalFileName)  $default,) {final _that = this;
switch (_that) {
case _ImageInput():
return $default(_that.filePath,_that.source,_that.originalFileName);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String filePath,  InputSource source,  String? originalFileName)?  $default,) {final _that = this;
switch (_that) {
case _ImageInput() when $default != null:
return $default(_that.filePath,_that.source,_that.originalFileName);case _:
  return null;

}
}

}

/// @nodoc


class _ImageInput implements ImageInput {
  const _ImageInput({required this.filePath, required this.source, this.originalFileName});
  

@override final  String filePath;
@override final  InputSource source;
@override final  String? originalFileName;

/// Create a copy of ImageInput
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ImageInputCopyWith<_ImageInput> get copyWith => __$ImageInputCopyWithImpl<_ImageInput>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ImageInput&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.source, source) || other.source == source)&&(identical(other.originalFileName, originalFileName) || other.originalFileName == originalFileName));
}


@override
int get hashCode => Object.hash(runtimeType,filePath,source,originalFileName);

@override
String toString() {
  return 'ImageInput(filePath: $filePath, source: $source, originalFileName: $originalFileName)';
}


}

/// @nodoc
abstract mixin class _$ImageInputCopyWith<$Res> implements $ImageInputCopyWith<$Res> {
  factory _$ImageInputCopyWith(_ImageInput value, $Res Function(_ImageInput) _then) = __$ImageInputCopyWithImpl;
@override @useResult
$Res call({
 String filePath, InputSource source, String? originalFileName
});




}
/// @nodoc
class __$ImageInputCopyWithImpl<$Res>
    implements _$ImageInputCopyWith<$Res> {
  __$ImageInputCopyWithImpl(this._self, this._then);

  final _ImageInput _self;
  final $Res Function(_ImageInput) _then;

/// Create a copy of ImageInput
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? filePath = null,Object? source = null,Object? originalFileName = freezed,}) {
  return _then(_ImageInput(
filePath: null == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as InputSource,originalFileName: freezed == originalFileName ? _self.originalFileName : originalFileName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
