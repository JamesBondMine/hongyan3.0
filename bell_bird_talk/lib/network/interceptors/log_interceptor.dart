import 'package:dio/dio.dart';
import 'dart:convert';

/// 日志拦截器 - 打印请求和响应信息
class AppLogInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    print('╔════════════════════════════════════════════════════════════════');
    print('║ 📤 REQUEST [${options.method}] ${options.uri}');
    print('║ Headers: ${options.headers}');
    if (options.queryParameters.isNotEmpty) {
      print('║ Query Parameters: ${options.queryParameters}');
    }
    if (options.data != null) {
      try {
        print('║ Body: ${_formatJson(options.data)}');
      } catch (e) {
        print('║ Body: ${options.data}');
      }
    }
    print('╚════════════════════════════════════════════════════════════════');
    
    handler.next(options);
  }
  
  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    print('╔════════════════════════════════════════════════════════════════');
    print('║ 📥 RESPONSE [${response.statusCode}] ${response.requestOptions.uri}');
    try {
      print('║ Data: ${_formatJson(response.data)}');
    } catch (e) {
      print('║ Data: ${response.data}');
    }
    print('╚════════════════════════════════════════════════════════════════');
    
    handler.next(response);
  }
  
  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    print('╔════════════════════════════════════════════════════════════════');
    print('║ ❌ ERROR [${err.response?.statusCode}] ${err.requestOptions.uri}');
    print('║ Message: ${err.message}');
    if (err.response != null) {
      try {
        print('║ Error Data: ${_formatJson(err.response?.data)}');
      } catch (e) {
        print('║ Error Data: ${err.response?.data}');
      }
    }
    print('╚════════════════════════════════════════════════════════════════');
    
    handler.next(err);
  }
  
  /// 格式化 JSON
  String _formatJson(dynamic data) {
    if (data is Map || data is List) {
      return const JsonEncoder.withIndent('  ').convert(data);
    }
    return data.toString();
  }
}

