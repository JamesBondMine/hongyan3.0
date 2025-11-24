import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 本地存储工具类（基于 SharedPreferences）
class StorageUtil {
  static StorageUtil? _instance;
  static SharedPreferences? _prefs;
  
  // 单例模式
  factory StorageUtil() {
    _instance ??= StorageUtil._internal();
    return _instance!;
  }
  
  StorageUtil._internal();
  
  /// 初始化（在 main 函数中调用）
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    print('✅ Storage 初始化成功');
  }
  
  /// 获取 SharedPreferences 实例
  SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('StorageUtil 未初始化，请先调用 StorageUtil.init()');
    }
    return _prefs!;
  }
  
  // ==================== String ====================
  
  /// 保存字符串
  Future<bool> setString(String key, String value) async {
    return await prefs.setString(key, value);
  }
  
  /// 获取字符串
  String? getString(String key, {String? defaultValue}) {
    return prefs.getString(key) ?? defaultValue;
  }
  
  // ==================== Int ====================
  
  /// 保存整数
  Future<bool> setInt(String key, int value) async {
    return await prefs.setInt(key, value);
  }
  
  /// 获取整数
  int? getInt(String key, {int? defaultValue}) {
    return prefs.getInt(key) ?? defaultValue;
  }
  
  // ==================== Double ====================
  
  /// 保存浮点数
  Future<bool> setDouble(String key, double value) async {
    return await prefs.setDouble(key, value);
  }
  
  /// 获取浮点数
  double? getDouble(String key, {double? defaultValue}) {
    return prefs.getDouble(key) ?? defaultValue;
  }
  
  // ==================== Bool ====================
  
  /// 保存布尔值
  Future<bool> setBool(String key, bool value) async {
    return await prefs.setBool(key, value);
  }
  
  /// 获取布尔值
  bool? getBool(String key, {bool? defaultValue}) {
    return prefs.getBool(key) ?? defaultValue;
  }
  
  // ==================== List<String> ====================
  
  /// 保存字符串列表
  Future<bool> setStringList(String key, List<String> value) async {
    return await prefs.setStringList(key, value);
  }
  
  /// 获取字符串列表
  List<String>? getStringList(String key) {
    return prefs.getStringList(key);
  }
  
  // ==================== Object (JSON) ====================
  
  /// 保存对象（转为 JSON）
  Future<bool> setObject(String key, dynamic value) async {
    final jsonString = jsonEncode(value);
    return await setString(key, jsonString);
  }
  
  /// 获取对象（从 JSON）
  T? getObject<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final jsonString = getString(key);
    if (jsonString == null || jsonString.isEmpty) {
      return null;
    }
    
    try {
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return fromJson(jsonMap);
    } catch (e) {
      print('❌ 解析对象失败: $e');
      return null;
    }
  }
  
  /// 保存对象列表
  Future<bool> setObjectList<T>(
    String key,
    List<T> list,
    Map<String, dynamic> Function(T) toJson,
  ) async {
    final jsonList = list.map((item) => toJson(item)).toList();
    final jsonString = jsonEncode(jsonList);
    return await setString(key, jsonString);
  }
  
  /// 获取对象列表
  List<T>? getObjectList<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final jsonString = getString(key);
    if (jsonString == null || jsonString.isEmpty) {
      return null;
    }
    
    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ 解析对象列表失败: $e');
      return null;
    }
  }
  
  // ==================== 其他操作 ====================
  
  /// 删除指定 key
  Future<bool> remove(String key) async {
    return await prefs.remove(key);
  }
  
  /// 清除所有数据
  Future<bool> clear() async {
    return await prefs.clear();
  }
  
  /// 检查 key 是否存在
  bool containsKey(String key) {
    return prefs.containsKey(key);
  }
  
  /// 获取所有 keys
  Set<String> getKeys() {
    return prefs.getKeys();
  }
  
  /// 重新加载数据
  Future<void> reload() async {
    await prefs.reload();
  }
}

/// 扩展方法 - 快速访问
extension StorageExtension on String {
  /// 保存字符串
  Future<bool> saveString(String value) async {
    return await StorageUtil().setString(this, value);
  }
  
  /// 获取字符串
  String? loadString() {
    return StorageUtil().getString(this);
  }
  
  /// 保存整数
  Future<bool> saveInt(int value) async {
    return await StorageUtil().setInt(this, value);
  }
  
  /// 获取整数
  int? loadInt() {
    return StorageUtil().getInt(this);
  }
  
  /// 保存布尔值
  Future<bool> saveBool(bool value) async {
    return await StorageUtil().setBool(this, value);
  }
  
  /// 获取布尔值
  bool? loadBool() {
    return StorageUtil().getBool(this);
  }
  
  /// 删除
  Future<bool> removeKey() async {
    return await StorageUtil().remove(this);
  }
}

