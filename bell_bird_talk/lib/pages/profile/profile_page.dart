import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../controllers/global_controller.dart';
import '../../services/native_bridge.dart';
import '../friends/blacklist_page.dart';

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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('个人资料'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () => EasyLoading.showInfo('我的二维码'),
          ),
        ],
      ),
      body: Obx(() {
        final user = _globalCtrl.currentUser.value;
        
        return SingleChildScrollView(
          child: Column(
            children: [
              // 头部信息卡片
              _buildHeaderCard(user),
              
              const SizedBox(height: 12),
              
              // 基本信息
              _buildBasicInfoSection(user),
              
              const SizedBox(height: 12),
              
              // 账号安全
              _buildAccountSecuritySection(user),
              
              const SizedBox(height: 12),
              
              // 更多设置
              _buildSettingsSection(),
              
              const SizedBox(height: 24),
              
              // 退出登录按钮
              _buildLogoutButton(),
              
              const SizedBox(height: 32),
            ],
          ),
        );
      }),
    );
  }
  
  /// 头部信息卡片
  Widget _buildHeaderCard(user) {
    return Container(
      color: Colors.blue,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 24),
            
            // 头像（可点击更换）
            GestureDetector(
              onTap: () => _showAvatarOptions(),
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue[100],
                    backgroundImage: (user?.avatar != null && user!.avatar!.isNotEmpty)
                        ? NetworkImage(user!.avatar!)
                        : null,
                    child: (user?.avatar == null || user!.avatar!.isEmpty)
                        ? const Icon(Icons.person, size: 50, color: Colors.blue)
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 昵称（可点击编辑）
            GestureDetector(
              onTap: () => _showEditNicknameDialog(user?.nickname),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    user?.nickname ?? '未设置昵称',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.edit, size: 18, color: Colors.grey[400]),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // 账号ID
            GestureDetector(
              onTap: () => _copyToClipboard(user?.username ?? ''),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '账号: ${user?.username ?? '未知'}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.copy, size: 14, color: Colors.grey[400]),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
  
  /// 基本信息区域
  Widget _buildBasicInfoSection(user) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('基本信息'),
          
          _buildInfoItem(
            icon: Icons.fingerprint,
            label: '用户ID',
            value: user?.id ?? '未知',
            canCopy: true,
          ),
          
          _buildInfoItem(
            icon: Icons.badge,
            label: '账号ID',
            value: user?.username ?? '未设置',
            canCopy: true,
          ),
          
          _buildInfoItem(
            icon: Icons.cake,
            label: '注册时间',
            value: user?.createdAt?.toString().substring(0, 10) ?? '未知',
          ),
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }
  
  /// 账号安全区域
  Widget _buildAccountSecuritySection(user) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('账号安全'),
          
          _buildInfoItem(
            icon: Icons.phone_android,
            label: '手机号',
            value: _maskPhone(user?.phone),
            trailing: user?.phone != null && user!.phone!.isNotEmpty
                ? _buildBindBadge('已绑定', Colors.green)
                : _buildBindBadge('未绑定', Colors.orange),
            onTap: () => _showPhoneBindDialog(user?.phone),
          ),
          
          _buildInfoItem(
            icon: Icons.email,
            label: '邮箱',
            value: _maskEmail(user?.email),
            trailing: user?.email != null && user!.email!.isNotEmpty
                ? _buildBindBadge('已绑定', Colors.green)
                : _buildBindBadge('未绑定', Colors.orange),
            onTap: () => _showEmailBindDialog(user?.email),
          ),
          
          _buildInfoItem(
            icon: Icons.lock,
            label: '修改密码',
            value: '',
            onTap: () => EasyLoading.showInfo('修改密码功能开发中'),
          ),
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }
  
  /// 更多设置区域
  Widget _buildSettingsSection() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('更多设置'),
          
          _buildInfoItem(
            icon: Icons.notifications,
            label: '消息通知',
            value: '',
            onTap: () => EasyLoading.showInfo('消息通知设置'),
          ),
   
          
          _buildInfoItem(
            icon: Icons.info_outline,
            label: '关于我们',
            value: '',
            onTap: () => EasyLoading.showInfo('铃鸟聊天 v1.0.0'),
          ),
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }
  
  /// 区块标题
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.grey[600],
        ),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[500], size: 22),
            const SizedBox(width: 12),
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
  
  /// 绑定状态徽章
  Widget _buildBindBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
  
  /// 退出登录按钮
  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () => _confirmLogout(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            elevation: 0,
          ),
          child: const Text(
            '退出登录',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
  
  // ==================== 工具方法 ====================
  
  String _getGenderText(int? gender) {
    switch (gender) {
      case 1: return '男';
      case 2: return '女';
      default: return '未设置';
    }
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
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('拍照'),
              onTap: () {
                Get.back();
                _pickAndUploadAvatar(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('从相册选择'),
              onTap: () {
                Get.back();
                _pickAndUploadAvatar(ImageSource.gallery);
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
      
      print('📷 选择图片: ${pickedFile.path}');
      
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

  // /// 获取上传凭证
  // Future<void> _prepareUpload() async {
  //   try {
  //     print('📤 首页初始化: 获取上传凭证...');
  //     final nativeService = IOSNativeService();
      
  //     // 获取头像上传凭证（作为默认凭证）
  //     final result = await nativeService.imPrepareUpload(
  //       businessModule: 'avatar',
  //       fileName: 'avatar.jpg',
  //     );
      
  //     print('📋 上传凭证结果: $result');
      
  //     final errorCode = result['errorCode'] as int? ?? -1;
  //     if (errorCode == 0) {
  //       setState(() {
  //         _uploadToken = result;
  //       });
  //       print('✅ 上传凭证获取成功');
        
  //       // 可以在这里解析并打印详细信息
  //       final dataStr = result['data'] as String?;
  //       if (dataStr != null) {
  //         print('📦 凭证详情: $dataStr');
  //       }
  //     } else {
  //       print('❌ 上传凭证获取失败: ${result['message']}');
  //     }
  //   } catch (e) {
  //     print('❌ 获取上传凭证异常: $e');
  //   }
  // }
  
  void _showEditNicknameDialog(String? currentNickname) {
    final controller = TextEditingController(text: currentNickname);
    
    Get.dialog(
      AlertDialog(
        title: const Text('修改昵称'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          decoration: const InputDecoration(
            hintText: '请输入新昵称',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
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
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
  
  void _showEditSignatureDialog(String? currentSignature) {
    final controller = TextEditingController(text: currentSignature);
    
    Get.dialog(
      AlertDialog(
        title: const Text('修改签名'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 50,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: '请输入个性签名',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final newSignature = controller.text.trim();
              
              Get.back();
              EasyLoading.show(status: '修改中...');
              
              final result = await _nativeBridge.imUpdateSignature(newSignature);
              
              if (result['errorCode'] == 0) {
                // 更新本地用户信息
                _globalCtrl.updateUserSignature(newSignature);
                EasyLoading.showSuccess('签名修改成功');
              } else {
                EasyLoading.showError(result['message'] ?? '修改失败');
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
  
  void _showGenderPicker(int? currentGender) {
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
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '选择性别',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.male, color: Colors.blue),
              title: const Text('男'),
              trailing: currentGender == 1 
                  ? const Icon(Icons.check, color: Colors.blue) 
                  : null,
              onTap: () async {
                Get.back();
                await _updateGender(0); // 0=男
              },
            ),
            ListTile(
              leading: const Icon(Icons.female, color: Colors.pink),
              title: const Text('女'),
              trailing: currentGender == 2 
                  ? const Icon(Icons.check, color: Colors.blue) 
                  : null,
              onTap: () async {
                Get.back();
                await _updateGender(1); // 1=女
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
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
  
  void _confirmLogout() {
    Get.dialog(
      AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              _globalCtrl.logout();
              EasyLoading.dismiss();
              EasyLoading.showSuccess('已退出登录');
              await Future.delayed(const Duration(seconds: 1));
              Get.offAllNamed('/login');
            },
            child: const Text('退出', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

