import 'package:dio/dio.dart';
import '../config/constants.dart';
import '../models/response_model.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/log_interceptor.dart';
import 'interceptors/error_interceptor.dart';

/// HTTP 客户端封装
class HttpClient {
  static HttpClient? _instance;
  late Dio _dio;
  
  // 单例模式
  factory HttpClient() {
    _instance ??= HttpClient._internal();
    return _instance!;
  }
  
  HttpClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: Duration(milliseconds: AppConstants.connectTimeout),
      receiveTimeout: Duration(milliseconds: AppConstants.receiveTimeout),
      sendTimeout: Duration(milliseconds: AppConstants.sendTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    // 添加拦截器
    _dio.interceptors.add(AuthInterceptor());
    _dio.interceptors.add(AppLogInterceptor());
    _dio.interceptors.add(ErrorInterceptor());
  }
  
  /// 获取 Dio 实例
  Dio get dio => _dio;
  
  /// 更新 Base URL
  void updateBaseUrl(String url) {
    _dio.options.baseUrl = url;
  }
  
  /// 更新 Token
  void updateToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }
  
  /// 清除 Token
  void clearToken() {
    _dio.options.headers.remove('Authorization');
  }
  
  // ==================== GET 请求 ====================
  
  /// GET 请求
  Future<ResponseModel<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic)? fromJsonT,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return _handleResponse<T>(response, fromJsonT);
    } catch (e) {
      return _handleError<T>(e);
    }
  }
  
  // ==================== POST 请求 ====================
  
  /// POST 请求
  Future<ResponseModel<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic)? fromJsonT,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return _handleResponse<T>(response, fromJsonT);
    } catch (e) {
      return _handleError<T>(e);
    }
  }
  
  // ==================== PUT 请求 ====================
  
  /// PUT 请求
  Future<ResponseModel<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic)? fromJsonT,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return _handleResponse<T>(response, fromJsonT);
    } catch (e) {
      return _handleError<T>(e);
    }
  }
  
  // ==================== DELETE 请求 ====================
  
  /// DELETE 请求
  Future<ResponseModel<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    T Function(dynamic)? fromJsonT,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return _handleResponse<T>(response, fromJsonT);
    } catch (e) {
      return _handleError<T>(e);
    }
  }
  
  // ==================== 文件上传 ====================
  
  /// 上传单个文件
  Future<ResponseModel<T>> uploadFile<T>(
    String path,
    String filePath, {
    String fileKey = 'file',
    Map<String, dynamic>? data,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
    T Function(dynamic)? fromJsonT,
  }) async {
    try {
      final formData = FormData.fromMap({
        fileKey: await MultipartFile.fromFile(filePath),
        ...?data,
      });
      
      final response = await _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
      );
      
      return _handleResponse<T>(response, fromJsonT);
    } catch (e) {
      return _handleError<T>(e);
    }
  }
  
  /// 上传多个文件
  Future<ResponseModel<T>> uploadFiles<T>(
    String path,
    List<String> filePaths, {
    String fileKey = 'files',
    Map<String, dynamic>? data,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
    T Function(dynamic)? fromJsonT,
  }) async {
    try {
      final files = await Future.wait(
        filePaths.map((path) => MultipartFile.fromFile(path)),
      );
      
      final formData = FormData.fromMap({
        fileKey: files,
        ...?data,
      });
      
      final response = await _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
      );
      
      return _handleResponse<T>(response, fromJsonT);
    } catch (e) {
      return _handleError<T>(e);
    }
  }
  
  // ==================== 文件下载 ====================
  
  /// 下载文件
  Future<ResponseModel<String>> downloadFile(
    String url,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      await _dio.download(
        url,
        savePath,
        queryParameters: queryParameters,
        options: options,
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken,
      );
      
      return ResponseModel.success(
        data: savePath,
        message: '下载成功',
      );
    } catch (e) {
      return _handleError<String>(e);
    }
  }
  
  // ==================== 响应处理 ====================
  
  /// 处理响应
  ResponseModel<T> _handleResponse<T>(
    Response response,
    T Function(dynamic)? fromJsonT,
  ) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data;
      
      if (data is Map<String, dynamic>) {
        return ResponseModel<T>.fromJson(data, fromJsonT);
      } else {
        return ResponseModel.success(
          data: data as T?,
          message: '请求成功',
        );
      }
    } else {
      return ResponseModel.error(
        code: response.statusCode ?? -1,
        message: response.statusMessage ?? '请求失败',
      );
    }
  }
  
  /// 处理错误
  ResponseModel<T> _handleError<T>(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return ResponseModel.error(
            code: -1,
            message: '请求超时，请稍后重试',
          );
          
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode ?? -1;
          final message = error.response?.statusMessage ?? '服务器错误';
          return ResponseModel.error(code: statusCode, message: message);
          
        case DioExceptionType.cancel:
          return ResponseModel.error(
            code: -1,
            message: '请求已取消',
          );
          
        case DioExceptionType.connectionError:
          return ResponseModel.error(
            code: -1,
            message: '网络连接失败，请检查网络',
          );
          
        default:
          return ResponseModel.error(
            code: -1,
            message: error.message ?? '未知错误',
          );
      }
    }
    
    return ResponseModel.error(
      code: -1,
      message: error.toString(),
    );
  }
}

