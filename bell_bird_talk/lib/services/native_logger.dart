
// ======================== 日志工具 ========================

import 'dart:convert';

import 'package:flutter/foundation.dart';

/// 原生调用日志工具
class NativeLogger {
  /// 是否启用日志（生产环境可关闭）
  static bool enabled = kDebugMode;
  
  /// 最大结果长度（超过则截断）
  static int maxResultLength = 800;
  
  /// 记录完整的 API 调用（一行输出）
  static void log(String method, dynamic params, dynamic result, Duration duration, {bool isError = false}) {
    if (!enabled) return;
    
    final icon = isError ? '❌' : '✅';
    final paramsStr = _toJson(params);
    final resultStr = _toJson(result);
    
    // 截断过长的结果
    final displayResult = resultStr.length > maxResultLength 
        ? '${resultStr.substring(0, maxResultLength)}...(${resultStr.length}字符)'
        : resultStr;
    
    // 使用 print 输出单行日志，更简洁
    if (kDebugMode) {
      print('\n===================================\n$icon ${duration.inMilliseconds}ms \n[$method]  \n$paramsStr \n----\n$displayResult \n===================================');
    }
  }
  
  /// 转换为 JSON 字符串
  static String _toJson(dynamic data) {
    if (data == null) return 'null';
    try {
      if (data is Map) {
        return json.encode(data);
      }
      return data.toString();
    } catch (e) {
      return data.toString();
    }
  }
}
