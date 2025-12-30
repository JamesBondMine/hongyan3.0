import 'dart:ui';

// import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:bell_bird_talk/widgets/shower.dart';
import 'package:get/get.dart';

class Global {
  final shower = Shower();
  static Future init(VoidCallback callback) async {
    setlang();
    callback();
  }

  static void setlang() {
    String lan = getLanguage();
    if (lan.isEmpty || lan == 'en') {
      Get.updateLocale(const Locale("en", "US"));
      return;
    }
    if (lan == 'zh') {
      Get.updateLocale(const Locale("zh", "CN"));
      return;
    }
    if (lan == 'hi') {
      Get.updateLocale(const Locale("hi", "IN"));
      return;
    }
  }

  static String getLanguage() {
    var defaultCode = "en";
    String languageCode = 'zh';
    return languageCode;
  }
}

Global gbs = Global();
