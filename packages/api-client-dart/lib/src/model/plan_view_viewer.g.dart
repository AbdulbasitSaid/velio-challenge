// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_view_viewer.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PlanViewViewerCWProxy {
  PlanViewViewer booking(PlanViewViewerBooking booking);

  PlanViewViewer canInvite(bool canInvite);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PlanViewViewer(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PlanViewViewer(...).copyWith(id: 12, name: "My name")
  /// ```
  PlanViewViewer call({PlanViewViewerBooking booking, bool canInvite});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPlanViewViewer.copyWith(...)` or call `instanceOfPlanViewViewer.copyWith.fieldName(value)` for a single field.
class _$PlanViewViewerCWProxyImpl implements _$PlanViewViewerCWProxy {
  const _$PlanViewViewerCWProxyImpl(this._value);

  final PlanViewViewer _value;

  @override
  PlanViewViewer booking(PlanViewViewerBooking booking) =>
      call(booking: booking);

  @override
  PlanViewViewer canInvite(bool canInvite) => call(canInvite: canInvite);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PlanViewViewer(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PlanViewViewer(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PlanViewViewer call({
    Object? booking = const $CopyWithPlaceholder(),
    Object? canInvite = const $CopyWithPlaceholder(),
  }) {
    return PlanViewViewer(
      booking: booking == const $CopyWithPlaceholder() || booking == null
          ? _value.booking
          // ignore: cast_nullable_to_non_nullable
          : booking as PlanViewViewerBooking,
      canInvite: canInvite == const $CopyWithPlaceholder() || canInvite == null
          ? _value.canInvite
          // ignore: cast_nullable_to_non_nullable
          : canInvite as bool,
    );
  }
}

extension $PlanViewViewerCopyWith on PlanViewViewer {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPlanViewViewer.copyWith(...)` or `instanceOfPlanViewViewer.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PlanViewViewerCWProxy get copyWith => _$PlanViewViewerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlanViewViewer _$PlanViewViewerFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PlanViewViewer', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['booking', 'canInvite']);
      final val = PlanViewViewer(
        booking: $checkedConvert(
          'booking',
          (v) => PlanViewViewerBooking.fromJson(v as Map<String, dynamic>),
        ),
        canInvite: $checkedConvert('canInvite', (v) => v as bool),
      );
      return val;
    });

Map<String, dynamic> _$PlanViewViewerToJson(PlanViewViewer instance) =>
    <String, dynamic>{
      'booking': instance.booking.toJson(),
      'canInvite': instance.canInvite,
    };
