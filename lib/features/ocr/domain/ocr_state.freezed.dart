// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ocr_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OcrState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OcrState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OcrState()';
}


}

/// @nodoc
class $OcrStateCopyWith<$Res>  {
$OcrStateCopyWith(OcrState _, $Res Function(OcrState) __);
}


/// Adds pattern-matching-related methods to [OcrState].
extension OcrStatePatterns on OcrState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( OcrStateIdle value)?  idle,TResult Function( OcrStatePickingImage value)?  pickingImage,TResult Function( OcrStatePreprocessing value)?  preprocessing,TResult Function( OcrStateInferring value)?  inferring,TResult Function( OcrStateComplete value)?  complete,TResult Function( OcrStateError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case OcrStateIdle() when idle != null:
return idle(_that);case OcrStatePickingImage() when pickingImage != null:
return pickingImage(_that);case OcrStatePreprocessing() when preprocessing != null:
return preprocessing(_that);case OcrStateInferring() when inferring != null:
return inferring(_that);case OcrStateComplete() when complete != null:
return complete(_that);case OcrStateError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( OcrStateIdle value)  idle,required TResult Function( OcrStatePickingImage value)  pickingImage,required TResult Function( OcrStatePreprocessing value)  preprocessing,required TResult Function( OcrStateInferring value)  inferring,required TResult Function( OcrStateComplete value)  complete,required TResult Function( OcrStateError value)  error,}){
final _that = this;
switch (_that) {
case OcrStateIdle():
return idle(_that);case OcrStatePickingImage():
return pickingImage(_that);case OcrStatePreprocessing():
return preprocessing(_that);case OcrStateInferring():
return inferring(_that);case OcrStateComplete():
return complete(_that);case OcrStateError():
return error(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( OcrStateIdle value)?  idle,TResult? Function( OcrStatePickingImage value)?  pickingImage,TResult? Function( OcrStatePreprocessing value)?  preprocessing,TResult? Function( OcrStateInferring value)?  inferring,TResult? Function( OcrStateComplete value)?  complete,TResult? Function( OcrStateError value)?  error,}){
final _that = this;
switch (_that) {
case OcrStateIdle() when idle != null:
return idle(_that);case OcrStatePickingImage() when pickingImage != null:
return pickingImage(_that);case OcrStatePreprocessing() when preprocessing != null:
return preprocessing(_that);case OcrStateInferring() when inferring != null:
return inferring(_that);case OcrStateComplete() when complete != null:
return complete(_that);case OcrStateError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function()?  pickingImage,TResult Function()?  preprocessing,TResult Function()?  inferring,TResult Function( OcrResult result)?  complete,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case OcrStateIdle() when idle != null:
return idle();case OcrStatePickingImage() when pickingImage != null:
return pickingImage();case OcrStatePreprocessing() when preprocessing != null:
return preprocessing();case OcrStateInferring() when inferring != null:
return inferring();case OcrStateComplete() when complete != null:
return complete(_that.result);case OcrStateError() when error != null:
return error(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function()  pickingImage,required TResult Function()  preprocessing,required TResult Function()  inferring,required TResult Function( OcrResult result)  complete,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case OcrStateIdle():
return idle();case OcrStatePickingImage():
return pickingImage();case OcrStatePreprocessing():
return preprocessing();case OcrStateInferring():
return inferring();case OcrStateComplete():
return complete(_that.result);case OcrStateError():
return error(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function()?  pickingImage,TResult? Function()?  preprocessing,TResult? Function()?  inferring,TResult? Function( OcrResult result)?  complete,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case OcrStateIdle() when idle != null:
return idle();case OcrStatePickingImage() when pickingImage != null:
return pickingImage();case OcrStatePreprocessing() when preprocessing != null:
return preprocessing();case OcrStateInferring() when inferring != null:
return inferring();case OcrStateComplete() when complete != null:
return complete(_that.result);case OcrStateError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class OcrStateIdle implements OcrState {
  const OcrStateIdle();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OcrStateIdle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OcrState.idle()';
}


}




/// @nodoc


class OcrStatePickingImage implements OcrState {
  const OcrStatePickingImage();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OcrStatePickingImage);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OcrState.pickingImage()';
}


}




/// @nodoc


class OcrStatePreprocessing implements OcrState {
  const OcrStatePreprocessing();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OcrStatePreprocessing);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OcrState.preprocessing()';
}


}




/// @nodoc


class OcrStateInferring implements OcrState {
  const OcrStateInferring();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OcrStateInferring);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OcrState.inferring()';
}


}




/// @nodoc


class OcrStateComplete implements OcrState {
  const OcrStateComplete(this.result);
  

 final  OcrResult result;

/// Create a copy of OcrState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OcrStateCompleteCopyWith<OcrStateComplete> get copyWith => _$OcrStateCompleteCopyWithImpl<OcrStateComplete>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OcrStateComplete&&(identical(other.result, result) || other.result == result));
}


@override
int get hashCode => Object.hash(runtimeType,result);

@override
String toString() {
  return 'OcrState.complete(result: $result)';
}


}

/// @nodoc
abstract mixin class $OcrStateCompleteCopyWith<$Res> implements $OcrStateCopyWith<$Res> {
  factory $OcrStateCompleteCopyWith(OcrStateComplete value, $Res Function(OcrStateComplete) _then) = _$OcrStateCompleteCopyWithImpl;
@useResult
$Res call({
 OcrResult result
});


$OcrResultCopyWith<$Res> get result;

}
/// @nodoc
class _$OcrStateCompleteCopyWithImpl<$Res>
    implements $OcrStateCompleteCopyWith<$Res> {
  _$OcrStateCompleteCopyWithImpl(this._self, this._then);

  final OcrStateComplete _self;
  final $Res Function(OcrStateComplete) _then;

/// Create a copy of OcrState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? result = null,}) {
  return _then(OcrStateComplete(
null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as OcrResult,
  ));
}

/// Create a copy of OcrState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OcrResultCopyWith<$Res> get result {
  
  return $OcrResultCopyWith<$Res>(_self.result, (value) {
    return _then(_self.copyWith(result: value));
  });
}
}

/// @nodoc


class OcrStateError implements OcrState {
  const OcrStateError(this.message);
  

 final  String message;

/// Create a copy of OcrState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OcrStateErrorCopyWith<OcrStateError> get copyWith => _$OcrStateErrorCopyWithImpl<OcrStateError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OcrStateError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'OcrState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $OcrStateErrorCopyWith<$Res> implements $OcrStateCopyWith<$Res> {
  factory $OcrStateErrorCopyWith(OcrStateError value, $Res Function(OcrStateError) _then) = _$OcrStateErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$OcrStateErrorCopyWithImpl<$Res>
    implements $OcrStateErrorCopyWith<$Res> {
  _$OcrStateErrorCopyWithImpl(this._self, this._then);

  final OcrStateError _self;
  final $Res Function(OcrStateError) _then;

/// Create a copy of OcrState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(OcrStateError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
