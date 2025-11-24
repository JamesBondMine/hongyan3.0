import 'package:dio/dio.dart';
import '../../utils/storage_util.dart';
import '../../config/constants.dart';

/// 认证拦截器 - 自动添加 Token
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 从本地存储获取 Token
    final token = await StorageUtil().getString(AppConstants.keyToken);
    
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    // 添加设备信息
    options.headers['Platform'] = 'iOS';
    options.headers['App-Version'] = AppConstants.appVersion;
    
    handler.next(options);
  }
  
  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    handler.next(response);
  }
  
  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    // Token 过期处理
    if (err.response?.statusCode == 401) {
      // 清除本地 Token
      StorageUtil().remove(AppConstants.keyToken);
      
      // 可以在这里跳转到登录页
      // Get.offAllNamed('/login');
    }
    
    handler.next(err);
  }
}

