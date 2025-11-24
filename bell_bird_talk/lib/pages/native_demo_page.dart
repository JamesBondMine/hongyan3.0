import 'package:flutter/material.dart';
import '../services/native_bridge.dart';
import '../widgets/native_ui_widget.dart';

/// 原生功能演示页面
class NativeDemoPage extends StatefulWidget {
  const NativeDemoPage({super.key});

  @override
  State<NativeDemoPage> createState() => _NativeDemoPageState();
}

class _NativeDemoPageState extends State<NativeDemoPage> {
  final IOSNativeService _nativeService = IOSNativeService();
  String _result = '等待操作...';
  
  @override
  void initState() {
    super.initState();
    _listenToNativeEvents();
  }

  /// 监听来自 iOS 的事件流
  void _listenToNativeEvents() {
    NativeBridge().eventStream.listen((event) {
      print('收到 iOS 事件: $event');
      setState(() {
        _result = '收到事件: $event';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter ↔️ iOS 原生互通演示'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 结果显示区
            _buildResultCard(),
            
            const SizedBox(height: 24),
            
            // 数据互通
            _buildSection(
              title: '📱 数据互通',
              children: [
                _buildButton('获取设备信息', _getDeviceInfo),
                _buildButton('保存数据到原生', _saveDataToNative),
                _buildButton('从原生读取数据', _loadDataFromNative),
              ],
            ),
            
            // iOS SDK 调用
            _buildSection(
              title: '🔧 iOS SDK 调用',
              children: [
                _buildButton('获取通讯录', _getContacts),
                _buildButton('打开相机', _openCamera),
                _buildButton('发送本地通知', _sendNotification),
              ],
            ),
            
            // 原生 UI
            _buildSection(
              title: '🎨 原生 UI',
              children: [
                _buildButton('打开系统设置', _openSettings),
                _buildButton('显示原生弹窗', _showNativeAlert),
              ],
            ),
            
            // 聊天功能
            _buildSection(
              title: '💬 聊天功能示例',
              children: [
                _buildButton('处理消息（加密）', _processMessage),
                _buildButton('同步聊天数据', _syncChatData),
              ],
            ),
            
            // Platform View 演示
            _buildSection(
              title: '🎯 原生 UI 嵌入',
              children: [
                _buildButton('查看 Platform View 演示', _openPlatformViewDemo),
              ],
            ),
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
            const Text(
              '📋 操作结果',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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
                _result,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
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

  Widget _buildButton(String label, VoidCallback onPressed) {
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

  // ==================== 功能实现 ====================

  // 数据互通
  Future<void> _getDeviceInfo() async {
    try {
      final info = await _nativeService.getDeviceInfo();
      setState(() {
        _result = '设备信息:\n${_formatJson(info)}';
      });
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _saveDataToNative() async {
    try {
      final success = await _nativeService.saveToNative(
        'test_key',
        {'message': 'Hello from Flutter!', 'timestamp': DateTime.now().toString()},
      );
      setState(() {
        _result = success == true ? '✅ 数据保存成功' : '❌ 数据保存失败';
      });
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _loadDataFromNative() async {
    try {
      final data = await _nativeService.loadFromNative('test_key');
      setState(() {
        _result = data != null ? '读取数据:\n${_formatJson(data)}' : '❌ 未找到数据';
      });
    } catch (e) {
      _showError(e);
    }
  }

  // iOS SDK 调用
  Future<void> _getContacts() async {
    try {
      final contacts = await _nativeService.getContacts();
      setState(() {
        _result = contacts != null 
            ? '通讯录 (${contacts.length} 个):\n${contacts.take(5).map((c) => c['givenName']).join(', ')}'
            : '❌ 获取失败';
      });
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _openCamera() async {
    try {
      final path = await _nativeService.openCamera();
      setState(() {
        _result = path != null ? '相机返回: $path' : '❌ 取消或失败';
      });
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _sendNotification() async {
    try {
      await _nativeService.sendLocalNotification(
        '铃鸟聊天',
        '这是一条来自 Flutter 的测试通知！',
      );
      setState(() {
        _result = '✅ 通知已发送';
      });
    } catch (e) {
      _showError(e);
    }
  }

  // 原生 UI
  Future<void> _openSettings() async {
    try {
      await _nativeService.openNativePage('settings', null);
      setState(() {
        _result = '✅ 已打开系统设置';
      });
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _showNativeAlert() async {
    try {
      final confirmed = await _nativeService.showNativeAlert(
        '原生弹窗',
        '这是一个 iOS 原生 UIAlertController',
      );
      setState(() {
        _result = confirmed == true ? '✅ 用户点击了确定' : '❌ 用户点击了取消';
      });
    } catch (e) {
      _showError(e);
    }
  }

  // 聊天功能
  Future<void> _processMessage() async {
    try {
      final result = await _nativeService.processMessage('Hello, this is a secret message!');
      setState(() {
        _result = '消息处理结果:\n${_formatJson(result)}';
      });
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _syncChatData() async {
    try {
      final messages = [
        {'id': 1, 'text': '你好', 'timestamp': DateTime.now().toString()},
        {'id': 2, 'text': '你好啊', 'timestamp': DateTime.now().toString()},
      ];
      final success = await _nativeService.syncChatData(messages);
      setState(() {
        _result = success == true ? '✅ 聊天数据同步成功' : '❌ 同步失败';
      });
    } catch (e) {
      _showError(e);
    }
  }

  // Platform View 演示
  void _openPlatformViewDemo() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PlatformViewDemoPage()),
    );
  }

  // 辅助方法
  void _showError(dynamic error) {
    setState(() {
      _result = '❌ 错误: $error';
    });
  }

  String _formatJson(dynamic data) {
    if (data is Map) {
      return data.entries.map((e) => '  ${e.key}: ${e.value}').join('\n');
    }
    return data.toString();
  }
}

