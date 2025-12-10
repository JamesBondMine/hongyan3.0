import 'package:get/get.dart';

/// 多语言翻译配置
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    // 中文
    'zh_CN': {
      'language_settings': '语言设置',
      'select_language': '选择语言',
      'chinese': '中文',
      'english': 'English',
      'korean': '한국어',
      'current_language': '当前语言',
      'language_changed': '语言已切换',
    },
    // 英文
    'en_US': {
      'language_settings': 'Language Settings',
      'select_language': 'Select Language',
      'chinese': '中文',
      'english': 'English',
      'korean': '한국어',
      'current_language': 'Current Language',
      'language_changed': 'Language Changed',
    },
    // 韩语
    'ko_KR': {
      'language_settings': '언어 설정',
      'select_language': '언어 선택',
      'chinese': '中文',
      'english': 'English',
      'korean': '한국어',
      'current_language': '현재 언어',
      'language_changed': '언어가 변경되었습니다',
    },
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

