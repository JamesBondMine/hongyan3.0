import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/voice_call_controller.dart';
import 'voice_call_page.dart';

/// 语音通话测试页面
/// 用于测试语音通话的最小化功能
class VoiceCallTestPage extends StatelessWidget {
  const VoiceCallTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('语音通话测试'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '语音通话功能测试',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            
            const SizedBox(height: 40),
            
            // 发起语音通话按钮
            ElevatedButton(
              onPressed: () {
                // 发起语音通话
                Get.to(() => const VoiceCallPage(
                  userId: 'test_user_123',
                  nickname: '测试用户',
                  avatar: null,
                  isIncoming: false,
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('发起语音通话'),
            ),
            
            const SizedBox(height: 20),
            
            // 模拟来电按钮
            ElevatedButton(
              onPressed: () {
                // 模拟来电
                Get.to(() => const VoiceCallPage(
                  userId: 'incoming_user_456',
                  nickname: '来电用户',
                  avatar: null,
                  isIncoming: true,
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('模拟来电'),
            ),
            
            const SizedBox(height: 40),
            
            // 当前通话状态显示
            Obx(() {
              final controller = VoiceCallController.to;
              return Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '通话状态: ${controller.callState.value.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('是否通话中: ${controller.isInCall}'),
                    Text('是否最小化: ${controller.isMinimized.value}'),
                    Text('通话时长: ${controller.formatDuration(controller.callDuration.value)}'),
                    if (controller.remoteUser.value != null)
                      Text('对方: ${controller.remoteUser.value!.nickname}'),
                  ],
                ),
              );
            }),
            
            const SizedBox(height: 20),
            
            // 控制按钮
            Obx(() {
              final controller = VoiceCallController.to;
              if (!controller.isInCall) {
                return const SizedBox.shrink();
              }
              
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 最小化按钮
                  if (!controller.isMinimized.value)
                    ElevatedButton(
                      onPressed: () => controller.minimizeCall(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('最小化'),
                    ),
                  
                  // 恢复按钮
                  if (controller.isMinimized.value)
                    ElevatedButton(
                      onPressed: () => controller.restoreCall(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('恢复通话'),
                    ),
                  
                  // 挂断按钮
                  ElevatedButton(
                    onPressed: () => controller.hangUp(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('挂断'),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}