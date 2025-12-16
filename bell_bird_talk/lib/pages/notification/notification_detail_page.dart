import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../services/native_bridge.dart';

class NotificationDetailPage extends StatefulWidget {
  final Map<String, dynamic> notification;
  const NotificationDetailPage({super.key, required this.notification});

  @override
  State<NotificationDetailPage> createState() => _NotificationDetailPageState();
}

class _NotificationDetailPageState extends State<NotificationDetailPage> {
  final IOSNativeService _nativeService = IOSNativeService();
  late Map<String, dynamic> _item;
  bool _marking = false;
  bool _marked = false;

  @override
  void initState() {
    super.initState();
    _item = Map<String, dynamic>.from(widget.notification);
    // 自动标记已读（仅未读时）
    final status = (_item['status'] as num?)?.toInt() ?? 0;
    if (status == 0) {
      Future.microtask(_markRead);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = (_item['display_title'] as String?) ?? (_item['title'] as String?) ?? '通知详情';
    final body = (_item['display_body'] as String?) ?? (_item['content'] as String?) ?? '';
    final type = (_item['notification_type'] as String?) ?? '';
    final createTime = (_item['create_time'] as num?)?.toInt();
    final rawContent = (_item['content'] as String?) ?? '';
    final contentJson = _ensureContentJson(_item);
    final status = (_item['status'] as num?)?.toInt() ?? 0;

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_marked);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('通知详情'),
          actions: [
            TextButton(
              onPressed: status == 0 ? _markRead : null,
              child: _marking
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('标记已读'),
            )
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (body.isNotEmpty)
              Text(
                body,
                style: const TextStyle(fontSize: 15),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (type.isNotEmpty)
                  // _chip('类型', type),
                _chip('状态', status == 0 ? '未读' : '已读'),
                if (createTime != null) _chip('时间', _formatTime(createTime)),
              ],
            ),
            // const SizedBox(height: 16),
            // _sectionTitle('内容详情'),
            // if (contentJson.isNotEmpty)
            //   _codeBox(_prettyJson(contentJson))
            // else if (rawContent.isNotEmpty)
            //   _codeBox(rawContent)
            // else
            //   const Text('无内容'),
            // const SizedBox(height: 16),
            // _sectionTitle('原始数据'),
            // _codeBox(_prettyJson(_item)),
          ],
        ),
      ),
    );
  }

  Future<void> _markRead() async {
    if (_marking) return;
    final id = (_item['id'] as num?)?.toInt();
    if (id == null) {
      EasyLoading.showError('缺少通知ID');
      return;
    }
    setState(() => _marking = true);
    final now = DateTime.now().millisecondsSinceEpoch;
    final result = await _nativeService.imMarkNotificationRead(
      notificationIds: [id],
      readTime: now,
    );
    if (!mounted) return;
    setState(() => _marking = false);
    if (result['errorCode'] == 0) {
      setState(() {
        _item['status'] = 1;
        _marked = true;
      });
      EasyLoading.showSuccess('已标记为已读');
    } else {
      EasyLoading.showError(result['message']?.toString() ?? '标记失败');
    }
  }

  Map<String, dynamic> _ensureContentJson(Map<String, dynamic> item) {
    final cached = item['content_json'];
    if (cached is Map<String, dynamic>) return cached;
    final contentStr = (item['content'] as String?) ?? '';
    if (contentStr.isEmpty) return {};
    try {
      final decoded = json.decode(contentStr);
      if (decoded is Map) return decoded.cast<String, dynamic>();
    } catch (_) {}
    return {};
  }

  String _formatTime(int ts) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ts);
    return '${dt.year}-${_two(dt.month)}-${_two(dt.day)} ${_two(dt.hour)}:${_two(dt.minute)}';
  }

  String _two(int v) => v.toString().padLeft(2, '0');

  Widget _chip(String label, String value) {
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: Colors.grey.shade200,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _codeBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        text,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
      ),
    );
  }

  String _prettyJson(Map<String, dynamic> map) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(map);
    } catch (_) {
      return map.toString();
    }
  }
}

