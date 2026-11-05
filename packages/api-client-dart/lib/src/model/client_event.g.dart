// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_event.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ClientEventCWProxy {
  ClientEvent name(ClientEventNameEnum name);

  ClientEvent activityId(String activityId);

  ClientEvent platform(ClientEventPlatformEnum? platform);

  ClientEvent metric(ClientEventMetricEnum metric);

  ClientEvent value(num value);

  ClientEvent page(ClientEventPageEnum page);

  ClientEvent connection(ClientEventConnectionEnum? connection);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ClientEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ClientEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  ClientEvent call({
    ClientEventNameEnum name,
    String activityId,
    ClientEventPlatformEnum? platform,
    ClientEventMetricEnum metric,
    num value,
    ClientEventPageEnum page,
    ClientEventConnectionEnum? connection,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfClientEvent.copyWith(...)` or call `instanceOfClientEvent.copyWith.fieldName(value)` for a single field.
class _$ClientEventCWProxyImpl implements _$ClientEventCWProxy {
  const _$ClientEventCWProxyImpl(this._value);

  final ClientEvent _value;

  @override
  ClientEvent name(ClientEventNameEnum name) => call(name: name);

  @override
  ClientEvent activityId(String activityId) => call(activityId: activityId);

  @override
  ClientEvent platform(ClientEventPlatformEnum? platform) =>
      call(platform: platform);

  @override
  ClientEvent metric(ClientEventMetricEnum metric) => call(metric: metric);

  @override
  ClientEvent value(num value) => call(value: value);

  @override
  ClientEvent page(ClientEventPageEnum page) => call(page: page);

  @override
  ClientEvent connection(ClientEventConnectionEnum? connection) =>
      call(connection: connection);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ClientEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ClientEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ClientEvent call({
    Object? name = const $CopyWithPlaceholder(),
    Object? activityId = const $CopyWithPlaceholder(),
    Object? platform = const $CopyWithPlaceholder(),
    Object? metric = const $CopyWithPlaceholder(),
    Object? value = const $CopyWithPlaceholder(),
    Object? page = const $CopyWithPlaceholder(),
    Object? connection = const $CopyWithPlaceholder(),
  }) {
    return ClientEvent(
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as ClientEventNameEnum,
      activityId:
          activityId == const $CopyWithPlaceholder() || activityId == null
          ? _value.activityId
          // ignore: cast_nullable_to_non_nullable
          : activityId as String,
      platform: platform == const $CopyWithPlaceholder()
          ? _value.platform
          // ignore: cast_nullable_to_non_nullable
          : platform as ClientEventPlatformEnum?,
      metric: metric == const $CopyWithPlaceholder() || metric == null
          ? _value.metric
          // ignore: cast_nullable_to_non_nullable
          : metric as ClientEventMetricEnum,
      value: value == const $CopyWithPlaceholder() || value == null
          ? _value.value
          // ignore: cast_nullable_to_non_nullable
          : value as num,
      page: page == const $CopyWithPlaceholder() || page == null
          ? _value.page
          // ignore: cast_nullable_to_non_nullable
          : page as ClientEventPageEnum,
      connection: connection == const $CopyWithPlaceholder()
          ? _value.connection
          // ignore: cast_nullable_to_non_nullable
          : connection as ClientEventConnectionEnum?,
    );
  }
}

extension $ClientEventCopyWith on ClientEvent {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfClientEvent.copyWith(...)` or `instanceOfClientEvent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ClientEventCWProxy get copyWith => _$ClientEventCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClientEvent _$ClientEventFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ClientEvent', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['name', 'activityId', 'metric', 'value', 'page'],
      );
      final val = ClientEvent(
        name: $checkedConvert(
          'name',
          (v) => $enumDecode(_$ClientEventNameEnumEnumMap, v),
        ),
        activityId: $checkedConvert('activityId', (v) => v as String),
        platform: $checkedConvert(
          'platform',
          (v) => $enumDecodeNullable(_$ClientEventPlatformEnumEnumMap, v),
        ),
        metric: $checkedConvert(
          'metric',
          (v) => $enumDecode(_$ClientEventMetricEnumEnumMap, v),
        ),
        value: $checkedConvert('value', (v) => v as num),
        page: $checkedConvert(
          'page',
          (v) => $enumDecode(_$ClientEventPageEnumEnumMap, v),
        ),
        connection: $checkedConvert(
          'connection',
          (v) => $enumDecodeNullable(_$ClientEventConnectionEnumEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ClientEventToJson(ClientEvent instance) =>
    <String, dynamic>{
      'name': _$ClientEventNameEnumEnumMap[instance.name]!,
      'activityId': instance.activityId,
      'platform': ?_$ClientEventPlatformEnumEnumMap[instance.platform],
      'metric': _$ClientEventMetricEnumEnumMap[instance.metric]!,
      'value': instance.value,
      'page': _$ClientEventPageEnumEnumMap[instance.page]!,
      'connection': ?_$ClientEventConnectionEnumEnumMap[instance.connection],
    };

const _$ClientEventNameEnumEnumMap = {
  ClientEventNameEnum.webVital: 'web_vital',
};

const _$ClientEventPlatformEnumEnumMap = {
  ClientEventPlatformEnum.web: 'web',
  ClientEventPlatformEnum.ios: 'ios',
  ClientEventPlatformEnum.android: 'android',
};

const _$ClientEventMetricEnumEnumMap = {
  ClientEventMetricEnum.FCP: 'FCP',
  ClientEventMetricEnum.LCP: 'LCP',
  ClientEventMetricEnum.TTFB: 'TTFB',
  ClientEventMetricEnum.CLS: 'CLS',
  ClientEventMetricEnum.INP: 'INP',
};

const _$ClientEventPageEnumEnumMap = {
  ClientEventPageEnum.activity: 'activity',
  ClientEventPageEnum.invite: 'invite',
  ClientEventPageEnum.community: 'community',
  ClientEventPageEnum.other: 'other',
};

const _$ClientEventConnectionEnumEnumMap = {
  ClientEventConnectionEnum.slow2g: 'slow-2g',
  ClientEventConnectionEnum.n2g: '2g',
  ClientEventConnectionEnum.n3g: '3g',
  ClientEventConnectionEnum.n4g: '4g',
};
