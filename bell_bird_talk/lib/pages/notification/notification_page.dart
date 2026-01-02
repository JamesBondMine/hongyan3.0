import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import '../../controllers/noti_controller.dart';
import 'notification_detail_page.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  String _formatTime(int? ts) {
    if (ts == null || ts <= 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(ts);
    return DateFormat('yyyy-MM-dd HH:mm').format(dt);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  /// 刷新数据
  Future<void> refresh() async {
    await Future.wait([
      NotiController.to.loadUnread(),
      NotiController.to.loadList(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通知'),
        // actions: [
        //   GetBuilder<NotiController>(
        //     id: NotiController.to.notificationDataListRefreshId,
        //     builder: (controller) {
        //       if (controller.unreadCount > 0) {
        //         return Padding(
        //           padding: const EdgeInsets.only(right: 16, top: 12),
        //           child: Container(
        //             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        //             decoration: BoxDecoration(
        //               color: Colors.redAccent,
        //               borderRadius: BorderRadius.circular(12),
        //             ),
        //             child: Text(
        //               '未读 ${controller.unreadCount}',
        //               style: const TextStyle(color: Colors.white, fontSize: 12),
        //             ),
        //           ),
        //         );
        //       }
        //       return const SizedBox.shrink();
        //     },
        //   ),
        // ],
      ),
      body: Column(
        children: [
          // Tab栏
          GetBuilder<NotiController>(
            id: NotiController.to.notificationBarRefreshId,
            builder: (controller) {
              return Container(
                width: Get.width,
                height: 52,
                margin: EdgeInsets.only(left: 16),
               
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildTabItem('全部', 0, controller),
                    _buildTabItem('未读', 1, controller),
                    _buildTabItem('已读', 2, controller),
                  ],
                ),
              );
            },
          ),
          // 通知列表
          Expanded(
            child:  RefreshIndicator(
                  onRefresh: refresh,
                  child: NotiController.to.loading
                      ? const Center(child: CircularProgressIndicator())
                      : NotiController.to.filteredItems.isEmpty
                          ? const Center(child: Text('暂无通知'))
                          : ListView.separated(
                              itemCount: NotiController.to.filteredItems.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final item = NotiController.to.filteredItems[index];
                                final title = (item['display_title'] as String?) ?? '通知';
                                final content = (item['display_body'] as String?) ?? '';
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
                                      NotiController.to.refresh();
                                    }
                                  },
                                );
                              },
                            ),
                )
              
            
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, int index, NotiController controller) {
    final isSelected = controller.selectedTab == index;
    return InkWell(
        onTap: () => controller.switchTab(index),
        child: Container(
          height: 52,
          margin: EdgeInsets.only(right: 20, left: 10),
          alignment: Alignment.center,
          // padding: const EdgeInsets.only(left: 10, right: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade600,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
            ),
          ),
        ),
      
    );
  }
}

