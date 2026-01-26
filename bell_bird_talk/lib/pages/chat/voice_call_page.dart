import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../controllers/voice_call_controller.dart';
import '../../utils/gbs_colors.dart';
import '../../models/user_model.dart';

/// 语音通话页面
class VoiceCallPage extends StatefulWidget {
  final String userId;
  final String nickname;
  final String? avatar;
  final bool isIncoming; // 是否是来电

  const VoiceCallPage({
    super.key,
    required this.userId,
    required this.nickname,
    this.avatar,
    this.isIncoming = false,
  });

  @override
  State<VoiceCallPage> createState() => _VoiceCallPageState();
}

class _VoiceCallPageState extends State<VoiceCallPage> {
  late VoiceCallController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(VoiceCallController());
    
    // 如果是来电，设置对方信息
    if (widget.isIncoming) {
      _controller.remoteUser.value = UserModel(
        id: widget.userId,
        username: widget.userId,
        nickname: widget.nickname,
        avatar: widget.avatar,
      );
    } else {
      // 如果是发起通话，自动发起
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.callUser(
          userId: widget.userId,
          nickname: widget.nickname,
          avatar: widget.avatar,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Obx(() => _buildCallUI(_controller)),
      ),
    );
  }

  Widget _buildCallUI(VoiceCallController controller) {
    final callState = controller.callState.value;
    final remoteUser = controller.remoteUser.value;
    final isMuted = controller.isMuted.value;
    final isHandsFree = controller.isHandsFree.value;
    final callDuration = controller.callDuration.value;

    return Column(
      children: [
        // 顶部状态栏
        _buildTopBar(controller),
        
        // 中间内容区域
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 头像
              _buildAvatar(remoteUser?.avatar),
              
              const SizedBox(height: 24),
              
              // 昵称
              Text(
                remoteUser?.nickname ?? widget.nickname,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // 通话状态/时长
              _buildCallStatus(controller, callState, callDuration),
            ],
          ),
        ),
        
        // 底部控制按钮
        _buildControlButtons(controller, callState, isMuted, isHandsFree),
        
        const SizedBox(height: 40),
      ],
    );
  }

  /// 构建顶部状态栏
  Widget _buildTopBar(VoiceCallController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 返回按钮（仅在非通话中显示）
          if (!controller.isInCall)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Get.back(),
            )
          else
            const SizedBox(width: 48),
          
          // 网络状态（可选）
          const Text(
            '语音通话',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  /// 构建头像
  Widget _buildAvatar(String? avatarUrl) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 2),
      ),
      child: ClipOval(
        child: avatarUrl != null && avatarUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: avatarUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (context, url, error) => _buildDefaultAvatar(),
              )
            : _buildDefaultAvatar(),
      ),
    );
  }

  /// 默认头像
  Widget _buildDefaultAvatar() {
    return Container(
      color: GbsColors.des1Color,
      child: const Icon(
        Icons.person,
        size: 60,
        color: Colors.white70,
      ),
    );
  }

  /// 构建通话状态
  Widget _buildCallStatus(
    VoiceCallController controller,
    CallState callState,
    int callDuration,
  ) {
    String statusText;
    Color statusColor;

    switch (callState) {
      case CallState.calling:
        statusText = controller.isAccepted ? '通话中' : '正在呼叫...';
        statusColor = Colors.white70;
        break;
      case CallState.accept:
        statusText = controller.formatDuration(callDuration);
        statusColor = Colors.white;
        break;
      case CallState.idle:
        statusText = '通话已结束';
        statusColor = Colors.white54;
        break;
    }

    return Text(
      statusText,
      style: TextStyle(
        color: statusColor,
        fontSize: 16,
      ),
    );
  }

  /// 构建控制按钮
  Widget _buildControlButtons(
    VoiceCallController controller,
    CallState callState,
    bool isMuted,
    bool isHandsFree,
  ) {
    // 如果是来电且未接听，显示接听/拒绝按钮
    if (widget.isIncoming && callState == CallState.calling && !controller.isAccepted) {
      return _buildIncomingCallButtons(controller);
    }

    // 通话中的控制按钮
    if (controller.isInCall) {
      return _buildInCallButtons(controller, isMuted, isHandsFree);
    }

    // 呼叫中的按钮（发起方）
    return _buildCallingButtons(controller);
  }

  /// 来电按钮（接听/拒绝）
  Widget _buildIncomingCallButtons(VoiceCallController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 拒绝按钮
        _buildControlButton(
          icon: Icons.call_end,
          backgroundColor: Colors.red,
          onPressed: () => controller.rejectCall(),
          size: 64,
        ),
        
        const SizedBox(width: 40),
        
        // 接听按钮
        _buildControlButton(
          icon: Icons.call,
          backgroundColor: Colors.green,
          onPressed: () => controller.acceptCall(),
          size: 64,
        ),
      ],
    );
  }

  /// 通话中按钮
  Widget _buildInCallButtons(
    VoiceCallController controller,
    bool isMuted,
    bool isHandsFree,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 静音按钮
        _buildControlButton(
          icon: isMuted ? Icons.mic_off : Icons.mic,
          backgroundColor: isMuted ? Colors.red : Colors.white24,
          onPressed: () => controller.toggleMute(),
        ),
        
        // 挂断按钮
        _buildControlButton(
          icon: Icons.call_end,
          backgroundColor: Colors.red,
          onPressed: () => controller.hangUp(),
          size: 64,
        ),
        
        // 免提按钮
        _buildControlButton(
          icon: isHandsFree ? Icons.volume_up : Icons.volume_down,
          backgroundColor: isHandsFree ? Colors.green : Colors.white24,
          onPressed: () => controller.toggleHandsFree(),
        ),
      ],
    );
  }

  /// 呼叫中按钮（发起方）
  Widget _buildCallingButtons(VoiceCallController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 挂断按钮
        _buildControlButton(
          icon: Icons.call_end,
          backgroundColor: Colors.red,
          onPressed: () => controller.hangUp(),
          size: 64,
        ),
      ],
    );
  }

  /// 构建控制按钮
  Widget _buildControlButton({
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback onPressed,
    double size = 56,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: size * 0.5,
        ),
      ),
    );
  }
}
