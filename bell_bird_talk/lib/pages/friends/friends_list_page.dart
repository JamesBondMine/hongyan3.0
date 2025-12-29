import 'dart:convert';
import 'package:bell_bird_talk/pages/friends/friend_detail_page.dart';
import 'package:bell_bird_talk/pages/models/friend_model.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import '../../controllers/global_controller.dart';
import '../../controllers/user_controller.dart';

/// 好友列表子页面
class FriendsListPage extends StatefulWidget {
  const FriendsListPage({super.key});

  @override
  State<FriendsListPage> createState() => _FriendsListPageState();
}

class _FriendsListPageState extends State<FriendsListPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final List<FriendModel> _friends = [];
  List<FriendModel> _filteredFriends = [];
  
  // 分组头部的位置映射（letter -> GlobalKey）
  final Map<String, GlobalKey> _groupHeaderKeys = {};
  
  bool _isLoading = false;
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMore = true;

  Worker? _refreshFriendListWorker;

  @override
  void initState() {
    super.initState();
    _loadFriends();
    
    final globalCtrl = Get.find<GlobalController>();
    _refreshFriendListWorker = ever(
      globalCtrl.refreshFriendList,
      (_) {
        _loadFriends(refresh: true);
      },
    );
  }

  @override
  void dispose() {
    _refreshFriendListWorker?.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

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
              _friends.clear();
            }
            
            final existingIds = _friends.map((f) => f.id).toSet();
            final uniqueNewFriends = newFriends.where((f) => !existingIds.contains(f.id)).toList();
            
            _friends.addAll(uniqueNewFriends);
            _filteredFriends = _sortAndGroupFriends(List.from(_friends));
            _hasMore = newFriends.length >= _pageSize;
            if (!refresh) {
              _currentPage++;
            }
          });
          
          _filterFriends(_searchController.text);
          Get.find<GlobalController>().triggerChatListRefresh();
        }
      }
    } catch (e) {
      print('❌ 获取好友列表失败: $e');
      EasyLoading.showError('获取好友列表失败');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshFriends() async {
    await _loadFriends(refresh: true);
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
      _filteredFriends = _sortAndGroupFriends(_filteredFriends);
      
      final currentLetters = _getGroupedFriends().keys.toSet();
      _groupHeaderKeys.removeWhere((letter, _) => !currentLetters.contains(letter));
    });
  }

  String _getFirstLetter(String name) {
    if (name.isEmpty) return '#';
    final firstChar = name[0];
    if (RegExp(r'[A-Za-z]').hasMatch(firstChar)) {
      return firstChar.toUpperCase();
    }
    if (RegExp(r'[0-9]').hasMatch(firstChar)) {
      return '#';
    }
    return '#';
  }

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

  List<FriendModel> _sortAndGroupFriends(List<FriendModel> friends) {
    final sorted = List<FriendModel>.from(friends);
    sorted.sort((a, b) {
      final letterA = _getFirstLetterFromPinyin(a);
      final letterB = _getFirstLetterFromPinyin(b);
      if (letterA != letterB) {
        if (letterA == '#') return 1;
        if (letterB == '#') return -1;
        return letterA.compareTo(letterB);
      }
      final cmpPinyin = a.pinyin.compareTo(b.pinyin);
      if (cmpPinyin != 0) return cmpPinyin;
      return a.displayName.compareTo(b.displayName);
    });
    return sorted;
  }

  Map<String, List<FriendModel>> _getGroupedFriends() {
    final grouped = <String, List<FriendModel>>{};
    for (final friend in _filteredFriends) {
      final letter = _getFirstLetterFromPinyin(friend);
      grouped.putIfAbsent(letter, () => []).add(friend);
    }
    return grouped;
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty ? '暂无好友' : '未找到匹配的好友',
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedFriendList() {
    final grouped = _getGroupedFriends();
    final letters = grouped.keys.toList()..sort((a, b) {
      if (a == '#') return 1;
      if (b == '#') return -1;
      return a.compareTo(b);
    });
    
    for (final letter in letters) {
      _groupHeaderKeys.putIfAbsent(letter, () => GlobalKey());
    }
    
    int totalCount = 0;
    for (final letter in letters) {
      totalCount += 1 + grouped[letter]!.length;
    }
    if (_hasMore) totalCount += 1;
    
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          int currentIndex = 0;
          for (final letter in letters) {
            final friends = grouped[letter]!;
            if (index == currentIndex) {
              return Container(
                key: _groupHeaderKeys[letter],
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
            currentIndex++;
            
            for (int i = 0; i < friends.length; i++) {
              if (index == currentIndex) {
                return _buildFriendItem(friends[i]);
              }
              currentIndex++;
            }
          }
          
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

  Widget _buildFriendItem(FriendModel friend) {
    return Container(
      color: Colors.white,
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
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        ),
        subtitle: friend.accountId != null && friend.accountId!.isNotEmpty
            ? Text(
                'ID: ${friend.accountId}  ${friend.displayName}',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
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
      () => FriendDetailPage(friend: friend, onDelete: _refreshFriends),
      transition: Transition.rightToLeft,
    );
    if (result == true) {
      _refreshFriends();
    }
  }

  Widget _buildAlphabetIndex() {
    final grouped = _getGroupedFriends();
    final letters = grouped.keys.toList()..sort((a, b) {
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
                  color: GbsColors.textPrimary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _scrollToLetter(String letter) {
    final key = _groupHeaderKeys[letter];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        alignment: 0.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshFriends,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollEndNotification &&
                        notification.metrics.extentAfter < 100 &&
                        _hasMore &&
                        !_isLoading) {
                      _loadFriends();
                    }
                    return false;
                  },
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      if (_filteredFriends.isEmpty)
                        SliverFillRemaining(child: _buildEmptyView())
                      else
                        _buildGroupedFriendList(),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
}

