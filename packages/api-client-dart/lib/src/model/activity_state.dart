//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'activity_state.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ActivityState {
  /// Returns a new [ActivityState] instance.
  ActivityState({

    required  this.id,

    required  this.spotsLeft,

    required  this.version,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'spotsLeft',
    required: true,
    includeIfNull: false,
  )


  final int spotsLeft;



  @JsonKey(
    
    name: r'version',
    required: true,
    includeIfNull: false,
  )


  final int version;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ActivityState &&
      other.id == id &&
      other.spotsLeft == spotsLeft &&
      other.version == version;

    @override
    int get hashCode =>
        id.hashCode +
        spotsLeft.hashCode +
        version.hashCode;

  factory ActivityState.fromJson(Map<String, dynamic> json) => _$ActivityStateFromJson(json);

  Map<String, dynamic> toJson() => _$ActivityStateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

