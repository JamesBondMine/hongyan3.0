import 'package:get/get.dart';
import 'translations/zh_cn.dart';
import 'translations/en_us.dart';
import 'translations/ko_kr.dart';
import 'translations/ja_jp.dart';
import 'translations/fr_fr.dart';
import 'translations/de_de.dart';
import 'translations/ru_ru.dart';
import 'translations/bn_bd.dart';

/// 多语言翻译配置
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    // 中文
    'zh_CN': ZhCnTranslations.translations,
    // 英文
    'en_US': EnUsTranslations.translations,
    // 韩语
    'ko_KR': KoKrTranslations.translations,
    // 日语
    'ja_JP': JaJpTranslations.translations,
    // 法语
    'fr_FR': FrFrTranslations.translations,
    // 德语
    'de_DE': DeDeTranslations.translations,
    // 俄语
    'ru_RU': RuRuTranslations.translations,
    // 孟加拉语
    'bn_BD': BnBdTranslations.translations,
  };
}

/// 支持的语言列表
class AppLanguages {
  static const List<LanguageModel> languages = [
    LanguageModel(
      name: 'chinese',
      displayName: '中文',
      locale: 'zh_CN',
      flag: '🇨🇳',
    ),
    LanguageModel(
      name: 'english',
      displayName: 'English',
      locale: 'en_US',
      flag: '🇺🇸',
    ),
    LanguageModel(
      name: 'korean',
      displayName: '한국어',
      locale: 'ko_KR',
      flag: '🇰🇷',
    ),
    LanguageModel(
      name: 'japanese',
      displayName: '日本語',
      locale: 'ja_JP',
      flag: '🇯🇵',
    ),
    LanguageModel(
      name: 'french',
      displayName: 'Français',
      locale: 'fr_FR',
      flag: '🇫🇷',
    ),
    LanguageModel(
      name: 'german',
      displayName: 'Deutsch',
      locale: 'de_DE',
      flag: '🇩🇪',
    ),
    LanguageModel(
      name: 'russian',
      displayName: 'Русский',
      locale: 'ru_RU',
      flag: '🇷🇺',
    ),
    LanguageModel(
      name: 'bengali',
      displayName: 'বাংলা',
      locale: 'bn_BD',
      flag: '🇧🇩',
    ),
  ];
}

/// 语言模型
class LanguageModel {
  final String name;
  final String displayName;
  final String locale;
  final String flag;

  const LanguageModel({
    required this.name,
    required this.displayName,
    required this.locale,
    required this.flag,
  });
}
