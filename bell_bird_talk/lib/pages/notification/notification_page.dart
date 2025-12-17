import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../services/native_bridge.dart';
import 'notification_detail_page.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final IOSNativeService _nativeService = IOSNativeService();

  int _unreadCount = 0;
  bool _loading = false;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    await Future.wait([
      _loadUnread(),
      _loadList(),
    ]);
  }

  Future<void> _loadUnread() async {
    final result = await _nativeService.imGetNotificationUnreadCount(types: ['0']);
    if (!mounted) return;
    if (result['errorCode'] == 0) {
      final dataStr = result['data'] as String? ?? '';
      if (dataStr.isNotEmpty) {
        try {
          final map = json.decode(dataStr) as Map<String, dynamic>;
          setState(() {
            _unreadCount = (map['total_unread'] as num?)?.toInt() ?? 0;
          });
        } catch (_) {
          // ignore parse error
        }
      }
    } else {
      EasyLoading.showError(result['message']?.toString() ?? '获取未读失败');
    }
  }

  Future<void> _loadList() async {
    setState(() => _loading = true);
    final result = await _nativeService.imPullNotifications(page: 1, pageSize: 50);
    if (!mounted) return;
    if (result['errorCode'] == 0) {
      final dataStr = result['data'] as String? ?? '';
      if (dataStr.isNotEmpty) {
        try {
          final map = json.decode(dataStr) as Map<String, dynamic>;
          final list = (map['notifications'] as List?) ?? [];
          setState(() {
            _items = list
                .map((e) => _mapNotification((e as Map).cast<String, dynamic>()))
                .toList();
          });
        } catch (e) {
          EasyLoading.showError('解析通知失败');
        }
      } else {
        setState(() => _items = []);
      }
    } else {
      EasyLoading.showError(result['message']?.toString() ?? '获取通知失败');
    }
    if (mounted) setState(() => _loading = false);
  }

  String _formatTime(int? ts) {
    if (ts == null || ts <= 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(ts);
    return DateFormat('yyyy-MM-dd HH:mm').format(dt);
  }

  /// 提取更友好的展示字段
  Map<String, dynamic> _mapNotification(Map<String, dynamic> raw) {
    final type = (raw['notification_type'] as String?) ?? '';
    final title = (raw['title'] as String?) ?? '';
    final contentStr = (raw['content'] as String?) ?? '';
    Map<String, dynamic> contentJson = {};
    try {
      if (contentStr.isNotEmpty) {
        contentJson = (json.decode(contentStr) as Map).cast<String, dynamic>();
      }
    } catch (_) {}

    String displayTitle = title;
    String displayBody = '';
    final friendName = (contentJson['friendName'] as String?) ??
        (contentJson['name'] as String?) ??
        (raw['related_user_id'] as String?) ??
        '';

    switch (type) {
      case 'FRIEND_REQUEST':
        displayTitle = '新的好友请求';
        displayBody =
            friendName.isNotEmpty ? '$friendName 请求添加你为好友' : '收到一条好友请求';
        break;
      case 'FRIEND_ADD':
        displayTitle = '新的好友请求';
        displayBody =
            friendName.isNotEmpty ? '$friendName 请求添加你为好友' : '收到一条好友请求';
        break;
      case 'FRIEND_REQUEST_ACCEPTED':
        displayTitle = '好友申请已通过';
        displayBody =
            friendName.isNotEmpty ? '$friendName 通过了你的好友申请' : '你的好友申请已通过';
        break;
      default:
        displayTitle = title.isNotEmpty ? title : '通知';
        displayBody = contentJson.isNotEmpty
            ? (contentJson['text'] as String? ??
                contentJson['content'] as String? ??
                contentStr)
            : (contentStr.isNotEmpty ? contentStr : '');
    }

    return {
      ...raw,
      'display_title': displayTitle,
      'display_body': displayBody,
      'content_json': contentJson,
      'display_friend_name': friendName,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通知'),
        actions: [
          if (_unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16, top: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '未读 $_unreadCount',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? const Center(child: Text('暂无通知'))
                : ListView.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final title = (item['display_title'] as String?) ?? '通知';
                      final content = (item['display_body'] as String?) ?? '';
                      final type = (item['notification_type'] as String?) ?? '';
                      final ts = (item['create_time'] as num?)?.toInt();
                      final status = (item['status'] as num?)?.toInt() ?? 0;
                      final isUnread = status == 0; // 0=UNREAD
                      return ListTile(
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: const Icon(Icons.notifications),
                            ),
                            if (isUnread)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (content.isNotEmpty)
                              Text(
                                content,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            Row(
                              children: [
                                if (type.isNotEmpty)
                                  // Container(
                                  //   margin: const EdgeInsets.only(top: 4, right: 6),
                                  //   padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  //   decoration: BoxDecoration(
                                  //     color: Colors.blue.shade50,
                                  //     borderRadius: BorderRadius.circular(8),
                                  //   ),
                                  //   child: Text(
                                  //     type,
                                  //     style: TextStyle(fontSize: 11, color: Colors.blue.shade600),
                                  //   ),
                                  // ),
                                if (ts != null)
                                  Text(
                                    _formatTime(ts),
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        onTap: () async {
                          final changed = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => NotificationDetailPage(notification: item),
                            ),
                          );
                          if (changed == true && mounted) {
                            _refresh();
                          }
                        },
                      );
                    },
                  ),
      ),
    );
  }
}

