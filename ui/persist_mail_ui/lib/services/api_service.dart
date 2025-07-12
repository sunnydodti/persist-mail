import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../models/email_model.dart';
import '../models/domain_model.dart';
import '../services/logging_service.dart';

class ApiService {
  late final Dio _dio;

  ApiService() {
    AppLogger.debug(
      'ApiService: Initializing with base URL: ${AppConfig.baseUrl}',
    );

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
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final fullUrl = '${options.baseUrl}${options.path}';
          AppLogger.apiRequest(options.method, fullUrl, data: options.data);
          AppLogger.debug('API Request Details', {
            'method': options.method,
            'url': fullUrl,
            'headers': options.headers,
            'queryParameters': options.queryParameters,
            'data': options.data,
          });
          handler.next(options);
        },
        onResponse: (response, handler) {
          try {
            final fullUrl =
                '${response.requestOptions.baseUrl}${response.requestOptions.path}';
            AppLogger.apiResponse(
              response.requestOptions.method,
              fullUrl,
              response.statusCode ?? 0,
              data: response.data,
            );
          } catch (e) {
            AppLogger.error('Error in response interceptor: $e');
          }
          handler.next(response);
        },
        onError: (error, handler) {
          try {
            final fullUrl =
                '${error.requestOptions.baseUrl}${error.requestOptions.path}';
            AppLogger.error(
              'API Error: ${error.requestOptions.method} $fullUrl',
              error,
            );
          } catch (e) {
            AppLogger.error('Error in error interceptor: $e');
          }
          handler.next(error);
        },
      ),
    );

    AppLogger.info('ApiService: Initialized successfully');
  }

  // Get available domains
  Future<List<DomainModel>> getDomains() async {
    final stopwatch = Stopwatch()..start();
    try {
      AppLogger.debug('ApiService: Fetching domains');
      final response = await _dio.get('/domains');

      // Debug: Log the raw response structure
      AppLogger.debug('ApiService: Raw domains response', {
        'responseType': response.data.runtimeType.toString(),
        'responseData': response.data,
      });

      // Handle different response structures
      List<dynamic> domainsJson = [];
      if (response.data is List) {
        // If response is directly a list
        domainsJson = response.data as List<dynamic>;
      } else if (response.data is Map<String, dynamic>) {
        // If response is wrapped in an object
        domainsJson = response.data['domains'] ?? response.data['data'] ?? [];
      }

      AppLogger.debug('ApiService: Parsed domains list', {
        'domainsJsonType': domainsJson.runtimeType.toString(),
        'domainsJsonLength': domainsJson.length,
        'firstItem': domainsJson.isNotEmpty ? domainsJson.first : null,
      });

      final domains = domainsJson.map((json) {
        try {
          return DomainModel.fromJson(json);
        } catch (e) {
          AppLogger.error(
            'ApiService: Failed to parse domain - json: $json (${json.runtimeType})',
            e,
          );
          rethrow;
        }
      }).toList();

      AppLogger.info('ApiService: Domains fetched successfully', {
        'count': domains.length,
        'duration': '${stopwatch.elapsedMilliseconds}ms',
      });

      return domains;
    } on DioException catch (e) {
      AppLogger.error('ApiService: Failed to fetch domains', e);
      throw _handleError(e);
    } finally {
      stopwatch.stop();
    }
  }

  // Get emails for specific email address
  Future<List<EmailModel>> getEmails(String emailAddress) async {
    final stopwatch = Stopwatch()..start();
    try {
      AppLogger.debug('ApiService: Fetching emails for: $emailAddress');
      final response = await _dio.get('/emails/$emailAddress');

      // Handle different response structures
      List<dynamic> emailsJson = [];
      if (response.data is List) {
        emailsJson = response.data as List<dynamic>;
      } else if (response.data is Map<String, dynamic>) {
        emailsJson = response.data['emails'] ?? response.data['data'] ?? [];
      }

      final emails = emailsJson
          .map((json) => EmailModel.fromJson(json))
          .toList();

      AppLogger.info('ApiService: Emails fetched successfully', {
        'emailAddress': emailAddress,
        'count': emails.length,
        'duration': '${stopwatch.elapsedMilliseconds}ms',
      });

      return emails;
    } on DioException catch (e) {
      AppLogger.error(
        'ApiService: Failed to fetch emails for: $emailAddress',
        e,
      );
      throw _handleError(e);
    } finally {
      stopwatch.stop();
    }
  }

  // Get specific email content
  Future<EmailModel> getEmailContent(String emailId) async {
    try {
      AppLogger.debug('ApiService: Fetching email content for: $emailId');
      final response = await _dio.get('/email/$emailId');
      
      AppLogger.info('ApiService: Email content fetched successfully', {
        'emailId': emailId,
      });
      
      return EmailModel.fromJson(response.data);
    } on DioException catch (e) {
      AppLogger.error(
        'ApiService: Failed to fetch email content for: $emailId',
        e,
      );
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
