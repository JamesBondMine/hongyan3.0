import 'dart:convert';
import 'dart:io';
import 'package:bell_bird_talk/controllers/user_controller.dart';
import 'package:bell_bird_talk/pages/friends/views/friend_remark_view.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:bell_bird_talk/widgets/common_line.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

import '../../controllers/global_controller.dart';
import '../../services/native_bridge.dart';

/// 个人资料页面
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final GlobalController _globalCtrl = Get.find<GlobalController>();
  final IOSNativeService _nativeBridge = IOSNativeService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isUploadingAvatar = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GbsColors.lightBackgroundA,
      appBar: AppBar(
        title: Text(
          '基本信息'.tr,
          style: TextStyle(
            fontSize: 16,
            color: GbsColors.titleColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        backgroundColor: GbsColors.lightAppBarColorB,
        foregroundColor: GbsColors.titleColor,
        elevation: 0,
        //
      ),
      body: Obx(() {
        final user = _globalCtrl.currentUser.value;

        return SingleChildScrollView(
          child: Column(
            children: [
              // 账号安全
              _buildAccountSecuritySection(user),
            ],
          ),
        );
      }),
    );
  }

  /// 账号安全区域
  Widget _buildAccountSecuritySection(user) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoItem(
            icon: Icons.phone_android,
            label: '头像'.tr,
            value: '',
            trailing: SizedBox(
              width: 32,
              height: 32,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue[100],
                backgroundImage:
                    (user?.avatar != null && user!.avatar!.isNotEmpty)
                    ? CachedNetworkImageProvider(user!.avatar!)
                    : null,
                child: (user?.avatar == null || user!.avatar!.isEmpty)
                    ? const Icon(Icons.person, size: 50, color: Colors.blue)
                    : null,
              ),
            ),
            onTap: () => _showAvatarOptions(),
          ),
          CommonLineView(),
          _buildInfoItem(
            icon: Icons.phone_android,
            label: '用户名'.tr,
            value: _maskPhone(user?.username),
            onTap: () => _showEditUsernameDialog(user?.username),
          ),
          CommonLineView(),
          _buildInfoItem(
            icon: Icons.phone_android,
            label: '昵称'.tr,
            value: _maskPhone(user?.nickname),
            onTap: () => _showEditNicknameDialog(user?.nickname),
          ),
          CommonLineView(),
          _buildInfoItem(
            icon: Icons.phone_android,
            label: '手机号/邮箱'.tr,
            value: user?.phone == '' || user?.phone == null
                ? _maskEmail(user?.email)
                : _maskPhone(user?.phone),
            // onTap: () => _showPhoneBindDialog(user?.phone),
          ),
          // CommonLineView(),
          // _buildInfoItem(
          //   icon: Icons.email,
          //   label: '邮箱'.tr,
          //   value: _maskEmail(user?.email),
          //   onTap: () => _showEmailBindDialog(user?.email),
          // ),
        ],
      ),
    );
  }

  /// 信息项
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    bool canCopy = false,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap:
          onTap ??
          (canCopy && value.isNotEmpty && !value.contains('未')
              ? () => _copyToClipboard(value)
              : null),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon(icon, color: Colors.grey[500], size: 22),
            // const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(color: Colors.grey[700], fontSize: 15),
            ),
            const Spacer(),
            if (value.isNotEmpty)
              Text(
                value,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing],
            if (canCopy && value.isNotEmpty && !value.contains('未')) ...[
              const SizedBox(width: 8),
              Icon(Icons.copy, color: Colors.grey[400], size: 16),
            ] else if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
            ] else ...[
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }

  String _maskPhone(String? phone) {
    if (phone == null || phone.isEmpty) return '未绑定'.tr;
    if (phone.length >= 11) {
      return '${phone.substring(0, 3)}****${phone.substring(phone.length - 4)}';
    }
    return phone;
  }

  String _maskEmail(String? email) {
    if (email == null || email.isEmpty) return '未绑定'.tr;
    final index = email.indexOf('@');
    if (index > 2) {
      return '${email.substring(0, 2)}***${email.substring(index)}';
    }
    return email;
  }

  void _copyToClipboard(String text) {
    if (text.isEmpty || text.contains('未')) return;
    Clipboard.setData(ClipboardData(text: text));
    EasyLoading.showSuccess('已复制'.tr);
  }

  /// 更新性别
  Future<void> _updateGender(int sex) async {
    EasyLoading.show(status: '修改中...'.tr);

    final result = await _nativeBridge.imUpdateSex(sex);

    if (result['errorCode'] == 0) {
      // 更新本地用户信息 (UI显示: 1=男, 2=女，SDK: 0=男, 1=女)
      _globalCtrl.updateUserGender(sex == 0 ? 1 : 2);
      EasyLoading.showSuccess('性别已修改'.tr);
    } else {
      EasyLoading.showError(result['message'] ?? '修改失败'.tr);
    }
  }

  // ==================== 弹窗和操作 ====================

  void _showAvatarOptions() {
    _pickAndUploadAvatar(ImageSource.gallery);
  }

  /// 选择并上传头像
  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    if (_isUploadingAvatar) {
      EasyLoading.showInfo('正在上传中，请稍候'.tr);
      return;
    }

    try {
      // 1. 选择图片
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 90,
      );

      if (pickedFile == null) {
        return;
      }

      // 2. 裁剪图片
      // 注意：Android 支持圆形裁剪框，iOS 只支持方形裁剪框（但显示时会用 CircleAvatar 显示成圆形）
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1), // 强制 1:1 比例
        uiSettings: [
          // Android 设置 - 支持圆形裁剪框
          AndroidUiSettings(
            toolbarTitle: '裁剪头像'.tr,
            toolbarColor: GbsColors.primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: false,
            showCropGrid: false,
          ),
          // iOS 设置 - 只能显示方形裁剪框
          IOSUiSettings(
            title: '裁剪头像'.tr,
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.square, // 只保留方形
            ],
            aspectRatioPickerButtonHidden: true,
            rotateButtonsHidden: false,
          ),
        ],
      );

      if (croppedFile == null) {
        print('❌ 用户取消裁剪');
        return;
      }

      // 3. 上传裁剪后的图片
      setState(() {
        _isUploadingAvatar = true;
      });
      EasyLoading.show(status: '上传中...'.tr);

      final File imageFile = File(croppedFile.path);
      await UserController.to.prepareAvatarInfo(imageFile);
    } catch (e) {
      print('❌ 上传头像异常: $e');
      EasyLoading.showError('${'上传失败'.tr}: $e');
    } finally {
      setState(() {
        _isUploadingAvatar = false;
      });
      EasyLoading.dismiss();
    }
  }

  // 修改用户名
  void _showEditUsernameDialog(String? currentUsername) {
    final controller = TextEditingController(text: currentUsername);
    // 新增分组
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: FriendRemarkView(
            controller: controller,
            tip: '请输入用户名'.tr,
            title: '修改用户名'.tr,
            onTap: () async {
              final newUsername = controller.text.trim();
              if (newUsername.isEmpty) {
                EasyLoading.showError('用户名不能为空'.tr);
                return;
              }

              Get.back();
              EasyLoading.show(status: '修改中...'.tr);

              final result = await _nativeBridge.imUpdateUsername(newUsername);

              if (result['errorCode'] == 0) {
                // 更新本地用户信息
                _globalCtrl.updateUserUsername(newUsername);
                EasyLoading.showSuccess('用户名修改成功'.tr);
              } else {
                EasyLoading.showError(result['message'] ?? '修改失败'.tr);
              }
            },
          ),
        );
      },
    );
  }

  // 修改昵称
  void _showEditNicknameDialog(String? currentNickname) {
    final controller = TextEditingController(text: currentNickname);
    // 新增分组
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: FriendRemarkView(
            controller: controller,
            tip: '请输入昵称'.tr,
            title: '修改昵称'.tr,
            onTap: () async {
              final newNickname = controller.text.trim();
              if (newNickname.isEmpty) {
                EasyLoading.showError('昵称不能为空'.tr);
                return;
              }

              Get.back();
              EasyLoading.show(status: '修改中...'.tr);

              final result = await _nativeBridge.imUpdateNickname(newNickname);

              if (result['errorCode'] == 0) {
                // 更新本地用户信息
                _globalCtrl.updateUserNickname(newNickname);
                EasyLoading.showSuccess('昵称修改成功'.tr);
              } else {
                EasyLoading.showError(result['message'] ?? '修改失败'.tr);
              }
            },
          ),
        );
      },
    );
  }

  void _showPhoneBindDialog(String? currentPhone) {
    if (currentPhone != null && currentPhone.isNotEmpty) {
      // 已绑定，显示换绑选项
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.swap_horiz, color: Colors.blue),
                title: Text('更换手机号'.tr),
                onTap: () {
                  Get.back();
                  EasyLoading.showInfo('换绑手机号功能开发中'.tr);
                },
              ),
              ListTile(
                leading: const Icon(Icons.link_off, color: Colors.red),
                title: Text('解绑手机号'.tr),
                onTap: () {
                  Get.back();
                  EasyLoading.showInfo('解绑手机号功能开发中'.tr);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                title: Text('取消'.tr, textAlign: TextAlign.center),
                onTap: () => Get.back(),
              ),
            ],
          ),
        ),
      );
    } else {
      EasyLoading.showInfo('绑定手机号功能开发中'.tr);
    }
  }

  void _showEmailBindDialog(String? currentEmail) {
    if (currentEmail != null && currentEmail.isNotEmpty) {
      // 已绑定，显示换绑选项
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.swap_horiz, color: Colors.blue),
                title: Text('更换邮箱'.tr),
                onTap: () {
                  Get.back();
                  EasyLoading.showInfo('换绑邮箱功能开发中'.tr);
                },
              ),
              ListTile(
                leading: const Icon(Icons.link_off, color: Colors.red),
                title: Text('解绑邮箱'.tr),
                onTap: () {
                  Get.back();
                  EasyLoading.showInfo('解绑邮箱功能开发中'.tr);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                title: Text('取消'.tr, textAlign: TextAlign.center),
                onTap: () => Get.back(),
              ),
            ],
          ),
        ),
      );
    } else {
      EasyLoading.showInfo('绑定邮箱功能开发中'.tr);
    }
  }
}
