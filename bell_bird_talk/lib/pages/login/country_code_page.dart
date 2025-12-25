import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/login_controller.dart';

/// 区号选择页面
class CountryCodePage extends StatelessWidget {
  const CountryCodePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LoginController>();

    // 区号数据
    final List<Map<String, String>> countryCodes = [
      {'flag': '🇨🇳', 'code': '+86', 'name': '中国'},
      {'flag': '🇺🇸', 'code': '+1', 'name': '美国'},
      {'flag': '🇬🇧', 'code': '+44', 'name': '英国'},
      {'flag': '🇯🇵', 'code': '+81', 'name': '日本'},
      {'flag': '🇰🇷', 'code': '+82', 'name': '韩国'},
      {'flag': '🇩🇪', 'code': '+49', 'name': '德国'},
      {'flag': '🇫🇷', 'code': '+33', 'name': '法国'},
      {'flag': '🇮🇹', 'code': '+39', 'name': '意大利'},
      {'flag': '🇨🇦', 'code': '+1', 'name': '加拿大'},
      {'flag': '🇦🇺', 'code': '+61', 'name': '澳大利亚'},
      {'flag': '🇮🇳', 'code': '+91', 'name': '印度'},
      {'flag': '🇧🇷', 'code': '+55', 'name': '巴西'},
      {'flag': '🇲🇽', 'code': '+52', 'name': '墨西哥'},
      {'flag': '🇪🇸', 'code': '+34', 'name': '西班牙'},
      {'flag': '🇳🇱', 'code': '+31', 'name': '荷兰'},
      {'flag': '🇸🇪', 'code': '+46', 'name': '瑞典'},
      {'flag': '🇳🇴', 'code': '+47', 'name': '挪威'},
      {'flag': '🇩🇰', 'code': '+45', 'name': '丹麦'},
      {'flag': '🇫🇮', 'code': '+358', 'name': '芬兰'},
      {'flag': '🇵🇱', 'code': '+48', 'name': '波兰'},
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // 标题栏
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '选择区号',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 列表
          Expanded(
            child: ListView.builder(
              itemCount: countryCodes.length,
              itemBuilder: (context, index) {
                final country = countryCodes[index];
                return ListTile(
                  leading: Text(
                    country['flag']!,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text('${country['code']} ${country['name']}'),
                  onTap: () {
                    controller.selectedCountryCode.value = country['code']!;
                    controller.selectedFlag.value = country['flag']!;
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}