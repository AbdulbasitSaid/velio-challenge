//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:velio_api/src/model/activity_card.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'next_steps.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class NextSteps {
  /// Returns a new [NextSteps] instance.
  NextSteps({

    required  this.hostOtherDates,

    required  this.moreInCommunity,
  });

  @JsonKey(
    
    name: r'hostOtherDates',
    required: true,
    includeIfNull: false,
  )


  final List<ActivityCard> hostOtherDates;



  @JsonKey(
    
    name: r'moreInCommunity',
    required: true,
    includeIfNull: false,
  )


  final List<ActivityCard> moreInCommunity;





    @override
    bool operator ==(Object other) => identical(this, other) || other is NextSteps &&
      other.hostOtherDates == hostOtherDates &&
      other.moreInCommunity == moreInCommunity;

    @override
    int get hashCode =>
        hostOtherDates.hashCode +
        moreInCommunity.hashCode;

  factory NextSteps.fromJson(Map<String, dynamic> json) => _$NextStepsFromJson(json);

  Map<String, dynamic> toJson() => _$NextStepsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

