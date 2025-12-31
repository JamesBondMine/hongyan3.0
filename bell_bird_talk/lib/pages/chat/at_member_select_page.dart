import 'dart:convert';
import 'package:bell_bird_talk/controllers/group_controller.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:bell_bird_talk/widgets/common_button.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// @群成员选择页面
class AtMemberSelectPage extends StatefulWidget {
  final String groupId;
  final String currentUserId; // 当前用户ID，用于排除自己

  ValueChanged<List<Map<String, dynamic>>> onMembersSelected;

  AtMemberSelectPage({
    super.key,
    required this.groupId,
    required this.currentUserId,
    required this.onMembersSelected,
  });

  @override
  State<AtMemberSelectPage> createState() => _AtMemberSelectPageState();
}

class _AtMemberSelectPageState extends State<AtMemberSelectPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _allMembers = [];
  List<Map<String, dynamic>> _filteredMembers = [];
  
  // 分组头部的位置映射（letter -> GlobalKey）
  final Map<String, GlobalKey> _groupHeaderKeys = {};
  
  // 多选相关
  bool _isMultiSelectMode = false;
  final Set<String> _selectedMemberIds = {};
  
  // 分页相关
  bool _isLoading = false;
  int _currentPage = 1;
  final int _pageSize = 50;
  bool _hasMore = true;
  
  // 搜索相关
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchText = _searchController.text;
    });
    _filterMembers();
  }

  void _filterMembers() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredMembers = _sortAndGroupMembers(List.from(_allMembers));
      } else {
        _filteredMembers = _sortAndGroupMembers(
          _allMembers.where((member) {
            final alias = (member['member_alias'] as String?) ?? '';
            final nickname = (member['nickname'] as String?) ?? '';
            final userId = (member['user_id'] as String?) ?? '';
            final displayName = alias.isNotEmpty ? alias : (nickname.isNotEmpty ? nickname : userId);
            return displayName.toLowerCase().contains(query) ||
                   userId.toLowerCase().contains(query);
          }).toList(),
        );
      }
      
      final currentLetters = _getGroupedMembers().keys.toSet();
      _groupHeaderKeys.removeWhere((letter, _) => !currentLetters.contains(letter));
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        _hasMore &&
        !_isLoading) {
      _loadMembers();
    }
  }

  Future<void> _loadMembers({bool refresh = false}) async {
    if (_isLoading) return;
    
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
        _allMembers.clear();
      });
    } else {
      setState(() => _isLoading = true);
    }
    
    try {
      final result = await GroupController.to.getGroupMembersFullInfo(
        widget.groupId,
        page: refresh ? 1 : _currentPage,
        pageSize: _pageSize,
      );
      
      if (!mounted) return;
      
      if (result['errorCode'] == 0) {
        final dataStr = json.encode(result);
        final map = json.decode(dataStr) as Map<String, dynamic>;
        final list = (map['members'] as List?) ?? [];
        final members = list.map((e) => (e as Map).cast<String, dynamic>()).toList();
        
        setState(() {
          // 排除当前用户
          final newMembers = members.where((member) {
            final userId = (member['user_id'] as String?) ?? '';
            return userId != widget.currentUserId;
          }).toList();
          
          if (refresh) {
            _allMembers = newMembers;
          } else {
            final existingIds = _allMembers.map((m) => m['user_id'] as String? ?? '').toSet();
            final uniqueNewMembers = newMembers.where((m) {
              final userId = m['user_id'] as String? ?? '';
              return userId.isNotEmpty && !existingIds.contains(userId);
            }).toList();
            _allMembers.addAll(uniqueNewMembers);
          }
          
          _filterMembers(); // 使用搜索过滤方法
          _hasMore = newMembers.length >= _pageSize;
          if (!refresh) {
            _currentPage++;
          }
        });
      }
    } catch (e) {
      print('❌ 获取群成员失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('获取群成员失败')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

  String _getFirstLetterFromPinyin(Map<String, dynamic> member) {
    // 获取成员昵称或ID
    final alias = (member['member_alias'] as String?) ?? '';
    final nickname = (member['nickname'] as String?) ?? '';
    final userId = (member['user_id'] as String?) ?? '';
    final displayName = alias.isNotEmpty ? alias : (nickname.isNotEmpty ? nickname : userId);
    
    // 如果有拼音字段，使用拼音首字母
    final pinyin = (member['pinyin'] as String?) ?? '';
    if (pinyin.isNotEmpty) {
      final c = pinyin[0].toUpperCase();
      if (RegExp(r'[A-Z]').hasMatch(c)) {
        return c;
      }
    }
    
    // 使用简化的拼音首字母估算
    if (displayName.isNotEmpty) {
      final firstChar = displayName[0];
      final code = firstChar.codeUnitAt(0);
      if (code >= 0x4E00 && code <= 0x9FFF) {
        // 中文字符，使用简化的拼音首字母估算
        final offset = code - 0x4E00;
        if (offset < 200) return 'A';
        if (offset < 500) return 'B';
        if (offset < 800) return 'C';
        if (offset < 1200) return 'D';
        if (offset < 1500) return 'E';
        if (offset < 1800) return 'F';
        if (offset < 2200) return 'G';
        if (offset < 2600) return 'H';
        if (offset < 3000) return 'J';
        if (offset < 3400) return 'K';
        if (offset < 3800) return 'L';
        if (offset < 4200) return 'M';
        if (offset < 4600) return 'N';
        if (offset < 5000) return 'O';
        if (offset < 5400) return 'P';
        if (offset < 5800) return 'Q';
        if (offset < 6200) return 'R';
        if (offset < 6600) return 'S';
        if (offset < 7000) return 'T';
        if (offset < 7500) return 'W';
        if (offset < 8000) return 'X';
        if (offset < 8500) return 'Y';
        if (offset < 9000) return 'Z';
      }
    }
    
    return _getFirstLetter(displayName);
  }

  List<Map<String, dynamic>> _sortAndGroupMembers(List<Map<String, dynamic>> members) {
    final sorted = List<Map<String, dynamic>>.from(members);
    sorted.sort((a, b) {
      final letterA = _getFirstLetterFromPinyin(a);
      final letterB = _getFirstLetterFromPinyin(b);
      if (letterA != letterB) {
        if (letterA == '#') return 1;
        if (letterB == '#') return -1;
        return letterA.compareTo(letterB);
      }
      
      // 相同首字母，按显示名称排序
      final aliasA = (a['member_alias'] as String?) ?? '';
      final nicknameA = (a['nickname'] as String?) ?? '';
      final userIdA = (a['user_id'] as String?) ?? '';
      final displayNameA = aliasA.isNotEmpty ? aliasA : (nicknameA.isNotEmpty ? nicknameA : userIdA);
      
      final aliasB = (b['member_alias'] as String?) ?? '';
      final nicknameB = (b['nickname'] as String?) ?? '';
      final userIdB = (b['user_id'] as String?) ?? '';
      final displayNameB = aliasB.isNotEmpty ? aliasB : (nicknameB.isNotEmpty ? nicknameB : userIdB);
      
      return displayNameA.compareTo(displayNameB);
    });
    return sorted;
  }

  Map<String, List<Map<String, dynamic>>> _getGroupedMembers() {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final member in _filteredMembers) {
      final letter = _getFirstLetterFromPinyin(member);
      grouped.putIfAbsent(letter, () => []).add(member);
    }
    return grouped;
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

  Widget _buildAlphabetIndex() {
    final grouped = _getGroupedMembers();
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

  void _toggleMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) {
        _selectedMemberIds.clear();
      }
    });
  }

  void _toggleMemberSelection(String userId) {
    setState(() {
      if (_selectedMemberIds.contains(userId)) {
        _selectedMemberIds.remove(userId);
      } else {
        _selectedMemberIds.add(userId);
      }
    });
  }

  // void _selectAllMembers() {
  //   if (!_isMultiSelectMode) {
  //     _toggleMultiSelectMode();
  //   }
  //   setState(() {
  //     _selectedMemberIds.clear();
  //     for (final member in _filteredMembers) {
  //       final userId = (member['user_id'] as String?) ?? '';
  //       if (userId.isNotEmpty) {
  //         _selectedMemberIds.add(userId);
  //       }
  //     }
  //   });
  // }

  void _confirmSelection() {
    if (_selectedMemberIds.isEmpty) {
      Navigator.pop(context, null);
      return;
    }

    // 构建选中的成员列表
    final selectedMembers = _filteredMembers.where((member) {
      final userId = (member['user_id'] as String?) ?? '';
      return _selectedMemberIds.contains(userId);
    }).toList();
    widget.onMembersSelected(selectedMembers);
    // 返回选中的成员列表
    Navigator.pop(context);
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 16, top: 12, bottom: 12),
      color: Colors.white,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
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
                  hintText: '搜索成员',
                  hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: TextStyle(color: Colors.grey[800], fontSize: 14),
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
      ),
    );
  }

  Widget _buildAtAllButton() {
    return Container(
      color: Colors.white,
      child: ListTile(
        leading: const CircleAvatar(
          radius: 20,
          backgroundColor: Colors.orange,
          child: Icon(Icons.group, size: 22, color: Colors.white),
        ),
        title: const Text(
          '所有人',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        subtitle: const Text('@所有人', style: TextStyle(fontSize: 14, color: Colors.grey)),
        onTap: () {
          Navigator.pop(context, [{'user_id': 'all', 'nickname': '所有人'}]);
        },
      ),
    );
  }

  Widget _buildGroupedMemberList() {
    final grouped = _getGroupedMembers();
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
            final members = grouped[letter]!;
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
            
            for (int i = 0; i < members.length; i++) {
              if (index == currentIndex) {
                return _buildMemberItem(members[i]);
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

  Widget _buildMemberItem(Map<String, dynamic> member) {
    final userId = (member['user_id'] as String?) ?? '';
    final alias = (member['member_alias'] as String?) ?? '';
    final nickname = (member['nickname'] as String?) ?? '';
    final displayName = alias.isNotEmpty ? alias : (nickname.isNotEmpty ? nickname : userId);
    final isAdmin = (member['is_admin'] as bool?) ?? false;
    final avatar = (member['avatar'] as String?) ?? '';
    final isSelected = _selectedMemberIds.contains(userId);

    return Container(
      color: Colors.white,
      child: ListTile(
        leading: _isMultiSelectMode
            ? Row(
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
                    backgroundImage: avatar.isNotEmpty
                        ? CachedNetworkImageProvider(avatar)
                        : null,
                    child: avatar.isEmpty
                        ? Text(
                            displayName.isNotEmpty ? displayName[0].toUpperCase() : '#',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          )
                        : null,
                  ),
                ],
              )
            : CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blue.shade50,
                backgroundImage: avatar.isNotEmpty
                    ? CachedNetworkImageProvider(avatar)
                    : null,
                child: avatar.isEmpty
                    ? Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : '#',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      )
                    : null,
              ),
        title: Text(
          displayName,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        subtitle: isAdmin
            ? const Text('管理员', style: TextStyle(fontSize: 14, color: Colors.orange))
            : null,
        onTap: () {
          if (_isMultiSelectMode) {
            _toggleMemberSelection(userId);
          } else {
            widget.onMembersSelected([member]);
            // 单选模式，直接返回
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, null),
        ),
        title: const Text(
          '选择提醒人',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          
          TextButton(
            child: Text(_isMultiSelectMode ? '取消' : '多选', style: TextStyle(color: GbsColors.des1Color, fontSize: 16),),
            onPressed: () {
              if (_isMultiSelectMode) {
                _confirmSelection();
              } else {
                _toggleMultiSelectMode();
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildSearchBar(),
              _buildAtAllButton(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => _loadMembers(refresh: true),
                  child: _filteredMembers.isEmpty && _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : CustomScrollView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            _buildGroupedMemberList(),
                          ],
                        ),
                ),
              ),
              // footer
              _buildFooterView()
            ],
          ),
          // 右侧字母索引条
          if (_filteredMembers.isNotEmpty)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: _buildAlphabetIndex(),
            ),
        ],
      ),
    );
  }

  Widget _buildFooterView() {
    if (!_isMultiSelectMode){
      return Container( );
    }
  
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: CommonButton(
        onPressed: () {
          _confirmSelection();
        },
        enabled: true,
        text: '确定')
    ); 
  }
}
