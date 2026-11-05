// H2 place search (S7b §4.4, FR-010): Places API (New) over REST with the key from
// `--dart-define=PLACES_KEY`. Requests name the app (package or bundle ID, and the signing SHA-1 when
// given) so the key can carry app restrictions. Its own Dio: none of our headers go to Google.
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../domain/host_form.dart';

const placesKey = String.fromEnvironment('PLACES_KEY');
const androidCertSha1 = String.fromEnvironment('ANDROID_CERT_SHA1');
const appId = 'io.github.abdulbasitsaid.velio';

class PlaceSuggestion {
  const PlaceSuggestion({required this.id, required this.name, required this.sub});
  final String id;
  final String name;
  final String sub;
}

class PlacesClient {
  PlacesClient({required this.platform, this.key = placesKey, Dio? dio})
    : _dio =
          dio ??
          Dio(BaseOptions(baseUrl: 'https://places.googleapis.com/v1', connectTimeout: const Duration(seconds: 10)));
  final String platform;
  final String key;
  final Dio _dio;

  /// One session per pick: autocomplete calls share it and the details request ends it (Places billing).
  String? _session;

  bool get configured => key.isNotEmpty;

  Map<String, String> get _headers => {
    'X-Goog-Api-Key': key,
    if (platform == 'ios') 'X-Ios-Bundle-Identifier': appId else 'X-Android-Package': appId,
    if (platform != 'ios' && androidCertSha1.isNotEmpty) 'X-Android-Cert': androidCertSha1,
  };

  Future<List<PlaceSuggestion>> search(String input, {required double lat, required double lng}) async {
    _session ??= const Uuid().v4();
    final res = await _dio.post<Map<String, dynamic>>(
      '/places:autocomplete',
      data: {
        'input': input,
        'sessionToken': _session,
        'locationBias': {
          'circle': {
            'center': {'latitude': lat, 'longitude': lng},
            'radius': 50000.0,
          },
        },
      },
      options: Options(headers: _headers),
    );
    final suggestions = (res.data?['suggestions'] as List?) ?? const [];
    return [
      for (final s in suggestions)
        if (s is Map && s['placePrediction'] is Map) _suggestion(s['placePrediction'] as Map<String, dynamic>),
    ];
  }

  PlaceSuggestion _suggestion(Map<String, dynamic> p) {
    final f = p['structuredFormat'] as Map<String, dynamic>?;
    String? text(Object? o) => o is Map ? o['text'] as String? : null;
    return PlaceSuggestion(
      id: p['placeId'] as String,
      name: text(f?['mainText']) ?? text(p['text']) ?? '',
      sub: text(f?['secondaryText']) ?? '',
    );
  }

  Future<PickedLocation> details(PlaceSuggestion s) async {
    final session = _session;
    _session = null;
    final res = await _dio.get<Map<String, dynamic>>(
      '/places/${Uri.encodeComponent(s.id)}',
      queryParameters: {'sessionToken': ?session},
      options: Options(headers: {..._headers, 'X-Goog-FieldMask': 'id,displayName,formattedAddress,location'}),
    );
    final p = res.data!;
    final loc = p['location'] as Map<String, dynamic>;
    return PickedLocation(
      placeId: p['id'] as String? ?? s.id,
      venueName: ((p['displayName'] as Map?)?['text'] as String?) ?? s.name,
      addressText: p['formattedAddress'] as String? ?? s.sub,
      lat: (loc['latitude'] as num).toDouble(),
      lng: (loc['longitude'] as num).toDouble(),
    );
  }
}
