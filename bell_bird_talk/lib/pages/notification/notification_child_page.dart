import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:bell_bird_talk/widgets/empty_view.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controllers/noti_controller.dart';
import 'notification_detail_page.dart';

/// 通知子页面 - 显示指定状态的通知列表
/// [statusIndex] 0=全部, 1=未读, 2=已读
class NotificationChildPage extends StatefulWidget {
  final int statusIndex;

  const NotificationChildPage({
    super.key,
    required this.statusIndex,
  });

  @override
  State<NotificationChildPage> createState() => _NotificationChildPageState();
}

class _NotificationChildPageState extends State<NotificationChildPage>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  int _pageIndex = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  List<Map<String, dynamic>> _items = [];

  @override
  bool get wantKeepAlive => true; // 保持页面状态

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadDataRequest(1, isRefresh: true);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoading &&
        _hasMore) {
      _loadMore();
    }
  }

  /// 加载数据
  Future<void> _loadDataRequest(int page, {bool isRefresh = false}) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      if (isRefresh) {
        _pageIndex = 1;
        _hasMore = true;
      }
    });

    try {
      final res = await NotiController.to.loadList(widget.statusIndex, page);
      
      if (mounted) {
        setState(() {
          if (isRefresh) {
            _items = res;
          } else {
            _items.addAll(res);
          }
          
          // 如果返回的数据少于10条，说明没有更多了
          if (res.length < 10) {
            _hasMore = false;
          }
          
          _isLoading = false;
          _pageIndex = page;
        });
        
        NotiController.to.updateNotificationDataList();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (!isRefresh) {
            _pageIndex--;
          }
        });
      }
    }
  }

  /// 加载更多
  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    await _loadDataRequest(_pageIndex + 1, isRefresh: false);
  }


  String _formatTime(int? ts) {
    if (ts == null || ts <= 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(ts);
    return DateFormat('yyyy-MM-dd HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      onRefresh: () async {
        await _loadDataRequest(1, isRefresh: true);
      },
      child: _isLoading && _items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height - 200,
                    child: Center(
                      child: EmptyView(
                        message: widget.statusIndex == 1
                            ? '暂无未读通知'
                            : widget.statusIndex == 2
                                ? '暂无已读通知'
                                : '暂无通知',
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: _items.length + (_hasMore ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 0),
                  itemBuilder: (context, index) {
                    if (index == _items.length) {
                      // 加载更多指示器
                      return _isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : const SizedBox.shrink();
                    }
                    return _cellItem(_items[index]);
                  },
                ),
    );
  }

  Widget _cellItem(Map<String, dynamic> item) {
    final title = (item['display_title'] as String?) ?? '通知';
    final content = (item['display_body'] as String?) ?? '';
    final ts = (item['create_time'] as num?)?.toInt();
    final status = (item['status'] as num?)?.toInt() ?? 0;
    final isUnread = status == 0; // 0=UNREAD

    return InkWell(
      onTap: () async {
        final changed = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => NotificationDetailPage(notification: item),
          ),
        );
        if (changed == true && mounted) {
          // 刷新数据
          await NotiController.to.loadUnread();
          await _loadDataRequest(1, isRefresh: true);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: GbsColors.lightBackgroundB,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: GbsColors.des1Color,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            if (content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: Text(
                  content,
                  maxLines: 2,
                  style: TextStyle(
                    color: GbsColors.des6Color,
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (ts != null)
                  Text(
                    _formatTime(ts),
                    style: TextStyle(
                      color: GbsColors.des9Color,
                      fontSize: 12,
                    ),
                  ),
                if (isUnread)
                  Text(
                    '去处理',
                    style: TextStyle(
                      color: GbsColors.primaryColor,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

