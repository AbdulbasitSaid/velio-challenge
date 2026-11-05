// Hosting (S7b FR-006–FR-012): My activities, create and changed-only edit, the photo pipeline,
// place search, and live attendance.
import 'dart:typed_data';

import 'package:velio_api/velio_api.dart';

import '../data/api.dart';
import '../data/photo.dart';
import '../data/places.dart';
import '../domain/host_form.dart';

export '../data/photo.dart' show PhotoError;
export '../data/places.dart' show PlaceSuggestion;

class HostRepository {
  HostRepository({required this._api, required this._photos, required this._places, required this._pickPhoto});

  final Api _api;
  final PhotoUploader _photos;
  final PlacesClient _places;
  final Future<Uint8List?> Function() _pickPhoto;

  Future<HostActivityList> hostActivities() => _api.hostActivities();

  Future<PublicActivity> activity(String id) => _api.activity(id);

  Future<CommunityList> communities() => _api.communities();

  /// The new activity's ID.
  Future<String> create(Map<String, Object?> body) => _api.createActivity(body);

  Future<void> patch(String id, Map<String, Object?> body) => _api.patchActivity(id, body);

  /// The gallery; null when the host cancels.
  Future<Uint8List?> pickPhoto() => _pickPhoto();

  /// Crops, encodes and uploads both sizes (S7b §4.5); throws [PhotoError] or [ApiException].
  Future<({String key, Uint8List preview})> uploadPhoto(Uint8List picked) => _photos.upload(picked);

  /// False without `PLACES_KEY`.
  bool get placesConfigured => _places.configured;

  Future<List<PlaceSuggestion>> searchPlaces(String input, {required double lat, required double lng}) =>
      _places.search(input, lat: lat, lng: lng);

  Future<PickedLocation> placeDetails(PlaceSuggestion s) => _places.details(s);

  Future<Attendance> attendance(String activityId) => _api.attendance(activityId);

  Future<Attendee> mark(String bookingId, AttendanceMark mark) => _api.mark(bookingId, mark);

  Future<void> remove(String bookingId) => _api.removeBooking(bookingId);
}
