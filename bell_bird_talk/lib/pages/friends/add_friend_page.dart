import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../services/native_bridge.dart';

/// 添加好友页面
class AddFriendPage extends StatefulWidget {
  const AddFriendPage({super.key});

  @override
  State<AddFriendPage> createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final IOSNativeService _nativeService = IOSNativeService();
  
  bool _isSearching = false;
  List<SearchResultItem> _searchResults = [];

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// 搜索用户
  Future<void> _searchUser() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      EasyLoading.showError('请输入用户ID或手机号/邮箱');
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      // 判断输入类型：邮箱、手机号还是用户ID
      String? userId;
      String? accountId;
      
      accountId = query;
      userId = query;
      // if (query.contains('@')) {
      //   // 邮箱作为账户ID
      //   accountId = query;
      // } else if (RegExp(r'^\d{11}$').hasMatch(query)) {
      //   // 11位数字作为手机号（账户ID）
      //   accountId = query;
      // } else {
      //   // 其他作为用户ID
      //   userId = query;
      // }
      
      print('🔍 搜索用户: userId=$userId, accountId=$accountId');
      
      // 调用原生搜索接口
      final result = await _nativeService.imSearchUser(
        userId: userId,
        accountId: accountId,
      );
      
      print('📬 搜索结果: $result');
      
      final errorCode = result['errorCode'] ?? -1;
      final message = result['message'] ?? '未知错误';
      final data = result['data'];
      
      if (errorCode == 0 && data != null && data.isNotEmpty) {
        // 解析返回的用户数据
        try {
          final userMap = json.decode(data) as Map<String, dynamic>;
          
          setState(() {
            _searchResults = [
              SearchResultItem(
                id: userMap['user_id'] ?? '',
                nickname: userMap['nickname'] ?? '未知用户',
                avatar: userMap['avatar'],
                signature: userMap['signature'],
                accountId: userMap['account_id'],
                email: userMap['email'],
                phone: userMap['phone'],
              ),
            ];
          });
          
          print('✅ 找到用户: ${_searchResults.first.nickname}');
        } catch (e) {
          print('⚠️ 解析用户数据失败: $e');
          EasyLoading.showError('解析数据失败');
        }
      } else {
        setState(() {
          _searchResults = [];
        });
        EasyLoading.showInfo(message);
      }
    } catch (e) {
      print('❌ 搜索用户错误: $e');
      EasyLoading.showError('搜索失败: $e');
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  /// 发送好友请求
  void _sendFriendRequest(SearchResultItem user) {
    Get.dialog(
      AlertDialog(
        title: const Text('发送好友请求'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue[100],
              child: Text(
                user.nickname[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              user.nickname,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              maxLines: 2,
              decoration: InputDecoration(
                hintText: '请输入验证消息（选填）',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              EasyLoading.showSuccess('好友请求已发送');
            },
            child: const Text('发送'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('添加好友'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Column(
        children: [
          // 搜索框
          _buildSearchBox(),
          
          // 添加方式入口
          _buildAddMethods(),
          
          // 搜索结果
          if (_searchResults.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '搜索结果',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Expanded(child: _buildSearchResults()),
          ],
        ],
      ),
    );
  }

  /// 搜索框
  Widget _buildSearchBox() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onSubmitted: (_) => _searchUser(),
              decoration: InputDecoration(
                hintText: '输入用户ID / 手机号 / 邮箱',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _isSearching ? null : _searchUser,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: _isSearching
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('搜索'),
          ),
        ],
      ),
    );
  }

  /// 添加方式入口
  Widget _buildAddMethods() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '其他添加方式',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          _buildMethodItem(
            icon: Icons.qr_code_scanner,
            title: '扫一扫',
            subtitle: '扫描好友二维码添加',
            color: Colors.blue,
            onTap: () => EasyLoading.showInfo('扫一扫功能开发中'),
          ),
          const Divider(height: 1, indent: 56),
          _buildMethodItem(
            icon: Icons.qr_code,
            title: '我的二维码',
            subtitle: '让好友扫描添加我',
            color: Colors.green,
            onTap: () => _showMyQRCode(),
          ),
          const Divider(height: 1, indent: 56),
          _buildMethodItem(
            icon: Icons.phone_android,
            title: '手机联系人',
            subtitle: '从手机通讯录添加',
            color: Colors.orange,
            onTap: () => EasyLoading.showInfo('手机联系人功能开发中'),
          ),
          const Divider(height: 1, indent: 56),
          _buildMethodItem(
            icon: Icons.share,
            title: '分享邀请',
            subtitle: '邀请朋友加入',
            color: Colors.purple,
            onTap: () => EasyLoading.showInfo('分享邀请功能开发中'),
          ),
        ],
      ),
    );
  }

  /// 方式项
  Widget _buildMethodItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 12,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }

  /// 搜索结果列表
  Widget _buildSearchResults() {
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return Container(
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 1),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.blue[100],
              backgroundImage: user.avatar != null
                  ? NetworkImage(user.avatar!)
                  : null,
              child: user.avatar == null
                  ? Text(
                      user.nickname[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    )
                  : null,
            ),
            title: Text(
              user.nickname,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            subtitle: user.signature != null
                ? Text(
                    user.signature!,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            trailing: ElevatedButton(
              onPressed: () => _sendFriendRequest(user),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('添加'),
            ),
          ),
        );
      },
    );
  }

  /// 显示我的二维码
  void _showMyQRCode() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '我的二维码',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Center(
                  child: Icon(
                    Icons.qr_code_2,
                    size: 150,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '扫一扫上面的二维码添加我为好友',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Get.back();
                      EasyLoading.showSuccess('二维码已保存');
                    },
                    icon: const Icon(Icons.save_alt),
                    label: const Text('保存'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Get.back();
                      EasyLoading.showInfo('分享功能开发中');
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('分享'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

/// 搜索结果项模型
class SearchResultItem {
  final String id;
  final String nickname;
  final String? avatar;
  final String? signature;
  final String? accountId;
  final String? email;
  final String? phone;

  SearchResultItem({
    required this.id,
    required this.nickname,
    this.avatar,
    this.signature,
    this.accountId,
    this.email,
    this.phone,
  });
}

