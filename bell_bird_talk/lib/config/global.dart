import 'dart:ui';

// import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:bell_bird_talk/controllers/global_controller.dart';
import 'package:bell_bird_talk/utils/storage_util.dart';
import 'package:bell_bird_talk/widgets/shower.dart';
import 'package:bell_bird_talk/config/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class Global {
  final shower = Shower();

  // 主域名
  static String mainDomain = 'loadingworks.com';

  static Future init(VoidCallback callback) async {

    // 确保 Flutter 绑定初始化
    WidgetsFlutterBinding.ensureInitialized();

    // 设置状态栏样式
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    // 初始化本地存储
    await StorageUtil.init();

    // 初始化全局控制器
    Get.put(GlobalController());

    await Future.delayed(Duration(milliseconds: 500));
    
    setlang();
    callback();
  }
  /// 将系统语言映射到应用支持的语言
  static String _mapSystemLocaleToAppLocale(Locale systemLocale) {
    final languageCode = systemLocale.languageCode.toLowerCase();
    final countryCode = systemLocale.countryCode?.toUpperCase() ?? '';
    
    // 构建完整的 locale 字符串
    final localeStr = countryCode.isNotEmpty 
        ? '${languageCode}_$countryCode' 
        : languageCode;
    
    // 检查应用是否支持该语言（需要导入 translations.dart）
    // 这里简化处理，只检查常见语言
    final supportedLocales = ['zh_CN', 'en_US', 'ko_KR', 'ja_JP', 'fr_FR', 'de_DE', 'ru_RU', 'bn_BD'];
    
    // 检查应用是否支持该语言
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale == localeStr) {
        return localeStr;
      }
      // 如果完整匹配失败，尝试只匹配语言代码
      if (supportedLocale.startsWith('${languageCode}_')) {
        return supportedLocale;
      }
    }
    
    // 如果不支持，返回默认中文
    return 'zh_CN';
  }

  /// 获取系统语言
  static Locale _getSystemLocale() {
    final systemLocales = PlatformDispatcher.instance.locales;
    if (systemLocales.isNotEmpty) {
      return systemLocales.first;
    }
    // 如果没有系统语言，返回默认中文
    return const Locale('zh', 'CN');
  }

  static void setlang() {
    // 优先使用存储的语言设置
    final storedLocaleStr = StorageUtil().getString('app_language');
    
    String localeStr;
    if (storedLocaleStr != null && storedLocaleStr.isNotEmpty) {
      // 有存储的语言设置，使用它
      localeStr = storedLocaleStr;
    } else {
      // 没有存储的语言设置，跟随系统语言
      final systemLocale = _getSystemLocale();
      localeStr = _mapSystemLocaleToAppLocale(systemLocale);
      print('🌐 未设置应用语言，跟随系统语言: $systemLocale -> $localeStr');
    }
    
    // 更新 GetX 语言
    final parts = localeStr.split('_');
    final localeObj = Locale(parts[0], parts.length > 1 ? parts[1] : '');
    Get.updateLocale(localeObj);
    print('🌐 语言已设置为: $localeStr ($localeObj)');
  }
}

Global gbs = Global();
