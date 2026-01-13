import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:bell_bird_talk/widgets/common_appbar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
      backgroundColor: GbsColors.lightBackgroundA,
      appBar: CommonAppBarView(title: 'language_settings'.tr),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 当前语言提示
          Container(
            height: 52.h,
            alignment: Alignment.center,
            margin: EdgeInsets.only(top: 16,left: 16, right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Image.asset('assets/img/user/settingglobal.png', width: 20.w, height: 20.h,),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'current_language'.tr,
                    style: TextStyle(
                      color: GbsColors.des1Color,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                    _getCurrentLanguageName(),
                    style: TextStyle(
                      color: GbsColors.des6Color,
                      fontSize: 14,
                    ),
                  ),
                Icon(Icons.arrow_forward_ios_outlined,color: GbsColors.des9Color,size: 14.sp,)
              ],
            ),
          ),
          
          // // 标题
          // Padding(
          //   padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          //   child: Text(
          //     'select_language'.tr,
          //     style: TextStyle(
          //       fontSize: 14,
          //       color: Colors.grey[600],
          //       fontWeight: FontWeight.w500,
          //     ),
          //   ),
          // ),
          
          // 语言列表
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
              // Container(
              //   width: 40,
              //   height: 40,
              //   decoration: BoxDecoration(
              //     color: Colors.grey[100],
              //     borderRadius: BorderRadius.circular(20),
              //   ),
              //   alignment: Alignment.center,
              //   child: Text(
              //     language.flag,
              //     style: const TextStyle(fontSize: 24),
              //   ),
              // ),
              
              // const SizedBox(width: 16),
              
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
                    // const SizedBox(height: 2),
                    // Text(
                    //   language.name.tr,
                    //   style: TextStyle(
                    //     fontSize: 13,
                    //     color: Colors.grey[500],
                    //   ),
                    // ),
                  ],
                ),
              ),
              
              // 选中图标
              if (isSelected)
                Container(
                  child: Icon(
                    Icons.check,
                    color: GbsColors.primaryColor,
                    size: 26,
                  ),
                )
              else Container()
            ],
          ),
        ),
      ),
    );
  }
}

