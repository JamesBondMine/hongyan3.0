import 'dart:convert';
import 'package:bell_bird_talk/controllers/user_controller.dart';
import 'package:bell_bird_talk/pages/friends/models/friends_model.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../../services/native_bridge.dart';

/// 好友/群组申请列表页面
class FriendRequestsPage extends StatefulWidget {
  final RequestType type;
  
  const FriendRequestsPage({
    super.key,
    required this.type,
  });

  @override
  State<FriendRequestsPage> createState() => _FriendRequestsPageState();
}

class _FriendRequestsPageState extends State<FriendRequestsPage> {
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
      if (widget.type == RequestType.friend) {
        await _loadFriendRequests(refresh);
      } else {
        await _loadGroupRequests(refresh);
      }
    } finally {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }
  
  /// 加载好友申请
  Future<void> _loadFriendRequests(bool refresh) async {
    try {
      final result = await UserController.to.getFriendRequests(status: -1, page: _currentPage, pageSize: _pageSize);
      
      print('📋 好友申请列表结果: $result');
      
      if (result['errorCode'] == 0) {
        final dataStr = result['data'] as String?;
        if (dataStr != null && dataStr.isNotEmpty) {
          final data = json.decode(dataStr);
          final requestsJson = data['requests'] as List? ?? [];
          
          final newRequests = requestsJson
              .map((json) => FriendRequestModel.fromJson(json))
              .toList();
          
          setState(() {
            if (refresh) {
              _friendRequests.clear();
            }
            _friendRequests.addAll(newRequests);
            _hasMore = newRequests.length >= _pageSize;
            if (newRequests.isNotEmpty) _currentPage++;
          });
        } else {
          setState(() => _hasMore = false);
        }
      }
    } catch (e) {
      print('❌ 获取好友申请失败: $e');
      EasyLoading.showError('获取数据失败');
    }
  }
  
  /// 加载群组申请
  Future<void> _loadGroupRequests(bool refresh) async {
    // TODO: 调用群组申请接口
    // 目前使用模拟数据
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      if (refresh) {
        _groupRequests.clear();
      }
      // 模拟无数据
      _hasMore = false;
    });
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
  
  /// 同意好友申请
  Future<void> _acceptFriendRequest(FriendRequestModel request) async {
    EasyLoading.show(status: '处理中...');
    
    try {
      final result = await _nativeService.imAcceptFriendRequest(
        requestId: request.requestId,
      );
      
      if (result['errorCode'] == 0) {
        EasyLoading.showSuccess('已同意');
        _hasChanges = true;
        
        // 从列表中移除
        setState(() {
          _friendRequests.removeWhere((r) => r.requestId == request.requestId);
        });
        
        // 刷新请求列表（确保数据同步）
        _loadRequests(refresh: true);
      } else {
        EasyLoading.showError(result['message'] ?? '操作失败');
      }
    } catch (e) {
      EasyLoading.showError('操作失败');
    }
  }
  
  /// 拒绝好友申请
  Future<void> _rejectFriendRequest(FriendRequestModel request) async {
    // 显示拒绝原因对话框
    final reasonController = TextEditingController();
    
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('拒绝申请'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('确定要拒绝 ${request.requesterName} 的好友申请吗？'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: '拒绝原因（可选）',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('确定拒绝', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    EasyLoading.show(status: '处理中...');
    
    try {
      final result = await _nativeService.imRejectFriendRequest(
        requestId: request.requestId,
        reason: reasonController.text.trim(),
      );
      
      if (result['errorCode'] == 0) {
        EasyLoading.showSuccess('已拒绝');
        _hasChanges = true;
        
        // 从列表中移除
        setState(() {
          _friendRequests.removeWhere((r) => r.requestId == request.requestId);
        });
        
        // 刷新请求列表（确保数据同步）
        _loadRequests(refresh: true);
      } else {
        EasyLoading.showError(result['message'] ?? '操作失败');
      }
    } catch (e) {
      print('❌ 拒绝好友申请失败: $e');
      EasyLoading.showError('操作失败');
    }
  }

  /// 按日期分组好友请求
Map<String, List<FriendRequestModel>> _groupRequestsByDate() {
  final Map<String, List<FriendRequestModel>> groupedRequests = {};

  for (final request in _friendRequests) {
    // 将毫秒时间戳转换为DateTime对象
    final requestDate = DateTime.fromMillisecondsSinceEpoch(request.requestTime);
    final requestDateOnly = DateTime(requestDate.year, requestDate.month, requestDate.day);
    
    // 获取今天的日期
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    
    String dateLabel;
    if (requestDateOnly.difference(todayDateOnly).inDays == 0) {
      dateLabel = '今天';
    } else {
      // 格式化日期为 "MM月dd日 星期X"
      final weekdays = ['日', '一', '二', '三', '四', '五', '六'];
      dateLabel = '${requestDate.month}月${requestDate.day}日 星期${weekdays[requestDate.weekday - 1]}';
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
    final isFriend = widget.type == RequestType.friend;
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Get.back(result: _hasChanges);
      },
      child: Scaffold(
        backgroundColor: GbsColors.lightAppBarColorB,
        appBar: AppBar(
          title: Text(isFriend ? '好友申请' : '群组申请'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: GbsColors.lightAppBarColorB,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Get.back(result: _hasChanges),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: _buildContent(),
        ),
      ),
    );
  }
  
  Widget _buildContent() {
    final isFriend = widget.type == RequestType.friend;
    final requests = isFriend ? _friendRequests : _groupRequests;
    
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
          padding: const EdgeInsets.all(12),
          itemCount: allDateKeys.length * 2 + (_hasMore ? 1 : 0), // 每组包括日期头和请求列表
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
                children: requestsForDate.map((request) => 
                  _buildFriendRequestItem(request)
                ).toList(),
              );
            }
          },
        ),
      );
    } else {
      // 群组申请保持原有逻辑
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
          padding: const EdgeInsets.all(12),
          itemCount: requests.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == requests.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            
            return _buildGroupRequestItem(_groupRequests[index]);
          },
        ),
      );
    }
  }
  
  /// 日期头部
  Widget _buildDateHeader(String dateLabel) {
    return Container(
      padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: GbsColors.lightAppBarColorB,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 0.5,
          ),
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
    final isFriend = widget.type == RequestType.friend;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFriend ? Icons.person_add_disabled : Icons.group_off,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            isFriend ? '暂无好友申请' : '暂无群组申请',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isFriend ? '当有人向你发送好友申请时会显示在这里' : '当有群组邀请时会显示在这里',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
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

  Color bgColor = avatarbg.isEmpty ? Colors.blue : Color(int.parse(bgcolorStr.replaceFirst('#', '0xFF')));
  Color txtColor = avatarbg.isEmpty ? Colors.blue : Color(int.parse(txtcolorStr.replaceFirst('#', '0xFF')));

  print('avatar $avatar');
  return SizedBox(width: 40,height: 40,child: CircleAvatar(
    radius: 18,
    
    backgroundColor: bgColor,
    backgroundImage: avatar.isNotEmpty
        ? CachedNetworkImageProvider(avatar) // 使用 CachedNetworkImageProvider 替代 CachedNetworkImage
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
  ),);
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
            _userHeadImgView(request.requesterAvatar ?? '', request.avatarBG ?? '',  request.requesterName),
            // CircleAvatar(
            //   radius: 28,
            //   backgroundColor: Colors.orange[100],
            //   backgroundImage: request.requesterAvatar != null
            //       ? NetworkImage(request.requesterAvatar!)
            //       : null,
            //   child: request.requesterAvatar == null
            //       ? Text(
            //           request.requesterName.isNotEmpty
            //               ? request.requesterName[0].toUpperCase()
            //               : '?',
            //           style: TextStyle(
            //             color: Colors.orange[700],
            //             fontWeight: FontWeight.bold,
            //             fontSize: 20,
            //           ),
            //         )
            //       : null,
            // ),
            
            const SizedBox(width: 12),
            
            // 中间 - 用户信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.requesterName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 假设账号信息在另一个字段中，如果没有则显示时间
                  Text(
                    request.formattedTime, // 替换为实际的账号字段，例如 request.account
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                  // 如果有验证消息，则显示
                  if (request.message != null && request.message!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '验证消息: ${request.message}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
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
                    icon: Image.asset(  'assets/img/user/request_off.png',
                      width: 24,
                      height: 24,
                    ),
                    // style: IconButton.styleFrom(
                    //   backgroundColor: Colors.grey[100],
                    //   padding: const EdgeInsets.all(8),
                    //   shape: const CircleBorder(),
                    // ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _acceptFriendRequest(request),
                    icon: Image.asset(  'assets/img/user/request_on.png',
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
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 时间
                Text(
                  request.formattedTime,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
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
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
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