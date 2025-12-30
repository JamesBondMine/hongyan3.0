import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../models/friend_model.dart';
import 'friend_detail_page.dart';
import '../../../services/native_bridge.dart';

/// 好友搜索页面
class FriendSearchPage extends StatefulWidget {
  final List<FriendModel> friends;

  const FriendSearchPage({
    super.key,
    required this.friends,
  });

  @override
  State<FriendSearchPage> createState() => _FriendSearchPageState();
}

class _FriendSearchPageState extends State<FriendSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final IOSNativeService _nativeService = IOSNativeService();
  
  List<FriendModel> _filteredFriends = [];
  String _searchText = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // 自动聚焦搜索框
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 输入变化时更新文本，但真正的搜索走后端
  void _onSearchChanged(String value) {
    setState(() {
      _searchText = value.trim();
    });
  }

  /// 清空搜索
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchText = '';
      _filteredFriends = widget.friends;
    });
    _focusNode.requestFocus();
  }

  /// 调用后端搜索联系人
  Future<void> _doSearch() async {
    final keyword = _searchText.trim();
    if (keyword.isEmpty) {
      setState(() {
        _filteredFriends = widget.friends;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      // 使用 imGetContactList 方法进行搜索
      final result = await _nativeService.imGetContactList(
        page: 1,
        pageSize: 200,  // 搜索时获取更多结果
        relationship: -1,  // 获取全部关系类型
        keyword: keyword,  // 传入搜索关键词
      );
      
      final errorCode = result['errorCode'] as int? ?? -1;
      if (errorCode != 0) {
        EasyLoading.showError(result['message']?.toString() ?? '搜索失败');
        return;
      }

      final dataStr = result['data'] as String? ?? '';
      if (dataStr.isEmpty) {
        setState(() {
          _filteredFriends = [];
        });
        return;
      }

      final decoded = json.decode(dataStr);
      List<dynamic> list;
      if (decoded is List) {
        list = decoded;
      } else if (decoded is Map && decoded['contacts'] is List) {
        list = decoded['contacts'] as List;
      } else {
        list = [];
      }

      final friends = list
          .map((e) => FriendModel.fromJson(
              (e as Map).cast<String, dynamic>()))
          .toList();

      setState(() {
        _filteredFriends = friends;
      });
    } catch (e) {
      EasyLoading.showError('搜索异常: $e');
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _buildSearchAppBar(),
      body: Column(
        children: [
          // 搜索结果统计
          if (_searchText.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              width: double.infinity,
              child: Text(
                '找到 ${_filteredFriends.length} 位好友',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ),
          
          // 好友列表
          Expanded(
            child: _filteredFriends.isEmpty
                ? _buildEmptyResult()
                : _buildFriendList(),
          ),
        ],
      ),
    );
  }

  /// 搜索 AppBar
  PreferredSizeWidget _buildSearchAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: () => Get.back(),
      ),
      title: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: '搜索好友昵称、备注、ID',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        style: const TextStyle(fontSize: 15),
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _doSearch(),
      ),
      actions: [
        if (_searchText.isNotEmpty)
          IconButton(
            icon: Icon(Icons.close, color: Colors.grey[600]),
            onPressed: _clearSearch,
          ),
        IconButton(
          icon: _isSearching
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.search, color: Colors.blue),
          onPressed: _isSearching ? null : _doSearch,
          ),
      ],
    );
  }

  /// 空结果
  Widget _buildEmptyResult() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchText.isEmpty ? Icons.search : Icons.person_search,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            _searchText.isEmpty ? '输入关键词搜索好友' : '未找到匹配的好友',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[500],
            ),
          ),
          if (_searchText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '试试其他关键词',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[400],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 好友列表
  Widget _buildFriendList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _filteredFriends.length,
      itemBuilder: (context, index) {
        final friend = _filteredFriends[index];
        return _buildFriendItem(friend);
      },
    );
  }

  /// 好友项
  Widget _buildFriendItem(FriendModel friend) {
    final displayName = friend.displayName;
    final avatar = friend.avatar ?? '';
    final remark = friend.remark ?? '';
    
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () {
          Get.to(() => FriendDetailPage(friend: friend, onDelete: () { 
            return _onSearchChanged('');
           },));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              // 头像
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.blue[100],
                backgroundImage: avatar.isNotEmpty
                    ? NetworkImage(avatar)
                    : null,
                child: avatar.isEmpty
                    ? Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              
              // 信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 名称（高亮搜索词）
                    _buildHighlightText(displayName),
                    const SizedBox(height: 4),
                    // 备注或ID
                    Text(
                      remark.isNotEmpty 
                          ? '昵称: ${friend.nickname}'
                          : 'ID: ${friend.id}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              
              // 在线状态
              if (friend.onlineStatus == 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '在线',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green[700],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 高亮搜索词
  Widget _buildHighlightText(String text) {
    if (_searchText.isEmpty) {
      return Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    final lowerText = text.toLowerCase();
    final matchIndex = lowerText.indexOf(_searchText);
    
    if (matchIndex == -1) {
      return Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        children: [
          if (matchIndex > 0)
            TextSpan(text: text.substring(0, matchIndex)),
          TextSpan(
            text: text.substring(matchIndex, matchIndex + _searchText.length),
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (matchIndex + _searchText.length < text.length)
            TextSpan(text: text.substring(matchIndex + _searchText.length)),
        ],
      ),
    );
  }
}

