
import 'dart:convert';
import 'dart:io';
import 'package:bell_bird_talk/controllers/global_controller.dart';
import 'package:bell_bird_talk/controllers/login_controller.dart';
import 'package:bell_bird_talk/pages/login/login_page.dart';
import 'package:bell_bird_talk/services/native_bridge.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:bell_bird_talk/widgets/common_button.dart';
import 'package:bell_bird_talk/widgets/login_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class RegisterInfoPage extends StatefulWidget {
  RegisterInfoPage({super.key, this.loginWithToken = false, this.loginData = const {}, required Map<String, dynamic> data});

  bool loginWithToken = false;

  Map<String, dynamic> loginData;
  
  @override
  State<StatefulWidget> createState() {
    return RegisterInfoPageState();
  }

}
class RegisterInfoPageState extends State<RegisterInfoPage> {
  final ImagePicker _imagePicker = ImagePicker();
  final IOSNativeService _nativeBridge = IOSNativeService();
  final GlobalController _globalCtrl = Get.find<GlobalController>();

  TextEditingController _nicknameController = TextEditingController();
  TextEditingController _userNameController = TextEditingController();

  File? _selectedImage;
  String? _uploadedAvatarUrl; // 存储上传后的头像URL
  bool _isUploadingAvatar = false;

