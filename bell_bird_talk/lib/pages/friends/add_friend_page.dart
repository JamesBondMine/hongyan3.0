import 'dart:convert';
import 'package:bell_bird_talk/config/global.dart';
import 'package:bell_bird_talk/controllers/friend_controller.dart';
import 'package:bell_bird_talk/pages/friends/models/friends_model.dart';
import 'package:bell_bird_talk/pages/friends/views/friend_remark_view.dart';
import 'package:bell_bird_talk/pages/friends/views/group_move_view.dart';
import 'package:bell_bird_talk/widgets/common_button.dart';
import 'package:bell_bird_talk/widgets/empty_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../services/native_bridge.dart';
import 'package:bell_bird_talk/pages/models/friend_model.dart';
import '../../utils/gbs_colors.dart';

/// 添加好友页面
class AddFriendPage extends StatefulWidget {
  const AddFriendPage({super.key});

  @override
  State<AddFriendPage> createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> {
  final IOSNativeService _nativeService = IOSNativeService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<SearchUserModel> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String? _lastSearchType; // 记住最后一次搜索的类型，用于发送请求

  FriendGroup? _selectedGroup;

  List<FriendGroup> _friendGroups = [];

  // 黑名单状态mini app
  bool? _isBlocked;

  @override
  void initState() {
    super.initState();
    // 自动聚焦搜索框
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    // 获取好友分组
    _loadFriendGroups();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _searchResults.isEmpty
          ? GbsColors.lightBackgroundB
          : GbsColors.lightBackgroundA,
      appBar: AppBar(
        title: Text(
          '添加好友'.tr,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: GbsColors.des1Color,
          ),
        ),
        centerTitle: true,
        backgroundColor: _searchResults.isEmpty
            ? GbsColors.lightBackgroundB
            : GbsColors.lightBackgroundA,

        foregroundColor: GbsColors.titleColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 搜索区域
          _buildSearchSection(),

          // 搜索结果
          Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }

  // 加载好友分组
  Future<void> _loadFriendGroups({bool refresh = false}) async {
    FriendController.to.getFriendGroups().then((groups) {
      if (refresh && mounted) {
        setState(() {
          _friendGroups = groups;
        });
        return;
      }
      _friendGroups = groups;
    });
  }

  /// 加载黑名单状态
  Future<bool?> _loadBlackStatus(String friendId) async {
    try {
      bool? result = await FriendController.to.loadBlackStatus(friendId);
      if (result != null) {
        _isBlocked = result;
        if (result) {
          EasyLoading.showError('用户已加入黑名单'.tr);
        }
      }
      if (!mounted) {
        setState(() {});
      }
      if (_isBlocked != null) {
        return _isBlocked;
      }
    } catch (e) {
      print('获取黑名单状态失败: $e');
    }
    return null;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 搜索用户
  Future<void> _searchUser() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      EasyLoading.showError('请输入搜索内容'.tr);
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _searchResults = [];
    });

