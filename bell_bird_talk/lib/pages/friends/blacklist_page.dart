import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../../services/native_bridge.dart';
import '../models/friend_model.dart';

/// 黑名单列表页面
class BlacklistPage extends StatefulWidget {
  const BlacklistPage({super.key});

  @override
  State<BlacklistPage> createState() => _BlacklistPageState();
}

class _BlacklistPageState extends State<BlacklistPage> {
  final IOSNativeService _nativeService = IOSNativeService();
  final List<FriendModel> _blacklist = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBlacklist();
  }

  Future<void> _loadBlacklist() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final result = await _nativeService.imGetContactList(
        page: 1,
        pageSize: 200,
        relationship: 2, // 2 = 黑名单
      );

      if (result['errorCode'] == 0) {
        final dataStr = result['data'] as String?;
        if (dataStr != null && dataStr.isNotEmpty) {
          final data = json.decode(dataStr);
          final contactsJson = data['contacts'] as List? ?? [];
          setState(() {
            _blacklist
              ..clear()
              ..addAll(
                contactsJson.map((json) => FriendModel.fromJson(json)).toList(),
              );
          });
        }
      } else {
        EasyLoading.showError(result['message'] ?? '获取失败');
      }
    } catch (e) {
      print('❌ 获取黑名单失败: $e');
      EasyLoading.showError('获取黑名单失败');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('黑名单'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadBlacklist,
        child: _isLoading && _blacklist.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _blacklist.isEmpty
                ? _buildEmptyView()
                : ListView.separated(
                    itemCount: _blacklist.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
                    itemBuilder: (context, index) {
                      final user = _blacklist[index];
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.blue[100],
                          backgroundImage: (user.avatar != null && user.avatar!.isNotEmpty)
                              ? NetworkImage(user.avatar!)
                              : null,
                          child: (user.avatar == null || user.avatar!.isEmpty)
                              ? Text(
                                  user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        title: Text(
                          user.displayName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        subtitle: user.accountId != null && user.accountId!.isNotEmpty
                            ? Text('ID: ${user.accountId}', style: TextStyle(color: Colors.grey[600]))
                            : null,
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.block, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            '暂无黑名单联系人',
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
          const SizedBox(height: 16),
          Text(
            '黑名单中的联系人不会收到你的消息',
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
        ],
      ),
    );
  }
}

