class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final Map<String, String>? fieldErrors;

  ApiException({required this.message, this.statusCode, this.fieldErrors});

  @override
  String toString() => message;
}
