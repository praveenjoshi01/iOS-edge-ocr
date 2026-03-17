// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ocr_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OcrResult {

 String get text; int get processingTimeMs; int get imageWidth; int get imageHeight;
/// Create a copy of OcrResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OcrResultCopyWith<OcrResult> get copyWith => _$OcrResultCopyWithImpl<OcrResult>(this as OcrResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OcrResult&&(identical(other.text, text) || other.text == text)&&(identical(other.processingTimeMs, processingTimeMs) || other.processingTimeMs == processingTimeMs)&&(identical(other.imageWidth, imageWidth) || other.imageWidth == imageWidth)&&(identical(other.imageHeight, imageHeight) || other.imageHeight == imageHeight));
}


@override
int get hashCode => Object.hash(runtimeType,text,processingTimeMs,imageWidth,imageHeight);

@override
String toString() {
  return 'OcrResult(text: $text, processingTimeMs: $processingTimeMs, imageWidth: $imageWidth, imageHeight: $imageHeight)';
}


}

/// @nodoc
abstract mixin class $OcrResultCopyWith<$Res>  {
  factory $OcrResultCopyWith(OcrResult value, $Res Function(OcrResult) _then) = _$OcrResultCopyWithImpl;
@useResult
$Res call({
 String text, int processingTimeMs, int imageWidth, int imageHeight
});




}
/// @nodoc
class _$OcrResultCopyWithImpl<$Res>
    implements $OcrResultCopyWith<$Res> {
  _$OcrResultCopyWithImpl(this._self, this._then);

  final OcrResult _self;
  final $Res Function(OcrResult) _then;

/// Create a copy of OcrResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = null,Object? processingTimeMs = null,Object? imageWidth = null,Object? imageHeight = null,}) {
  return _then(_self.copyWith(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,processingTimeMs: null == processingTimeMs ? _self.processingTimeMs : processingTimeMs // ignore: cast_nullable_to_non_nullable
as int,imageWidth: null == imageWidth ? _self.imageWidth : imageWidth // ignore: cast_nullable_to_non_nullable
as int,imageHeight: null == imageHeight ? _self.imageHeight : imageHeight // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [OcrResult].
extension OcrResultPatterns on OcrResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OcrResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OcrResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OcrResult value)  $default,){
final _that = this;
switch (_that) {
case _OcrResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OcrResult value)?  $default,){
final _that = this;
switch (_that) {
case _OcrResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String text,  int processingTimeMs,  int imageWidth,  int imageHeight)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OcrResult() when $default != null:
return $default(_that.text,_that.processingTimeMs,_that.imageWidth,_that.imageHeight);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String text,  int processingTimeMs,  int imageWidth,  int imageHeight)  $default,) {final _that = this;
switch (_that) {
case _OcrResult():
return $default(_that.text,_that.processingTimeMs,_that.imageWidth,_that.imageHeight);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String text,  int processingTimeMs,  int imageWidth,  int imageHeight)?  $default,) {final _that = this;
switch (_that) {
case _OcrResult() when $default != null:
return $default(_that.text,_that.processingTimeMs,_that.imageWidth,_that.imageHeight);case _:
  return null;

}
}

}

/// @nodoc


class _OcrResult implements OcrResult {
  const _OcrResult({required this.text, required this.processingTimeMs, required this.imageWidth, required this.imageHeight});
  

@override final  String text;
@override final  int processingTimeMs;
@override final  int imageWidth;
@override final  int imageHeight;

/// Create a copy of OcrResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OcrResultCopyWith<_OcrResult> get copyWith => __$OcrResultCopyWithImpl<_OcrResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OcrResult&&(identical(other.text, text) || other.text == text)&&(identical(other.processingTimeMs, processingTimeMs) || other.processingTimeMs == processingTimeMs)&&(identical(other.imageWidth, imageWidth) || other.imageWidth == imageWidth)&&(identical(other.imageHeight, imageHeight) || other.imageHeight == imageHeight));
}


@override
int get hashCode => Object.hash(runtimeType,text,processingTimeMs,imageWidth,imageHeight);

@override
String toString() {
  return 'OcrResult(text: $text, processingTimeMs: $processingTimeMs, imageWidth: $imageWidth, imageHeight: $imageHeight)';
}


}

/// @nodoc
abstract mixin class _$OcrResultCopyWith<$Res> implements $OcrResultCopyWith<$Res> {
  factory _$OcrResultCopyWith(_OcrResult value, $Res Function(_OcrResult) _then) = __$OcrResultCopyWithImpl;
@override @useResult
$Res call({
 String text, int processingTimeMs, int imageWidth, int imageHeight
});




}
/// @nodoc
class __$OcrResultCopyWithImpl<$Res>
    implements _$OcrResultCopyWith<$Res> {
  __$OcrResultCopyWithImpl(this._self, this._then);

  final _OcrResult _self;
  final $Res Function(_OcrResult) _then;

/// Create a copy of OcrResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,Object? processingTimeMs = null,Object? imageWidth = null,Object? imageHeight = null,}) {
  return _then(_OcrResult(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,processingTimeMs: null == processingTimeMs ? _self.processingTimeMs : processingTimeMs // ignore: cast_nullable_to_non_nullable
as int,imageWidth: null == imageWidth ? _self.imageWidth : imageWidth // ignore: cast_nullable_to_non_nullable
as int,imageHeight: null == imageHeight ? _self.imageHeight : imageHeight // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
