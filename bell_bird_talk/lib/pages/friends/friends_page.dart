import 'dart:convert';
import 'package:bell_bird_talk/pages/friends/models/friends_model.dart';
import 'package:bell_bird_talk/pages/friends/group_list_page.dart';
import 'package:bell_bird_talk/pages/friends/group_settings_sheet.dart';
import 'package:bell_bird_talk/pages/models/friend_model.dart' hide FriendRequestModel;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../controllers/global_controller.dart';
import '../../services/native_bridge.dart';
import '../../services/message_database.dart';
import 'friend_detail_page.dart';
import 'friend_requests_page.dart';
import 'friend_search_page.dart';

/// 好友列表页面
class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final IOSNativeService _nativeService = IOSNativeService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final List<FriendModel> _friends = [];
  List<FriendModel> _filteredFriends = [];
  
  // 分组头部的位置映射（letter -> GlobalKey）
  final Map<String, GlobalKey> _groupHeaderKeys = {};
  
  // 好友申请
  final List<FriendRequestModel> _friendRequests = [];
  int _groupRequestCount = 0;  // 群组申请数量
  bool _isLoadingRequests = false;
  
  // 好友分组
  final List<FriendGroup> _groups = [
    FriendGroup(id: 'all', name: '全部', isDefault: true),
  ];
  String _selectedGroupId = 'all';  // 当前选中的分组
  
  bool _isLoading = false;
  int _totalCount = 0;
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMore = true;

  Worker? _refreshFriendListWorker;
  Worker? _refreshFriendRequestsWorker;
  
  @override
  void initState() {
    super.initState();
    _loadFriendRequests();  // 先加载好友申请
    _loadContactGroups();   // 加载联系人分组
    _loadFriends();
    
    final globalCtrl = Get.find<GlobalController>();
    
    // 监听好友列表刷新信号
    _refreshFriendListWorker = ever(
      globalCtrl.refreshFriendList,
      (_) {
        print('📨 收到好友列表刷新信号');
        _loadFriends(refresh: true);
      },
    );
    
    // 监听好友申请列表刷新信号
    _refreshFriendRequestsWorker = ever(
      globalCtrl.refreshFriendRequests,
      (_) {
        print('📨 收到好友申请列表刷新信号');
        _loadFriendRequests();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _isSearchMode ? _buildSearchAppBar() : _buildNormalAppBar(),
      body: _isLoading && _friends.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _buildMainContent(),
      // 浮动添加按钮
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/add-friend'),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }
  

  @override
  void dispose() {
    _refreshFriendListWorker?.dispose();
    _refreshFriendRequestsWorker?.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 加载好友申请列表
  Future<void> _loadFriendRequests() async {
    if (_isLoadingRequests) return;
    
    setState(() => _isLoadingRequests = true);
    
    try {
      final result = await _nativeService.imGetFriendRequests(
        status: 0,  // 只获取待处理的
        page: 1,
        pageSize: 1,
      );
      if (result['errorCode'] == 0) {
        final dataStr = result['data'] as String?;
        if (dataStr != null && dataStr.isNotEmpty) {
          final data = json.decode(dataStr);
          final requestsJson = data['requests'] as List? ?? [];
          
          setState(() {
            _friendRequests.clear();
            _friendRequests.addAll(
              requestsJson.map((json) => FriendRequestModel.fromJson(json)).toList(),
            );
          });
        }
      }
    } catch (e) {
      print('❌ 获取好友申请失败: $e');
    } finally {
      setState(() => _isLoadingRequests = false);
    }
  }

  /// 加载联系人分组列表
  Future<void> _loadContactGroups() async {
    try {
      final result = await _nativeService.imGetContactGroups(
        page: 1,
        pageSize: 100,
      );
      if (result['errorCode'] == 0) {
        final dataStr = result['data'] as String?;
        if (dataStr != null && dataStr.isNotEmpty) {
          final data = json.decode(dataStr);
          final groupsJson = data['groups'] as List? ?? [];
          
          setState(() {
            // 保留默认分组
            final defaultGroups = _groups.where((g) => g.isDefault).toList();
            _groups.clear();
            _groups.addAll(defaultGroups);
            
            // 更新"全部"分组的数量
            if (_friends.isNotEmpty) {
              final allGroup = _groups.firstWhere((g) => g.id == 'all', orElse: () => _groups.first);
              allGroup.count = _friends.length;
            }
            
            // 添加服务器返回的分组
            for (var json in groupsJson) {
              final group = FriendGroup.fromJson(json);
              // 避免重复添加
              if (!_groups.any((g) => g.id == group.id)) {
                _groups.add(group);
              }
            }
            
            // 按 order 排序（默认分组除外）
            final nonDefaultGroups = _groups.where((g) => !g.isDefault).toList();
            nonDefaultGroups.sort((a, b) => a.order.compareTo(b.order));
            _groups.removeWhere((g) => !g.isDefault);
            _groups.addAll(nonDefaultGroups);
          });
          
          print('✅ 加载了 ${groupsJson.length} 个自定义分组');
        }
      }
    } catch (e) {
      print('❌ 获取联系人分组失败: $e');
    }
  }

  /// 加载好友列表
  Future<void> _loadFriends({bool refresh = false}) async {
    if (_isLoading) return;
    
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
      });
    } else {
      setState(() => _isLoading = true);
    }
    
    try {
      // 根据选中的分组获取 groupId
      int? groupId;
      if (_selectedGroupId != 'all' && _selectedGroupId != 'special') {
        // 查找对应的分组对象
        final selectedGroup = _groups.firstWhere(
          (g) => g.id == _selectedGroupId,
          orElse: () => _groups.first,
        );
        // 将字符串形式的 groupId 转换为 int（FriendGroup.id 是 group_id 的字符串形式）
        if (selectedGroup.id.isNotEmpty) {
          final parsedId = int.tryParse(selectedGroup.id);
          if (parsedId != null && parsedId > 0) {
            groupId = parsedId;
          }
        }
      }
      
      final result = await _nativeService.imGetContactList(
        page: refresh ? 1 : _currentPage,
        pageSize: _pageSize,
        groupId: groupId,
        relationship: -1,
      );
      
      print('📋 好友列表结果: $result');
      
      if (result['errorCode'] == 0) {
        final dataStr = result['data'] as String?;
        if (dataStr != null && dataStr.isNotEmpty) {
          final data = json.decode(dataStr);
          
          _totalCount = data['total_count'] ?? 0;
          final contactsJson = data['contacts'] as List? ?? [];
          
          final newFriends = contactsJson
              .map((json) => FriendModel.fromJson(json))
              .toList();
          
          setState(() {
            if (refresh) {
              _friends.clear();
            }
            
            // 去重：根据好友ID去重，避免重复数据
            final existingIds = _friends.map((f) => f.id).toSet();
            final uniqueNewFriends = newFriends.where((f) => !existingIds.contains(f.id)).toList();
            
            _friends.addAll(uniqueNewFriends);
            _filteredFriends = _sortAndGroupFriends(List.from(_friends));
            _hasMore = newFriends.length >= _pageSize;
            if (!refresh) {
              _currentPage++;
            }
          });
          
          // 保存好友到数据库缓存
          _cacheContactsToDatabase(contactsJson);
          
          // 应用搜索过滤
          _filterFriends(_searchController.text);

          // 联系人更新后，触发会话列表刷新
          Get.find<GlobalController>().triggerChatListRefresh();
        } else {
          setState(() {
            if (refresh) {
              _friends.clear();
              _filteredFriends.clear();
            }
            _hasMore = false;
          });
        }
      } else {
        final message = result['message'] ?? '获取失败';
        EasyLoading.showError(message);
      }
    } catch (e) {
      print('❌ 获取好友列表失败: $e');
      EasyLoading.showError('获取好友列表失败');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 刷新好友列表
  Future<void> _refreshFriends() async {
    await Future.wait([
      _loadFriendRequests(),
      _loadFriends(refresh: true),
      _loadContactGroups(),
    ]);
  }

  /// 加载更多
  Future<void> _loadMore() async {
    if (_hasMore && !_isLoading) {
      await _loadFriends();
    }
  }
  
  /// 缓存好友到数据库
  Future<void> _cacheContactsToDatabase(List<dynamic> contactsJson) async {
    try {
      final userId = Get.find<GlobalController>().currentUser.value?.id;
      if (userId == null || userId.isEmpty) return;
      
      final contacts = contactsJson.map((json) {
        return {
          'contact_user_id': json['contact_user_id'] ?? '',
          'nickname': json['nickname'] ?? '',
          'avatar': json['avatar'] ?? '',
          'remark': json['remark'] ?? '',
          'phone': json['target_phone'] ?? '',
          'email': json['target_email'] ?? '',
          'account_id': json['account_id'] ?? '',
          'relationship': json['relationship'] ?? 0,
          'online_status': json['online_status'] ?? 0,
          'add_channel': json['add_channel'] ?? 0,
          'group_id': json['group_id'],
          'group_name': json['group_name'] ?? '',
          'create_time': json['create_time'],
          'last_chat_time': json['last_chat_time'],
        };
      }).toList();
      
      await MessageDatabase().saveContacts(userId, contacts);
    } catch (e) {
      print('❌ 缓存好友到数据库失败: $e');
    }
  }

  void _filterFriends(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredFriends = List.from(_friends);
      } else {
        _filteredFriends = _friends
            .where((friend) =>
                friend.displayName.toLowerCase().contains(query.toLowerCase()) ||
                (friend.accountId?.toLowerCase().contains(query.toLowerCase()) ?? false))
            .toList();
      }
      // 重新排序和分组
      _filteredFriends = _sortAndGroupFriends(_filteredFriends);
      
      // 清理不再使用的分组头部 keys
      final currentLetters = _getGroupedFriends().keys.toSet();
      _groupHeaderKeys.removeWhere((letter, _) => !currentLetters.contains(letter));
    });
  }

  /// 获取首字母（支持中文拼音首字母）
  String _getFirstLetter(String name) {
    if (name.isEmpty) return '#';
    
    final firstChar = name[0];
    
    // 如果是英文字母
    if (firstChar.contains(RegExp(r'[A-Za-z]'))) {
      return firstChar.toUpperCase();
    }
    
    // 如果是中文字符，转换为拼音首字母
    if (firstChar.contains(RegExp(r'[\u4e00-\u9fa5]'))) {
      return _getPinyinFirstLetter(firstChar);
    }
    
    // 其他字符归为 #
    return '#';
  }

  /// 获取中文字符的拼音首字母
  String _getPinyinFirstLetter(String char) {
    final code = char.codeUnitAt(0);
    
    // 中文字符Unicode范围：0x4E00-0x9FFF
    if (code >= 0x4E00 && code <= 0x9FFF) {
      // 根据Unicode范围估算拼音首字母
      // 这是一个简化实现，基于Unicode编码的近似分布
      final offset = code - 0x4E00;
      
      // 根据Unicode范围映射到拼音首字母
      // 这个映射是基于常用汉字的Unicode分布
      if (offset < 200) return 'A';      // 阿、爱等
      if (offset < 500) return 'B';      // 八、白等
      if (offset < 800) return 'C';      // 擦、才等
      if (offset < 1200) return 'D';     // 大、的等
      if (offset < 1500) return 'E';    // 额、而等
      if (offset < 1800) return 'F';     // 发、方等
      if (offset < 2200) return 'G';    // 噶、该等
      if (offset < 2600) return 'H';     // 哈、好等
      if (offset < 3000) return 'J';    // 家、见等
      if (offset < 3400) return 'K';    // 卡、开等
      if (offset < 3800) return 'L';    // 拉、来等
      if (offset < 4200) return 'M';     // 马、吗等
      if (offset < 4600) return 'N';     // 那、你等
      if (offset < 5000) return 'O';     // 哦、欧等
      if (offset < 5400) return 'P';     // 趴、怕等
      if (offset < 5800) return 'Q';     // 七、其等
      if (offset < 6200) return 'R';     // 日、人等
      if (offset < 6600) return 'S';     // 撒、三等
      if (offset < 7000) return 'T';      // 他、太等
      if (offset < 7500) return 'W';     // 无、我等
      if (offset < 8000) return 'X';     // 西、下等
      if (offset < 8500) return 'Y';     // 压、一、有等
      if (offset < 9000) return 'Z';     // 杂、在等
      
      // 超出范围，使用更粗略的估算
      final index = offset ~/ 200;
      final letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'W', 'X', 'Y', 'Z'];
      if (index < letters.length) {
        return letters[index];
      }
    }
    
    return '#';
  }

  /// 按首字母排序和分组
  List<FriendModel> _sortAndGroupFriends(List<FriendModel> friends) {
    // 先按显示名称排序
    final sorted = List<FriendModel>.from(friends);
    sorted.sort((a, b) {
      final letterA = _getFirstLetterFromPinyin(a);
      final letterB = _getFirstLetterFromPinyin(b);
      // 先按首字母排序
      if (letterA != letterB) {
        // # 放在最后
        if (letterA == '#') return 1;
        if (letterB == '#') return -1;
        return letterA.compareTo(letterB);
      }
      
      // 首字母相同，按拼音整体排序（再按显示名兜底）
      final cmpPinyin = a.pinyin.compareTo(b.pinyin);
      if (cmpPinyin != 0) return cmpPinyin;
      return a.displayName.compareTo(b.displayName);
    });
    
    return sorted;
  }

  /// 从拼音获取首字母，若无则回退 displayName
  String _getFirstLetterFromPinyin(FriendModel friend) {
    final pinyin = friend.pinyin.trim();
    if (pinyin.isNotEmpty) {
      final c = pinyin[0].toUpperCase();
      if (RegExp(r'[A-Z]').hasMatch(c)) {
        return c;
      }
    }
    return _getFirstLetter(friend.displayName);
  }

  /// 获取分组后的好友列表（按首字母分组）
  Map<String, List<FriendModel>> _getGroupedFriends() {
    final grouped = <String, List<FriendModel>>{};
    
    for (final friend in _filteredFriends) {
      final letter = _getFirstLetterFromPinyin(friend);
      grouped.putIfAbsent(letter, () => []).add(friend);
    }
    
    return grouped;
  }

  // 是否显示搜索模式
  bool _isSearchMode = false;
  
  

  /// 主内容区域
  Widget _buildMainContent() {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _refreshFriends,
          child: NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 100 &&
            _hasMore &&
            !_isLoading) {
          _loadMore();
        }
        return false;
      },
      child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(), // 确保可以下拉刷新
        slivers: [
          // 新消息入口（好友申请、群组申请）
          SliverToBoxAdapter(child: _buildRequestsEntry()),
          
          // 好友分组
          SliverToBoxAdapter(child: _buildGroupTabs()),
          
                // 好友列表（按首字母分组）
          if (_filteredFriends.isEmpty)
            SliverFillRemaining(child: _buildEmptyView())
          else
                  _buildGroupedFriendList(),
              ],
            ),
          ),
        ),
        // 右侧字母索引条
        if (_filteredFriends.isNotEmpty)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: _buildAlphabetIndex(),
          ),
      ],
    );
  }
  
  /// 构建字母索引条
  Widget _buildAlphabetIndex() {
    final grouped = _getGroupedFriends();
    final letters = grouped.keys.toList()..sort((a, b) {
      // # 放在最后
      if (a == '#') return 1;
      if (b == '#') return -1;
      return a.compareTo(b);
    });
    
    if (letters.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      width: 24,
      padding: const EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: letters.map((letter) {
          return GestureDetector(
            onTap: () => _scrollToLetter(letter),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 20,
              padding: const EdgeInsets.symmetric(vertical: 1),
              alignment: Alignment.center,
              child: Text(
                letter,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue[600],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  /// 滚动到指定字母的分组
  void _scrollToLetter(String letter) {
    final key = _groupHeaderKeys[letter];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        alignment: 0.0, // 滚动到顶部对齐
      );
    }
  }
  
  /// 新消息入口（好友申请、群组申请）
  Widget _buildRequestsEntry() {
    final friendCount = _friendRequests.where((r) => r.status == 0).length;
    
    return Container(
      margin: const EdgeInsets.all(12),
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
      child: Column(
        children: [
          // 好友申请入口
          _buildRequestEntryItem(
            icon: Icons.person_add,
            iconColor: Colors.orange,
            iconBgColor: Colors.orange[50]!,
            title: '好友申请',
            count: friendCount,
            onTap: () async {
              final result = await Get.to(() => const FriendRequestsPage(type: RequestType.friend));
              if (result == true) {
                // 有好友申请被处理，刷新好友列表和请求数量
                _loadFriends(refresh: true);
                _loadFriendRequests();
              }
            },
          ),
          
          Divider(height: 1, indent: 56, color: Colors.grey[100]),
          
          // 群组入口
          _buildRequestEntryItem(
            icon: Icons.group_add,
            iconColor: Colors.blue,
            iconBgColor: Colors.blue[50]!,
            title: '群组',
            count: _groupRequestCount,
            onTap: () async {
              await Get.to(() => const GroupListPage());
              // 返回后可选择刷新，确保显示最新好友/群关联
              // _loadFriends(refresh: true);
            },
          ),
        ],
      ),
    );
  }
  
  /// 申请入口项
  Widget _buildRequestEntryItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required int count,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // 图标
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            
            // 标题
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            // 数量角标
            if (count > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '+$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            
            const SizedBox(width: 8),
            
            // 箭头
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  /// 普通 AppBar
  AppBar _buildNormalAppBar() {
    return AppBar(
      title: const Text('好友'),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.blue,
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: _openSearchPage,
          tooltip: '搜索好友',
        ),
        IconButton(
          icon: const Icon(Icons.person_add_outlined),
          onPressed: () => Get.toNamed('/add-friend'),
          tooltip: '添加好友',
        ),
      ],
    );
  }

  /// 打开搜索页面
  void _openSearchPage() {
    Get.to(() => FriendSearchPage(friends: _friends));
  }
  
  /// 搜索模式 AppBar
  AppBar _buildSearchAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.blue,
      automaticallyImplyLeading: false,
      title: TextField(
        controller: _searchController,
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        cursorColor: Colors.white,
        decoration: InputDecoration(
          hintText: '搜索好友',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white),
                  onPressed: () {
                    _searchController.clear();
                    _filterFriends('');
                  },
                )
              : null,
        ),
        onChanged: _filterFriends,
      ),
      actions: [
        TextButton(
          onPressed: () {
            _searchController.clear();
            _filterFriends('');
            setState(() => _isSearchMode = false);
          },
          child: const Text(
            '取消',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ],
    );
  }

  /// 好友分组标签栏
  Widget _buildGroupTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // 分组列表（横向滚动）
          Expanded(
            child: SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _groups.length,
                itemBuilder: (context, index) {
                  final group = _groups[index];
                  final isSelected = group.id == _selectedGroupId;
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildGroupChip(group, isSelected),
                  );
                },
              ),
            ),
          ),
          
          // 分组设置按钮
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: _showGroupSettings,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.settings,
                  size: 18,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 分组标签
  Widget _buildGroupChip(FriendGroup group, bool isSelected) {
    // 更新分组内的好友数量
    if (group.id == 'all') {
      group.count = _totalCount;
    } else if (group.id == 'special') {
      // TODO: 特别关心的筛选逻辑
      group.count = 0;
    }
    
    return GestureDetector(
      onTap: () => _selectGroup(group.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[100],
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              group.name,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (group.count > 0) ...[
              const SizedBox(width: 4),
              Text(
                '${group.count}',
                style: TextStyle(
                  color: isSelected ? Colors.white.withOpacity(0.8) : Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// 选择分组
  void _selectGroup(String groupId) {
    if (_selectedGroupId == groupId) return;
    
    setState(() {
      _selectedGroupId = groupId;
    });
    
    // 切换分组时，重新从服务器加载该分组的好友列表
    _loadFriends(refresh: true);
    }
  
  
  /// 显示分组设置
  void _showGroupSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => GroupSettingsSheet(
        groups: _groups,
        onAddGroup: _addGroup,
        onDeleteGroup: _deleteGroup,
        onUpdateGroup: _updateGroup,
      ),
    );
  }
  
  /// 显示移动到分组弹窗
  Future<void> _showMoveToGroupDialog(FriendModel friend) async {
    // 获取好友当前所在的分组ID（从数据库查询）
    String? currentGroupId;
    try {
      final userId = Get.find<GlobalController>().currentUser.value?.id;
      if (userId != null) {
        final contactData = await MessageDatabase().getContact(userId, friend.id);
        if (contactData != null && contactData['group_id'] != null) {
          currentGroupId = contactData['group_id'].toString();
        }
      }
    } catch (e) {
      print('获取好友分组失败: $e');
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _MoveToGroupSheet(
        friend: friend,
        groups: _groups,
        currentGroupId: currentGroupId,
        onMoveToGroup: (groupId) => _moveFriendToGroup(friend, groupId),
        onShowGroupSettings: () {
          Navigator.pop(context); // 关闭移动到分组弹窗
          _showGroupSettings(); // 打开分组管理弹窗
        },
      ),
    );
  }
  
  /// 移动好友到分组
  Future<void> _moveFriendToGroup(FriendModel friend, String groupId) async {
    EasyLoading.show(status: '正在移动...');
    
    try {
      // 将 groupId 转换为 int（如果是 'all' 则传 0 表示移除分组）
      int targetGroupId = 0;
      if (groupId != 'all' && groupId != 'special') {
        final parsedId = int.tryParse(groupId);
        if (parsedId != null && parsedId > 0) {
          targetGroupId = parsedId;
        }
      }
      
      // 调用移动联系人到分组的方法
      final result = await _nativeService.imMoveContactToGroup(
        contactUserId: friend.id,
        groupId: targetGroupId,
      );
      
      if (result['errorCode'] == 0) {
        EasyLoading.showSuccess('移动成功');
        // 刷新好友列表
        await _loadFriends(refresh: true);
      } else {
        EasyLoading.showError(result['message'] ?? '移动失败');
      }
    } catch (e) {
      print('移动好友到分组错误: $e');
      EasyLoading.showError('移动失败，请稍后重试');
    }
  }
  
  /// 添加分组
  Future<void> _addGroup(String name) async {
    if (name.isEmpty) {
      EasyLoading.showError('分组名称不能为空');
      return;
    }
    
    // 检查是否已存在
    if (_groups.any((g) => g.name == name)) {
      EasyLoading.showError('分组已存在');
      return;
    }
    
    EasyLoading.show(status: '正在创建分组...');
    
    try {
      final result = await _nativeService.imCreateContactGroup(
        groupName: name,
      );
      
      print('📁 创建联系人分组结果: $result');
      
      if (result['errorCode'] == 0) {
    EasyLoading.showSuccess('分组创建成功');
        // 刷新分组列表
        await _loadContactGroups();
      } else {
        EasyLoading.showError(result['message'] ?? '创建失败');
      }
    } catch (e) {
      print('创建分组错误: $e');
      EasyLoading.showError('创建失败，请稍后重试');
    }
  }
  
  /// 删除分组
  void _deleteGroup(FriendGroup group) {
    if (group.isDefault) {
      EasyLoading.showError('默认分组不能删除');
      return;
    }
    
    Get.dialog(
      AlertDialog(
        title: const Text('删除分组'),
        content: Text('确定要删除「${group.name}」分组吗？'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _confirmDeleteGroup(group);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteGroup(FriendGroup group) async {
    EasyLoading.show(status: '删除分组中...');
    try {
      final gid = int.tryParse(group.id) ?? 0;
      final result = await _nativeService.imDeleteContactGroup(groupId: gid);
      if (result['errorCode'] == 0) {
        EasyLoading.showSuccess('分组已删除');
        await _loadContactGroups();
        if (_selectedGroupId == group.id) {
          _selectedGroupId = 'all';
          await _loadFriends(refresh: true);
        }
      } else {
        EasyLoading.showError(result['message'] ?? '删除失败');
      }
    } catch (e) {
      EasyLoading.showError('删除失败，请稍后重试');
    }
  }

  Future<void> _updateGroup(FriendGroup group) async {
    final controller = TextEditingController(text: group.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('修改分组名称'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: '请输入新的分组名称'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('保存')),
          ],
        );
      },
    );
    if (newName == null) return;
    if (newName.isEmpty) {
      EasyLoading.showError('分组名称不能为空');
      return;
    }
    if (newName == group.name) return;

    EasyLoading.show(status: '更新分组中...');
    try {
      final gid = int.tryParse(group.id) ?? 0;
      final result = await _nativeService.imUpdateContactGroup(
        groupId: gid,
        groupName: newName,
      );
      if (result['errorCode'] == 0) {
        EasyLoading.showSuccess('分组已更新');
        await _loadContactGroups();
      } else {
        EasyLoading.showError(result['message'] ?? '更新失败');
      }
    } catch (e) {
      EasyLoading.showError('更新失败，请稍后重试');
    }
  }

  /// 空视图
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty ? '暂无好友' : '未找到匹配的好友',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          if (_searchController.text.isEmpty)
            ElevatedButton.icon(
              onPressed: () => Get.toNamed('/add-friend'),
              icon: const Icon(Icons.person_add),
              label: const Text('添加好友'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建分组的好友列表
  Widget _buildGroupedFriendList() {
    final grouped = _getGroupedFriends();
    final letters = grouped.keys.toList()..sort((a, b) {
      // # 放在最后
      if (a == '#') return 1;
      if (b == '#') return -1;
      return a.compareTo(b);
    });
    
    // 确保每个字母都有对应的 GlobalKey
    for (final letter in letters) {
      _groupHeaderKeys.putIfAbsent(letter, () => GlobalKey());
    }
    
    // 计算总项目数（包括分组头部）
    int totalCount = 0;
    for (final letter in letters) {
      totalCount += 1 + grouped[letter]!.length; // 1个分组头部 + 好友数量
    }
    if (_hasMore) totalCount += 1; // 加载更多指示器
    
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          int currentIndex = 0;
          
          // 遍历所有分组
          for (final letter in letters) {
            final friends = grouped[letter]!;
            
            // 分组头部
            if (index == currentIndex) {
              return _buildGroupHeader(letter, _groupHeaderKeys[letter]!);
            }
            currentIndex++;
            
            // 分组内的好友
            for (int i = 0; i < friends.length; i++) {
              if (index == currentIndex) {
                return _buildFriendItem(friends[i]);
              }
              currentIndex++;
            }
          }
          
          // 加载更多指示器
          if (index == currentIndex && _hasMore) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          
          return const SizedBox.shrink();
        },
        childCount: totalCount,
      ),
    );
  }

  /// 构建分组头部
  Widget _buildGroupHeader(String letter, GlobalKey key) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[100],
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  /// 好友项
  Widget _buildFriendItem(FriendModel friend) {
    return Container(
      color: Colors.white,
      child: GestureDetector(
        onLongPress: () => _showMoveToGroupDialog(friend),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 24,
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
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      )
                    : null,
              ),
              // 在线状态指示器
              if (friend.isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            '${friend.nickname} ${friend.remark==null || friend.remark!.isEmpty || friend.remark != friend.nickname ? "(${friend.remark})" : ""}',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          subtitle: friend.accountId != null && friend.accountId!.isNotEmpty
              ? Text(
                  'ID: ${friend.accountId}  ${friend.displayName}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          onTap: () => _showFriendDetail(friend),
        ),
      ),
    );
  }

  /// 显示好友详情
  void _showFriendDetail(FriendModel friend) async {
    final result = await Get.to(
      () => FriendDetailPage(friend: friend, onDelete: _refreshFriends),
      transition: Transition.rightToLeft,
    );
    
    // 如果返回 true，刷新好友列表
    if (result == true) {
      _refreshFriends();
    }
  }
}

/// 移动到分组底部弹窗
class _MoveToGroupSheet extends StatelessWidget {
  final FriendModel friend;
  final List<FriendGroup> groups;
  final String? currentGroupId;
  final Function(String) onMoveToGroup;
  final VoidCallback onShowGroupSettings;
  
  const _MoveToGroupSheet({
    required this.friend,
    required this.groups,
    required this.currentGroupId,
    required this.onMoveToGroup,
    required this.onShowGroupSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖动条
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // 标题栏
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text(
                  '移动到分组',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: onShowGroupSettings,
                  tooltip: '添加分组',
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // 分组列表
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                final isCurrentGroup = currentGroupId != null && 
                    (currentGroupId == group.id || 
                     (currentGroupId == 'all' && group.id == 'all'));
                
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: group.isDefault ? Colors.blue[50] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      group.id == 'special' ? Icons.star : Icons.folder,
                      color: group.isDefault ? Colors.blue : Colors.grey[600],
                      size: 20,
                    ),
                  ),
                  title: Text(
                    group.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isCurrentGroup ? Colors.grey[400] : Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    group.isDefault ? '默认分组' : '${group.count} 位好友',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 13,
                    ),
                  ),
                  trailing: isCurrentGroup
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  enabled: !isCurrentGroup,
                  onTap: isCurrentGroup
                      ? null
                      : () {
                          Navigator.pop(context);
                          onMoveToGroup(group.id);
                        },
                );
              },
            ),
          ),
          
          // 底部安全区域
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}
