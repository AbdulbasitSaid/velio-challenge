// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SessionResponseCWProxy {
  SessionResponse user(MemberPerson user);

  SessionResponse token(String? token);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SessionResponse(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SessionResponse(...).copyWith(id: 12, name: "My name")
  /// ```
  SessionResponse call({MemberPerson user, String? token});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSessionResponse.copyWith(...)` or call `instanceOfSessionResponse.copyWith.fieldName(value)` for a single field.
class _$SessionResponseCWProxyImpl implements _$SessionResponseCWProxy {
  const _$SessionResponseCWProxyImpl(this._value);

  final SessionResponse _value;

  @override
  SessionResponse user(MemberPerson user) => call(user: user);

  @override
  SessionResponse token(String? token) => call(token: token);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SessionResponse(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SessionResponse(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SessionResponse call({
    Object? user = const $CopyWithPlaceholder(),
    Object? token = const $CopyWithPlaceholder(),
  }) {
    return SessionResponse(
      user: user == const $CopyWithPlaceholder() || user == null
          ? _value.user
          // ignore: cast_nullable_to_non_nullable
          : user as MemberPerson,
      token: token == const $CopyWithPlaceholder()
          ? _value.token
          // ignore: cast_nullable_to_non_nullable
          : token as String?,
    );
  }
}

extension $SessionResponseCopyWith on SessionResponse {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSessionResponse.copyWith(...)` or `instanceOfSessionResponse.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SessionResponseCWProxy get copyWith => _$SessionResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SessionResponse _$SessionResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SessionResponse', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['user']);
      final val = SessionResponse(
        user: $checkedConvert(
          'user',
          (v) => MemberPerson.fromJson(v as Map<String, dynamic>),
        ),
        token: $checkedConvert('token', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$SessionResponseToJson(SessionResponse instance) =>
    <String, dynamic>{'user': instance.user.toJson(), 'token': ?instance.token};
