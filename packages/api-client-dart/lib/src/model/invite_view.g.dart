// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite_view.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$InviteViewCWProxy {
  InviteView code(String code);

  InviteView rail(InviteViewRailEnum rail);

  InviteView status(InviteViewStatusEnum status);

  InviteView pausedReason(PauseReason? pausedReason);

  InviteView inviter(PublicPerson inviter);

  InviteView note(String? note);

  InviteView claimedByViewer(bool claimedByViewer);

  InviteView activity(PublicActivity activity);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `InviteView(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// InviteView(...).copyWith(id: 12, name: "My name")
  /// ```
  InviteView call({
    String code,
    InviteViewRailEnum rail,
    InviteViewStatusEnum status,
    PauseReason? pausedReason,
    PublicPerson inviter,
    String? note,
    bool claimedByViewer,
    PublicActivity activity,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfInviteView.copyWith(...)` or call `instanceOfInviteView.copyWith.fieldName(value)` for a single field.
class _$InviteViewCWProxyImpl implements _$InviteViewCWProxy {
  const _$InviteViewCWProxyImpl(this._value);

  final InviteView _value;

  @override
  InviteView code(String code) => call(code: code);

  @override
  InviteView rail(InviteViewRailEnum rail) => call(rail: rail);

  @override
  InviteView status(InviteViewStatusEnum status) => call(status: status);

  @override
  InviteView pausedReason(PauseReason? pausedReason) =>
      call(pausedReason: pausedReason);

  @override
  InviteView inviter(PublicPerson inviter) => call(inviter: inviter);

  @override
  InviteView note(String? note) => call(note: note);

  @override
  InviteView claimedByViewer(bool claimedByViewer) =>
      call(claimedByViewer: claimedByViewer);

  @override
  InviteView activity(PublicActivity activity) => call(activity: activity);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `InviteView(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// InviteView(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  InviteView call({
    Object? code = const $CopyWithPlaceholder(),
    Object? rail = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? pausedReason = const $CopyWithPlaceholder(),
    Object? inviter = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
    Object? claimedByViewer = const $CopyWithPlaceholder(),
    Object? activity = const $CopyWithPlaceholder(),
  }) {
    return InviteView(
      code: code == const $CopyWithPlaceholder() || code == null
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as String,
      rail: rail == const $CopyWithPlaceholder() || rail == null
          ? _value.rail
          // ignore: cast_nullable_to_non_nullable
          : rail as InviteViewRailEnum,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as InviteViewStatusEnum,
      pausedReason: pausedReason == const $CopyWithPlaceholder()
          ? _value.pausedReason
          // ignore: cast_nullable_to_non_nullable
          : pausedReason as PauseReason?,
      inviter: inviter == const $CopyWithPlaceholder() || inviter == null
          ? _value.inviter
          // ignore: cast_nullable_to_non_nullable
          : inviter as PublicPerson,
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String?,
      claimedByViewer:
          claimedByViewer == const $CopyWithPlaceholder() ||
              claimedByViewer == null
          ? _value.claimedByViewer
          // ignore: cast_nullable_to_non_nullable
          : claimedByViewer as bool,
      activity: activity == const $CopyWithPlaceholder() || activity == null
          ? _value.activity
          // ignore: cast_nullable_to_non_nullable
          : activity as PublicActivity,
    );
  }
}

extension $InviteViewCopyWith on InviteView {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfInviteView.copyWith(...)` or `instanceOfInviteView.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$InviteViewCWProxy get copyWith => _$InviteViewCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InviteView _$InviteViewFromJson(Map<String, dynamic> json) =>
    $checkedCreate('InviteView', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'code',
          'rail',
          'status',
          'pausedReason',
          'inviter',
          'note',
          'claimedByViewer',
          'activity',
        ],
      );
      final val = InviteView(
        code: $checkedConvert('code', (v) => v as String),
        rail: $checkedConvert(
          'rail',
          (v) => $enumDecode(_$InviteViewRailEnumEnumMap, v),
        ),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$InviteViewStatusEnumEnumMap, v),
        ),
        pausedReason: $checkedConvert(
          'pausedReason',
          (v) => $enumDecodeNullable(_$PauseReasonEnumMap, v),
        ),
        inviter: $checkedConvert(
          'inviter',
          (v) => PublicPerson.fromJson(v as Map<String, dynamic>),
        ),
        note: $checkedConvert('note', (v) => v as String?),
        claimedByViewer: $checkedConvert('claimedByViewer', (v) => v as bool),
        activity: $checkedConvert(
          'activity',
          (v) => PublicActivity.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$InviteViewToJson(InviteView instance) =>
    <String, dynamic>{
      'code': instance.code,
      'rail': _$InviteViewRailEnumEnumMap[instance.rail]!,
      'status': _$InviteViewStatusEnumEnumMap[instance.status]!,
      'pausedReason': _$PauseReasonEnumMap[instance.pausedReason],
      'inviter': instance.inviter.toJson(),
      'note': instance.note,
      'claimedByViewer': instance.claimedByViewer,
      'activity': instance.activity.toJson(),
    };

const _$InviteViewRailEnumEnumMap = {
  InviteViewRailEnum.vouch: 'vouch',
  InviteViewRailEnum.public: 'public',
};

const _$InviteViewStatusEnumEnumMap = {
  InviteViewStatusEnum.claimable: 'claimable',
  InviteViewStatusEnum.claimed: 'claimed',
  InviteViewStatusEnum.expired: 'expired',
  InviteViewStatusEnum.paused: 'paused',
};

const _$PauseReasonEnumMap = {
  PauseReason.owner: 'owner',
  PauseReason.host: 'host',
  PauseReason.auto: 'auto',
};
