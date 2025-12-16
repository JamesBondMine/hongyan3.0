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
          leading: const Icon(Icons.image_outlined, color: Colors.purple),
          title: const Text('修改群头像'),
          subtitle: const Text('填写图片URL'),
          onTap: _editGroupAvatar,
        ),
        const Divider(height: 1),
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

  Future<void> _editGroupAvatar() async {
    final controller = TextEditingController(text: _groupAvatar ?? '');
    final newUrl = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('修改群头像'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: '输入头像图片URL'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('保存')),
          ],
        );
      },
    );
    if (newUrl == null || newUrl.isEmpty || newUrl == _groupAvatar) return;
    EasyLoading.show(status: '修改群头像...');
    final res = await _nativeService.imUpdateGroup(
      groupId: widget.groupId,
      groupAvatar: newUrl,
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
      final file = File(img.path);
      final fileName = file.path.split('/').last;
      final fileSize = await file.length();
      final prepare = await _nativeService.imPrepareUpload(
        businessModule: 'group_avatar',
        fileName: fileName,
        fileSize: fileSize,
        contentType: 'image/jpeg',
      );
      if (prepare['errorCode'] != 0) {
        EasyLoading.showError(prepare['message']?.toString() ?? '获取上传凭证失败');
        return;
      }
      final url = await _uploadWithPrepared(prepare, file.path);
      if (url == null || url.isEmpty) {
        EasyLoading.showError('上传失败');
        return;
      }
      final res = await _nativeService.imUpdateGroup(
        groupId: widget.groupId,
        groupAvatar: url,
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
      EasyLoading.showError('上传失败: $e');
    }
  }

  Future<String?> _uploadWithPrepared(Map<String, dynamic> prepare, String path) async {
    final method = (prepare['method'] as String?)?.toUpperCase() ?? 'PUT';
    final uploadUrl = prepare['upload_url'] as String? ?? '';
    if (uploadUrl.isEmpty) return null;
    final headers = (prepare['headers'] as Map?)?.cast<String, dynamic>() ?? {};
    final formData = (prepare['form_data'] as Map?)?.cast<String, dynamic>();
    final fileUrl = prepare['file_url'] as String?;

    final file = File(path);
    if (!await file.exists()) return null;

    if (method == 'POST' && formData != null && formData.isNotEmpty) {
      final req = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      formData.forEach((k, v) {
        req.fields[k] = v.toString();
      });
      req.files.add(await http.MultipartFile.fromPath('file', path));
      headers.forEach((k, v) => req.headers[k] = v.toString());
      final resp = await req.send();
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return fileUrl ?? prepare['file_path'] as String?;
      }
    } else {
      final bytes = await file.readAsBytes();
      final resp = await http.put(
        Uri.parse(uploadUrl),
        headers: headers.map((k, v) => MapEntry(k, v.toString())),
        body: bytes,
      );
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return fileUrl ?? prepare['file_path'] as String?;
      }
    }
    return null;
  }
}


