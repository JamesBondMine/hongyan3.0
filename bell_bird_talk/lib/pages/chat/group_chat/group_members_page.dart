import 'dart:convert';
import 'package:bell_bird_talk/pages/chat/group_chat/group_add_member.dart';
import 'package:bell_bird_talk/pages/friends/models/friends_model.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import '../../../services/native_bridge.dart';
import '../../../controllers/global_controller.dart';
import '../../../controllers/group_controller.dart';

class GroupMembersPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupMembersPage({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupMembersPage> createState() => _GroupMembersPageState();
}

class _GroupMembersPageState extends State<GroupMembersPage> {
  final IOSNativeService _nativeService = IOSNativeService();
  final GroupController _groupController = GroupController.to;
  final GlobalController _globalCtrl = Get.find<GlobalController>();
  
  bool _loading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  static const int _pageSize = 50;
  List<Map<String, dynamic>> _members = [];
  String? _creatorUserId;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMembers(clearFirst: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.8) {
      if (!_loading && _hasMore) {
        _loadMembers();
      }
    }
  }

  Future<void> _loadMembers({bool clearFirst = false}) async {
    if (_loading) return;
    
    setState(() => _loading = true);
    
    if (clearFirst) {
      _currentPage = 1;
      _members = [];
      _hasMore = true;
    }
    
    final result = await _groupController.getGroupMembersFullInfo(
      widget.groupId,
      page: _currentPage,
      pageSize: _pageSize,
    );
    
    if (!mounted) return;
    
    if (result['errorCode'] == 0) {
      final members = result['members'] as List<dynamic>? ?? [];
      final creatorUserId = result['creatorUserId'] as String?;
      
      setState(() {
        if (clearFirst) {
          _members = members.map((e) => (e as Map).cast<String, dynamic>()).toList();
        } else {
          _members.addAll(members.map((e) => (e as Map).cast<String, dynamic>()));
        }
        _creatorUserId = creatorUserId;
        _hasMore = members.length >= _pageSize;
        if (_hasMore) {
          _currentPage++;
        }
      });
    } else {
      EasyLoading.showError(result['message']?.toString() ?? '获取群成员失败');
    }
    
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _globalCtrl.currentUser.value?.id ?? '';
    final isOwner = currentUserId.isNotEmpty && 
                    _creatorUserId != null && 
                    currentUserId == _creatorUserId;
    
    return Scaffold(
      backgroundColor: GbsColors.lightAppBarColorB,
      appBar: AppBar(
        title: Text(
          '群成员 (${_members.length})',
          style: const TextStyle(
            fontSize: 16,
            color: GbsColors.titleColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadMembers(clearFirst: true),
        child: _members.isEmpty && _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: GbsColors.lightAppBarColorA,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: GridView.builder(
                        controller: _scrollController,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.7,
                        ),
                        itemCount: _members.length + (isOwner ? 2 : 0),
                        itemBuilder: (context, index) {
                          if (index < _members.length) {
                            return _buildMemberItem(_members[index]);
                          } else if (index == _members.length && isOwner) {
                            return _buildAddMemberButton();
                          } else if (index == _members.length + 1 && isOwner) {
                            return _buildRemoveMemberButton();
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  if (_loading && _members.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (!_hasMore && _members.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          '已加载全部成员',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
  Widget _buildAvatar(String avatar, String avatarBG, String name){
    String bg = avatarBG;

      String bgcolorStr = '';
    String txtcolorStr = '';
    if (bg.isNotEmpty && bg.contains(':')) {
      bgcolorStr = bg.split(':').first;
      txtcolorStr = bg.split(':').last;
      if (bgcolorStr.isNotEmpty && bgcolorStr.contains('&')) {
        bgcolorStr = bgcolorStr.split('&').first;
      }
    }

    Color bgColor = bg.isEmpty ? Colors.blue : Color(int.parse(bgcolorStr.replaceFirst('#', '0xFF')));
    Color txtColor = bg.isEmpty ? Colors.blue : Color(int.parse(txtcolorStr.replaceFirst('#', '0xFF')));

    return CircleAvatar(
          radius: 22,
          backgroundColor: bgColor,
          child: avatar.isNotEmpty ? Container(
            width: 44,
            height: 44,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: CachedNetworkImageProvider(avatar),
                fit: BoxFit.cover,
              ),
            ),child: CachedNetworkImage(imageUrl: avatar, width: 44, height: 44, fit: BoxFit.cover),
          ) : Text(
            name.isNotEmpty ? name.substring(0,1) : '',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: txtColor),
          ),
    );
  }

  Widget _buildMemberItem(Map<String, dynamic> m) {
    final userId = (m['user_id'] as String?) ?? '';
    final alias = (m['member_alias'] as String?) ?? '';
    final isAdmin = (m['is_admin'] as bool?) ?? false;
    final avatar = (m['avatar'] as String?) ?? '';
    final avatarBG = (m['avatar_bg'] as String?) ?? '';
    final nickname = (m['nickname'] as String?) ?? '';
    
    final name = alias.isNotEmpty ? alias : userId;
    final initial = name.isNotEmpty ? name.characters.first : '#';
    
    return GestureDetector(
      onLongPress: () {
        final currentUserId = _globalCtrl.currentUser.value?.id ?? '';
        if (currentUserId.isNotEmpty && 
            _creatorUserId != null && 
            currentUserId == _creatorUserId &&
            currentUserId != userId) {
          _showRemoveMemberDialog(userId);
        }
      },
      onTap: () async {
        if (userId == _globalCtrl.currentUser.value?.id) {
          Get.toNamed('/profile');
          return;
        } else {
          final result = await _nativeService.imSearchUser(
            userId: userId,
            accountId: userId,
          );

          if (result['errorCode'] == 0) {
            final dataStr = result['data'] as String?;
            if (dataStr != null && dataStr.isNotEmpty) {
              try {
                final data = json.decode(dataStr);
                if (data is Map) {
                  if (data['user_id'] != null || data['id'] != null) {
                    SearchUserModel user = SearchUserModel.fromJson(data.cast<String, dynamic>());
                    _showUserInfo(user);
                  }
                }
              } catch (e) {
                print('解析用户信息失败: $e');
              }
            }
          }
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
        _buildAvatar(avatar, avatarBG, nickname),
          const SizedBox(height: 4),
          Text(
            nickname.isNotEmpty ? nickname : name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
          // if (isAdmin)
          //   Text(
          //     '群主',
          //     style: TextStyle(fontSize: 10, color: Colors.orange.shade700),
          //   ),
        ],
      ),
    );
  }

  Widget _buildAddMemberButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _showAddMemberDialog,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue.shade300, width: 2),
            ),
            child: Icon(
              Icons.add,
              color: Colors.blue.shade700,
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          ' ',
          style: TextStyle(fontSize: 12, color: Colors.blue),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRemoveMemberButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            // 显示选择移除成员的界面
            _showSelectRemoveMemberDialog();
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.red.shade300, width: 2),
            ),
            child: Icon(
              Icons.remove,
              color: Colors.red.shade700,
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          ' ',
          style: TextStyle(fontSize: 12, color: Colors.red),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showUserInfo(SearchUserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('用户信息'),
        content: _buildUserCard(user),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(SearchUserModel user) {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.blue[100],
              backgroundImage: (user.avatar != null && user.avatar!.isNotEmpty)
                  ? NetworkImage(user.avatar!)
                  : null,
              child: (user.avatar == null || user.avatar!.isEmpty)
                  ? Text(
                      user.nickname.isNotEmpty ? user.nickname[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.nickname,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.gender != null) ...[
                        const SizedBox(width: 6),
                        Icon(
                          user.gender == 1 ? Icons.male : Icons.female,
                          size: 16,
                          color: user.gender == 1 ? Colors.blue : Colors.pink,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (user.accountId != null && user.accountId!.isNotEmpty)
                    Text(
                      'ID: ${user.accountId}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddMemberDialog() async {
    EasyLoading.show(status: '加载联系人...');
    
    try {
      final result = await _nativeService.imGetContactList(
        page: 1,
        pageSize: 200,
      );
      
      if (!mounted) return;
      EasyLoading.dismiss();
      
      if (result['errorCode'] != 0) {
        EasyLoading.showError('获取联系人失败');
        return;
      }
      
      final dataStr = result['data'] as String? ?? '';
      if (dataStr.isEmpty) {
        EasyLoading.showInfo('暂无联系人可添加');
        return;
      }
      
      final map = json.decode(dataStr) as Map<String, dynamic>;
      final contacts = (map['contacts'] as List?) ?? [];
      
      if (contacts.isEmpty) {
        EasyLoading.showInfo('暂无联系人可添加');
        return;
      }
      
      // 过滤掉已经是群成员的联系人
      final memberUserIds = _members.map((m) => (m['user_id'] as String?) ?? '').toSet();
      final availableContacts = contacts.where((contact) {
        final userId = (contact['contact_user_id'] as String?) ?? '';
        return userId.isNotEmpty && !memberUserIds.contains(userId);
      }).toList();
      
      if (availableContacts.isEmpty) {
        EasyLoading.showInfo('所有联系人已在群中');
        return;
      }
      
      if (!mounted) return;
      final selectedUserIds = await showDialog<Set<String>>(
        context: context,
        builder: (context) => AddMemberDialog(contacts: availableContacts),
      );
      
      if (selectedUserIds == null || selectedUserIds.isEmpty) {
        return;
      }
      
      EasyLoading.show(status: '添加群成员...');
      final addResult = await _nativeService.imAddGroupMembers(
        groupId: widget.groupId,
        userIds: selectedUserIds.toList(),
      );
      
      if (!mounted) return;
      
      if (addResult['errorCode'] == 0) {
        EasyLoading.showSuccess('添加成功');
        await _loadMembers(clearFirst: true);
      } else {
        EasyLoading.showError(addResult['message']?.toString() ?? '添加失败');
      }
    } catch (e) {
      if (!mounted) return;
      EasyLoading.dismiss();
      EasyLoading.showError('操作失败: $e');
    }
  }

  void _showSelectRemoveMemberDialog() {
    // 过滤掉自己，因为不能移除自己
    final currentUserId = _globalCtrl.currentUser.value?.id ?? '';
    final removableMembers = _members.where((m) {
      final userId = (m['user_id'] as String?) ?? '';
      return userId.isNotEmpty && userId != currentUserId;
    }).toList();

    if (removableMembers.isEmpty) {
      EasyLoading.showInfo('没有可移除的成员');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择要移除的成员'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: removableMembers.length,
            itemBuilder: (context, index) {
              final member = removableMembers[index];
              final userId = (member['user_id'] as String?) ?? '';
              final nickname = (member['nickname'] as String?) ?? '';
              final alias = (member['member_alias'] as String?) ?? '';
              final avatar = (member['avatar'] as String?) ?? '';
              final displayName = nickname.isNotEmpty ? nickname : (alias.isNotEmpty ? alias : userId);

              return ListTile(
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                  child: avatar.isEmpty
                      ? Text(
                          displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white),
                        )
                      : null,
                ),
                title: Text(displayName),
                onTap: () {
                  Navigator.pop(context);
                  _showRemoveMemberDialog(userId);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRemoveMemberDialog(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移除群成员'),
        content: const Text('确定要移除群成员吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      EasyLoading.show(status: '移除群成员...');
      final removeResult = await _nativeService.imRemoveGroupMembers(
        groupId: widget.groupId,
        userIds: [userId],
      );

      if (!mounted) return;

      if (removeResult['errorCode'] == 0) {
        EasyLoading.showSuccess('移除成功');
        await _loadMembers(clearFirst: true);
      } else {
        EasyLoading.showError(removeResult['message']?.toString() ?? '移除失败');
      }
    } catch (e) {
      if (!mounted) return;
      EasyLoading.showError('操作失败: $e');
    }
  }
}

