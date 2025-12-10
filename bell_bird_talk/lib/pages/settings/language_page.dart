import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/translations.dart';
import '../../utils/storage_util.dart';

/// 语言设置页面
class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  String _currentLocale = 'zh_CN';

  @override
  void initState() {
    super.initState();
    _loadCurrentLanguage();
  }

  Future<void> _loadCurrentLanguage() async {
    final locale = StorageUtil().getString('app_language') ?? 'zh_CN';
    setState(() {
      _currentLocale = locale;
    });
  }

  Future<void> _changeLanguage(LanguageModel language) async {
    // 保存语言设置
    await StorageUtil().setString('app_language', language.locale);
    
    // 更新 GetX 语言
    final parts = language.locale.split('_');
    Get.updateLocale(Locale(parts[0], parts.length > 1 ? parts[1] : ''));
    
    setState(() {
      _currentLocale = language.locale;
    });

    // 显示提示
    Get.snackbar(
      'language_changed'.tr,
      language.displayName,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.withOpacity(0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('language_settings'.tr),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 当前语言提示
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue.withOpacity(0.1),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${'current_language'.tr}: ${_getCurrentLanguageName()}',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 标题
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Text(
              'select_language'.tr,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          // 语言列表
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: AppLanguages.languages.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: Colors.grey[200],
                    indent: 56,
                  ),
                  itemBuilder: (context, index) {
                    final language = AppLanguages.languages[index];
                    final isSelected = _currentLocale == language.locale;
                    
                    return _buildLanguageItem(language, isSelected);
                  },
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _getCurrentLanguageName() {
    for (var lang in AppLanguages.languages) {
      if (lang.locale == _currentLocale) {
        return lang.displayName;
      }
    }
    return '中文';
  }

  Widget _buildLanguageItem(LanguageModel language, bool isSelected) {
    return Material(
      color: isSelected ? Colors.blue.withOpacity(0.05) : Colors.white,
      child: InkWell(
        onTap: () => _changeLanguage(language),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              // 国旗
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  language.flag,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // 语言名称
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      language.displayName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? Colors.blue : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      language.name.tr,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              
              // 选中图标
              if (isSelected)
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                )
              else
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

