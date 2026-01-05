import 'dart:convert';
import 'package:bell_bird_talk/config/global.dart';
import 'package:bell_bird_talk/controllers/friend_controller.dart';
import 'package:bell_bird_talk/pages/friends/pages/add_friends_group_page.dart';
import 'package:bell_bird_talk/pages/friends/views/friend_detail_page.dart';
import 'package:bell_bird_talk/pages/models/friend_model.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/user_controller.dart';
import '../../services/native_bridge.dart';

/// 分组列表子页面（折叠的分组列表）
class FriendGroupsPage extends StatefulWidget {
  FriendGroupsPage({super.key, required this.onSettingGroup});
  VoidCallback onSettingGroup;

  @override
  State<FriendGroupsPage> createState() => FriendGroupsPageState();
}

class FriendGroupsPageState extends State<FriendGroupsPage> {
  final IOSNativeService _nativeService = IOSNativeService();
  
  final List<FriendGroup> _groups = [
    FriendGroup(id: 'all', name: '全部', isDefault: true),
  ];
  
  // 跟踪每个分组的展开/折叠状态
  final Map<String, bool> _expandedStates = {};
  
  // 存储每个分组的好友列表
  final Map<String, List<FriendModel>> _groupFriends = {};
  
  // 跟踪加载状态
  final Map<String, bool> _loadingStates = {};

  final FriendController _friendController = FriendController();

  @override
  void initState() {
    super.initState();
    _loadContactGroups();
    _registerNotification();
  }

  // 注册通知
  void _registerNotification() {
    _friendController.addListenerId(_friendController.friendGropRefreshId, () {
      print('监听到创建了新的好友分组，需要 刷新好友分组列表');
      setState(() {
        _loadContactGroups();
      });
    });
  }

  // 刷新
  void refresh() {
    setState(() {
      _loadContactGroups();
    });
  }

  Future<void> _loadContactGroups() async {
    try {
      final result = await _nativeService.imGetContactGroups(page: 1, pageSize: 30);
      if (result['errorCode'] == 0) {
        final dataStr = result['data'] as String?;
        if (dataStr != null && dataStr.isNotEmpty) {
          final data = json.decode(dataStr);
          final groupsJson = data['groups'] as List? ?? [];
          
          setState(() {
            final defaultGroups = _groups.where((g) => g.isDefault).toList();
            _groups.clear();
            _groups.addAll(defaultGroups);
            
            for (var json in groupsJson) {
              final group = FriendGroup.fromJson(json);
              if (!_groups.any((g) => g.id == group.id)) {
                _groups.add(group);
              }
            }
            
            final nonDefaultGroups = _groups.where((g) => !g.isDefault).toList();
            nonDefaultGroups.sort((a, b) => a.order.compareTo(b.order));
            _groups.removeWhere((g) => !g.isDefault);
            _groups.addAll(nonDefaultGroups);
            
            // 初始化展开状态（默认全部折叠）
            for (var group in _groups) {
              _expandedStates[group.id] = false;
            }
          });
          
          // 加载所有分组的好友
          for (var group in _groups) {
            _loadGroupFriends(group.id);
          }
        } else 
        {
          setState(() {
            _groups.removeWhere((g) => !g.isDefault);
          });
        }
      }
    } catch (e) {
      print('❌ 获取联系人分组失败: $e');
    }
  }