    try {
      String? userId;
      String? accountId;

      // 自动判断搜索类型
      if (query.contains('@')) {
        accountId = query;
        _lastSearchType = 'email';
      } else if (RegExp(r'^\d{11}$').hasMatch(query)) {
        accountId = query;
        _lastSearchType = 'phone';
      } else {
        userId = query;
        _lastSearchType = 'id';
      }

      print(
        '🔍 搜索用户: userId=$userId, accountId=$accountId, type=$_lastSearchType',
      );

      final result = await _nativeService.imSearchUser(
        userId: userId,
        accountId: accountId,
      );

      print('📊 搜索结果: $result');

      if (result['errorCode'] == 0) {
        final dataStr = result['data'] as String?;
        if (dataStr != null && dataStr.isNotEmpty) {
          try {
            final data = json.decode(dataStr);

            // 检查是否有用户数据
            if (data is Map) {
              // 单个用户
              if (data['user_id'] != null || data['id'] != null) {
                setState(() {
                  _searchResults = [
                    SearchUserModel.fromJson(data.cast<String, dynamic>()),
                  ];
                });
              } else if (data['user'] != null) {
                final userData = data['user'] as Map<String, dynamic>;
                setState(() {
                  _searchResults = [SearchUserModel.fromJson(userData)];
                });
              } else if (data['users'] != null) {
                // 多个用户
                final users = data['users'] as List;
                setState(() {
                  _searchResults = users
                      .map(
                        (u) =>
                            SearchUserModel.fromJson(u as Map<String, dynamic>),
                      )
                      .toList();
                });
              }
              _loadBlackStatus(_searchResults.first.id);
            } else if (data is List) {
              setState(() {
                _searchResults = data
                    .map(
                      (u) =>
                          SearchUserModel.fromJson(u as Map<String, dynamic>),
                    )
                    .toList();
              });
              _loadBlackStatus(_searchResults.first.id);
            }
          } catch (e) {
            print('解析搜索结果失败: $e');
          }
        }

        if (_searchResults.isEmpty) {
          EasyLoading.showInfo('未找到用户'.tr);
        }
      } else {
        EasyLoading.showError(result['message'] ?? '搜索失败'.tr);
      }
    } catch (e) {
      print('❌ 搜索用户失败: $e');
      EasyLoading.showError('搜索失败'.tr);
    } finally {
      setState(() => _isSearching = false);
    }
  }

  /// 发送好友申请
  Future<void> _sendFriendRequest(
    SearchUserModel user,
    String message, {
    int? groupId,
  }) async {
    EasyLoading.show(status: '发送中...'.tr);

    try {
      // 确定添加渠道
      int channel = 0; // 默认用户ID
      String? targetValue = user.id;

      if (_lastSearchType == 'phone' && user.phone != null) {
        channel = 2; // 手机号
        targetValue = user.phone;
      } else if (_lastSearchType == 'email' && user.email != null) {
        channel = 3; // 邮箱
        targetValue = user.email;
      }

      final result = await _nativeService.imAddContact(
        targetUserId: user.id,
        channel: channel,
        message: message.isNotEmpty ? message : null,
        targetValue: targetValue,
        targetPhone: user.phone,
        targetEmail: user.email,
        groupId: groupId,
      );

      if (result['errorCode'] == 0) {
        EasyLoading.showSuccess('申请已发送'.tr);
        Get.back();
      } else {
        // 检查一下黑名单状态
        bool? isBlocked = await _loadBlackStatus(user.id);
        if (isBlocked != null && isBlocked == false) {
          EasyLoading.showError(result['message'] ?? '发送失败'.tr);
        }
      }
    } catch (e) {
      print('❌ 发送好友申请失败: $e');
      EasyLoading.showError('发送失败'.tr);
    }
  }

  /// 显示添加好友对话框
  void _showAddFriendDialog(SearchUserModel user) {
    int? groupIdInt;
    if (_selectedGroup != null && _selectedGroup!.id.isNotEmpty) {
      groupIdInt = int.tryParse(_selectedGroup!.id);
    }
    _sendFriendRequest(user, '你好，我想添加你为好友。', groupId: groupIdInt);
  }

  /// 搜索区域
  Widget _buildSearchSection() {
    if (_searchResults.isNotEmpty) {
      return Container();
    }
    return Container(
      // margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: GbsColors.lightBackgroundA,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(Icons.search, color: Colors.grey[400]),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: _getSearchHint(),
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: InputBorder.none,
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _searchUser(),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: Icon(Icons.clear, color: Colors.grey[400], size: 20),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchResults = [];
                    _hasSearched = false;
                  });
                },
              ),
            const SizedBox(width: 16), // 保持右侧间距
          ],
        ),
      ),
    );
  }

  /// 获取搜索提示文本
  String _getSearchHint() {
    return '输入用户ID、手机号或邮箱'.tr;
  }

  /// 搜索结果区域
  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasSearched) {
      return _buildSearchTips();
    }

    if (_searchResults.isEmpty) {
      return EmptyView(message: '该用户不存在'.tr);
    }

    // 只显示第一个搜索结果
    final user = _searchResults.first;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 用户卡片
          _buildUserCard(user),
          const SizedBox(height: 16),

          // 好友分组选择卡片
          _buildGroupSelectionCard(),
          const SizedBox(height: 36),

          // 添加好友按钮
          _buildAddFriendButton(user),
          const SizedBox(height: 16),

          // 移出黑名单按钮
          _buildBlacklistButton(user),
        ],
      ),
    );
  }

  /// 搜索提示
  Widget _buildSearchTips() {
    return Center(child: Padding(padding: const EdgeInsets.all(32)));
  }

  /// 好友分组选择卡片
  Widget _buildGroupSelectionCard() {
    return InkWell(
      onTap: () {
        _showMoveGroupDialog();
      },
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '好友分组'.tr,
              style: TextStyle(fontSize: 16, color: GbsColors.des1Color),
            ),
            Spacer(),
            Text(
              _friendGroups.isEmpty
                  ? '暂无分组'.tr
                  : _selectedGroup != null
                  ? _selectedGroup!.name
                  : '',
              style: TextStyle(fontSize: 14, color: GbsColors.des6Color),
            ),
            SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_sharp,
              size: 12,
              color: GbsColors.des6Color,
            ),
          ],
        ),
      ),
    );
  }

  /// 添加好友按钮
  Widget _buildAddFriendButton(SearchUserModel user) {
    return CommonButton(
      enabled: true,
      text: '添加好友'.tr,
      onPressed: () {
        _showAddFriendDialog(user);
      },
    );
  }

  /// 移出黑名单按钮
  Widget _buildBlacklistButton(SearchUserModel user) {
    if (_isBlocked == null || _isBlocked == false) {
      return Container();
    }
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: GestureDetector(
        onTap: () {
          // TODO: 实现黑名单操作
          EasyLoading.showInfo('黑名单功能开发中'.tr);
        },

        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '已添加至黑名单,'.tr,
              style: TextStyle(fontSize: 16, color: GbsColors.des6Color),
            ),
            SizedBox(width: 8),
            Text(
              '移出黑名单'.tr,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: GbsColors.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 调整分组
  void _showMoveGroupDialog() async {
    if (_friendGroups.isEmpty) {
      final result = await _nativeService.showNativeAlert(
        title: '请先新增分组后再设置好友分组'.tr,
        message: '',
        confirmText: '新增分组'.tr,
        cancelText: '取消'.tr,
        showCancel: true,
      );

      if (result != null && result['action'] == 'confirm') {
        final controller = TextEditingController(text: '');
        // 新增分组
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: FriendRemarkView(
                controller: controller,
                tip: '请输入分组名称'.tr,
                title: '新建分组'.tr,
                onTap: () async {
                  final gname = controller.text.trim();
                  Navigator.pop(context);

                  EasyLoading.show(status: '正在创建分组...'.tr);

                  try {
                    final result = await _nativeService.imCreateContactGroup(
                      groupName: gname,
                    );
                    if (result['errorCode'] == 0) {
                      // 刷新分组列表
                      await _loadFriendGroups(refresh: true);
                      EasyLoading.showSuccess('分组创建成功'.tr);
                    } else {
                      EasyLoading.showError(result['message'] ?? '创建失败'.tr);
                    }
                  } catch (e) {
                    print('创建分组错误: $e');
                    EasyLoading.showError('创建失败，请稍后重试'.tr);
                  }
                },
              ),
            );
          },
        );
      }
    } else {
      gbs.shower.showScreenViewCustom(
        context,
        400,
        Container(
          width: Get.width,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: GbsColors.lightBackgroundB,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: FriendGroupSelectView(
            onItemClick: (value) {
              if (mounted) {
                setState(() {
                  _selectedGroup = value;
                });
              }
            },
          ),
        ),
      );
    }
  }

  /// 用户卡片
  Widget _buildUserCard(SearchUserModel user) {
    return Container(
      height: 70,
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // 头像
          SizedBox(
            width: 40,
            height: 40,
            child: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.blue[100],
              backgroundImage: (user.avatar != null && user.avatar!.isNotEmpty)
                  ? NetworkImage(user.avatar!)
                  : null,
              child: (user.avatar == null || user.avatar!.isEmpty)
                  ? Text(
                      user.nickname.isNotEmpty
                          ? user.nickname[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          // 用户信息
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
                  ],
                ),
                const SizedBox(height: 4),
                if (user.accountId != null && user.accountId!.isNotEmpty)
                  Text(
                    'ID: ${user.accountId}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                if (user.signature != null && user.signature!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    user.signature!,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
