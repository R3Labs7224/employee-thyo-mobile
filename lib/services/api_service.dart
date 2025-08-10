import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:ems/utils/const.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/api_response.dart';
import '../utils/helpers.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;
  String? _refreshToken;
  bool _debugMode = true; // 🐛 Enable debug mode by default

  // 🔐 Set authentication token
  void setToken(String token) {
    _token = token;
    _debugLog('🔐 TOKEN SET', 'Token updated successfully', {
      'token_length': token.length,
      'token_prefix': token.substring(0, token.length > 10 ? 10 : token.length),
    });
  }

  // 🔄 Set refresh token for token renewal
  void setRefreshToken(String? refreshToken) {
    _refreshToken = refreshToken;
    _debugLog('🔄 REFRESH TOKEN', refreshToken != null ? 'Refresh token set' : 'Refresh token cleared', {
      'has_refresh_token': refreshToken != null,
      'token_length': refreshToken?.length ?? 0,
    });
  }

  // 🧹 Clear all tokens
  void clearToken() {
    _token = null;
    _refreshToken = null;
    _debugLog('🧹 TOKEN CLEARED', 'All authentication tokens cleared', {
      'previous_token_existed': _token != null,
      'previous_refresh_existed': _refreshToken != null,
    });
  }

  // 🔍 Get current token
  String? get token => _token;

  // ✅ Check if user is authenticated
  bool get isAuthenticated => _token != null;

  // 📋 Get default headers
  Map<String, String> get _headers {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'EmployeeManagement-Flutter/${AppConfig.appVersion}',
    };

    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    _debugLog('📋 HEADERS GENERATED', 'Request headers prepared', {
      'content_type': headers['Content-Type'],
      'has_auth': headers.containsKey('Authorization'),
      'user_agent': headers['User-Agent'],
      'total_headers': headers.length,
    });

    return headers;
  }

  // 📎 Get headers for multipart requests
  Map<String, String> get _multipartHeaders {
    Map<String, String> headers = {
      'Accept': 'application/json',
      'User-Agent': 'EmployeeManagement-Flutter/${AppConfig.appVersion}',
    };

    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    _debugLog('📎 MULTIPART HEADERS', 'Multipart headers prepared', {
      'has_auth': headers.containsKey('Authorization'),
      'accept_type': headers['Accept'],
      'total_headers': headers.length,
    });

    return headers;
  }

  // 📥 GET request with enhanced debugging
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? queryParams,
    T? Function(dynamic)? fromJson,
    bool requiresAuth = true,
  }) async {
    try {
      String url = AppConfig.baseUrl + endpoint;
      
      _debugLog('🚀 GET REQUEST INITIATED', 'Starting GET request', {
        'endpoint': endpoint,
        'base_url': AppConfig.baseUrl,
        'requires_auth': requiresAuth,
        'has_query_params': queryParams != null,
        'query_param_count': queryParams?.length ?? 0,
      });

      if (queryParams != null && queryParams.isNotEmpty) {
        final uri = Uri.parse(url);
        final newUri = uri.replace(queryParameters: queryParams);
        url = newUri.toString();
        
        _debugLog('🔗 QUERY PARAMS ADDED', 'URL parameters processed', {
          'original_url': AppConfig.baseUrl + endpoint,
          'final_url': url,
          'parameters': queryParams,
        });
      }

      final headers = requiresAuth ? _headers : {'Content-Type': 'application/json'};
      
      _debugLog('📡 SENDING GET REQUEST', 'Request being sent to server', {
        'url': url,
        'headers': headers,
        'timeout_ms': AppConfig.requestTimeout,
        'method': 'GET',
      });

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(Duration(milliseconds: AppConfig.requestTimeout));

      return _handleResponse(response, fromJson, 'GET', endpoint);

    } on SocketException catch (e) {
      _debugLog('🌐❌ NETWORK ERROR', 'Socket connection failed', {
        'error_type': 'SocketException',
        'endpoint': endpoint,
        'error_message': e.message,
        'error_os_code': e.osError?.errorCode,
      });
      
      return ApiResponse(
        success: false,
        message: Constants.errorNetworkConnection,
        timestamp: DateTime.now().toIso8601String(),
      );
    } on HttpException catch (e) {
      _debugLog('🔌❌ HTTP ERROR', 'HTTP connection failed', {
        'error_type': 'HttpException',
        'endpoint': endpoint,
        'error_message': e.message,
        'uri': e.uri?.toString(),
      });
      
      return ApiResponse(
        success: false,
        message: Constants.errorServerConnection,
        timestamp: DateTime.now().toIso8601String(),
      );
    } catch (e) {
      _debugLog('💥 UNEXPECTED ERROR', 'Unexpected error in GET request', {
        'error_type': e.runtimeType.toString(),
        'endpoint': endpoint,
        'error_message': e.toString(),
        'stack_trace': e is Error ? e.stackTrace?.toString() : null,
      });
      
      return ApiResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  // 📤 POST request with enhanced debugging
  Future<ApiResponse<T>> post<T>(
    String endpoint,
    Map<String, dynamic> body, {
    T? Function(dynamic)? fromJson,
    bool requiresAuth = true,
  }) async {
    try {
      final url = AppConfig.baseUrl + endpoint;
      
      _debugLog('🚀 POST REQUEST INITIATED', 'Starting POST request', {
        'endpoint': endpoint,
        'base_url': AppConfig.baseUrl,
        'requires_auth': requiresAuth,
        'body_keys': body.keys.toList(),
        'body_size': body.length,
      });

      // 🔍 Validate request body fields
      _validateRequestBody(body, endpoint);

      final jsonBody = json.encode(body);
      final headers = requiresAuth ? _headers : {'Content-Type': 'application/json'};

      _debugLog('📡 SENDING POST REQUEST', 'Request being sent to server', {
        'url': url,
        'headers': headers,
        'body_json': jsonBody,
        'body_length': jsonBody.length,
        'timeout_ms': AppConfig.requestTimeout,
        'method': 'POST',
      });

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonBody,
      ).timeout(Duration(milliseconds: AppConfig.requestTimeout));

      return _handleResponse(response, fromJson, 'POST', endpoint, requestBody: body);

    } on SocketException catch (e) {
      _debugLog('🌐❌ NETWORK ERROR', 'Socket connection failed in POST', {
        'error_type': 'SocketException',
        'endpoint': endpoint,
        'request_body_keys': body.keys.toList(),
        'error_message': e.message,
        'error_os_code': e.osError?.errorCode,
      });
      
      return ApiResponse(
        success: false,
        message: Constants.errorNetworkConnection,
        timestamp: DateTime.now().toIso8601String(),
      );
    } on HttpException catch (e) {
      _debugLog('🔌❌ HTTP ERROR', 'HTTP connection failed in POST', {
        'error_type': 'HttpException',
        'endpoint': endpoint,
        'request_body_keys': body.keys.toList(),
        'error_message': e.message,
        'uri': e.uri?.toString(),
      });
      
      return ApiResponse(
        success: false,
        message: Constants.errorServerConnection,
        timestamp: DateTime.now().toIso8601String(),
      );
    } catch (e) {
      _debugLog('💥 UNEXPECTED ERROR', 'Unexpected error in POST request', {
        'error_type': e.runtimeType.toString(),
        'endpoint': endpoint,
        'request_body_keys': body.keys.toList(),
        'error_message': e.toString(),
        'stack_trace': e is Error ? e.stackTrace?.toString() : null,
      });
      
      return ApiResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  // 🔄 PUT request with enhanced debugging
  Future<ApiResponse<T>> put<T>(
    String endpoint,
    Map<String, dynamic> body, {
    T? Function(dynamic)? fromJson,
    bool requiresAuth = true,
  }) async {
    try {
      final url = AppConfig.baseUrl + endpoint;
      
      _debugLog('🚀 PUT REQUEST INITIATED', 'Starting PUT request', {
        'endpoint': endpoint,
        'base_url': AppConfig.baseUrl,
        'requires_auth': requiresAuth,
        'body_keys': body.keys.toList(),
        'body_size': body.length,
      });

      // 🔍 Validate request body fields
      _validateRequestBody(body, endpoint);

      final jsonBody = json.encode(body);
      final headers = requiresAuth ? _headers : {'Content-Type': 'application/json'};

      _debugLog('📡 SENDING PUT REQUEST', 'Request being sent to server', {
        'url': url,
        'headers': headers,
        'body_json': jsonBody,
        'body_length': jsonBody.length,
        'timeout_ms': AppConfig.requestTimeout,
        'method': 'PUT',
      });

      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonBody,
      ).timeout(Duration(milliseconds: AppConfig.requestTimeout));

      return _handleResponse(response, fromJson, 'PUT', endpoint, requestBody: body);

    } on SocketException catch (e) {
      _debugLog('🌐❌ NETWORK ERROR', 'Socket connection failed in PUT', {
        'error_type': 'SocketException',
        'endpoint': endpoint,
        'request_body_keys': body.keys.toList(),
        'error_message': e.message,
        'error_os_code': e.osError?.errorCode,
      });
      
      return ApiResponse(
        success: false,
        message: Constants.errorNetworkConnection,
        timestamp: DateTime.now().toIso8601String(),
      );
    } on HttpException catch (e) {
      _debugLog('🔌❌ HTTP ERROR', 'HTTP connection failed in PUT', {
        'error_type': 'HttpException',
        'endpoint': endpoint,
        'request_body_keys': body.keys.toList(),
        'error_message': e.message,
        'uri': e.uri?.toString(),
      });
      
      return ApiResponse(
        success: false,
        message: Constants.errorServerConnection,
        timestamp: DateTime.now().toIso8601String(),
      );
    } catch (e) {
      _debugLog('💥 UNEXPECTED ERROR', 'Unexpected error in PUT request', {
        'error_type': e.runtimeType.toString(),
        'endpoint': endpoint,
        'request_body_keys': body.keys.toList(),
        'error_message': e.toString(),
        'stack_trace': e is Error ? e.stackTrace?.toString() : null,
      });
      
      return ApiResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  // 🗑️ DELETE request with enhanced debugging
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T? Function(dynamic)? fromJson,
    bool requiresAuth = true,
  }) async {
    try {
      final url = AppConfig.baseUrl + endpoint;
      
      _debugLog('🚀 DELETE REQUEST INITIATED', 'Starting DELETE request', {
        'endpoint': endpoint,
        'base_url': AppConfig.baseUrl,
        'requires_auth': requiresAuth,
        'has_body': body != null,
        'body_keys': body?.keys.toList() ?? [],
        'body_size': body?.length ?? 0,
      });

      final headers = requiresAuth ? _headers : {'Content-Type': 'application/json'};

      _debugLog('📡 SENDING DELETE REQUEST', 'Request being sent to server', {
        'url': url,
        'headers': headers,
        'body': body != null ? json.encode(body) : null,
        'timeout_ms': AppConfig.requestTimeout,
        'method': 'DELETE',
      });

      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
        body: body != null ? json.encode(body) : null,
      ).timeout(Duration(milliseconds: AppConfig.requestTimeout));

      return _handleResponse(response, fromJson, 'DELETE', endpoint, requestBody: body);

    } on SocketException catch (e) {
      _debugLog('🌐❌ NETWORK ERROR', 'Socket connection failed in DELETE', {
        'error_type': 'SocketException',
        'endpoint': endpoint,
        'request_body_keys': body?.keys.toList() ?? [],
        'error_message': e.message,
        'error_os_code': e.osError?.errorCode,
      });
      
      return ApiResponse(
        success: false,
        message: Constants.errorNetworkConnection,
        timestamp: DateTime.now().toIso8601String(),
      );
    } on HttpException catch (e) {
      _debugLog('🔌❌ HTTP ERROR', 'HTTP connection failed in DELETE', {
        'error_type': 'HttpException',
        'endpoint': endpoint,
        'request_body_keys': body?.keys.toList() ?? [],
        'error_message': e.message,
        'uri': e.uri?.toString(),
      });
      
      return ApiResponse(
        success: false,
        message: Constants.errorServerConnection,
        timestamp: DateTime.now().toIso8601String(),
      );
    } catch (e) {
      _debugLog('💥 UNEXPECTED ERROR', 'Unexpected error in DELETE request', {
        'error_type': e.runtimeType.toString(),
        'endpoint': endpoint,
        'request_body_keys': body?.keys.toList() ?? [],
        'error_message': e.toString(),
        'stack_trace': e is Error ? e.stackTrace?.toString() : null,
      });
      
      return ApiResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  // 📎 Enhanced multipart request with field validation
  Future<ApiResponse<T>> multipart<T>(
    String endpoint,
    Map<String, String> fields, {
    Map<String, String>? files,
    T? Function(dynamic)? fromJson,
    bool requiresAuth = true,
  }) async {
    try {
      final url = AppConfig.baseUrl + endpoint;
      
      _debugLog('🚀 MULTIPART REQUEST INITIATED', 'Starting multipart upload', {
        'endpoint': endpoint,
        'field_keys': fields.keys.toList(),
        'field_count': fields.length,
        'file_keys': files?.keys.toList() ?? [],
        'file_count': files?.length ?? 0,
        'requires_auth': requiresAuth,
      });

      final request = http.MultipartRequest('POST', Uri.parse(url));
      
      // Add headers
      request.headers.addAll(requiresAuth ? _multipartHeaders : {'Accept': 'application/json'});
      
      // Add fields with validation
      _validateMultipartFields(fields, endpoint);
      request.fields.addAll(fields);

      // Add files from base64 strings with validation
      if (files != null) {
        for (var entry in files.entries) {
          try {
            String fieldName = entry.key;
            String base64Data = entry.value;
            
            _debugLog('📎 PROCESSING FILE', 'Processing file for upload', {
              'field_name': fieldName,
              'base64_length': base64Data.length,
              'has_data_prefix': base64Data.contains(','),
            });

            String cleanBase64 = base64Data;
            if (base64Data.contains(',')) {
              cleanBase64 = base64Data.split(',').last;
            }

            final bytes = base64Decode(cleanBase64);
            request.files.add(
              http.MultipartFile.fromBytes(
                fieldName,
                bytes,
                filename: '$fieldName.jpg',
              ),
            );
            
            _debugLog('✅ FILE ADDED', 'File successfully added to request', {
              'field_name': fieldName,
              'file_size_bytes': bytes.length,
              'filename': '$fieldName.jpg',
            });
            
          } catch (e) {
            _debugLog('📎❌ FILE ERROR', 'Error processing file', {
              'field_name': entry.key,
              'error': e.toString(),
              'base64_preview': entry.value.substring(0, entry.value.length > 50 ? 50 : entry.value.length),
            });
          }
        }
      }

      _debugLog('📡 SENDING MULTIPART REQUEST', 'Multipart request being sent', {
        'url': url,
        'headers': request.headers,
        'fields': request.fields,
        'files': request.files.map((f) => {'field': f.field, 'filename': f.filename, 'length': f.length}).toList(),
        'timeout_ms': AppConfig.requestTimeout * 2,
      });

      final streamedResponse = await request.send().timeout(
        Duration(milliseconds: AppConfig.requestTimeout * 2),
      );
      
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response, fromJson, 'MULTIPART', endpoint, requestBody: fields);

    } on SocketException catch (e) {
      _debugLog('🌐❌ MULTIPART NETWORK ERROR', 'Socket error in multipart upload', {
        'error_type': 'SocketException',
        'endpoint': endpoint,
        'field_keys': fields.keys.toList(),
        'error_message': e.message,
        'error_os_code': e.osError?.errorCode,
      });
      
      return ApiResponse(
        success: false,
        message: Constants.errorNetworkConnection,
        timestamp: DateTime.now().toIso8601String(),
      );
    } catch (e) {
      _debugLog('💥 MULTIPART ERROR', 'Unexpected error in multipart upload', {
        'error_type': e.runtimeType.toString(),
        'endpoint': endpoint,
        'field_keys': fields.keys.toList(),
        'error_message': e.toString(),
      });
      
      return ApiResponse(
        success: false,
        message: 'Upload error: ${e.toString()}',
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  // 📁 Upload file from bytes with enhanced debugging
  Future<ApiResponse<T>> uploadFile<T>(
    String endpoint,
    String fieldName,
    Uint8List fileBytes,
    String filename, {
    Map<String, String>? additionalFields,
    T? Function(dynamic)? fromJson,
    bool requiresAuth = true,
  }) async {
    try {
      final url = AppConfig.baseUrl + endpoint;
      
      _debugLog('🚀 FILE UPLOAD INITIATED', 'Starting file upload', {
        'endpoint': endpoint,
        'field_name': fieldName,
        'filename': filename,
        'file_size_bytes': fileBytes.length,
        'additional_fields': additionalFields?.keys.toList() ?? [],
        'requires_auth': requiresAuth,
      });

      final request = http.MultipartRequest('POST', Uri.parse(url));
      
      // Add headers
      request.headers.addAll(requiresAuth ? _multipartHeaders : {'Accept': 'application/json'});
      
      // Add additional fields
      if (additionalFields != null) {
        _validateMultipartFields(additionalFields, endpoint);
        request.fields.addAll(additionalFields);
      }

      // Add file
      request.files.add(
        http.MultipartFile.fromBytes(
          fieldName,
          fileBytes,
          filename: filename,
        ),
      );

      _debugLog('📡 SENDING FILE UPLOAD', 'File upload request being sent', {
        'url': url,
        'headers': request.headers,
        'fields': request.fields,
        'file_field': fieldName,
        'filename': filename,
        'file_size_bytes': fileBytes.length,
        'timeout_ms': AppConfig.requestTimeout * 3,
      });

      final streamedResponse = await request.send().timeout(
        Duration(milliseconds: AppConfig.requestTimeout * 3),
      );
      
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response, fromJson, 'FILE_UPLOAD', endpoint, requestBody: additionalFields);

    } on SocketException catch (e) {
      _debugLog('🌐❌ FILE UPLOAD NETWORK ERROR', 'Socket error in file upload', {
        'error_type': 'SocketException',
        'endpoint': endpoint,
        'field_name': fieldName,
        'file_size_bytes': fileBytes.length,
        'error_message': e.message,
        'error_os_code': e.osError?.errorCode,
      });
      
      return ApiResponse(
        success: false,
        message: Constants.errorNetworkConnection,
        timestamp: DateTime.now().toIso8601String(),
      );
    } catch (e) {
      _debugLog('💥 FILE UPLOAD ERROR', 'Unexpected error in file upload', {
        'error_type': e.runtimeType.toString(),
        'endpoint': endpoint,
        'field_name': fieldName,
        'file_size_bytes': fileBytes.length,
        'error_message': e.toString(),
      });
      
      return ApiResponse(
        success: false,
        message: 'File upload error: ${e.toString()}',
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  // 🔄 Enhanced response handler with detailed field analysis
  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T? Function(dynamic)? fromJson,
    String method,
    String endpoint, {
    Map<String, dynamic>? requestBody,
  }) {
    try {
      _debugLog('📥 RESPONSE RECEIVED', 'Processing server response', {
        'method': method,
        'endpoint': endpoint,
        'status_code': response.statusCode,
        'content': response.body,
        'content_type': response.headers['content-type'],
        'server': response.headers['server'],
      });

      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      
      _debugLog('🔍 RESPONSE ANALYSIS', 'Analyzing response structure', {
        'response_keys': jsonResponse.keys.toList(),
        'has_success_field': jsonResponse.containsKey('success'),
        'has_data_field': jsonResponse.containsKey('data'),
        'has_message_field': jsonResponse.containsKey('message'),
        'has_errors_field': jsonResponse.containsKey('errors'),
        'response_structure': _analyzeResponseStructure(jsonResponse),
      });

      // Success response handling
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _debugLog('✅ SUCCESS RESPONSE', 'Request completed successfully', {
          'status_code': response.statusCode,
          'success_flag': jsonResponse['success'],
          'data': jsonResponse['data']?.toString(),
          'message': jsonResponse['message'],
        });

        return ApiResponse.fromJson(jsonResponse, fromJson!);
      } else {
        // Error response handling with field mismatch analysis
        _debugLog('❌ ERROR RESPONSE', 'Server returned error response', {
          'status_code': response.statusCode,
          'error_category': _categorizeError(response.statusCode),
          'server_message': jsonResponse['message'],
          'validation_errors': jsonResponse['errors'],
          'field_mismatches': _analyzeFieldMismatches(requestBody, jsonResponse),
        });

        String errorMessage = _getDetailedErrorMessage(response.statusCode, jsonResponse, requestBody);
        
        if (response.statusCode == 401) {
          clearToken();
          _debugLog('🔐 TOKEN CLEARED', 'Authentication token cleared due to 401 error', {
            'previous_token_existed': _token != null,
          });
        }

        return ApiResponse(
          success: false,
          message: errorMessage,
          timestamp: jsonResponse['timestamp'] ?? DateTime.now().toIso8601String(),
          serverTime: jsonResponse['server_time'],
        );
      }

    } on FormatException catch (e) {
      _debugLog('📋❌ JSON PARSE ERROR', 'Failed to parse server response', {
        'method': method,
        'endpoint': endpoint,
        'status_code': response.statusCode,
        'response_preview': response.body.substring(0, response.body.length > 200 ? 200 : response.body.length),
        'error_message': e.message,
      });
      
      return ApiResponse(
        success: false,
        message: 'Invalid response format from server',
        timestamp: DateTime.now().toIso8601String(),
      );
    } catch (e) {
      _debugLog('💥 RESPONSE HANDLER ERROR', 'Unexpected error processing response', {
        'method': method,
        'endpoint': endpoint,
        'error_type': e.runtimeType.toString(),
        'error_message': e.toString(),
        'status_code': response.statusCode,
      });
      
      return ApiResponse(
        success: false,
        message: 'Failed to process response: ${e.toString()}',
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  // 🔍 Request body validation helper
  void _validateRequestBody(Map<String, dynamic> body, String endpoint) {
    _debugLog('🔍 VALIDATING REQUEST BODY', 'Checking request body structure', {
      'endpoint': endpoint,
      'field_count': body.length,
      'field_names': body.keys.toList(),
      'field_types': body.map((key, value) => MapEntry(key, value.runtimeType.toString())),
      'empty_fields': body.entries.where((e) => e.value == null || e.value == '').map((e) => e.key).toList(),
      'null_fields': body.entries.where((e) => e.value == null).map((e) => e.key).toList(),
    });

    // Check for common field issues
    List<String> issues = [];
    
    body.forEach((key, value) {
      if (value == null) {
        issues.add('🚨 Field "$key" is null');
      } else if (value is String && value.trim().isEmpty) {
        issues.add('⚠️ Field "$key" is empty string');
      } else if (value is List && value.isEmpty) {
        issues.add('📋 Field "$key" is empty list');
      } else if (value is Map && value.isEmpty) {
        issues.add('📄 Field "$key" is empty object');
      }
    });

    if (issues.isNotEmpty) {
      _debugLog('⚠️ FIELD ISSUES DETECTED', 'Found potential issues in request body', {
        'endpoint': endpoint,
        'total_issues': issues.length,
        'issues': issues,
      });
    }
  }

  // 📎 Multipart fields validation
  void _validateMultipartFields(Map<String, String> fields, String endpoint) {
    _debugLog('📎 VALIDATING MULTIPART FIELDS', 'Checking multipart field structure', {
      'endpoint': endpoint,
      'field_count': fields.length,
      'field_names': fields.keys.toList(),
      'field_lengths': fields.map((key, value) => MapEntry(key, value.length)),
      'empty_fields': fields.entries.where((e) => e.value.trim().isEmpty).map((e) => e.key).toList(),
    });
  }

  // 🔍 Analyze response structure for debugging
  Map<String, dynamic> _analyzeResponseStructure(Map<String, dynamic> response) {
    return {
      'total_keys': response.length,
      'nested_objects': response.entries.where((e) => e.value is Map).length,
      'arrays': response.entries.where((e) => e.value is List).length,
      'strings': response.entries.where((e) => e.value is String).length,
      'numbers': response.entries.where((e) => e.value is num).length,
      'booleans': response.entries.where((e) => e.value is bool).length,
      'nulls': response.entries.where((e) => e.value == null).length,
    };
  }

  // 🔍 Analyze field mismatches between request and response
  Map<String, dynamic> _analyzeFieldMismatches(Map<String, dynamic>? requestBody, Map<String, dynamic> response) {
    if (requestBody == null) return {};

    List<String> requestFields = requestBody.keys.toList();
    List<String> responseFields = response.keys.toList();
    Map<String, dynamic>? errors = response['errors'] as Map<String, dynamic>?;

    return {
      'request_fields': requestFields,
      'response_fields': responseFields,
      'missing_in_response': requestFields.where((field) => !responseFields.contains(field)).toList(),
      'extra_in_response': responseFields.where((field) => !requestFields.contains(field)).toList(),
      'validation_errors': errors?.keys.toList() ?? [],
      'error_field_details': errors?.map((key, value) => MapEntry(key, {
        'sent_value': requestBody[key],
        'sent_type': requestBody[key]?.runtimeType.toString(),
        'error_message': value,
      })) ?? {},
    };
  }

  // 🏷️ Categorize error types
  String _categorizeError(int statusCode) {
    switch (statusCode) {
      case 400: return 'Bad Request - Client Error';
      case 401: return 'Unauthorized - Authentication Required';
      case 403: return 'Forbidden - Access Denied';
      case 404: return 'Not Found - Resource Missing';
      case 422: return 'Validation Error - Field Issues';
      case 429: return 'Rate Limited - Too Many Requests';
      case 500: return 'Server Error - Internal Issue';
      case 502: return 'Bad Gateway - Proxy Error';
      case 503: return 'Service Unavailable - Server Down';
      case 504: return 'Gateway Timeout - Server Slow';
      default: return 'Unknown Error - Status $statusCode';
    }
  }

  // 📝 Get detailed error message with field analysis
  String _getDetailedErrorMessage(int statusCode, Map<String, dynamic> response, Map<String, dynamic>? requestBody) {
    String baseMessage = response['message'] ?? 'Request failed';
    
    switch (statusCode) {
      case 401:
        return '🔐 ${Constants.errorSessionExpired}';
      case 422:
        String validationDetails = '';
        if (response['errors'] != null) {
          Map<String, dynamic> errors = response['errors'];
          validationDetails = '\n🔍 Field Issues:\n';
          errors.forEach((field, error) {
            String sentValue = requestBody?[field]?.toString() ?? 'null';
            validationDetails += '• $field: $error (sent: $sentValue)\n';
          });
        }
        return '⚠️ Validation Error: $baseMessage$validationDetails';
      case 400:
        return '❌ Bad Request: $baseMessage';
      case 403:
        return '🚫 Access Denied: You don\'t have permission to perform this action';
      case 404:
        return '🔍 Not Found: The requested resource was not found';
      case 429:
        return '⏰ Rate Limited: Too many requests. Please try again later';
      case 500:
      case 502:
      case 503:
      case 504:
        return '🔧 ${Constants.errorServerConnection}';
      default:
        return '❓ Error ($statusCode): $baseMessage';
    }
  }

  // 📊 Debug logging helper
  void _debugLog(String emoji, String title, Map<String, dynamic> details) {
    if (!_debugMode) return;
    
    print('\n$emoji ═══════════════════════════════════════');
    print('📍 $title');
    print('⏰ ${DateTime.now().toIso8601String()}');
    print('─────────────────────────────────────────');
    
    details.forEach((key, value) {
      if (value is List) {
        print('📋 $key: [${value.join(', ')}]');
      } else if (value is Map) {
        print('📄 $key:');
        value.forEach((k, v) => print('   • $k: $v'));
      } else {
        print('🔹 $key: $value');
      }
    });
    
    print('═══════════════════════════════════════\n');
  }

  // 🔄 Refresh token if needed with enhanced debugging
  Future<bool> refreshTokenIfNeeded() async {
    if (_refreshToken == null) {
      _debugLog('❌ REFRESH TOKEN', 'No refresh token available', {
        'has_refresh_token': false,
        'current_token_exists': _token != null,
      });
      return false;
    }

    try {
      _debugLog('🔄 TOKEN REFRESH INITIATED', 'Starting token refresh process', {
        'has_refresh_token': _refreshToken != null,
        'refresh_token_length': _refreshToken!.length,
      });

      final response = await post(
        'auth/refresh.php',
        {'refresh_token': _refreshToken!},
        requiresAuth: false,
      );

      if (response.success && response.data != null) {
        final newToken = response.data['token'];
        if (newToken != null) {
          setToken(newToken);
          _debugLog('✅ TOKEN REFRESHED', 'Token successfully refreshed', {
            'new_token_length': newToken.length,
            'refresh_successful': true,
          });
          return true;
        }
      }

      _debugLog('❌ TOKEN REFRESH FAILED', 'Failed to refresh token', {
        'response_success': response.success,
        'has_data': response.data != null,
        'error_message': response.message,
      });
      
      return false;
    } catch (e) {
      _debugLog('💥 TOKEN REFRESH ERROR', 'Unexpected error during token refresh', {
        'error_type': e.runtimeType.toString(),
        'error_message': e.toString(),
      });
      return false;
    }
  }

  // 🌐 Check network connectivity with enhanced debugging
  Future<bool> checkConnectivity() async {
    try {
      _debugLog('🌐 CONNECTIVITY CHECK', 'Checking network connectivity', {
        'health_endpoint': '${AppConfig.baseUrl}health.php',
        'timeout_seconds': 5,
      });

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}health.php'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      bool isConnected = response.statusCode == 200;
      
      _debugLog(isConnected ? '✅ CONNECTIVITY OK' : '❌ CONNECTIVITY FAILED', 'Network connectivity check result', {
        'status_code': response.statusCode,
        'is_connected': isConnected,
        'response_length': response.body.length,
      });

      return isConnected;
    } catch (e) {
      _debugLog('❌ CONNECTIVITY ERROR', 'Network connectivity check failed', {
        'error_type': e.runtimeType.toString(),
        'error_message': e.toString(),
      });
      return false;
    }
  }

  // 🔄 Retry mechanism for failed requests with enhanced debugging
  Future<ApiResponse<T>> _retryRequest<T>(
    Future<ApiResponse<T>> Function() request, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    int retryCount = 0;
    ApiResponse<T> lastResponse;

    _debugLog('🔄 RETRY MECHANISM', 'Starting retry mechanism', {
      'max_retries': maxRetries,
      'initial_delay_ms': delay.inMilliseconds,
    });

    do {
      lastResponse = await request();
      
      _debugLog('🎯 RETRY ATTEMPT', 'Retry attempt completed', {
        'attempt_number': retryCount + 1,
        'success': lastResponse.success,
        'error_message': lastResponse.message,
        'is_network_error': Helpers.isNetworkError(lastResponse.message),
      });

      if (lastResponse.success || retryCount >= maxRetries) {
        break;
      }

      // Check if it's a network error worth retrying
      if (Helpers.isNetworkError(lastResponse.message)) {
        retryCount++;
        if (retryCount < maxRetries) {
          Duration currentDelay = delay * retryCount;
          _debugLog('⏰ RETRY DELAY', 'Waiting before next retry', {
            'retry_count': retryCount,
            'delay_ms': currentDelay.inMilliseconds,
            'remaining_retries': maxRetries - retryCount,
          });
          await Future.delayed(currentDelay);
        }
      } else {
        _debugLog('🚫 NO RETRY', 'Not retrying - non-network error', {
          'error_type': 'Non-network error',
          'message': lastResponse.message,
        });
        break; // Don't retry for non-network errors
      }
    } while (retryCount < maxRetries);

    _debugLog(lastResponse.success ? '✅ RETRY SUCCESS' : '❌ RETRY EXHAUSTED', 'Retry mechanism completed', {
      'total_attempts': retryCount + 1,
      'final_success': lastResponse.success,
      'final_message': lastResponse.message,
    });

    return lastResponse;
  }

  // 📥 GET with retry and enhanced debugging
  Future<ApiResponse<T>> getWithRetry<T>(
    String endpoint, {
    Map<String, String>? queryParams,
    T? Function(dynamic)? fromJson,
    bool requiresAuth = true,
    int maxRetries = 3,
  }) async {
    return _retryRequest(
      () => get(endpoint, queryParams: queryParams, fromJson: fromJson, requiresAuth: requiresAuth),
      maxRetries: maxRetries,
    );
  }

  // 📤 POST with retry and enhanced debugging
  Future<ApiResponse<T>> postWithRetry<T>(
    String endpoint,
    Map<String, dynamic> body, {
    T? Function(dynamic)? fromJson,
    bool requiresAuth = true,
    int maxRetries = 3,
  }) async {
    return _retryRequest(
      () => post(endpoint, body, fromJson: fromJson, requiresAuth: requiresAuth),
      maxRetries: maxRetries,
    );
  }

  // 📁 Download file with enhanced debugging
  Future<Uint8List?> downloadFile(String url) async {
    try {
      _debugLog('📁 DOWNLOAD INITIATED', 'Starting file download', {
        'url': url,
        'has_auth_token': _token != null,
        'timeout_ms': AppConfig.requestTimeout * 2,
      });

      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(Duration(milliseconds: AppConfig.requestTimeout * 2));

      if (response.statusCode == 200) {
        _debugLog('✅ DOWNLOAD SUCCESS', 'File downloaded successfully', {
          'url': url,
          'file_size_bytes': response.bodyBytes.length,
          'content_type': response.headers['content-type'],
        });
        return response.bodyBytes;
      } else {
        _debugLog('❌ DOWNLOAD FAILED', 'File download failed', {
          'url': url,
          'status_code': response.statusCode,
          'error_message': response.reasonPhrase,
        });
        return null;
      }
    } catch (e) {
      _debugLog('💥 DOWNLOAD ERROR', 'Unexpected error during file download', {
        'url': url,
        'error_type': e.runtimeType.toString(),
        'error_message': e.toString(),
      });
      return null;
    }
  }

  // 🛑 Cancel all ongoing requests (for app lifecycle management)
  void cancelAllRequests() {
    _debugLog('🛑 CANCEL REQUESTS', 'Cancelling all ongoing API requests', {
      'has_active_token': _token != null,
      'timestamp': DateTime.now().toIso8601String(),
    });
    // This would require maintaining a list of ongoing requests
    // For now, we'll just clear the token to prevent new authenticated requests
  }

  // 🐛 Toggle debug mode
  void enableDebugMode(bool enable) {
    _debugMode = enable;
    _debugLog('🐛 DEBUG MODE', enable ? 'Debug mode enabled' : 'Debug mode disabled', {
      'previous_state': !enable,
      'current_state': enable,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}

// 🔧 Extension for convenient error handling
extension ApiResponseExtension on ApiResponse {
  bool get isNetworkError => Helpers.isNetworkError(message);
  bool get isAuthError => message.contains('token') || message.contains('auth');
  bool get isValidationError => message.contains('validation') || message.contains('required');
}
