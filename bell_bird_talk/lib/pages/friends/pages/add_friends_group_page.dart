import 'dart:convert';
import 'package:bell_bird_talk/controllers/friend_controller.dart';
import 'package:bell_bird_talk/controllers/user_controller.dart';
import 'package:bell_bird_talk/pages/friends/views/friends_page.dart';
import 'package:bell_bird_talk/pages/models/friend_model.dart';
import 'package:bell_bird_talk/services/native_bridge.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:bell_bird_talk/widgets/common_button.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class AddFriendGroupPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return AddFriendGroupPageState();
  }
}

class AddFriendGroupPageState extends State<AddFriendGroupPage> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final IOSNativeService _nativeService = IOSNativeService();

  List<FriendModel> _allFriends = [];
  List<FriendModel> _filteredFriends = [];
  final Set<String> _selectedFriendIds = {};

  bool _isLoading = false;
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMore = true;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _loadFriends();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        _hasMore &&
        !_isLoading) {
      _loadFriends();
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchText = _searchController.text;
    });
    _filterFriends();
  }

  Future<void> _loadFriends({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
        _allFriends.clear();
      });
    } else {
      setState(() => _isLoading = true);
    }

    try {
      final result = await UserController.to.getContactList(
        page: refresh ? 1 : _currentPage,
        pageSize: _pageSize,
        groupId: null,
        relationship: -1,
      );

      if (result['errorCode'] == 0) {
        final dataStr = result['data'] as String?;
        if (dataStr != null && dataStr.isNotEmpty) {
          final data = json.decode(dataStr);
          final contactsJson = data['contacts'] as List? ?? [];

          final newFriends = contactsJson
              .map((json) => FriendModel.fromJson(json))
              .toList();

          setState(() {
            if (refresh) {
              _allFriends.clear();
            }

            final existingIds = _allFriends.map((f) => f.id).toSet();
            final uniqueNewFriends =
                newFriends.where((f) => !existingIds.contains(f.id)).toList();

            _allFriends.addAll(uniqueNewFriends);
            _hasMore = newFriends.length >= _pageSize;
            if (!refresh) {
              _currentPage++;
            }
          });

          _filterFriends();
        }
      }
    } catch (e) {
      print('❌ 获取好友列表失败: $e');
      if (mounted) {
        EasyLoading.showError('获取好友列表失败');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterFriends() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredFriends = List.from(_allFriends);
      } else {
        _filteredFriends = _allFriends
            .where((friend) =>
                friend.displayName.toLowerCase().contains(query) ||
                (friend.accountId?.toLowerCase().contains(query) ?? false) ||
                friend.nickname.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  void _toggleFriendSelection(String friendId) {
    setState(() {
      if (_selectedFriendIds.contains(friendId)) {
        _selectedFriendIds.remove(friendId);
      } else {
        _selectedFriendIds.add(friendId);
      }
    });
  }

  Future<void> _createGroup() async {
    final groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) {
      EasyLoading.showError('请输入分组名称');
      return;
    }

    if (groupName.length > 10) {
      EasyLoading.showError('分组名称不能超过10个字符');
      return;
    }

    EasyLoading.show(status: '正在创建分组...');

    try {
      // 1. 创建分组
      final result = await _nativeService.imCreateContactGroup(
        groupName: groupName,
      );

      print('📁 创建联系人分组结果: $result');

      if (result['errorCode'] == 0) {
        // 2. 获取创建的分组ID
        // 创建分组成功后，可能需要重新获取分组列表来获取新创建的分组ID
        // 或者如果接口直接返回group_id，可以使用返回的ID
        String? groupIdStr;
        final dataStr = result['data'] as String?;
        int? groupId;
        
        if (dataStr != null && dataStr.isNotEmpty) {
          try {
            final data = json.decode(dataStr) as Map<String, dynamic>;
            groupIdStr = data['group_id']?.toString();
            if (groupIdStr != null && groupIdStr.isNotEmpty) {
              groupId = int.tryParse(groupIdStr);
            }
          } catch (e) {
            print('解析分组ID失败: $e');
          }
        }

        // 3. 如果有选中的好友且获取到了分组ID，将好友移动到新分组
        if (_selectedFriendIds.isNotEmpty && groupId != null && groupId > 0) {
          int successCount = 0;
          for (final friendId in _selectedFriendIds) {
            try {
              final moveResult = await _nativeService.imMoveContactToGroup(
                contactUserId: friendId,
                groupId: groupId,
              );
              if (moveResult['errorCode'] == 0) {
                successCount++;
              }
            } catch (e) {
              print('移动好友到分组失败: $e');
            }
          }
          print('✅ 已将 $successCount/${_selectedFriendIds.length} 个好友移动到新分组');
        } else if (_selectedFriendIds.isNotEmpty) {
          // 如果没有获取到分组ID，提示用户
          print('⚠️ 无法获取分组ID，无法移动好友到新分组');
        }

        EasyLoading.showSuccess('分组创建成功');
        Navigator.pop(context, true);
      } else {
        EasyLoading.showError(result['message'] ?? '创建失败');
      }
    } catch (e) {
      print('创建分组错误: $e');
      EasyLoading.showError('创建失败，请稍后重试');
    }
  }

  Future<void> _createGroupWithoutFriends(VoidCallback success) async {
    final groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) {
      EasyLoading.showError('请输入分组名称');
      return;
    }

    if (groupName.length > 10) {
      EasyLoading.showError('分组名称不能超过10个字符');
      return;
    }

    EasyLoading.show(status: '正在创建分组...');

    try {
      final result = await _nativeService.imCreateContactGroup(
        groupName: groupName,
      );

      print('📁 创建联系人分组结果: $result');

      if (result['errorCode'] == 0) {
        print('📁 创建联系人分组结果****123');
        EasyLoading.showSuccess('分组创建成功');
        // 通知好友分组页刷新页面
        FriendController.to.updateFriendGroupRefreshId();
        success();
      } else {
        EasyLoading.showError(result['message'] ?? '创建失败');
      }
    } catch (e) {
      print('创建分组错误: $e');
      EasyLoading.showError('创建失败，请稍后重试');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GbsColors.lightAppBarColorA,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTitle('分组名称'),
            _buildEditGroupName(),
            _buildTitle('添加好友到分组'),
            _buildSearch(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _loadFriends(refresh: true),
                child: _filteredFriends.isEmpty && _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: _filteredFriends.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= _filteredFriends.length) {
                            // 加载更多指示器
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          return _buildFriendItem(_filteredFriends[index]);
                        },
                      ),
              ),
            ),
            _buildConfirmButton(),
            _buildCreateButton(),
          ],
        ),
      ),
    );
  }

  // 头部
  Widget _buildHeader() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '新建分组',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: GbsColors.titleColor,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // 编辑分组名称
  Widget _buildEditGroupName() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: GbsColors.lightBackgroundA,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _groupNameController,
            decoration: InputDecoration(
              hintText: '请输入分组名称',
              hintStyle: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              border: InputBorder.none,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            _createGroupWithoutFriends((){
              Navigator.pop(context);
            });
          },
        ),
      ],),
    );
  }

  // 标题
  Widget _buildTitle(String title) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: GbsColors.titleColor,
        ),
      ),
    );
  }

  // 搜索
  Widget _buildSearch() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: GbsColors.lightBackgroundA,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.grey[600], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(fontSize: 14, color: GbsColors.titleColor),
            ),
          ),
          if (_searchText.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
              },
              child: Icon(Icons.clear, color: Colors.grey[600], size: 18),
            ),
        ],
      ),
    );
  }

  // 好友列表项
  Widget _buildFriendItem(FriendModel friend) {
    final isSelected = _selectedFriendIds.contains(friend.id);

    return Container(
      color: Colors.white,
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blue.shade50,
              backgroundImage: (friend.avatar != null && friend.avatar!.isNotEmpty)
                  ? CachedNetworkImageProvider(friend.avatar!)
                  : null,
              child: (friend.avatar == null || friend.avatar!.isEmpty)
                  ? Text(
                      friend.displayName.isNotEmpty
                          ? friend.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 18,
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
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        subtitle: friend.accountId != null && friend.accountId!.isNotEmpty
            ? Text(
                'ID: ${friend.accountId}',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              )
            : null,
        onTap: () {
          _toggleFriendSelection(friend.id);
        },
      ),
    );
  }

  // 确认创建按钮
  Widget _buildConfirmButton() {
    final count = _selectedFriendIds.length;
    return Container(
      margin: const EdgeInsets.all(16),
      child: CommonButton(
        enabled: true,
        onPressed: (){
          _createGroupWithoutFriends((){
              Navigator.pop(context);
            });
        },
        text: count > 0 ? '创建($count)' : '创建',
      ),
    );
  }

  // 不选择好友直接创建
  Widget _buildCreateButton() {
    return InkWell(
      onTap:(){
        _createGroupWithoutFriends((){
              Navigator.pop(context);
            });
      },
      child: Container(
        height: 48,
        alignment: Alignment.center,
        child: Text(
          '不选好友直接创建',
          style: TextStyle(
            fontSize: 14,
            color: Colors.blue,
          ),
        ),
      ),
    );
  }
}