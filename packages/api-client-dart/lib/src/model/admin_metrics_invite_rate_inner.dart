//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:velio_api/src/model/ratio.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_metrics_invite_rate_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminMetricsInviteRateInner {
  /// Returns a new [AdminMetricsInviteRateInner] instance.
  AdminMetricsInviteRateInner({

    required  this.rail,

    required  this.rate,
  });

  @JsonKey(
    
    name: r'rail',
    required: true,
    includeIfNull: false,
  )


  final AdminMetricsInviteRateInnerRailEnum rail;



  @JsonKey(
    
    name: r'rate',
    required: true,
    includeIfNull: false,
  )


  final Ratio rate;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminMetricsInviteRateInner &&
      other.rail == rail &&
      other.rate == rate;

    @override
    int get hashCode =>
        rail.hashCode +
        rate.hashCode;

  factory AdminMetricsInviteRateInner.fromJson(Map<String, dynamic> json) => _$AdminMetricsInviteRateInnerFromJson(json);

  Map<String, dynamic> toJson() => _$AdminMetricsInviteRateInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

enum AdminMetricsInviteRateInnerRailEnum {
@JsonValue(r'any')
any(r'any'),
@JsonValue(r'vouch')
vouch(r'vouch'),
@JsonValue(r'public')
public(r'public');

const AdminMetricsInviteRateInnerRailEnum(this.value);

final String value;

@override
String toString() => value;
}


