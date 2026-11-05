//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'ratio.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Ratio {
  /// Returns a new [Ratio] instance.
  Ratio({

    required  this.numerator,

    required  this.denominator,

    required  this.value,
  });

  @JsonKey(
    
    name: r'numerator',
    required: true,
    includeIfNull: false,
  )


  final int numerator;



  @JsonKey(
    
    name: r'denominator',
    required: true,
    includeIfNull: false,
  )


  final int denominator;



  @JsonKey(
    
    name: r'value',
    required: true,
    includeIfNull: true,
  )


  final num? value;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Ratio &&
      other.numerator == numerator &&
      other.denominator == denominator &&
      other.value == value;

    @override
    int get hashCode =>
        numerator.hashCode +
        denominator.hashCode +
        (value == null ? 0 : value.hashCode);

  factory Ratio.fromJson(Map<String, dynamic> json) => _$RatioFromJson(json);

  Map<String, dynamic> toJson() => _$RatioToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

