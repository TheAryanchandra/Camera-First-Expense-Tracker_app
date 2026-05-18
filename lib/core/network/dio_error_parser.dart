import 'package:dio/dio.dart';

class DioErrorParser {
  static String parse(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timeout. Please check your internet connection and try again.';
        case DioExceptionType.badResponse:
          final response = error.response;
          if (response != null) {
            final data = response.data;
            if (data is Map<String, dynamic>) {
              // Extract backend error message if available
              return data['message'] ?? data['error'] ?? 'Server error: ${response.statusCode}';
            }
            return 'Server error: ${response.statusCode}';
          }
          return 'Received invalid response from server.';
        case DioExceptionType.cancel:
          return 'Request was cancelled.';
        case DioExceptionType.connectionError:
          return 'No internet connection. Please verify your connection status.';
        default:
          return error.message ?? 'An unexpected network error occurred.';
      }
    }
    return error.toString().replaceAll('Exception: ', '');
  }
}