  /// 从相册选择图片并上传
  Future<void> _pickImageFromGallery() async {
    if (_isUploadingAvatar) {
      EasyLoading.showInfo('正在上传中，请稍候');
      return;
    }
    
    try {
      // 1. 选择图片
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image == null) {
        print('❌ 用户取消选择图片');
        return;
      }
      
      print('📷 选择图片: ${image.path}');
      
      // 2. 更新UI显示选中的图片
      setState(() {
        _selectedImage = File(image.path);
        _isUploadingAvatar = true;
      });
      
      // 3. 上传图片
      await _uploadAvatar(image.path);
      
    } catch (e) {
      print('❌ 选择图片失败: $e');
      Get.snackbar('提示', '选择图片失败');
      setState(() {
        _isUploadingAvatar = false;
      });
    }
  }

  /// 上传头像到云服务
  Future<void> _uploadAvatar(String imagePath) async {
    try {
      EasyLoading.show(status: '上传中...');
      
      // 1. 获取文件信息
      final File imageFile = File(imagePath);
      final int fileSize = await imageFile.length();
      final String fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String contentType = 'image/jpeg';
      
      print('📦 文件信息: fileName=$fileName, size=$fileSize');
      
      // 2. 获取上传凭证
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
        setState(() {
          _isUploadingAvatar = false;
        });
        return;
      }
      
      // 3. 解析凭证数据
      final String? dataStr = prepareResult['data'] as String?;
      if (dataStr == null || dataStr.isEmpty) {
        EasyLoading.showError('上传凭证数据为空');
        setState(() {
          _isUploadingAvatar = false;
        });
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
      
      // 4. 上传图片
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
        setState(() {
          _isUploadingAvatar = false;
        });
        return;
      }
      
      if (!uploadSuccess) {
        EasyLoading.showError('图片上传失败');
        setState(() {
          _isUploadingAvatar = false;
        });
        return;
      }
      
      print('✅ 图片上传成功: fileUrl=$fileUrl');
      
      // 5. 更新用户头像
      EasyLoading.show(status: '更新头像...');
      
      final updateResult = await _nativeBridge.imUpdateUserInfo(avatar: fileUrl);
      final int updateErrorCode = updateResult['errorCode'] as int? ?? -1;
      
      if (updateErrorCode == 0) {
        // 更新本地用户信息
        await _globalCtrl.updateUserAvatar(fileUrl);
        setState(() {
          _uploadedAvatarUrl = fileUrl;
        });
        EasyLoading.showSuccess('头像上传成功');
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
      print('❌ 腾讯云上传异常: $e');
      return false;
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
  

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());

    return Scaffold(
      backgroundColor: GbsColors.lightBackgroundA ,
      body: Stack(
        children: [
          Image.asset(
            'assets/img/login/loginbgsmall.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          // 主内容
          SafeArea(
            child:Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 32),
                    child: Column(children: [
                      _buildAppBar(),
                      SizedBox(height: 18),
              
              // 头像上传区域
              GestureDetector(
                onTap: _pickImageFromGallery,
                child: Column(
                  children: [
                    // 渐变色圆形头像
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blue.shade400,
                            Colors.purple.shade400,
                          ],
                        ),
                      ),
                      child: _selectedImage != null
                          ? ClipOval(
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                                width: 92,
                                height: 92,
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.blue.shade400,
                                    Colors.purple.shade400,
                                  ],
                                ),
                              ),
                              child: Icon(
                                Icons.person,
                                size: 48,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    // 上传文字
                    GestureDetector(
                      onTap: _pickImageFromGallery,
                      child: Text(
                        '上传',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: GbsColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

        const SizedBox(height: 8),
        
              SizedBox(height: 16),
              _buildnickNameInput(controller),
              SizedBox(height: 16),
              _buildUserNameInput(controller),
              
              Padding(padding: EdgeInsetsGeometry.only(top: 10, bottom: 10), child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                Text(
          '用户名不可与其他用户重复',
          style: TextStyle(
            fontSize: 12,
            color: Colors.black.withOpacity(0.9),
          ),
        )
              ],),),
              SizedBox(height: 16),
              CommonButton(
                text: '完成',
                enabled: controller.inviteCodeController.text.isNotEmpty,
                onPressed: () {
                  // 更新用户信息
                  updateUserInfo(() {
                    // 跳转到首页
                    Get.offAllNamed('/home');
                  });
                },
              ),
              Spacer(),
              _buildLoginButton()
            ],)))]));

  }

  // 更新用户信息
  void updateUserInfo(VoidCallback success) async {

     final newNickname = _nicknameController.text.trim();
     final username = _userNameController.text.trim();
              if (newNickname.isEmpty) {
                EasyLoading.showError('昵称不能为空');
                return;
              }
              if (username.isEmpty) {
                EasyLoading.showError('用户名不能为空');
                return;
              }
              
              Get.back();
              EasyLoading.show(status: '修改中...');
              
              final result = await _nativeBridge.imUpdateNickAndUsername(newNickname,username);
              
              if (result['errorCode'] == 0) {
                // 更新本地用户信息
                _globalCtrl.updateUserNickname(newNickname);
                EasyLoading.showSuccess('昵称修改成功');
                success();
              } else {
                EasyLoading.showError(result['message'] ?? '修改失败');
                Get.offAll(LoginPage());
              }


  }




  /// 登录按钮
  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: TextButton(
        onPressed: () {
          if (widget.loginWithToken) {
            Get.offAllNamed('/home');
            return;
          }
          Get.offAll(LoginPage());
        },
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '跳过,后续设置',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 顶部导航栏
  Widget _buildAppBar() {
    return  Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Get.back(),
          ),
        ],
      mainAxisAlignment: MainAxisAlignment.start,
    );
  }

  /// 昵称输入框
  Widget _buildnickNameInput(LoginController controller) {
    return LoginTextField(
      controller: _nicknameController,
      title: '昵称',
      hintText: '请输入昵称（选填）',
      onChanged: (value) {
        // 可选填写，无需特殊处理
        if (mounted) {
          setState(() {
            
          });
        }
      },
      // prefixIcon: const Icon(Icons.card_giftcard_outlined),
    );
  }

  /// 用户名输入框
  Widget _buildUserNameInput(LoginController controller) {
    return LoginTextField(
      controller: _userNameController,
      title: '用户名',
      hintText: '请输入用户名',
      onChanged: (value) {
        // 可选填写，无需特殊处理
        if (mounted) {
          setState(() {
            
          });
        }
      },
      // prefixIcon: const Icon(Icons.card_giftcard_outlined),
    );
  }

}