import 'package:dio/dio.dart';

/// 错误拦截器 - 统一错误处理和提示
class ErrorInterceptor extends Interceptor {
  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    String errorMessage = _getErrorMessage(err);
    
    // 显示错误提示（根据需要开启）
    // EasyLoading.showError(errorMessage);
    
    print('❌ Error: $errorMessage');
    
    handler.next(err);
  }
  
  /// 获取错误信息
  String _getErrorMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return '连接超时，请检查网络';
      case DioExceptionType.sendTimeout:
        return '请求超时，请稍后重试';
      case DioExceptionType.receiveTimeout:
        return '响应超时，请稍后重试';
      case DioExceptionType.badResponse:
        return _getHttpErrorMessage(error.response?.statusCode);
      case DioExceptionType.cancel:
        return '请求已取消';
      case DioExceptionType.connectionError:
        return '网络连接失败';
      default:
        return '未知错误';
    }
  }
  
  /// 获取 HTTP 状态码对应的错误信息
  String _getHttpErrorMessage(int? statusCode) {
    switch (statusCode) {
      case 400:
        return '请求参数错误';
      case 401:
        return '未授权，请重新登录';
      case 403:
        return '拒绝访问';
      case 404:
        return '请求的资源不存在';
      case 405:
        return '请求方法不允许';
      case 408:
        return '请求超时';
      case 500:
        return '服务器内部错误';
      case 502:
        return '网关错误';
      case 503:
        return '服务不可用';
      case 504:
        return '网关超时';
      default:
        return '服务器错误 ($statusCode)';
    }
  }
}

