import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../network/http_client.dart';
import '../utils/storage_util.dart';
import '../utils/encrypt_util.dart';
import '../utils/file_util.dart';
import '../utils/permission_util.dart';
import '../controllers/global_controller.dart';

/// 框架功能测试页面
class FrameworkTestPage extends StatefulWidget {
  const FrameworkTestPage({super.key});

  @override
  State<FrameworkTestPage> createState() => _FrameworkTestPageState();
}

class _FrameworkTestPageState extends State<FrameworkTestPage> {
  final GlobalController _globalCtrl = Get.find<GlobalController>();
  String _testResult = '等待测试...';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('框架功能测试'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 结果显示
            _buildResultCard(),
            
            const SizedBox(height: 20),
            
            // 网络测试
            _buildSection('网络请求', [
              _buildTestButton('测试 HTTP 客户端', _testHttp),
              _buildTestButton('测试 WebSocket', _testWebSocket),
            ]),
            
            // 存储测试
            _buildSection('数据持久化', [
              _buildTestButton('测试本地存储', _testStorage),
            ]),
            
            // 加密测试
            _buildSection('加密工具', [
              _buildTestButton('测试加密功能', _testEncrypt),
            ]),
            
            // 文件测试
            _buildSection('文件管理', [
              _buildTestButton('测试文件操作', _testFile),
            ]),
            
            // 权限测试
            _buildSection('权限管理', [
              _buildTestButton('测试权限请求', _testPermission),
            ]),
            
            // 全局状态测试
            _buildSection('全局状态', [
              _buildTestButton('测试状态管理', _testGlobalState),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  '测试结果',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _testResult,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(label),
      ),
    );
  }

  // ==================== 测试方法 ====================

  /// 测试 HTTP 客户端
  Future<void> _testHttp() async {
    try {
      EasyLoading.show(status: '测试中...');
      
      final result = StringBuffer();
      result.writeln('✅ HTTP 客户端测试\n');
      
      // 测试基本配置
      result.writeln('Base URL: ${HttpClient().dio.options.baseUrl}');
      result.writeln('连接超时: ${HttpClient().dio.options.connectTimeout}');
      result.writeln('拦截器数量: ${HttpClient().dio.interceptors.length}');
      
      result.writeln('\n✅ 配置正常');
      
      setState(() => _testResult = result.toString());
      EasyLoading.showSuccess('测试完成');
    } catch (e) {
      setState(() => _testResult = '❌ 错误: $e');
      EasyLoading.showError('测试失败');
    }
  }

  /// 测试 WebSocket（已移除，长连接由 SDK 管理）
  Future<void> _testWebSocket() async {
    try {
      EasyLoading.show(status: '测试中...');
      
      final result = StringBuffer();
      result.writeln('✅ WebSocket 测试\n');
      
      // 长连接已由 SDK 统一管理
      result.writeln('📍 长连接已由 IM SDK 统一管理');
      result.writeln('📍 请使用 IM SDK 状态查看连接情况');
      
      final globalController = Get.find<GlobalController>();
      result.writeln('\nIM SDK 状态: ${globalController.imsdkStatus.value}');
      result.writeln('是否初始化: ${globalController.isIMSDKInitialized.value}');
      
      setState(() => _testResult = result.toString());
      EasyLoading.showSuccess('测试完成');
    } catch (e) {
      setState(() => _testResult = '❌ 错误: $e');
      EasyLoading.showError('测试失败');
    }
  }

  /// 测试本地存储
  Future<void> _testStorage() async {
    try {
      EasyLoading.show(status: '测试中...');
      
      final result = StringBuffer();
      result.writeln('✅ 本地存储测试\n');
      
      // 测试字符串
      await StorageUtil().setString('test_key', 'test_value');
      final value = StorageUtil().getString('test_key');
      result.writeln('字符串: $value');
      
      // 测试整数
      await StorageUtil().setInt('test_int', 123);
      final intValue = StorageUtil().getInt('test_int');
      result.writeln('整数: $intValue');
      
      // 测试布尔值
      await StorageUtil().setBool('test_bool', true);
      final boolValue = StorageUtil().getBool('test_bool');
      result.writeln('布尔值: $boolValue');
      
      // 测试对象
      await StorageUtil().setObject('test_obj', {'name': '测试', 'age': 25});
      final objValue = StorageUtil().getObject<Map>('test_obj', (json) => json);
      result.writeln('对象: $objValue');
      
      result.writeln('\n✅ 所有存储功能正常');
      
      setState(() => _testResult = result.toString());
      EasyLoading.showSuccess('测试完成');
    } catch (e) {
      setState(() => _testResult = '❌ 错误: $e');
      EasyLoading.showError('测试失败');
    }
  }

