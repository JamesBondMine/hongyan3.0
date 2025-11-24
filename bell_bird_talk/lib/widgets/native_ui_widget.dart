import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// iOS 原生 UI 组件（通过 Platform View 嵌入）
class NativeUIWidget extends StatelessWidget {
  const NativeUIWidget({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    // 根据平台返回对应的视图
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return SizedBox(
        width: width,
        height: height,
        child: const UiKitView(
          viewType: 'native-ui-view',
          layoutDirection: TextDirection.ltr,
          creationParams: null,
          creationParamsCodec: StandardMessageCodec(),
          // 手势识别配置
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{},
        ),
      );
    }
    
    // 非 iOS 平台显示占位符
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Center(
        child: Text('仅支持 iOS 平台'),
      ),
    );
  }
}

/// iOS 原生地图组件示例
class NativeMapWidget extends StatelessWidget {
  const NativeMapWidget({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return SizedBox(
        width: width,
        height: height,
        child: const UiKitView(
          viewType: 'native-map-view',
          layoutDirection: TextDirection.ltr,
          creationParams: null,
          creationParamsCodec: StandardMessageCodec(),
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{},
        ),
      );
    }
    
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Center(
        child: Text('仅支持 iOS 平台'),
      ),
    );
  }
}

/// Platform View 演示页面
class PlatformViewDemoPage extends StatelessWidget {
  const PlatformViewDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('原生 UI 嵌入演示'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 说明卡片
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Platform View 说明',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Platform View 允许你在 Flutter 中嵌入原生 iOS 视图组件，'
                      '如地图、视频播放器、广告、第三方 SDK UI 等。',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 原生 UI 组件 1
            const Text(
              '示例 1: 原生按钮和标签',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                child: NativeUIWidget(),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 原生 UI 组件 2
            const Text(
              '示例 2: 原生地图（可替换为真实地图 SDK）',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                child: NativeMapWidget(),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 使用场景说明
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '💡 常见使用场景',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildUseCaseItem('地图服务', '集成高德地图、百度地图等原生 SDK'),
                    _buildUseCaseItem('视频播放', '使用 AVPlayer 等原生播放器'),
                    _buildUseCaseItem('广告展示', '集成穿山甲、广点通等广告 SDK'),
                    _buildUseCaseItem('Web 浏览', '使用 WKWebView 实现复杂网页'),
                    _buildUseCaseItem('相机预览', '实时相机预览和特效处理'),
                    _buildUseCaseItem('第三方 UI', '任何原生 iOS UI 组件'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUseCaseItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

