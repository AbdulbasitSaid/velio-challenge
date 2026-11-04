// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_state.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ActivityStateCWProxy {
  ActivityState id(String id);

  ActivityState spotsLeft(int spotsLeft);

  ActivityState version(int version);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ActivityState(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ActivityState(...).copyWith(id: 12, name: "My name")
  /// ```
  ActivityState call({String id, int spotsLeft, int version});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfActivityState.copyWith(...)` or call `instanceOfActivityState.copyWith.fieldName(value)` for a single field.
class _$ActivityStateCWProxyImpl implements _$ActivityStateCWProxy {
  const _$ActivityStateCWProxyImpl(this._value);

  final ActivityState _value;

  @override
  ActivityState id(String id) => call(id: id);

  @override
  ActivityState spotsLeft(int spotsLeft) => call(spotsLeft: spotsLeft);

  @override
  ActivityState version(int version) => call(version: version);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ActivityState(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ActivityState(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ActivityState call({
    Object? id = const $CopyWithPlaceholder(),
    Object? spotsLeft = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
  }) {
    return ActivityState(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      spotsLeft: spotsLeft == const $CopyWithPlaceholder() || spotsLeft == null
          ? _value.spotsLeft
          // ignore: cast_nullable_to_non_nullable
          : spotsLeft as int,
      version: version == const $CopyWithPlaceholder() || version == null
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as int,
    );
  }
}

extension $ActivityStateCopyWith on ActivityState {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfActivityState.copyWith(...)` or `instanceOfActivityState.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ActivityStateCWProxy get copyWith => _$ActivityStateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActivityState _$ActivityStateFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ActivityState', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['id', 'spotsLeft', 'version']);
      final val = ActivityState(
        id: $checkedConvert('id', (v) => v as String),
        spotsLeft: $checkedConvert('spotsLeft', (v) => (v as num).toInt()),
        version: $checkedConvert('version', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$ActivityStateToJson(ActivityState instance) =>
    <String, dynamic>{
      'id': instance.id,
      'spotsLeft': instance.spotsLeft,
      'version': instance.version,
    };
