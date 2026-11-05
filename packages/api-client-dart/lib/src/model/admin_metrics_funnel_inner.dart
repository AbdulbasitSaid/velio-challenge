//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:velio_api/src/model/ratio.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_metrics_funnel_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminMetricsFunnelInner {
  /// Returns a new [AdminMetricsFunnelInner] instance.
  AdminMetricsFunnelInner({

    required  this.rail,

    required  this.invites,

    required  this.opens,

    required  this.claims,

    required  this.openToClaim,
  });

  @JsonKey(
    
    name: r'rail',
    required: true,
    includeIfNull: false,
  )


  final AdminMetricsFunnelInnerRailEnum rail;



  @JsonKey(
    
    name: r'invites',
    required: true,
    includeIfNull: false,
  )


  final int invites;



  @JsonKey(
    
    name: r'opens',
    required: true,
    includeIfNull: false,
  )


  final int opens;



  @JsonKey(
    
    name: r'claims',
    required: true,
    includeIfNull: false,
  )


  final int claims;



  @JsonKey(
    
    name: r'openToClaim',
    required: true,
    includeIfNull: false,
  )


  final Ratio openToClaim;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminMetricsFunnelInner &&
      other.rail == rail &&
      other.invites == invites &&
      other.opens == opens &&
      other.claims == claims &&
      other.openToClaim == openToClaim;

    @override
    int get hashCode =>
        rail.hashCode +
        invites.hashCode +
        opens.hashCode +
        claims.hashCode +
        openToClaim.hashCode;

  factory AdminMetricsFunnelInner.fromJson(Map<String, dynamic> json) => _$AdminMetricsFunnelInnerFromJson(json);

  Map<String, dynamic> toJson() => _$AdminMetricsFunnelInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

enum AdminMetricsFunnelInnerRailEnum {
@JsonValue(r'vouch')
vouch(r'vouch'),
@JsonValue(r'public')
public(r'public');

const AdminMetricsFunnelInnerRailEnum(this.value);

final String value;

@override
String toString() => value;
}


