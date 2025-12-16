import 'dart:convert';
import 'package:bell_bird_talk/pages/friends/models/friends_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../services/native_bridge.dart';


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
      final result = await _nativeService.imGetFriendRequests(
        status: -1,  // 获取所有状态
        page: _currentPage,
        pageSize: _pageSize,
      );
      
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
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: Text(isFriend ? '好友申请' : '群组申请'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.blue,
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
          
          if (widget.type == RequestType.friend) {
            return _buildFriendRequestItem(_friendRequests[index]);
          } else {
            return _buildGroupRequestItem(_groupRequests[index]);
          }
        },
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 用户信息行
            Row(
              children: [
                // 头像
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.orange[100],
                  backgroundImage: request.requesterAvatar != null
                      ? NetworkImage(request.requesterAvatar!)
                      : null,
                  child: request.requesterAvatar == null
                      ? Text(
                          request.requesterName.isNotEmpty
                              ? request.requesterName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                
                // 名称和时间
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
                      Text(
                        request.formattedTime,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 状态标签
                if (!request.isPending)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: request.status == 1
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      request.status == 1 ? '已同意' : '已拒绝',
                      style: TextStyle(
                        color: request.status == 1 ? Colors.green : Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
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
            
            // 操作按钮（仅待处理状态显示）
            if (request.isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _rejectFriendRequest(request),
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
                      onPressed: () => _acceptFriendRequest(request),
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

