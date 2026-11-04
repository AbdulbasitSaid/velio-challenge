// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'error_envelope.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ErrorEnvelopeCWProxy {
  ErrorEnvelope error(ErrorEnvelopeError error);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ErrorEnvelope(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ErrorEnvelope(...).copyWith(id: 12, name: "My name")
  /// ```
  ErrorEnvelope call({ErrorEnvelopeError error});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfErrorEnvelope.copyWith(...)` or call `instanceOfErrorEnvelope.copyWith.fieldName(value)` for a single field.
class _$ErrorEnvelopeCWProxyImpl implements _$ErrorEnvelopeCWProxy {
  const _$ErrorEnvelopeCWProxyImpl(this._value);

  final ErrorEnvelope _value;

  @override
  ErrorEnvelope error(ErrorEnvelopeError error) => call(error: error);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ErrorEnvelope(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ErrorEnvelope(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ErrorEnvelope call({Object? error = const $CopyWithPlaceholder()}) {
    return ErrorEnvelope(
      error: error == const $CopyWithPlaceholder() || error == null
          ? _value.error
          // ignore: cast_nullable_to_non_nullable
          : error as ErrorEnvelopeError,
    );
  }
}

extension $ErrorEnvelopeCopyWith on ErrorEnvelope {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfErrorEnvelope.copyWith(...)` or `instanceOfErrorEnvelope.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ErrorEnvelopeCWProxy get copyWith => _$ErrorEnvelopeCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ErrorEnvelope _$ErrorEnvelopeFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ErrorEnvelope', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['error']);
      final val = ErrorEnvelope(
        error: $checkedConvert(
          'error',
          (v) => ErrorEnvelopeError.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ErrorEnvelopeToJson(ErrorEnvelope instance) =>
    <String, dynamic>{'error': instance.error.toJson()};
