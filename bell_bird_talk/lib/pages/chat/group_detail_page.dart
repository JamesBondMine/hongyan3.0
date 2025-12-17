import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../services/native_bridge.dart';

class GroupDetailPage extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String? groupAvatar;

  const GroupDetailPage({
    super.key,
    required this.groupId,
    required this.groupName,
    this.groupAvatar,
  });

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  final IOSNativeService _nativeService = IOSNativeService();
  bool _loading = false;
  List<Map<String, dynamic>> _members = [];
  late String _groupName;
  String? _groupAvatar;

  @override
  void initState() {
    super.initState();
    _groupName = widget.groupName;
    _groupAvatar = widget.groupAvatar;
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() => _loading = true);
    final result = await _nativeService.imGetGroupMembers(
      groupId: widget.groupId,
      page: 1,
      pageSize: 200,
    );
    if (!mounted) return;
    if (result['errorCode'] == 0) {
      final dataStr = result['data'] as String? ?? '';
      if (dataStr.isNotEmpty) {
        try {
          final map = json.decode(dataStr) as Map<String, dynamic>;
          final list = (map['members'] as List?) ?? [];
          setState(() {
            _members = list.map((e) => (e as Map).cast<String, dynamic>()).toList();
          });
        } catch (e) {
          EasyLoading.showError('解析群成员失败');
        }
      } else {
        setState(() => _members = []);
      }
    } else {
      EasyLoading.showError(result['message']?.toString() ?? '获取群成员失败');
    }
    await _refreshGroupInfo();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _refreshGroupInfo() async {
    final res = await _nativeService.imGetGroupInfo(groupId: widget.groupId);
    if (res['errorCode'] == 0) {
      final dataStr = res['data'] as String? ?? '';
      if (dataStr.isNotEmpty) {
        try {
          final map = json.decode(dataStr) as Map<String, dynamic>;
          final groupName = (map['group_name'] as String?) ?? _groupName;
          final groupAvatar = (map['group_avatar'] as String?) ?? _groupAvatar;
          setState(() {
            _groupName = groupName;
            _groupAvatar = groupAvatar;
          });
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final memberCount = _members.length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('群聊详情'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadMembers,
        child: ListView(
          children: [
            const SizedBox(height: 12),
            _buildGroupHeader(memberCount),
            const SizedBox(height: 8),
            _buildMemberSection(),
            const Divider(height: 24),
            _buildSettingSection(),
            const SizedBox(height: 24),
            _buildDangerZone(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupHeader(int memberCount) {
    return ListTile(
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.blue.shade50,
            backgroundImage: (_groupAvatar != null && _groupAvatar!.isNotEmpty)
                ? NetworkImage(_groupAvatar!)
                : null,
            child: (_groupAvatar == null || _groupAvatar!.isEmpty)
                ? Text(
                    _groupName.isNotEmpty ? _groupName.characters.first : '#',
                    style: const TextStyle(color: Colors.blue, fontSize: 20, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: GestureDetector(
              onTap: _pickAndUpdateAvatar,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.camera_alt, size: 16, color: Colors.blue),
              ),
            ),
          ),
        ],
      ),
      title: Text(
        _groupName,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '群ID: ${widget.groupId}  ·  成员 $memberCount 人',
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.edit),
        onPressed: _editGroupName,
      ),
    );
  }

  Widget _buildMemberSection() {
    if (_loading && _members.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_members.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('暂无群成员')),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '群成员',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _members.map((m) => _buildMemberItem(m)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMemberItem(Map<String, dynamic> m) {
    final userId = (m['user_id'] as String?) ?? '';
    final alias = (m['member_alias'] as String?) ?? '';
    final isAdmin = (m['is_admin'] as bool?) ?? false;
    final name = alias.isNotEmpty ? alias : userId;
    final initial = name.isNotEmpty ? name.characters.first : '#';
    return SizedBox(
      width: 64,
      child: Column(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.grey.shade200,
            child: Text(
              initial,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
          if (isAdmin)
            Text(
              '管理员',
              style: TextStyle(fontSize: 10, color: Colors.orange.shade700),
            ),
        ],
      ),
    );
  }

  Widget _buildSettingSection() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.person_add_alt_1_outlined, color: Colors.blue),
          title: const Text('添加群成员'),
          onTap: () {
            EasyLoading.showInfo('添加群成员功能待实现');
          },
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.person_outline, color: Colors.green),
          title: const Text('设置我的群昵称'),
          onTap: _editGroupAlias,
        ),
        const Divider(height: 1),
        SwitchListTile(
          value: false,
          onChanged: (v) {
            EasyLoading.showInfo('群免打扰功能待实现');
          },
          title: const Text('消息免打扰'),
        ),
      ],
    );
  }

  Widget _buildDangerZone() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const Divider(height: 1),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
              ),
              onPressed: () {
                EasyLoading.showInfo('退出 / 解散群功能待实现');
              },
              child: const Text(
                '退出/解散群聊',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editGroupName() async {
    final controller = TextEditingController(text: _groupName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('修改群名称'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: '输入新的群名称'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('保存')),
          ],
        );
      },
    );
    if (newName == null || newName.isEmpty || newName == _groupName) return;
    EasyLoading.show(status: '修改群名称...');
    final res = await _nativeService.imUpdateGroup(
      groupId: widget.groupId,
      groupName: newName,
      version: 1,
    );
    if (!mounted) return;
    if (res['errorCode'] == 0) {
      EasyLoading.showSuccess('修改成功');
      await _refreshGroupInfo();
    } else {
      EasyLoading.showError(res['message']?.toString() ?? '修改失败');
    }
  }


  Future<void> _editGroupAlias() async {
    final controller = TextEditingController();
    final alias = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('设置我的群昵称'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: '请输入群昵称'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('保存')),
          ],
        );
      },
    );
    if (alias == null || alias.isEmpty) return;
    EasyLoading.show(status: '设置群昵称...');
    final res = await _nativeService.imSetGroupAlias(
      groupId: widget.groupId,
      alias: alias,
    );
    if (!mounted) return;
    if (res['errorCode'] == 0) {
      EasyLoading.showSuccess('设置成功');
      _loadMembers();
    } else {
      EasyLoading.showError(res['message']?.toString() ?? '设置失败');
    }
  }

  Future<void> _pickAndUpdateAvatar() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
    if (img == null) return;
    
    EasyLoading.show(status: '上传群头像...');
    
    try {
      // 1. 获取文件信息
      final File imageFile = File(img.path);
      final int fileSize = await imageFile.length();
      final String fileName = 'group_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String contentType = 'image/jpeg';
      
      print('📦 文件信息: fileName=$fileName, size=$fileSize');
      
      // 2. 获取上传凭证
      final prepareResult = await _nativeService.imPrepareUpload(
        businessModule: 'group_avatar',
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
      
      // 3. 解析凭证数据
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
        return;
      }
      
      if (!uploadSuccess) {
        EasyLoading.showError('图片上传失败');
        return;
      }
      
      print('✅ 图片上传成功: fileUrl=$fileUrl');
      
      // 5. 更新群头像
      EasyLoading.show(status: '更新群头像...');
      
      final res = await _nativeService.imUpdateGroup(
        groupId: widget.groupId,
        groupAvatar: fileUrl,
        version: 1,
      );
      
      if (!mounted) return;
      
      if (res['errorCode'] == 0) {
        EasyLoading.showSuccess('群头像已更新');
        await _refreshGroupInfo();
      } else {
        EasyLoading.showError(res['message']?.toString() ?? '更新群头像失败');
      }
    } catch (e) {
      print('❌ 上传群头像异常: $e');
      EasyLoading.showError('上传失败: $e');
    } finally {
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
      
      final result = await _nativeService.imUploadWithTencentSTS(
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
}


