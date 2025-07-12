import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../models/email_model.dart';
import '../models/domain_model.dart';

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors for logging and error handling
    _dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true, error: true),
    );
  }

  // Get available domains
  Future<List<DomainModel>> getDomains() async {
    try {
      final response = await _dio.get('/api/domains');
      final List<dynamic> domainsJson = response.data['domains'] ?? [];
      return domainsJson.map((json) => DomainModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Generate new email address
  Future<String> generateEmail(String domain) async {
    try {
      final response = await _dio.post(
        '/api/email/generate',
        data: {'domain': domain},
      );
      return response.data['email'] ?? '';
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get emails for specific email address
  Future<List<EmailModel>> getEmails(String emailAddress) async {
    try {
      final response = await _dio.get('/api/emails/$emailAddress');
      final List<dynamic> emailsJson = response.data['emails'] ?? [];
      return emailsJson.map((json) => EmailModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get specific email content
  Future<EmailModel> getEmailContent(String emailId) async {
    try {
      final response = await _dio.get('/api/email/$emailId');
      return EmailModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 404) {
          return 'Resource not found.';
        } else if (statusCode == 500) {
          return 'Server error. Please try again later.';
        }
        return 'Request failed with status: $statusCode';
      default:
        return 'Network error occurred. Please try again.';
    }
  }
}