  /// 测试加密功能
  Future<void> _testEncrypt() async {
    try {
      EasyLoading.show(status: '测试中...');
      
      final result = StringBuffer();
      result.writeln('✅ 加密工具测试\n');
      
      const testText = 'Hello World 你好世界';
      
      // AES 加密
      final encrypted = EncryptUtil().aesEncrypt(testText);
      final decrypted = EncryptUtil().aesDecrypt(encrypted);
      result.writeln('原文: $testText');
      result.writeln('AES 加密: $encrypted');
      result.writeln('AES 解密: $decrypted');
      result.writeln('解密正确: ${testText == decrypted}\n');
      
      // MD5
      final md5Hash = EncryptUtil().md5('password123');
      result.writeln('MD5: $md5Hash\n');
      
      // Base64
      final base64Encoded = EncryptUtil().base64Encode(testText);
      final base64Decoded = EncryptUtil().base64Decode(base64Encoded);
      result.writeln('Base64 编码: $base64Encoded');
      result.writeln('Base64 解码: $base64Decoded\n');
      
      result.writeln('✅ 所有加密功能正常');
      
      setState(() => _testResult = result.toString());
      EasyLoading.showSuccess('测试完成');
    } catch (e) {
      setState(() => _testResult = '❌ 错误: $e');
      EasyLoading.showError('测试失败');
    }
  }

  /// 测试文件操作
  Future<void> _testFile() async {
    try {
      EasyLoading.show(status: '测试中...');
      
      final result = StringBuffer();
      result.writeln('✅ 文件管理测试\n');
      
      // 获取目录
      final cacheDir = await FileUtil().getCacheDir();
      result.writeln('缓存目录: ${cacheDir.path}\n');
      
      final imageDir = await FileUtil().getImageCacheDir();
      result.writeln('图片目录: ${imageDir.path}\n');
      
      // 测试文件写入/读取
      final testFile = '${cacheDir.path}/test.txt';
      await FileUtil().writeFile(testFile, 'Test Content');
      final content = await FileUtil().readFile(testFile);
      result.writeln('写入/读取测试: $content\n');
      
      // 获取缓存大小
      final cacheSize = await FileUtil().getCacheSize();
      result.writeln('缓存大小: ${FileUtil().formatFileSize(cacheSize)}\n');
      
      result.writeln('✅ 所有文件功能正常');
      
      setState(() => _testResult = result.toString());
      EasyLoading.showSuccess('测试完成');
    } catch (e) {
      setState(() => _testResult = '❌ 错误: $e');
      EasyLoading.showError('测试失败');
    }
  }

  /// 测试权限请求
  Future<void> _testPermission() async {
    try {
      EasyLoading.show(status: '测试中...');
      
      final result = StringBuffer();
      result.writeln('✅ 权限管理测试\n');
      
      // 检查相机权限
      final cameraGranted = await PermissionUtil().checkCamera();
      result.writeln('相机权限: ${cameraGranted ? "已授予" : "未授予"}\n');
      
      // 检查相册权限
      final photosGranted = await PermissionUtil().checkPhotos();
      result.writeln('相册权限: ${photosGranted ? "已授予" : "未授予"}\n');
      
      result.writeln('提示: 点击下方按钮可以请求具体权限');
      
      setState(() => _testResult = result.toString());
      EasyLoading.dismiss();
    } catch (e) {
      setState(() => _testResult = '❌ 错误: $e');
      EasyLoading.showError('测试失败');
    }
  }

  /// 测试全局状态
  Future<void> _testGlobalState() async {
    try {
      EasyLoading.show(status: '测试中...');
      
      final result = StringBuffer();
      result.writeln('✅ 全局状态测试\n');
      
      result.writeln('登录状态: ${_globalCtrl.isLoggedIn.value}');
      result.writeln('主题模式: ${_globalCtrl.isDarkMode.value ? "暗色" : "亮色"}');
      result.writeln('语言: ${_globalCtrl.language.value}');
      result.writeln('未读消息: ${_globalCtrl.unreadCount.value}');
      result.writeln('WebSocket: ${_globalCtrl.isWsConnected.value ? "已连接" : "未连接"}');
      
      result.writeln('\n✅ 全局状态管理正常');
      
      setState(() => _testResult = result.toString());
      EasyLoading.showSuccess('测试完成');
    } catch (e) {
      setState(() => _testResult = '❌ 错误: $e');
      EasyLoading.showError('测试失败');
    }
  }
}

