import 'dart:convert';
import 'dart:io';
import 'package:bell_bird_talk/pages/friends/views/friend_remark_view.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:bell_bird_talk/widgets/common_line.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
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
        title: const Text('基本信息', style: TextStyle(fontSize: 16, color: GbsColors.titleColor, fontWeight: FontWeight.w500)),
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
            label: '头像',
            value: '',
            trailing: SizedBox(width: 32,height: 32,child: CircleAvatar(
                    radius: 16,
                    
                    backgroundColor: Colors.blue[100],
                    backgroundImage: (user?.avatar != null && user!.avatar!.isNotEmpty)
                        ? CachedNetworkImageProvider(user!.avatar!, maxWidth: 32, maxHeight: 32)
                        : null,
                    child: (user?.avatar == null || user!.avatar!.isEmpty)
                        ? const Icon(Icons.person, size: 50, color: Colors.blue)
                        : null,
                  ),),
            onTap: () => _showAvatarOptions()
          ),
          CommonLineView(),
                     _buildInfoItem(
            icon: Icons.phone_android,
            label: '用户名',
            value: _maskPhone(user?.username),
            onTap: () => _showEditUsernameDialog(user?.username),
          ),
          CommonLineView(),
           _buildInfoItem(
            icon: Icons.phone_android,
            label: '昵称',
            value: _maskPhone(user?.nickname),
            onTap: () => _showEditNicknameDialog(user?.nickname),
          ),
          CommonLineView(),
          _buildInfoItem(
            icon: Icons.phone_android,
            label: '手机号',
            value: _maskPhone(user?.phone),
            onTap: () => _showPhoneBindDialog(user?.phone),
          ),
          CommonLineView(),
          _buildInfoItem(
            icon: Icons.email,
            label: '邮箱',
            value: _maskEmail(user?.email),
            onTap: () => _showEmailBindDialog(user?.email),
          ),
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
      onTap: onTap ?? (canCopy && value.isNotEmpty && !value.contains('未') 
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
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 15,
              ),
            ),
            const Spacer(),
            if (value.isNotEmpty)
              Text(
                value,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing,
            ],
            if (canCopy && value.isNotEmpty && !value.contains('未')) ...[
              const SizedBox(width: 8),
              Icon(Icons.copy, color: Colors.grey[400], size: 16),
            ] else if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
            ],
          ],
        ),
      ),
    );
  }
  

  

  String _maskPhone(String? phone) {
    if (phone == null || phone.isEmpty) return '未绑定';
    if (phone.length >= 11) {
      return '${phone.substring(0, 3)}****${phone.substring(phone.length - 4)}';
    }
    return phone;
  }
  
  String _maskEmail(String? email) {
    if (email == null || email.isEmpty) return '未绑定';
    final index = email.indexOf('@');
    if (index > 2) {
      return '${email.substring(0, 2)}***${email.substring(index)}';
    }
    return email;
  }
  
  void _copyToClipboard(String text) {
    if (text.isEmpty || text.contains('未')) return;
    Clipboard.setData(ClipboardData(text: text));
    EasyLoading.showSuccess('已复制');
  }
  
  /// 更新性别
  Future<void> _updateGender(int sex) async {
    EasyLoading.show(status: '修改中...');
    
    final result = await _nativeBridge.imUpdateSex(sex);
    
    if (result['errorCode'] == 0) {
      // 更新本地用户信息 (UI显示: 1=男, 2=女，SDK: 0=男, 1=女)
      _globalCtrl.updateUserGender(sex == 0 ? 1 : 2);
      EasyLoading.showSuccess('性别已修改');
    } else {
      EasyLoading.showError(result['message'] ?? '修改失败');
    }
  }
  
  // ==================== 弹窗和操作 ====================
  
  void _showAvatarOptions() {
    _pickAndUploadAvatar(ImageSource.gallery);
    // showModalBottomSheet(
    //   context: context,
    //   shape: const RoundedRectangleBorder(
    //     borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    //   ),
    //   builder: (context) => SafeArea(
    //     child: Column(
    //       mainAxisSize: MainAxisSize.min,
    //       children: [
    //         Container(
    //           width: 40,
    //           height: 4,
    //           margin: const EdgeInsets.symmetric(vertical: 12),
    //           decoration: BoxDecoration(
    //             color: Colors.grey[300],
    //             borderRadius: BorderRadius.circular(2),
    //           ),
    //         ),
    //         ListTile(
    //           leading: const Icon(Icons.camera_alt, color: Colors.blue),
    //           title: const Text('拍照'),
    //           onTap: () {
    //             Get.back();
    //             _pickAndUploadAvatar(ImageSource.camera);
    //           },
    //         ),
    //         ListTile(
    //           leading: const Icon(Icons.photo_library, color: Colors.green),
    //           title: const Text('从相册选择'),
    //           onTap: () {
    //             Get.back();
    //             _pickAndUploadAvatar(ImageSource.gallery);
    //           },
    //         ),
    //         const SizedBox(height: 8),
    //         ListTile(
    //           title: const Text('取消', textAlign: TextAlign.center),
    //           onTap: () => Get.back(),
    //         ),
    //       ],
    //     ),
    //   ),
    // );
  }
  
  /// 选择并上传头像
  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    if (_isUploadingAvatar) {
      EasyLoading.showInfo('正在上传中，请稍候');
      return;
    }
    
    try {
      // 1. 选择图片
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (pickedFile == null) {
        print('❌ 用户取消选择图片');
        return;
      }
      setState(() {
        _isUploadingAvatar = true;
      });
      EasyLoading.show(status: '上传中...');
      
      // 2. 获取文件信息
      final File imageFile = File(pickedFile.path);
      final int fileSize = await imageFile.length();
      final String fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String contentType = 'image/jpeg';
      
      print('📦 文件信息: fileName=$fileName, size=$fileSize');
      
      // 3. 获取上传凭证
      final prepareResult = await _nativeBridge.imPrepareUpload(
        businessModule: 'avatar',
        fileName: fileName,
        fileSize: fileSize,
        contentType: contentType,
      );
      
      print('📋 上传凭证结果: $prepareResult');
      
      final int errorCode = prepareResult['errorCode'] as int? ?? -1;
      if (errorCode != 0) {
        EasyLoading.showError(prepareResult['message'] ?? '获取上传凭证失败');
        return;
      }
      
      // 4. 解析凭证数据
      final String? dataStr = prepareResult['data'] as String?;
      if (dataStr == null || dataStr.isEmpty) {
        EasyLoading.showError('上传凭证数据为空');
        return;
      }
      
      final Map<String, dynamic> tokenData = json.decode(dataStr);
      print('📦 凭证详情: $tokenData');
      
      final String uploadUrl = tokenData['upload_url'] ?? '';
      final String fileUrl = tokenData['file_url'] ?? '';
      final String method = tokenData['method'] ?? 'POST';
      final String objectKey = tokenData['file_path'] ?? '';
      final String uploadMode = tokenData['upload_mode'] ?? '';
      final String providerCode = tokenData['provider_code'] ?? '';
      final Map<String, dynamic> headers = Map<String, dynamic>.from(tokenData['headers'] ?? {});
      final Map<String, dynamic> formData = Map<String, dynamic>.from(tokenData['form_data'] ?? {});
      
      // STS 凭证（腾讯云等）
      final String bucketName = tokenData['bucket_name'] ?? '';
      final String region = tokenData['region'] ?? '';
      final String stsAccessKeyId = tokenData['sts_access_key_id'] ?? '';
      final String stsAccessKeySecret = tokenData['sts_access_key_secret'] ?? '';
      final String stsSecurityToken = tokenData['sts_security_token'] ?? '';
      
      print('📤 开始上传: uploadMode=$uploadMode, provider=$providerCode');
      
      // 5. 上传图片
      bool uploadSuccess = false;
      
      if (uploadMode == 'STS_SDK' && providerCode == 'tencent') {
        // 腾讯云 STS SDK 上传
        uploadSuccess = await _uploadWithTencentSTS(
          localFilePath: imageFile.path,
          objectKey: objectKey,
          bucketName: bucketName,
          region: region,
          secretId: stsAccessKeyId,
          secretKey: stsAccessKeySecret,
          token: stsSecurityToken,
        );
      } else if (uploadUrl.isNotEmpty) {
        // HTTP 上传（PUT 或 POST）
        if (method.toUpperCase() == 'PUT') {
          uploadSuccess = await _uploadWithPut(uploadUrl, imageFile, headers);
        } else {
          uploadSuccess = await _uploadWithPost(uploadUrl, imageFile, objectKey, headers, formData);
        }
      } else {
        EasyLoading.showError('不支持的上传模式: $uploadMode');
        return;
      }
      
      if (!uploadSuccess) {
        EasyLoading.showError('图片上传失败');
        return;
      }
      
      print('✅ 图片上传成功: fileUrl=$fileUrl');
      
      // 6. 更新用户头像
      EasyLoading.show(status: '更新头像...');
      
      final updateResult = await _nativeBridge.imUpdateUserInfo(avatar: fileUrl);
      final int updateErrorCode = updateResult['errorCode'] as int? ?? -1;
      
      if (updateErrorCode == 0) {
        // 更新本地用户信息
        await _globalCtrl.updateUserAvatar(fileUrl);
        EasyLoading.showSuccess('头像更新成功');
      } else {
        EasyLoading.showError(updateResult['message'] ?? '头像更新失败');
      }
      
    } catch (e) {
      print('❌ 上传头像异常: $e');
      EasyLoading.showError('上传失败: $e');
    } finally {
      setState(() {
        _isUploadingAvatar = false;
      });
      EasyLoading.dismiss();
    }
  }
  
  /// PUT 方式上传
  Future<bool> _uploadWithPut(String url, File file, Map<String, dynamic> headers) async {
    try {
      final bytes = await file.readAsBytes();
      
      final response = await http.put(
        Uri.parse(url),
        headers: headers.map((k, v) => MapEntry(k, v.toString())),
        body: bytes,
      );
      
      print('📤 PUT 上传响应: ${response.statusCode}');
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('❌ PUT 上传失败: $e');
      return false;
    }
  }
  
  /// POST 表单方式上传
  Future<bool> _uploadWithPost(
    String url, 
    File file, 
    String filePath,
    Map<String, dynamic> headers, 
    Map<String, dynamic> formData,
  ) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));
      
      // 添加表单字段
      formData.forEach((key, value) {
        request.fields[key] = value.toString();
      });
      
      // 添加文件
      final fileName = filePath.isNotEmpty ? filePath.split('/').last : 'file';
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename: fileName,
      ));
      
      // 添加 headers
      headers.forEach((key, value) {
        request.headers[key] = value.toString();
      });
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('📤 POST 上传响应: ${response.statusCode}');
      print('📤 响应内容: ${response.body}');
      
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('❌ POST 上传失败: $e');
      return false;
    }
  }
  
  /// 腾讯云 STS SDK 上传
  Future<bool> _uploadWithTencentSTS({
    required String localFilePath,
    required String objectKey,
    required String bucketName,
    required String region,
    required String secretId,
    required String secretKey,
    required String token,
  }) async {
    try {
      print('📤 腾讯云 STS 上传开始...');
      print('  - localFilePath: $localFilePath');
      print('  - objectKey: $objectKey');
      print('  - bucket: $bucketName');
      print('  - region: $region');
      
      final result = await _nativeBridge.imUploadWithTencentSTS(
        localFilePath: localFilePath,
        objectKey: objectKey,
        bucketName: bucketName,
        region: region,
        secretId: secretId,
        secretKey: secretKey,
        token: token,
      );
      
      final bool success = result['success'] == true;
      if (success) {
        print('✅ 腾讯云上传成功: ${result['url']}');
      } else {
        print('❌ 腾讯云上传失败: ${result['error']}');
      }
      
      return success;
    } catch (e) {
      print('❌ 腾讯云 STS 上传异常: $e');
      return false;
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
                tip: '请输入用户名',
                title: '修改用户名',
                onTap: () async {
                  final newUsername = controller.text.trim();
              if (newUsername.isEmpty) {
                EasyLoading.showError('用户名不能为空');
                return;
              }
              
              Get.back();
              EasyLoading.show(status: '修改中...');
              
              final result = await _nativeBridge.imUpdateUsername(newUsername);
              
              if (result['errorCode'] == 0) {
                // 更新本地用户信息
                _globalCtrl.updateUserUsername( newUsername);
                EasyLoading.showSuccess('用户名修改成功');
              } else {
                EasyLoading.showError(result['message'] ?? '修改失败');
              }
                }
              ));
          });
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
                tip: '请输入昵称',
                title: '修改昵称',
                onTap: () async {
                  final newNickname = controller.text.trim();
              if (newNickname.isEmpty) {
                EasyLoading.showError('昵称不能为空');
                return;
              }
              
              Get.back();
              EasyLoading.show(status: '修改中...');
              
              final result = await _nativeBridge.imUpdateNickname(newNickname);
              
              if (result['errorCode'] == 0) {
                // 更新本地用户信息
                _globalCtrl.updateUserNickname(newNickname);
                EasyLoading.showSuccess('昵称修改成功');
              } else {
                EasyLoading.showError(result['message'] ?? '修改失败');
              }
                }
              ));
          });
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
                title: const Text('更换手机号'),
                onTap: () {
                  Get.back();
                  EasyLoading.showInfo('换绑手机号功能开发中');
                },
              ),
              ListTile(
                leading: const Icon(Icons.link_off, color: Colors.red),
                title: const Text('解绑手机号'),
                onTap: () {
                  Get.back();
                  EasyLoading.showInfo('解绑手机号功能开发中');
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                title: const Text('取消', textAlign: TextAlign.center),
                onTap: () => Get.back(),
              ),
            ],
          ),
        ),
      );
    } else {
      EasyLoading.showInfo('绑定手机号功能开发中');
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
                title: const Text('更换邮箱'),
                onTap: () {
                  Get.back();
                  EasyLoading.showInfo('换绑邮箱功能开发中');
                },
              ),
              ListTile(
                leading: const Icon(Icons.link_off, color: Colors.red),
                title: const Text('解绑邮箱'),
                onTap: () {
                  Get.back();
                  EasyLoading.showInfo('解绑邮箱功能开发中');
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                title: const Text('取消', textAlign: TextAlign.center),
                onTap: () => Get.back(),
              ),
            ],
          ),
        ),
      );
    } else {
      EasyLoading.showInfo('绑定邮箱功能开发中');
    }
  }
}

