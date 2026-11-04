// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'next_steps.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$NextStepsCWProxy {
  NextSteps hostOtherDates(List<ActivityCard> hostOtherDates);

  NextSteps moreInCommunity(List<ActivityCard> moreInCommunity);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `NextSteps(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// NextSteps(...).copyWith(id: 12, name: "My name")
  /// ```
  NextSteps call({
    List<ActivityCard> hostOtherDates,
    List<ActivityCard> moreInCommunity,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfNextSteps.copyWith(...)` or call `instanceOfNextSteps.copyWith.fieldName(value)` for a single field.
class _$NextStepsCWProxyImpl implements _$NextStepsCWProxy {
  const _$NextStepsCWProxyImpl(this._value);

  final NextSteps _value;

  @override
  NextSteps hostOtherDates(List<ActivityCard> hostOtherDates) =>
      call(hostOtherDates: hostOtherDates);

  @override
  NextSteps moreInCommunity(List<ActivityCard> moreInCommunity) =>
      call(moreInCommunity: moreInCommunity);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `NextSteps(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// NextSteps(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  NextSteps call({
    Object? hostOtherDates = const $CopyWithPlaceholder(),
    Object? moreInCommunity = const $CopyWithPlaceholder(),
  }) {
    return NextSteps(
      hostOtherDates:
          hostOtherDates == const $CopyWithPlaceholder() ||
              hostOtherDates == null
          ? _value.hostOtherDates
          // ignore: cast_nullable_to_non_nullable
          : hostOtherDates as List<ActivityCard>,
      moreInCommunity:
          moreInCommunity == const $CopyWithPlaceholder() ||
              moreInCommunity == null
          ? _value.moreInCommunity
          // ignore: cast_nullable_to_non_nullable
          : moreInCommunity as List<ActivityCard>,
    );
  }
}

extension $NextStepsCopyWith on NextSteps {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfNextSteps.copyWith(...)` or `instanceOfNextSteps.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$NextStepsCWProxy get copyWith => _$NextStepsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NextSteps _$NextStepsFromJson(Map<String, dynamic> json) => $checkedCreate(
  'NextSteps',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['hostOtherDates', 'moreInCommunity']);
    final val = NextSteps(
      hostOtherDates: $checkedConvert(
        'hostOtherDates',
        (v) => (v as List<dynamic>)
            .map((e) => ActivityCard.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      moreInCommunity: $checkedConvert(
        'moreInCommunity',
        (v) => (v as List<dynamic>)
            .map((e) => ActivityCard.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
    );
    return val;
  },
);

Map<String, dynamic> _$NextStepsToJson(NextSteps instance) => <String, dynamic>{
  'hostOtherDates': instance.hostOtherDates.map((e) => e.toJson()).toList(),
  'moreInCommunity': instance.moreInCommunity.map((e) => e.toJson()).toList(),
};
