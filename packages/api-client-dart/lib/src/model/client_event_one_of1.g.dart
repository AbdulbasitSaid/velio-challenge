// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_event_one_of1.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ClientEventOneOf1CWProxy {
  ClientEventOneOf1 name(ClientEventOneOf1NameEnum name);

  ClientEventOneOf1 metric(ClientEventOneOf1MetricEnum metric);

  ClientEventOneOf1 value(num value);

  ClientEventOneOf1 page(ClientEventOneOf1PageEnum page);

  ClientEventOneOf1 connection(ClientEventOneOf1ConnectionEnum? connection);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ClientEventOneOf1(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ClientEventOneOf1(...).copyWith(id: 12, name: "My name")
  /// ```
  ClientEventOneOf1 call({
    ClientEventOneOf1NameEnum name,
    ClientEventOneOf1MetricEnum metric,
    num value,
    ClientEventOneOf1PageEnum page,
    ClientEventOneOf1ConnectionEnum? connection,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfClientEventOneOf1.copyWith(...)` or call `instanceOfClientEventOneOf1.copyWith.fieldName(value)` for a single field.
class _$ClientEventOneOf1CWProxyImpl implements _$ClientEventOneOf1CWProxy {
  const _$ClientEventOneOf1CWProxyImpl(this._value);

  final ClientEventOneOf1 _value;

  @override
  ClientEventOneOf1 name(ClientEventOneOf1NameEnum name) => call(name: name);

  @override
  ClientEventOneOf1 metric(ClientEventOneOf1MetricEnum metric) =>
      call(metric: metric);

  @override
  ClientEventOneOf1 value(num value) => call(value: value);

  @override
  ClientEventOneOf1 page(ClientEventOneOf1PageEnum page) => call(page: page);

  @override
  ClientEventOneOf1 connection(ClientEventOneOf1ConnectionEnum? connection) =>
      call(connection: connection);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ClientEventOneOf1(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ClientEventOneOf1(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ClientEventOneOf1 call({
    Object? name = const $CopyWithPlaceholder(),
    Object? metric = const $CopyWithPlaceholder(),
    Object? value = const $CopyWithPlaceholder(),
    Object? page = const $CopyWithPlaceholder(),
    Object? connection = const $CopyWithPlaceholder(),
  }) {
    return ClientEventOneOf1(
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as ClientEventOneOf1NameEnum,
      metric: metric == const $CopyWithPlaceholder() || metric == null
          ? _value.metric
          // ignore: cast_nullable_to_non_nullable
          : metric as ClientEventOneOf1MetricEnum,
      value: value == const $CopyWithPlaceholder() || value == null
          ? _value.value
          // ignore: cast_nullable_to_non_nullable
          : value as num,
      page: page == const $CopyWithPlaceholder() || page == null
          ? _value.page
          // ignore: cast_nullable_to_non_nullable
          : page as ClientEventOneOf1PageEnum,
      connection: connection == const $CopyWithPlaceholder()
          ? _value.connection
          // ignore: cast_nullable_to_non_nullable
          : connection as ClientEventOneOf1ConnectionEnum?,
    );
  }
}

extension $ClientEventOneOf1CopyWith on ClientEventOneOf1 {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfClientEventOneOf1.copyWith(...)` or `instanceOfClientEventOneOf1.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ClientEventOneOf1CWProxy get copyWith =>
      _$ClientEventOneOf1CWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClientEventOneOf1 _$ClientEventOneOf1FromJson(Map<String, dynamic> json) =>
    $checkedCreate('ClientEventOneOf1', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['name', 'metric', 'value', 'page']);
      final val = ClientEventOneOf1(
        name: $checkedConvert(
          'name',
          (v) => $enumDecode(_$ClientEventOneOf1NameEnumEnumMap, v),
        ),
        metric: $checkedConvert(
          'metric',
          (v) => $enumDecode(_$ClientEventOneOf1MetricEnumEnumMap, v),
        ),
        value: $checkedConvert('value', (v) => v as num),
        page: $checkedConvert(
          'page',
          (v) => $enumDecode(_$ClientEventOneOf1PageEnumEnumMap, v),
        ),
        connection: $checkedConvert(
          'connection',
          (v) =>
              $enumDecodeNullable(_$ClientEventOneOf1ConnectionEnumEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ClientEventOneOf1ToJson(
  ClientEventOneOf1 instance,
) => <String, dynamic>{
  'name': _$ClientEventOneOf1NameEnumEnumMap[instance.name]!,
  'metric': _$ClientEventOneOf1MetricEnumEnumMap[instance.metric]!,
  'value': instance.value,
  'page': _$ClientEventOneOf1PageEnumEnumMap[instance.page]!,
  'connection': ?_$ClientEventOneOf1ConnectionEnumEnumMap[instance.connection],
};

const _$ClientEventOneOf1NameEnumEnumMap = {
  ClientEventOneOf1NameEnum.webVital: 'web_vital',
};

const _$ClientEventOneOf1MetricEnumEnumMap = {
  ClientEventOneOf1MetricEnum.FCP: 'FCP',
  ClientEventOneOf1MetricEnum.LCP: 'LCP',
  ClientEventOneOf1MetricEnum.TTFB: 'TTFB',
  ClientEventOneOf1MetricEnum.CLS: 'CLS',
  ClientEventOneOf1MetricEnum.INP: 'INP',
};

const _$ClientEventOneOf1PageEnumEnumMap = {
  ClientEventOneOf1PageEnum.activity: 'activity',
  ClientEventOneOf1PageEnum.invite: 'invite',
  ClientEventOneOf1PageEnum.community: 'community',
  ClientEventOneOf1PageEnum.other: 'other',
};

const _$ClientEventOneOf1ConnectionEnumEnumMap = {
  ClientEventOneOf1ConnectionEnum.slow2g: 'slow-2g',
  ClientEventOneOf1ConnectionEnum.n2g: '2g',
  ClientEventOneOf1ConnectionEnum.n3g: '3g',
  ClientEventOneOf1ConnectionEnum.n4g: '4g',
};
