//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'client_event_one_of1.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ClientEventOneOf1 {
  /// Returns a new [ClientEventOneOf1] instance.
  ClientEventOneOf1({

    required  this.name,

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


  final ClientEventOneOf1NameEnum name;



  @JsonKey(
    
    name: r'metric',
    required: true,
    includeIfNull: false,
  )


  final ClientEventOneOf1MetricEnum metric;



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


  final ClientEventOneOf1PageEnum page;



  @JsonKey(
    
    name: r'connection',
    required: false,
    includeIfNull: false,
  )


  final ClientEventOneOf1ConnectionEnum? connection;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ClientEventOneOf1 &&
      other.name == name &&
      other.metric == metric &&
      other.value == value &&
      other.page == page &&
      other.connection == connection;

    @override
    int get hashCode =>
        name.hashCode +
        metric.hashCode +
        value.hashCode +
        page.hashCode +
        connection.hashCode;

  factory ClientEventOneOf1.fromJson(Map<String, dynamic> json) => _$ClientEventOneOf1FromJson(json);

  Map<String, dynamic> toJson() => _$ClientEventOneOf1ToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

enum ClientEventOneOf1NameEnum {
@JsonValue(r'web_vital')
webVital(r'web_vital');

const ClientEventOneOf1NameEnum(this.value);

final String value;

@override
String toString() => value;
}


enum ClientEventOneOf1MetricEnum {
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

const ClientEventOneOf1MetricEnum(this.value);

final String value;

@override
String toString() => value;
}


enum ClientEventOneOf1PageEnum {
@JsonValue(r'activity')
activity(r'activity'),
@JsonValue(r'invite')
invite(r'invite'),
@JsonValue(r'community')
community(r'community'),
@JsonValue(r'other')
other(r'other');

const ClientEventOneOf1PageEnum(this.value);

final String value;

@override
String toString() => value;
}


enum ClientEventOneOf1ConnectionEnum {
@JsonValue(r'slow-2g')
slow2g(r'slow-2g'),
@JsonValue(r'2g')
n2g(r'2g'),
@JsonValue(r'3g')
n3g(r'3g'),
@JsonValue(r'4g')
n4g(r'4g');

const ClientEventOneOf1ConnectionEnum(this.value);

final String value;

@override
String toString() => value;
}


