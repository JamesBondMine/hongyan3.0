import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
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

  @override
  void initState() {
    super.initState();
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
    if (mounted) setState(() => _loading = false);
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
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.blue.shade50,
        backgroundImage: (widget.groupAvatar != null && widget.groupAvatar!.isNotEmpty)
            ? NetworkImage(widget.groupAvatar!)
            : null,
        child: (widget.groupAvatar == null || widget.groupAvatar!.isEmpty)
            ? Text(
                widget.groupName.isNotEmpty ? widget.groupName.characters.first : '#',
                style: const TextStyle(color: Colors.blue, fontSize: 20, fontWeight: FontWeight.bold),
              )
            : null,
      ),
      title: Text(
        widget.groupName,
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
          onTap: () {
            EasyLoading.showInfo('设置群昵称功能待实现');
          },
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
    final controller = TextEditingController(text: widget.groupName);
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
    if (newName == null || newName.isEmpty || newName == widget.groupName) return;
    EasyLoading.showInfo('修改群名称功能待实现');
  }
}


