import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../services/native_bridge.dart';
import '../chat/group_chat_page.dart';

class GroupListPage extends StatefulWidget {
  const GroupListPage({super.key});

  @override
  State<GroupListPage> createState() => _GroupListPageState();
}

class _GroupListPageState extends State<GroupListPage> {
  final IOSNativeService _nativeService = IOSNativeService();
  bool _loading = false;
  List<Map<String, dynamic>> _groups = [];

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() => _loading = true);
    final result = await _nativeService.imGetGroupList(page: 1, pageSize: 100);
    if (!mounted) return;
    if (result['errorCode'] == 0) {
      final dataStr = result['data'] as String? ?? '';
      if (dataStr.isNotEmpty) {
        try {
          final map = json.decode(dataStr) as Map<String, dynamic>;
          final list = (map['groups'] as List?) ?? [];
          setState(() {
            _groups = list.map((e) => (e as Map).cast<String, dynamic>()).toList();
          });
        } catch (e) {
          EasyLoading.showError('解析群组列表失败');
        }
      } else {
        setState(() => _groups = []);
      }
    } else {
      EasyLoading.showError(result['message']?.toString() ?? '获取群组失败');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('群组列表')),
      body: RefreshIndicator(
        onRefresh: _loadGroups,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _groups.isEmpty
                ? const Center(child: Text('暂无群组'))
                : ListView.separated(
                    itemCount: _groups.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _groups[index];
                      final name = (item['group_name'] as String?) ?? '群组';
                      final desc = (item['group_description'] as String?) ?? '';
                      final avatar = (item['group_avatar'] as String?) ?? '';
                      final gid = (item['group_id'] as String?) ?? '';
                      final type = (item['group_type'] as num?)?.toInt() ?? 0;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade50,
                          backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                          child: avatar.isEmpty
                              ? Text(
                                  name.isNotEmpty ? name.characters.first : '#',
                                  style: const TextStyle(color: Colors.blue),
                                )
                              : null,
                        ),
                        title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (desc.isNotEmpty)
                              Text(
                                desc,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            // Text(
                            //   'ID: $gid${type == 1 ? " · 超级群" : ""}',
                            //   style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            // ),
                          ],
                        ),
                        onTap: () => _enterGroupChat(gid: gid, name: name, avatar: avatar, type: type),
                      );
                    },
                  ),
      ),
    );
  }

  Future<void> _enterGroupChat({
    required String gid,
    required String name,
    required String avatar,
    required int type,
  }) async {
    if (gid.isEmpty) {
      EasyLoading.showError('群组ID缺失');
      return;
    }
    EasyLoading.show(status: '进入群聊...');
    try {
      final res = await _nativeService.imCreateConversation(
        convType: 2,
        targetId: gid,
        displayName: name,
        avatarUrl: avatar.isNotEmpty ? avatar : null,
      );
      if (res['errorCode'] == 0) {
        final dataStr = res['data'] as String? ?? '';
        String? convId;
        if (dataStr.isNotEmpty) {
          try {
            final map = json.decode(dataStr) as Map<String, dynamic>;
            convId = (map['conv_id'] as String?) ?? (map['convId'] as String?);
          } catch (_) {}
        }
        if (convId == null || convId.isEmpty) {
          EasyLoading.showError('未获取到会话ID');
          return;
        }
        EasyLoading.dismiss();
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GroupChatPage(
              convId: convId!,
              groupId: gid,
              groupName: name,
              groupAvatar: avatar.isNotEmpty ? avatar : null,
            ),
          ),
        );
      } else {
        EasyLoading.showError(res['message']?.toString() ?? '创建会话失败');
      }
    } catch (e) {
      EasyLoading.showError('进入群聊失败');
    }
  }
}

