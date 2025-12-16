import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../services/native_bridge.dart';
import 'package:bell_bird_talk/pages/models/friend_model.dart';

/// 搜索结果用户模型
class SearchUserModel {
  final String id;
  final String? accountId;
  final String nickname;
  final String? avatar;
  final String? phone;
  final String? email;
  final int? gender;
  final String? signature;
  
  SearchUserModel({
    required this.id,
    this.accountId,
    required this.nickname,
    this.avatar,
    this.phone,
    this.email,
    this.gender,
    this.signature,
  });
  
  factory SearchUserModel.fromJson(Map<String, dynamic> json) {
    return SearchUserModel(
      id: json['user_id'] ?? json['id'] ?? '',
      accountId: json['account_id'],
      nickname: json['nickname'] ?? '未知用户',
      avatar: json['avatar'],
      phone: json['phone'],
      email: json['email'],
      gender: json['gender'] ?? json['sex'],
      signature: json['signature'],
    );
  }
}

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
  String _searchType = 'id';  // id, phone, email
  
  // 好友分组
  final List<FriendGroup> _groups = [];
  String? _selectedGroupId;  // 选中的分组ID（null表示不选择分组）
  
  @override
  void initState() {
    super.initState();
    // 加载分组列表
    _loadContactGroups();
    // 自动聚焦搜索框
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
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
            _groups.clear();
            _groups.addAll(
              groupsJson.map((json) => FriendGroup.fromJson(json)).toList(),
            );
          });
        }
      }
    } catch (e) {
      print('❌ 获取联系人分组失败: $e');
    }
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
      EasyLoading.showError('请输入搜索内容');
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
      
      // 根据搜索类型设置参数
      if (_searchType == 'phone' || _searchType == 'email') {
        accountId = query;
      } else {
        // 自动判断搜索类型
        if (query.contains('@')) {
          accountId = query;
          _searchType = 'email';
        } else if (RegExp(r'^\d{11}$').hasMatch(query)) {
          accountId = query;
          _searchType = 'phone';
        } else {
          userId = query;
          _searchType = 'id';
        }
      }
      
      print('🔍 搜索用户: userId=$userId, accountId=$accountId, type=$_searchType');
      
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
                  _searchResults = [SearchUserModel.fromJson(data.cast<String, dynamic>())];
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
                      .map((u) => SearchUserModel.fromJson(u as Map<String, dynamic>))
                      .toList();
                });
              }
            } else if (data is List) {
              setState(() {
                _searchResults = data
                    .map((u) => SearchUserModel.fromJson(u as Map<String, dynamic>))
                    .toList();
              });
            }
          } catch (e) {
            print('解析搜索结果失败: $e');
          }
        }
        
        if (_searchResults.isEmpty) {
          EasyLoading.showInfo('未找到用户');
        }
      } else {
        EasyLoading.showError(result['message'] ?? '搜索失败');
      }
    } catch (e) {
      print('❌ 搜索用户失败: $e');
      EasyLoading.showError('搜索失败');
    } finally {
      setState(() => _isSearching = false);
    }
  }
  
  /// 发送好友申请
  Future<void> _sendFriendRequest(SearchUserModel user, String message, {int? groupId}) async {
    EasyLoading.show(status: '发送中...');
    
    try {
      // 确定添加渠道
      int channel = 0;  // 默认用户ID
      String? targetValue = user.id;
      
      if (_searchType == 'phone' && user.phone != null) {
        channel = 2;  // 手机号
        targetValue = user.phone;
      } else if (_searchType == 'email' && user.email != null) {
        channel = 3;  // 邮箱
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
      
      print('📊 添加好友结果: $result');
      
      if (result['errorCode'] == 0) {
        EasyLoading.showSuccess('申请已发送');
        Get.back();
      } else {
        EasyLoading.showError(result['message'] ?? '发送失败');
      }
    } catch (e) {
      print('❌ 发送好友申请失败: $e');
      EasyLoading.showError('发送失败');
    }
  }
  
  /// 显示添加好友对话框
  void _showAddFriendDialog(SearchUserModel user) {
    final messageController = TextEditingController(text: '你好，我想加你为好友');
    String? selectedGroupId = _selectedGroupId;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Row(
                children: [
                  const Text(
                    '添加好友',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              
              // 用户信息
              Row(
                children: [
                  CircleAvatar(
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.nickname,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
                
                const SizedBox(height: 20),
                
                // 选择分组
                const Text(
                  '选择分组',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[50],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: selectedGroupId,
                      isExpanded: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      hint: const Text('不选择分组（默认）'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('不选择分组（默认）'),
                        ),
                        ..._groups.map((group) {
                          final groupIdInt = int.tryParse(group.id);
                          if (groupIdInt != null && groupIdInt > 0) {
                            return DropdownMenuItem<String?>(
                              value: group.id,
                              child: Text(group.name),
                            );
                          }
                          return null;
                        }).where((item) => item != null).cast<DropdownMenuItem<String?>>(),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedGroupId = value;
                        });
                      },
                    ),
                  ),
                ),
              
              const SizedBox(height: 20),
              
              // 验证消息
              const Text(
                '验证消息',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: messageController,
                maxLines: 3,
                maxLength: 100,
                decoration: InputDecoration(
                  hintText: '请输入验证消息',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 发送按钮
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                      int? groupIdInt;
                      if (selectedGroupId != null && selectedGroupId!.isNotEmpty) {
                        groupIdInt = int.tryParse(selectedGroupId!);
                      }
                      _sendFriendRequest(
                        user, 
                        messageController.text.trim(),
                        groupId: groupIdInt,
                      );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '发送申请',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
            ],
            ),
          ),
        ),
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
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 搜索区域
          _buildSearchSection(),
          
          // 搜索类型选择
          _buildSearchTypeSelector(),
          
          // 搜索结果
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }
  
  /// 搜索区域
  Widget _buildSearchSection() {
    return Container(
      color: Colors.blue,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
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
            Container(
              margin: const EdgeInsets.only(right: 4),
              child: ElevatedButton(
                onPressed: _isSearching ? null : _searchUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: _isSearching
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('搜索'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 获取搜索提示文本
  String _getSearchHint() {
    switch (_searchType) {
      case 'phone':
        return '输入手机号搜索';
      case 'email':
        return '输入邮箱搜索';
      default:
        return '输入用户ID、手机号或邮箱';
    }
  }
  
  /// 搜索类型选择器
  Widget _buildSearchTypeSelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Text(
            '搜索方式：',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          _buildTypeChip('id', '用户ID'),
          const SizedBox(width: 8),
          _buildTypeChip('phone', '手机号'),
          const SizedBox(width: 8),
          _buildTypeChip('email', '邮箱'),
        ],
      ),
    );
  }
  
  /// 搜索类型选项
  Widget _buildTypeChip(String type, String label) {
    final isSelected = _searchType == type;
    return GestureDetector(
      onTap: () {
        setState(() => _searchType = type);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontSize: 13,
          ),
        ),
      ),
    );
  }
  
  /// 搜索结果区域
  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (!_hasSearched) {
      return _buildSearchTips();
    }
    
    if (_searchResults.isEmpty) {
      return _buildNoResults();
    }
    
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildUserCard(_searchResults[index]);
      },
    );
  }
  
  /// 搜索提示
  Widget _buildSearchTips() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              '搜索用户',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '输入用户ID、手机号或邮箱\n即可搜索添加好友',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            // 快捷入口
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildQuickAction(
                  icon: Icons.qr_code_scanner,
                  label: '扫一扫',
                  onTap: () => EasyLoading.showInfo('扫码功能开发中'),
                ),
                const SizedBox(width: 32),
                _buildQuickAction(
                  icon: Icons.contact_phone,
                  label: '通讯录',
                  onTap: () => EasyLoading.showInfo('通讯录功能开发中'),
                ),
                const SizedBox(width: 32),
                _buildQuickAction(
                  icon: Icons.group_add,
                  label: '面对面',
                  onTap: () => EasyLoading.showInfo('面对面功能开发中'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// 快捷操作按钮
  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.blue, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 无结果视图
  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            '未找到相关用户',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请检查输入是否正确',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
  
  /// 用户卡片
  Widget _buildUserCard(SearchUserModel user) {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAddFriendDialog(user),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 头像
                CircleAvatar(
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
                const SizedBox(width: 16),
                
                // 用户信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      if (user.signature != null && user.signature!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          user.signature!,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                
                // 添加按钮
                ElevatedButton(
                  onPressed: () => _showAddFriendDialog(user),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('添加'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
