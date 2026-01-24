import 'package:bell_bird_talk/controllers/community_controller.dart';
import 'package:bell_bird_talk/pages/friends/models/friends_model.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:bell_bird_talk/widgets/empty_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../../services/native_bridge.dart';

/// 好友/群组申请列表页面
class CmtMemberRequestsPage extends StatefulWidget {
  final String cmtyId;

  const CmtMemberRequestsPage({super.key, required this.cmtyId});

  @override
  State<CmtMemberRequestsPage> createState() => _CmtMemberRequestsPageState();
}

class _CmtMemberRequestsPageState extends State<CmtMemberRequestsPage> {
  final IOSNativeService _nativeService = IOSNativeService();

  final List<FriendRequestModel> _friendRequests = [];
  final List<GroupRequestModel> _groupRequests = [];

  bool _isLoading = false;
  bool _isRefreshing = false;
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMore = true;

  /// 是否有请求被处理（用于通知父页面刷新）
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  /// 加载申请列表
  Future<void> _loadRequests({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }

    setState(() {
      _isLoading = true;
      if (refresh) _isRefreshing = true;
    });

    try {
      await _loadCmtRequests(refresh);
    } finally {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  /// 加载社群申请
  Future<void> _loadCmtRequests(bool refresh) async {
    try {
      // 如果是刷新，重置页码
      final page = refresh ? 1 : _currentPage;

      final result = await CommunityController.to.loadlistJoinRequests(
        cmtyId: widget.cmtyId,
        page: page,
        pageSize: _pageSize,
      );

      final newRequests = result.records
          .map(
            (joinRequest) => FriendRequestModel(
              requestId: joinRequest.requestId,
              requesterId: joinRequest.userId,
              userId: joinRequest.userId,
              requesterName: joinRequest.nickname.isNotEmpty
                  ? joinRequest.nickname
                  : joinRequest.username.isNotEmpty
                  ? joinRequest.username
                  : '未知用户',
              requesterAvatar: joinRequest.avatar.isNotEmpty
                  ? joinRequest.avatar
                  : null,
              message: joinRequest.requestMessage.isNotEmpty
                  ? joinRequest.requestMessage
                  : null,
              // 状态映射：0=待审核 -> 0=待处理, 1=已通过 -> 1=已同意, 2=已拒绝 -> 2=已拒绝
              status: joinRequest.status,
              requestTime: joinRequest.requestTime,
              expireTime: joinRequest.expireTime,
            ),
          )
          .toList();

      setState(() {
        if (refresh) {
          _friendRequests.clear();
          _currentPage = 1;
        }
        _friendRequests.addAll(newRequests);
        // 判断是否还有更多数据：当前列表数量小于总数，且本次返回的数据量等于每页数量
        _hasMore =
            _friendRequests.length < result.total &&
            newRequests.length >= _pageSize;
        if (newRequests.isNotEmpty && !refresh) {
          _currentPage++;
        } else if (refresh && newRequests.isNotEmpty) {
          _currentPage = 2; // 刷新后，如果还有数据，下一页是第2页
        }
      });
    } catch (e) {
      print('❌ 获取社群申请失败: $e');
      EasyLoading.showError('获取数据失败');
      setState(() {
        _hasMore = false;
      });
    }
  }

  /// 刷新
  Future<void> _refresh() async {
    await _loadRequests(refresh: true);
  }

  /// 加载更多
  Future<void> _loadMore() async {
    if (!_hasMore || _isLoading) return;
    await _loadRequests();
  }

  /// 同意社群申请
  Future<void> _acceptFriendRequest(FriendRequestModel request) async {
    final result = await _nativeService.showNativeAlert(
      title: '确定同意${request.requesterName}加入社群?',
      message: '',
      confirmText: '确认'.tr,
      cancelText: '取消'.tr,
      showCancel: true,
    );

    if (result != null && result['action'] == 'confirm') {
      EasyLoading.show(status: '处理中...');

      try {
        final reviewResult = await _nativeService.community.reviewJoinRequest(
          cmtyId: widget.cmtyId,
          requestId: request.requestId,
          approve: true,
          reviewMessage: '',
        );
        EasyLoading.dismiss();
        if (reviewResult['errorCode'] == 0) {
          EasyLoading.showSuccess('已同意');
          _hasChanges = true;

          // 更新状态为已通过
          setState(() {
            final index = _friendRequests.indexWhere(
              (r) => r.requestId == request.requestId,
            );
            if (index != -1) {
              _friendRequests[index] = FriendRequestModel(
                requestId: request.requestId,
                requesterId: request.requesterId,
                userId: request.userId,
                requesterName: request.requesterName,
                requesterAvatar: request.requesterAvatar,
                avatarBG: request.avatarBG,
                message: request.message,
                channel: request.channel,
                status: 1, // 已通过
                requestTime: request.requestTime,
                expireTime: request.expireTime,
              );
            }
          });

          // 延迟刷新请求列表（确保数据同步）
          await Future.delayed(const Duration(milliseconds: 500));
          _loadRequests(refresh: true);
        } else {
          EasyLoading.showError(reviewResult['message'] ?? '操作失败');
        }
      } catch (e) {
        EasyLoading.dismiss();
        print('❌ 同意社群申请失败: $e');
        EasyLoading.showError('操作失败');
      }
    }
  }

  /// 拒绝社群申请
  Future<void> _rejectFriendRequest(FriendRequestModel request) async {
    final result = await _nativeService.showNativeAlert(
      title: '拒绝申请'.tr,
      message: '确定要拒绝当前账号吗？',
      confirmText: '确定',
      cancelText: '取消'.tr,
      showCancel: true,
    );

    if (result != null && result['action'] == 'confirm') {
      EasyLoading.show(status: '处理中...');

      try {
        final reviewResult = await _nativeService.community.reviewJoinRequest(
          cmtyId: widget.cmtyId,
          requestId: request.requestId,
          approve: false,
          reviewMessage: '',
        );
        EasyLoading.dismiss();
        if (reviewResult['errorCode'] == 0) {
          EasyLoading.showSuccess('已拒绝');
          _hasChanges = true;

          // 更新状态为已拒绝
          setState(() {
            final index = _friendRequests.indexWhere(
              (r) => r.requestId == request.requestId,
            );
            if (index != -1) {
              _friendRequests[index] = FriendRequestModel(
                requestId: request.requestId,
                userId: request.userId,
                requesterId: request.requesterId,
                requesterName: request.requesterName,
                requesterAvatar: request.requesterAvatar,
                avatarBG: request.avatarBG,
                message: request.message,
                channel: request.channel,
                status: 2, // 已拒绝
                requestTime: request.requestTime,
                expireTime: request.expireTime,
              );
            }
          });

          // 延迟刷新请求列表（确保数据同步）
          await Future.delayed(const Duration(milliseconds: 500));
          _loadRequests(refresh: true);
        } else {
          EasyLoading.showError(reviewResult['message'] ?? '操作失败');
        }
      } catch (e) {
        print('❌ 拒绝社群申请失败: $e');
        EasyLoading.showError('操作失败');
      }
    }
  }

  /// 按日期分组好友请求
  Map<String, List<FriendRequestModel>> _groupRequestsByDate() {
    final Map<String, List<FriendRequestModel>> groupedRequests = {};

    for (final request in _friendRequests) {
      // 将毫秒时间戳转换为DateTime对象
      final requestDate = DateTime.fromMillisecondsSinceEpoch(
        request.requestTime,
      );
      final requestDateOnly = DateTime(
        requestDate.year,
        requestDate.month,
        requestDate.day,
      );

      // 获取今天的日期
      final today = DateTime.now();
      final todayDateOnly = DateTime(today.year, today.month, today.day);

      String dateLabel;
      if (requestDateOnly.difference(todayDateOnly).inDays == 0) {
        dateLabel = '今天';
      } else {
        // 格式化日期为 "MM月dd日 星期X"
        // final weekdays = ['日', '一', '二', '三', '四', '五', '六'];
        // dateLabel = '${requestDate.month}月${requestDate.day}日 星期${weekdays[requestDate.weekday - 1]}';
        dateLabel = '${requestDate.month} - ${requestDate.day}';
      }

      if (!groupedRequests.containsKey(dateLabel)) {
        groupedRequests[dateLabel] = [];
      }
      groupedRequests[dateLabel]!.add(request);
    }

    return groupedRequests;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Get.back(result: _hasChanges);
      },
      child: Scaffold(
        backgroundColor: GbsColors.lightAppBarColorB,
        body: RefreshIndicator(onRefresh: _refresh, child: _buildContent()),
      ),
    );
  }

