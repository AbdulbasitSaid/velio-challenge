//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:velio_api/src/model/client_event_one_of.dart';
import 'package:velio_api/src/model/client_event_one_of1.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'client_event.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ClientEvent {
  /// Returns a new [ClientEvent] instance.
  ClientEvent({

    required  this.name,

    required  this.activityId,

     this.platform,

    required  this.metric,

    required  this.value,

    required  this.page,

     this.connection,
  });

  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final ClientEventNameEnum name;



  @JsonKey(
    
    name: r'activityId',
    required: true,
    includeIfNull: false,
  )


  final String activityId;



  @JsonKey(
    
    name: r'platform',
    required: false,
    includeIfNull: false,
  )


  final ClientEventPlatformEnum? platform;



  @JsonKey(
    
    name: r'metric',
    required: true,
    includeIfNull: false,
  )


  final ClientEventMetricEnum metric;



          // minimum: 0
          // maximum: 600000
  @JsonKey(
    
    name: r'value',
    required: true,
    includeIfNull: false,
  )


  final num value;



  @JsonKey(
    
    name: r'page',
    required: true,
    includeIfNull: false,
  )


  final ClientEventPageEnum page;



  @JsonKey(
    
    name: r'connection',
    required: false,
    includeIfNull: false,
  )


  final ClientEventConnectionEnum? connection;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ClientEvent &&
      other.name == name &&
      other.activityId == activityId &&
      other.platform == platform &&
      other.metric == metric &&
      other.value == value &&
      other.page == page &&
      other.connection == connection;

    @override
    int get hashCode =>
        name.hashCode +
        activityId.hashCode +
        platform.hashCode +
        metric.hashCode +
        value.hashCode +
        page.hashCode +
        connection.hashCode;

  factory ClientEvent.fromJson(Map<String, dynamic> json) => _$ClientEventFromJson(json);

  Map<String, dynamic> toJson() => _$ClientEventToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

enum ClientEventNameEnum {
@JsonValue(r'web_vital')
webVital(r'web_vital');

const ClientEventNameEnum(this.value);

final String value;

@override
String toString() => value;
}


enum ClientEventPlatformEnum {
@JsonValue(r'web')
web(r'web'),
@JsonValue(r'ios')
ios(r'ios'),
@JsonValue(r'android')
android(r'android');

const ClientEventPlatformEnum(this.value);

final String value;

@override
String toString() => value;
}


enum ClientEventMetricEnum {
@JsonValue(r'FCP')
FCP(r'FCP'),
@JsonValue(r'LCP')
LCP(r'LCP'),
@JsonValue(r'TTFB')
TTFB(r'TTFB'),
@JsonValue(r'CLS')
CLS(r'CLS'),
@JsonValue(r'INP')
INP(r'INP');

const ClientEventMetricEnum(this.value);

final String value;

@override
String toString() => value;
}


enum ClientEventPageEnum {
@JsonValue(r'activity')
activity(r'activity'),
@JsonValue(r'invite')
invite(r'invite'),
@JsonValue(r'community')
community(r'community'),
@JsonValue(r'other')
other(r'other');

const ClientEventPageEnum(this.value);

final String value;

@override
String toString() => value;
}


enum ClientEventConnectionEnum {
@JsonValue(r'slow-2g')
slow2g(r'slow-2g'),
@JsonValue(r'2g')
n2g(r'2g'),
@JsonValue(r'3g')
n3g(r'3g'),
@JsonValue(r'4g')
n4g(r'4g');

const ClientEventConnectionEnum(this.value);

final String value;

@override
String toString() => value;
}


