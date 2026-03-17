// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'runtime_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RuntimeState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RuntimeState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RuntimeState()';
}


}

/// @nodoc
class $RuntimeStateCopyWith<$Res>  {
$RuntimeStateCopyWith(RuntimeState _, $Res Function(RuntimeState) __);
}


/// Adds pattern-matching-related methods to [RuntimeState].
extension RuntimeStatePatterns on RuntimeState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( RuntimeStateUninitialized value)?  uninitialized,TResult Function( RuntimeStateDownloading value)?  downloading,TResult Function( RuntimeStateInitializing value)?  initializing,TResult Function( RuntimeStateReady value)?  ready,TResult Function( RuntimeStateError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case RuntimeStateUninitialized() when uninitialized != null:
return uninitialized(_that);case RuntimeStateDownloading() when downloading != null:
return downloading(_that);case RuntimeStateInitializing() when initializing != null:
return initializing(_that);case RuntimeStateReady() when ready != null:
return ready(_that);case RuntimeStateError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( RuntimeStateUninitialized value)  uninitialized,required TResult Function( RuntimeStateDownloading value)  downloading,required TResult Function( RuntimeStateInitializing value)  initializing,required TResult Function( RuntimeStateReady value)  ready,required TResult Function( RuntimeStateError value)  error,}){
final _that = this;
switch (_that) {
case RuntimeStateUninitialized():
return uninitialized(_that);case RuntimeStateDownloading():
return downloading(_that);case RuntimeStateInitializing():
return initializing(_that);case RuntimeStateReady():
return ready(_that);case RuntimeStateError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( RuntimeStateUninitialized value)?  uninitialized,TResult? Function( RuntimeStateDownloading value)?  downloading,TResult? Function( RuntimeStateInitializing value)?  initializing,TResult? Function( RuntimeStateReady value)?  ready,TResult? Function( RuntimeStateError value)?  error,}){
final _that = this;
switch (_that) {
case RuntimeStateUninitialized() when uninitialized != null:
return uninitialized(_that);case RuntimeStateDownloading() when downloading != null:
return downloading(_that);case RuntimeStateInitializing() when initializing != null:
return initializing(_that);case RuntimeStateReady() when ready != null:
return ready(_that);case RuntimeStateError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  uninitialized,TResult Function( double progress,  int downloadedBytes,  int totalBytes)?  downloading,TResult Function()?  initializing,TResult Function()?  ready,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RuntimeStateUninitialized() when uninitialized != null:
return uninitialized();case RuntimeStateDownloading() when downloading != null:
return downloading(_that.progress,_that.downloadedBytes,_that.totalBytes);case RuntimeStateInitializing() when initializing != null:
return initializing();case RuntimeStateReady() when ready != null:
return ready();case RuntimeStateError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  uninitialized,required TResult Function( double progress,  int downloadedBytes,  int totalBytes)  downloading,required TResult Function()  initializing,required TResult Function()  ready,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case RuntimeStateUninitialized():
return uninitialized();case RuntimeStateDownloading():
return downloading(_that.progress,_that.downloadedBytes,_that.totalBytes);case RuntimeStateInitializing():
return initializing();case RuntimeStateReady():
return ready();case RuntimeStateError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  uninitialized,TResult? Function( double progress,  int downloadedBytes,  int totalBytes)?  downloading,TResult? Function()?  initializing,TResult? Function()?  ready,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case RuntimeStateUninitialized() when uninitialized != null:
return uninitialized();case RuntimeStateDownloading() when downloading != null:
return downloading(_that.progress,_that.downloadedBytes,_that.totalBytes);case RuntimeStateInitializing() when initializing != null:
return initializing();case RuntimeStateReady() when ready != null:
return ready();case RuntimeStateError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class RuntimeStateUninitialized implements RuntimeState {
  const RuntimeStateUninitialized();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RuntimeStateUninitialized);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RuntimeState.uninitialized()';
}


}




/// @nodoc


class RuntimeStateDownloading implements RuntimeState {
  const RuntimeStateDownloading({required this.progress, required this.downloadedBytes, required this.totalBytes});
  

 final  double progress;
 final  int downloadedBytes;
 final  int totalBytes;

/// Create a copy of RuntimeState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RuntimeStateDownloadingCopyWith<RuntimeStateDownloading> get copyWith => _$RuntimeStateDownloadingCopyWithImpl<RuntimeStateDownloading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RuntimeStateDownloading&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.downloadedBytes, downloadedBytes) || other.downloadedBytes == downloadedBytes)&&(identical(other.totalBytes, totalBytes) || other.totalBytes == totalBytes));
}


@override
int get hashCode => Object.hash(runtimeType,progress,downloadedBytes,totalBytes);

@override
String toString() {
  return 'RuntimeState.downloading(progress: $progress, downloadedBytes: $downloadedBytes, totalBytes: $totalBytes)';
}


}

/// @nodoc
abstract mixin class $RuntimeStateDownloadingCopyWith<$Res> implements $RuntimeStateCopyWith<$Res> {
  factory $RuntimeStateDownloadingCopyWith(RuntimeStateDownloading value, $Res Function(RuntimeStateDownloading) _then) = _$RuntimeStateDownloadingCopyWithImpl;
@useResult
$Res call({
 double progress, int downloadedBytes, int totalBytes
});




}
/// @nodoc
class _$RuntimeStateDownloadingCopyWithImpl<$Res>
    implements $RuntimeStateDownloadingCopyWith<$Res> {
  _$RuntimeStateDownloadingCopyWithImpl(this._self, this._then);

  final RuntimeStateDownloading _self;
  final $Res Function(RuntimeStateDownloading) _then;

/// Create a copy of RuntimeState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? progress = null,Object? downloadedBytes = null,Object? totalBytes = null,}) {
  return _then(RuntimeStateDownloading(
progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,downloadedBytes: null == downloadedBytes ? _self.downloadedBytes : downloadedBytes // ignore: cast_nullable_to_non_nullable
as int,totalBytes: null == totalBytes ? _self.totalBytes : totalBytes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class RuntimeStateInitializing implements RuntimeState {
  const RuntimeStateInitializing();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RuntimeStateInitializing);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RuntimeState.initializing()';
}


}




/// @nodoc


class RuntimeStateReady implements RuntimeState {
  const RuntimeStateReady();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RuntimeStateReady);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RuntimeState.ready()';
}


}




/// @nodoc


class RuntimeStateError implements RuntimeState {
  const RuntimeStateError(this.message);
  

 final  String message;

/// Create a copy of RuntimeState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RuntimeStateErrorCopyWith<RuntimeStateError> get copyWith => _$RuntimeStateErrorCopyWithImpl<RuntimeStateError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RuntimeStateError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'RuntimeState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $RuntimeStateErrorCopyWith<$Res> implements $RuntimeStateCopyWith<$Res> {
  factory $RuntimeStateErrorCopyWith(RuntimeStateError value, $Res Function(RuntimeStateError) _then) = _$RuntimeStateErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$RuntimeStateErrorCopyWithImpl<$Res>
    implements $RuntimeStateErrorCopyWith<$Res> {
  _$RuntimeStateErrorCopyWithImpl(this._self, this._then);

  final RuntimeStateError _self;
  final $Res Function(RuntimeStateError) _then;

/// Create a copy of RuntimeState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(RuntimeStateError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
