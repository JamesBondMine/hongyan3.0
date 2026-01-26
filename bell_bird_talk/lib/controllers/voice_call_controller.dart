import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
// TODO: 根据tencent_calls_uikit的实际API调整导入和调用
// import 'package:tencent_calls_uikit/tencent_calls_uikit.dart';
import '../controllers/global_controller.dart';
import '../models/user_model.dart';
import '../pages/chat/voice_call_page.dart';

/// 语音通话控制器
/// 管理语音通话的状态和逻辑
/// 
/// 注意：此实现需要根据tencent_calls_uikit的实际API进行调整
/// 请参考官方文档：https://pub.dev/packages/tencent_calls_uikit
class VoiceCallController extends GetxController {
  static VoiceCallController get to => Get.put(VoiceCallController());

  final GlobalController _globalCtrl = Get.find<GlobalController>();

  // 通话状态
  final Rx<CallState> callState = CallState.idle.obs;
  
  // 通话时长（秒）
  final RxInt callDuration = 0.obs;
  
  // 是否静音
  final RxBool isMuted = false.obs;
  
  // 是否免提
  final RxBool isHandsFree = true.obs;
  
  // 对方用户信息
  final Rx<UserModel?> remoteUser = Rx<UserModel?>(null);
  
  // 🔥 新增：是否最小化
  final RxBool isMinimized = false.obs;
  
  // 当前用户信息
  UserModel? get currentUser => _globalCtrl.currentUser.value;
  
  // 是否正在通话中
  bool get isInCall => callState.value == CallState.accept || callState.value == CallState.calling;
  
  // 是否已接听
  bool get isAccepted => callState.value == CallState.accept;

  @override
  void onInit() {
    super.onInit();
    _initCallKit();
  }

  @override
  void onClose() {
    _disposeCallKit();
    super.onClose();
  }

  /// 初始化TUICallKit
  /// TODO: 根据tencent_calls_uikit的实际API实现
  void _initCallKit() {
    try {
      // TODO: 设置用户信息
      // 示例：
      // if (currentUser != null) {
      //   TUICallKit.instance.setSelfInfo(...);
      // }
      
      // TODO: 设置事件监听
      // 示例：
      // TUICallKit.instance.setCallingListener(
      //   TUICallingListener(
      //     onCallBegin: (callId, callerId, calleeIdList, callType, isGroup) {
      //       callState.value = CallState.calling;
      //       _startCallTimer();
      //     },
      //     onCallEnd: (callId, callType, totalTime) {
      //       callState.value = CallState.idle;
      //       _stopCallTimer();
      //       Get.back();
      //     },
      //     // ... 其他回调
      //   ),
      // );
      
      print('📞 TUICallKit初始化（需要根据实际API实现）');
    } catch (e) {
      print('❌ 初始化TUICallKit失败: $e');
    }
  }

  /// 释放TUICallKit资源
  /// TODO: 根据tencent_calls_uikit的实际API实现
  void _disposeCallKit() {
    try {
      // TODO: 清理资源
      // 示例：
      // TUICallKit.instance.setCallingListener(null);
      print('📞 TUICallKit资源释放（需要根据实际API实现）');
    } catch (e) {
      print('❌ 释放TUICallKit失败: $e');
    }
  }

  /// 发起语音通话
  /// [userId] 对方用户ID
  /// [nickname] 对方昵称
  /// [avatar] 对方头像
  /// TODO: 根据tencent_calls_uikit的实际API实现
  Future<void> callUser({
    required String userId,
    required String nickname,
    String? avatar,
  }) async {
    try {
      if (currentUser == null) {
        EasyLoading.showError('请先登录');
        return;
      }

      remoteUser.value = UserModel(
        id: userId,
        username: userId,
        nickname: nickname,
        avatar: avatar,
      );

      callState.value = CallState.calling;

      // TODO: 调用TUICallKit发起语音通话
      // 示例：
      // await TUICallKit.instance.call(
      //   userId,
      //   CallType.audio, // 或 TUICallMediaType.audio
      // );

      print('📞 发起语音通话: $userId（需要根据实际API实现）');
      
      // 临时：模拟通话开始（实际使用时删除）
      Future.delayed(const Duration(seconds: 2), () {
        if (callState.value == CallState.calling) {
          callState.value = CallState.accept;
          _startCallTimer();
        }
      });
    } catch (e) {
      print('❌ 发起通话失败: $e');
      EasyLoading.showError('发起通话失败');
      callState.value = CallState.idle;
    }
  }

