import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/voice_call_controller.dart';
import '../utils/gbs_colors.dart';

/// 语音通话最小化卡片
/// 显示在聊天页面右下角，97*68像素，白色圆角
class VoiceCallCard extends StatelessWidget {
  const VoiceCallCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = VoiceCallController.to;
      
      // 只有在通话中且已最小化时才显示
      if (!controller.isInCall || !controller.isMinimized.value) {
        return const SizedBox.shrink();
      }

      final remoteUser = controller.remoteUser.value;
      final callDuration = controller.callDuration.value;
      final isMuted = controller.isMuted.value;

      return Positioned(
        right: 12,
        bottom: 100, // 在输入框上方
        child: GestureDetector(
          onTap: () => controller.restoreCall(),
          child: Container(
            width: 97,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 头像
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                  child: ClipOval(
                    child: remoteUser?.avatar != null && remoteUser!.avatar!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: remoteUser.avatar!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: GbsColors.des1Color,
                              child: const Icon(
                                Icons.person,
                                size: 16,
                                color: Colors.white70,
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: GbsColors.des1Color,
                              child: const Icon(
                                Icons.person,
                                size: 16,
                                color: Colors.white70,
                              ),
                            ),
                          )
                        : Container(
                            color: GbsColors.des1Color,
                            child: const Icon(
                              Icons.person,
                              size: 16,
                              color: Colors.white70,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // 通话时长
                Text(
                  controller.formatDuration(callDuration),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                const SizedBox(height: 2),
                
                // 状态指示器
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 静音指示器
                    if (isMuted)
                      Icon(
                        Icons.mic_off,
                        size: 10,
                        color: Colors.red[400],
                      ),
                    
                    // 通话状态指示器（绿色圆点）
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}