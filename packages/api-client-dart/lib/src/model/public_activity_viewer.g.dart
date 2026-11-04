// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_activity_viewer.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PublicActivityViewerCWProxy {
  PublicActivityViewer isHost(bool isHost);

  PublicActivityViewer booking(PublicActivityViewerBooking? booking);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PublicActivityViewer(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PublicActivityViewer(...).copyWith(id: 12, name: "My name")
  /// ```
  PublicActivityViewer call({
    bool isHost,
    PublicActivityViewerBooking? booking,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPublicActivityViewer.copyWith(...)` or call `instanceOfPublicActivityViewer.copyWith.fieldName(value)` for a single field.
class _$PublicActivityViewerCWProxyImpl
    implements _$PublicActivityViewerCWProxy {
  const _$PublicActivityViewerCWProxyImpl(this._value);

  final PublicActivityViewer _value;

  @override
  PublicActivityViewer isHost(bool isHost) => call(isHost: isHost);

  @override
  PublicActivityViewer booking(PublicActivityViewerBooking? booking) =>
      call(booking: booking);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PublicActivityViewer(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PublicActivityViewer(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PublicActivityViewer call({
    Object? isHost = const $CopyWithPlaceholder(),
    Object? booking = const $CopyWithPlaceholder(),
  }) {
    return PublicActivityViewer(
      isHost: isHost == const $CopyWithPlaceholder() || isHost == null
          ? _value.isHost
          // ignore: cast_nullable_to_non_nullable
          : isHost as bool,
      booking: booking == const $CopyWithPlaceholder()
          ? _value.booking
          // ignore: cast_nullable_to_non_nullable
          : booking as PublicActivityViewerBooking?,
    );
  }
}

extension $PublicActivityViewerCopyWith on PublicActivityViewer {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPublicActivityViewer.copyWith(...)` or `instanceOfPublicActivityViewer.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PublicActivityViewerCWProxy get copyWith =>
      _$PublicActivityViewerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicActivityViewer _$PublicActivityViewerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PublicActivityViewer', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['isHost', 'booking']);
  final val = PublicActivityViewer(
    isHost: $checkedConvert('isHost', (v) => v as bool),
    booking: $checkedConvert(
      'booking',
      (v) => v == null
          ? null
          : PublicActivityViewerBooking.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
});

Map<String, dynamic> _$PublicActivityViewerToJson(
  PublicActivityViewer instance,
) => <String, dynamic>{
  'isHost': instance.isHost,
  'booking': instance.booking?.toJson(),
};