  /// 接听通话
  /// TODO: 根据tencent_calls_uikit的实际API实现
  Future<void> acceptCall() async {
    try {
      // TODO: 调用TUICallKit接听
      // 示例：
      // await TUICallKit.instance.accept();
      
      callState.value = CallState.accept;
      _startCallTimer();
      print('✅ 接听通话（需要根据实际API实现）');
    } catch (e) {
      print('❌ 接听失败: $e');
      EasyLoading.showError('接听失败');
    }
  }

  /// 拒绝通话
  /// TODO: 根据tencent_calls_uikit的实际API实现
  Future<void> rejectCall() async {
    try {
      // TODO: 调用TUICallKit拒绝
      // 示例：
      // await TUICallKit.instance.reject();
      
      callState.value = CallState.idle;
      _stopCallTimer();
      Get.back();
      print('❌ 拒绝通话（需要根据实际API实现）');
    } catch (e) {
      print('❌ 拒绝失败: $e');
      EasyLoading.showError('拒绝失败');
    }
  }

  /// 挂断通话
  /// TODO: 根据tencent_calls_uikit的实际API实现
  Future<void> hangUp() async {
    try {
      // TODO: 调用TUICallKit挂断
      // 示例：
      // await TUICallKit.instance.hangup();
      
      callState.value = CallState.idle;
      isMinimized.value = false; // 挂断时重置最小化状态
      _stopCallTimer();
      Get.back();
      print('📞 挂断通话（需要根据实际API实现）');
    } catch (e) {
      print('❌ 挂断失败: $e');
      EasyLoading.showError('挂断失败');
    }
  }

  /// 🔥 新增：最小化通话
  void minimizeCall() {
    if (isInCall) {
      isMinimized.value = true;
      Get.back(); // 关闭通话页面
      print('📱 通话已最小化');
    }
  }

  /// 🔥 新增：恢复通话（从最小化状态）
  void restoreCall() {
    if (isInCall && isMinimized.value) {
      isMinimized.value = false;
      // 重新打开通话页面
      Get.to(() => VoiceCallPage(
        userId: remoteUser.value?.id ?? '',
        nickname: remoteUser.value?.nickname ?? '',
        avatar: remoteUser.value?.avatar,
        isIncoming: false,
      ));
      print('📱 通话已恢复');
    }
  }

  /// 切换静音
  /// TODO: 根据tencent_calls_uikit的实际API实现
  void toggleMute() {
    try {
      isMuted.value = !isMuted.value;
      
      // TODO: 调用TUICallKit静音
      // 示例：
      // TUICallKit.instance.muteMicrophone(isMuted.value);
      
      print('🔇 静音: ${isMuted.value}（需要根据实际API实现）');
    } catch (e) {
      print('❌ 切换静音失败: $e');
    }
  }

  /// 切换免提
  /// TODO: 根据tencent_calls_uikit的实际API实现
  void toggleHandsFree() {
    try {
      isHandsFree.value = !isHandsFree.value;
      
      // TODO: 调用TUICallKit免提
      // 示例：
      // TUICallKit.instance.setHandsFree(isHandsFree.value);
      
      print('🔊 免提: ${isHandsFree.value}（需要根据实际API实现）');
    } catch (e) {
      print('❌ 切换免提失败: $e');
    }
  }

  // 通话计时器
  int _timerSeconds = 0;
  Worker? _timerWorker;

  /// 开始通话计时
  void _startCallTimer() {
    _timerSeconds = 0;
    _stopCallTimer();
    
    // 使用Timer实现计时
    _timerWorker = ever(callState, (state) {
      if (state == CallState.accept || state == CallState.calling) {
        Future.delayed(const Duration(seconds: 1), () {
          if (isInCall) {
            _timerSeconds++;
            callDuration.value = _timerSeconds;
            _startCallTimer();
          }
        });
      }
    });
    
    // 立即开始计时
    if (isInCall) {
      Future.delayed(const Duration(seconds: 1), () {
        if (isInCall) {
          _timerSeconds++;
          callDuration.value = _timerSeconds;
          _startCallTimer();
        }
      });
    }
  }

  /// 停止通话计时
  void _stopCallTimer() {
    _timerWorker?.dispose();
    _timerWorker = null;
    _timerSeconds = 0;
    callDuration.value = 0;
  }

  /// 格式化通话时长
  String formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }
}

/// 通话状态枚举
enum CallState {
  idle,      // 空闲
  calling,   // 呼叫中
  accept,    // 已接听
}