  Widget _buildContent() {
    final isFriend = true;
    final requests = _friendRequests;

    if (_isLoading && requests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (requests.isEmpty) {
      return _buildEmptyView();
    }

    if (isFriend) {
      // 好友申请按日期分组显示
      final groupedRequests = _groupRequestsByDate();
      final allDateKeys = groupedRequests.keys.toList();

      return NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification &&
              notification.metrics.extentAfter < 100 &&
              _hasMore &&
              !_isLoading) {
            _loadMore();
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
          itemCount:
              allDateKeys.length * 2 + (_hasMore ? 1 : 0), // 每组包括日期头和请求列表
          itemBuilder: (context, index) {
            if (index == allDateKeys.length * 2) {
              // 加载更多指示器
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final groupIndex = index ~/ 2;
            final isHeader = index % 2 == 0;

            if (isHeader) {
              // 日期头部
              return _buildDateHeader(allDateKeys[groupIndex]);
            } else {
              // 请求列表
              final requestsForDate = groupedRequests[allDateKeys[groupIndex]]!;
              return Column(
                children: requestsForDate
                    .map((request) => _buildFriendRequestItem(request))
                    .toList(),
              );
            }
          },
        ),
      );
    }
  }

  /// 日期头部
  Widget _buildDateHeader(String dateLabel) {
    return Container(
      padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: GbsColors.lightAppBarColorB,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Text(
            dateLabel,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// 空视图
  Widget _buildEmptyView() {
    return Center(child: EmptyView());
  }

  Widget _userHeadImgView(String avatar, String avatarbg, String nickname) {
    String bgcolorStr = '';
    String txtcolorStr = '';
    if (avatarbg.isNotEmpty && avatarbg.contains(':')) {
      bgcolorStr = avatarbg.split(':').first;
      txtcolorStr = avatarbg.split(':').last;
      if (bgcolorStr.isNotEmpty && bgcolorStr.contains('&')) {
        bgcolorStr = bgcolorStr.split('&').first;
      }
    }

    Color bgColor = avatarbg.isEmpty
        ? Colors.blue
        : Color(int.parse(bgcolorStr.replaceFirst('#', '0xFF')));
    Color txtColor = avatarbg.isEmpty
        ? Colors.blue
        : Color(int.parse(txtcolorStr.replaceFirst('#', '0xFF')));

    print('avatar $avatar');
    return SizedBox(
      width: 40,
      height: 40,
      child: CircleAvatar(
        radius: 18,

        backgroundColor: bgColor,
        backgroundImage: avatar.isNotEmpty
            ? CachedNetworkImageProvider(
                avatar,
              ) // 使用 CachedNetworkImageProvider 替代 CachedNetworkImage
            : null,
        child: avatar.isEmpty
            ? Text(
                nickname.isNotEmpty ? nickname.substring(0, 1) : '我',
                style: TextStyle(
                  color: txtColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
    );
  }

  /// 好友申请项
  Widget _buildFriendRequestItem(FriendRequestModel request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 左侧 - 头像
            _userHeadImgView(
              request.requesterAvatar ?? '',
              request.avatarBG ?? '',
              request.requesterName,
            ),

            const SizedBox(width: 12),

            // 中间 - 用户信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        request.requesterName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '(${request.userId})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: GbsColors.des9Color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // 假设账号信息在另一个字段中，如果没有则显示时间
                  Text(
                    '请求加入社群', // 替换为实际的账号字段，例如 request.account
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                  // 如果有验证消息，则显示
                  if (request.message != null &&
                      request.message!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '验证消息: ${request.message}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 16),

            // 右侧 - 操作按钮
            if (request.isPending)
              Row(
                children: [
                  IconButton(
                    onPressed: () => _rejectFriendRequest(request),
                    icon: Image.asset(
                      'assets/img/user/request_off.png',
                      width: 24,
                      height: 24,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _acceptFriendRequest(request),
                    icon: Image.asset(
                      'assets/img/user/request_on.png',
                      width: 24,
                      height: 24,
                    ),
                    // style: IconButton.styleFrom(
                    //   backgroundColor: Colors.blue,
                    //   padding: const EdgeInsets.all(8),
                    //   shape: const CircleBorder(),
                    // ),
                  ),
                ],
              ),
            if (!request.isPending)
              Text(
                '已处理',
                style: TextStyle(color: GbsColors.des6Color, fontSize: 14),
              ),
          ],
        ),
      ),
    );
  }

  /// 群组申请项
  Widget _buildGroupRequestItem(GroupRequestModel request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 群组信息行
            Row(
              children: [
                // 群头像
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.blue[100],
                  backgroundImage: request.groupAvatar != null
                      ? NetworkImage(request.groupAvatar!)
                      : null,
                  child: request.groupAvatar == null
                      ? Icon(Icons.group, color: Colors.blue[700], size: 28)
                      : null,
                ),
                const SizedBox(width: 12),

                // 群名和申请人
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.groupName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${request.requesterName} 申请加入',
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                    ],
                  ),
                ),

                // 时间
                Text(
                  request.formattedTime,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),

            // 验证消息
            if (request.message != null && request.message!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '验证消息: ${request.message}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ),
            ],

            // 操作按钮
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // TODO: 拒绝群组申请
                      EasyLoading.showInfo('拒绝群组申请');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('拒绝'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: 同意群组申请
                      EasyLoading.showInfo('同意群组申请');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('同意'),
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