  Future<void> _loadGroupFriends(String groupId) async {
    if (_loadingStates[groupId] == true) return;
    
    setState(() {
      _loadingStates[groupId] = true;
    });
    
    try {
      int? gid;
      if (groupId != 'all' && groupId != 'special') {
        final parsedId = int.tryParse(groupId);
        if (parsedId != null && parsedId > 0) {
          gid = parsedId;
        }
      }
      
      final result = await UserController.to.getContactList(
        page: 1,
        pageSize: 200,
        groupId: gid,
        relationship: -1,
      );
      
      if (result['errorCode'] == 0) {
        final dataStr = result['data'] as String?;
        if (dataStr != null && dataStr.isNotEmpty) {
          final data = json.decode(dataStr);
          final contactsJson = data['contacts'] as List? ?? [];
          
          final friends = contactsJson
              .map((json) => FriendModel.fromJson(json))
              .toList();
          
          setState(() {
            _groupFriends[groupId] = friends;
            // 更新分组数量
            final group = _groups.firstWhere(
              (g) => g.id == groupId,
              orElse: () => _groups.first,
            );
            group.count = friends.length;
          });
        }
      }
    } catch (e) {
      print('❌ 获取分组好友失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loadingStates[groupId] = false;
        });
      }
    }
  }

  void _toggleGroup(String groupId) {
    final isCurrentlyExpanded = _expandedStates[groupId] ?? false;
    
    setState(() {
      // 如果当前分组是展开的，则折叠它
      if (isCurrentlyExpanded) {
        _expandedStates[groupId] = false;
      } else {
        // 如果当前分组是折叠的，则先折叠所有其他分组，再展开当前分组（手风琴效果）
        for (var group in _groups) {
          _expandedStates[group.id] = false;
        }
        _expandedStates[groupId] = true;
      }
    });
    
    // 如果展开且还没有加载好友，则加载
    if (!isCurrentlyExpanded && !_groupFriends.containsKey(groupId)) {
      _loadGroupFriends(groupId);
    }
  }

  Widget _buildGroupItem(FriendGroup group) {
    final isExpanded = _expandedStates[group.id] ?? false;
    final friends = _groupFriends[group.id] ?? [];
    final isLoading = _loadingStates[group.id] ?? false;
    
    return Container(
      // margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        // borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // 分组头部
          InkWell(
            onLongPress: () {
              widget.onSettingGroup();
            },
            onTap: () => _toggleGroup(group.id),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    isExpanded ? Icons.arrow_drop_down_sharp : Icons.arrow_right,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      group.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${friends.length}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 分组内容（好友列表）
          if (isExpanded)
            Container(
              constraints: const BoxConstraints(maxHeight: 400),
              child: isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : friends.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            '暂无好友',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: friends.length,
                          itemBuilder: (context, index) {
                            return _buildFriendItem(friends[index]);
                          },
                        ),
            ),
        ],
      ),
    );
  }

  Widget _buildFriendItem(FriendModel friend) {
    return Container(
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blue[100],
              backgroundImage: (friend.avatar != null && friend.avatar!.isNotEmpty)
                  ? NetworkImage(friend.avatar!)
                  : null,
              child: (friend.avatar == null || friend.avatar!.isEmpty)
                  ? Text(
                      friend.displayName.isNotEmpty 
                          ? friend.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    )
                  : null,
            ),
      
          ],
        ),
        title: Text(
          friend.displayName,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
        ),
        subtitle: friend.accountId != null && friend.accountId!.isNotEmpty
            ? Text(
                'ID: ${friend.accountId}',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        onTap: () => _showFriendDetail(friend),
      ),
    );
  }

  void _showFriendDetail(FriendModel friend) async {
    final result = await Get.to(
      () => FriendDetailPage(
        friend: friend,
        onDelete: () {
          // 刷新该分组的好友列表
          final groupId = _groups.firstWhere(
            (g) => _groupFriends[g.id]?.any((f) => f.id == friend.id) ?? false,
            orElse: () => _groups.first,
          ).id;
          _loadGroupFriends(groupId);
        },
      ),
      transition: Transition.rightToLeft,
    );
    if (result == true) {
      // 刷新所有分组
      for (var group in _groups) {
        _loadGroupFriends(group.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadContactGroups();
        for (var group in _groups) {
          await _loadGroupFriends(group.id);
        }
      },
      child: _groups.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _groups.length,
              itemBuilder: (context, index) {
                return _buildGroupItem(_groups[index]);
              },
            ),
    );
  }
}

