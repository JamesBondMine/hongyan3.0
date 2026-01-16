import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

/// Shader预热工具类
/// 用于在应用启动时预热常用的shader，减少首次渲染卡顿
/// 
/// 这个实现模拟了聊天页面中常用的渲染效果：
/// - 圆角矩形（消息气泡）
/// - 圆形头像
/// - 阴影效果
/// - 渐变
/// - 文本渲染
/// - 图片渲染
class AppShaderWarmUp extends ShaderWarmUp {
  const AppShaderWarmUp();

  @override
  Size get size => const Size(400, 500);

  @override
  Future<void> warmUpOnCanvas(Canvas canvas) async {
    final size = this.size;
    try {
      // 1. 预热圆角矩形（聊天消息气泡常用）
      final roundedRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(10, 10, size.width - 20, 60),
        const Radius.circular(8),
      );
      
      // 蓝色气泡（自己发送的消息）
      final bluePaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.fill;
      canvas.drawRRect(roundedRect, bluePaint);
      
      // 白色气泡（对方发送的消息）
      final whiteRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(10, 80, size.width - 20, 60),
        const Radius.circular(8),
      );
      final whitePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawRRect(whiteRect, whitePaint);
      
      // 2. 预热阴影效果（消息气泡阴影）
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawRRect(roundedRect.shift(const Offset(0, 2)), shadowPaint);
      
      // 3. 预热圆形（头像）
      final circlePaint = Paint()
        ..color = Colors.grey[300]!
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        const Offset(30, 200),
        18,
        circlePaint,
      );
      
      // 4. 预热渐变效果
      final gradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.blue.shade300,
          Colors.blue.shade600,
        ],
      );
      final gradientPaint = Paint()
        ..shader = gradient.createShader(
          Rect.fromLTWH(10, 250, size.width - 20, 40),
        );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(10, 250, size.width - 20, 40),
          const Radius.circular(8),
        ),
        gradientPaint,
      );
      
      // 5. 预热文本渲染（模拟消息文本）
      final textPainter = TextPainter(
        text: const TextSpan(
          text: '这是一条测试消息',
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      );
      textPainter.layout(maxWidth: size.width - 40);
      textPainter.paint(canvas, const Offset(20, 30));
      
      // 6. 预热路径绘制（用于复杂形状，如三角形指示器）
      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(10, 0)
        ..lineTo(5, 8)
        ..close();
      final pathPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, pathPaint);
      
      // 7. 预热图片渲染（模拟）
      final testImage = await _createTestImage();
      canvas.drawImageRect(
        testImage,
        Rect.fromLTWH(0, 0, 50, 50),
        Rect.fromLTWH(10, 300, 50, 50),
        Paint(),
      );
      testImage.dispose();
      
      // 8. 预热带边框的圆角矩形
      final borderPaint = Paint()
        ..color = Colors.grey[300]!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(10, 360, size.width - 20, 40),
          const Radius.circular(8),
        ),
        borderPaint,
      );
      
      debugPrint('✅ Shader预热完成');
    } catch (e) {
      debugPrint('⚠️ Shader预热失败: $e');
    }
  }
  
  /// 创建一个测试图片用于预热
  static Future<ui.Image> _createTestImage() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = Colors.grey[400]!;
    canvas.drawRect(const Rect.fromLTWH(0, 0, 50, 50), paint);
    final picture = recorder.endRecording();
    final image = await picture.toImage(50, 50);
    picture.dispose();
    return image;
  }
}
