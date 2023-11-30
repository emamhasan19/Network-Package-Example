import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:network/network.dart';

part 'api_options.dart';

class FlutterNetwork {
  static final FlutterNetwork _instance = FlutterNetwork._internal();

  FlutterNetwork._internal();

  factory FlutterNetwork({
    required String baseUrl,
    Future<String?> Function()? tokenCallback,
    VoidCallback? onUnAuthorizedError,
    CacheOptions? cacheOptions,
    RetryInterceptor? retryInterceptor,
    int connectionTimeout = 30000,
    int receiveTimeout = 30000,
  }) {
    _instance.baseUrl = baseUrl;
    _instance.tokenCallback = tokenCallback;
    _instance.onUnAuthorizedError = onUnAuthorizedError ?? () {};
    _instance.connectionTimeout = connectionTimeout;
    _instance.receiveTimeout = receiveTimeout;
    _instance.cacheOptions = cacheOptions;
    _instance.retryInterceptor = retryInterceptor;

    BaseOptions options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: Duration(milliseconds: connectionTimeout),
      receiveTimeout: Duration(milliseconds: receiveTimeout),
    );

    _instance._dio = Dio(options);
    return _instance;
  }

  late Dio _dio;
  late int connectionTimeout;
  late int receiveTimeout;
  late String baseUrl;
  late Future<String?> Function()? tokenCallback;
  late VoidCallback onUnAuthorizedError;
  late CacheOptions? cacheOptions;
  late RetryInterceptor? retryInterceptor;

  Future<Response<dynamic>> get(
    String path, {
    APIType apiType = APIType.public,
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
    bool isCacheEnabled = false,
  }) async {
    _setDioInterceptorList(isCacheEnabled: isCacheEnabled);

    final standardHeaders = await _getOptions(apiType);

    return _dio
        .get(path, queryParameters: query, options: standardHeaders)
        .then((value) => value)
        .catchError(_handleException);
  }

  Future<Response<dynamic>> post(
    String path, {
    required Map<String, dynamic> data,
    APIType apiType = APIType.public,
    bool isFormData = false,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? query,
  }) async {
    _setDioInterceptorList();

    final standardHeaders = await _getOptions(apiType);
    if (headers != null) {
      standardHeaders.headers?.addAll(headers);
    }

    if (isFormData) {
      standardHeaders.headers?.addAll({
        'Content-Type': 'multipart/form-data',
      });
    } else {
      if (headers != null) {
        standardHeaders.headers?.addAll(headers);
      }
    }

    return _dio
        .post(
          path,
          data: isFormData ? FormData.fromMap(data) : data,
          options: standardHeaders,
          queryParameters: query,
        )
        .then((value) => value)
        .catchError(_handleException);
  }

  Future<Response<dynamic>> patch(
    String path, {
    required Map<String, dynamic> data,
    APIType apiType = APIType.public,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? query,
  }) async {
    _setDioInterceptorList();

    final standardHeaders = await _getOptions(apiType);
    if (headers != null) {
      standardHeaders.headers?.addAll(headers);
    }

    return _dio
        .patch(
          path,
          data: data,
          options: standardHeaders,
          queryParameters: query,
        )
        .then((value) => value)
        .catchError(_handleException);
  }

  Future<Response<dynamic>> put(
    String path, {
    required Map<String, dynamic> data,
    APIType apiType = APIType.public,
    bool isFormData = false,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? query,
  }) async {
    _setDioInterceptorList();

    final standardHeaders = await _getOptions(apiType);

    if (isFormData) {
      if (headers != null) {
        standardHeaders.headers?.addAll({
          'Content-Type': 'multipart/form-data',
        });
      }
      data.addAll({
        '_method': 'PUT',
      });
    } else {
      if (headers != null) {
        standardHeaders.headers?.addAll(headers);
      }
    }

    return _dio
        .put(
          path,
          data: isFormData ? FormData.fromMap(data) : data,
          options: standardHeaders,
        )
        .then((value) => value)
        .catchError(_handleException);
  }

  Future<Response<dynamic>> delete(
    String path, {
    Map<String, dynamic>? data,
    APIType apiType = APIType.public,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? query,
  }) async {
    _setDioInterceptorList();

    final standardHeaders = await _getOptions(apiType);
    if (headers != null) {
      standardHeaders.headers?.addAll(headers);
    }

    return _dio
        .delete(
          path,
          data: data,
          queryParameters: query,
          options: standardHeaders,
        )
        .then((value) => value)
        .catchError(_handleException);
  }

  dynamic _handleException(error) {
    dynamic errorData = error.response!.data;

    switch (error.response?.statusCode) {
      case 400:
        throw BadRequest(errorData);
      case 401:
        onUnAuthorizedError();
        throw Unauthorized(errorData);
      case 403:
        throw Forbidden(errorData);
      case 404:
        throw NotFound(errorData);
      case 405:
        throw MethodNotAllowed(errorData);
      case 406:
        throw NotAcceptable(errorData);
      case 408:
        throw RequestTimeout(errorData);
      case 409:
        throw Conflict(errorData);
      case 410:
        throw Gone(errorData);
      case 411:
        throw LengthRequired(errorData);
      case 412:
        throw PreconditionFailed(errorData);
      case 413:
        throw PayloadTooLarge(errorData);
      case 414:
        throw URITooLong(errorData);
      case 415:
        throw UnsupportedMediaType(errorData);
      case 416:
        throw RangeNotSatisfiable(errorData);
      case 417:
        throw ExpectationFailed(errorData);
      case 422:
        throw UnprocessableEntity(errorData);
      case 429:
        throw TooManyRequests(errorData);
      case 500:
        throw InternalServerError(errorData);
      case 501:
        throw NotImplemented(errorData);
      case 502:
        throw BadGateway(errorData);
      case 503:
        throw ServiceUnavailable(errorData);
      case 504:
        throw GatewayTimeout(errorData);
      default:
        throw Unexpected(errorData);
    }
  }

  void _setDioInterceptorList({bool isCacheEnabled = false}) async {
    List<Interceptor> interceptorList = [];
    _dio.interceptors.clear();

    if (kDebugMode) {
      interceptorList.add(PrettyDioLogger());
    }

    if (isCacheEnabled && cacheOptions == null) {
      throw Exception('Cache options is null. Please provide cache options');
    } else {
      interceptorList.add(DioCacheInterceptor(options: cacheOptions!));
    }

    if (retryInterceptor != null) {
      interceptorList.add(retryInterceptor!);
    }

    _dio.interceptors.addAll(interceptorList);
  }

  Future<Options> _getOptions(APIType api) async {
    switch (api) {
      case APIType.public:
        return PublicApiOptions().options;

      case APIType.protected:
        if (tokenCallback == null) {
          throw Exception(
              'Token callback is null. Please provide token callback');
        }

        String? token = await tokenCallback!();

        return ProtectedApiOptions(token!).options;

      default:
        return PublicApiOptions().options;
    }
  }
}
