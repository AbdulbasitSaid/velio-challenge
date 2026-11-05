// The API's typed error, shared by every layer. The data layer maps transport failures into it.

/// The API's typed error, or a network failure (`code == null`, `status == null`).
class ApiException implements Exception {
  const ApiException({this.status, this.code, this.message = ''});
  final int? status;
  final String? code;
  final String message;

  bool get network => status == null;

  /// Repositories throw [ApiException]; anything else is an internal failure.
  static ApiException from(Object error) =>
      error is ApiException ? error : ApiException(code: 'internal', message: '$error');

  @override
  String toString() => 'ApiException($status, $code)';
}
