import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../services/native_bridge.dart';

/// 创建群聊页面
/// 支持多选联系人来创建群聊
class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final IOSNativeService _nativeService = IOSNativeService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _groupNameController = TextEditingController();
  
  List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> _filteredContacts = [];
  Set<String> _selectedUserIds = {};
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadContacts();
    _searchController.addListener(_filterContacts);
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _groupNameController.dispose();
    super.dispose();
  }
  
  /// 加载联系人列表
  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await _nativeService.imGetContactList(
        page: 1,
        pageSize: 200,  // 获取较多联系人
      );
      
      if (result['errorCode'] == 0) {
        final dataStr = result['data'] as String?;
        if (dataStr != null && dataStr.isNotEmpty) {
          final data = json.decode(dataStr);
          final contacts = data['contacts'] as List<dynamic>? ?? [];
          
          setState(() {
            _contacts = contacts.map((c) => c as Map<String, dynamic>).toList();
            _filteredContacts = List.from(_contacts);
          });
        }
      } else {
        EasyLoading.showError('获取联系人失败');
      }
    } catch (e) {
      print('加载联系人错误: $e');
      EasyLoading.showError('加载联系人失败');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  /// 过滤联系人
  void _filterContacts() {
    final keyword = _searchController.text.toLowerCase().trim();
    
    if (keyword.isEmpty) {
      setState(() {
        _filteredContacts = List.from(_contacts);
      });
    } else {
      setState(() {
        _filteredContacts = _contacts.where((contact) {
          final nickname = (contact['nickname'] ?? '').toString().toLowerCase();
          final remark = (contact['remark'] ?? '').toString().toLowerCase();
          final userId = (contact['contact_user_id'] ?? '').toString().toLowerCase();
          
          return nickname.contains(keyword) ||
                 remark.contains(keyword) ||
                 userId.contains(keyword);
        }).toList();
      });
    }
  }
  
  /// 切换选择状态
  void _toggleSelection(String userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        _selectedUserIds.add(userId);
      }
    });
  }
  
  /// 创建群聊
  Future<void> _createGroup() async {
    if (_selectedUserIds.length < 2) {
      EasyLoading.showInfo('请至少选择2人');
      return;
    }
    
    // 获取群名称
    String groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) {
      // 自动生成群名：使用前三个成员的昵称
      final selectedContacts = _contacts.where(
        (c) => _selectedUserIds.contains(c['contact_user_id'])
      ).take(3).toList();
      
      groupName = selectedContacts.map((c) {
        return c['remark']?.toString().isNotEmpty == true 
            ? c['remark'] 
            : c['nickname'] ?? '未知';
      }).join('、');
      
      if (_selectedUserIds.length > 3) {
        groupName = '$groupName等${_selectedUserIds.length}人';
      }
    }
    
    EasyLoading.show(status: '创建中...');
    
    try {
      final result = await _nativeService.imCreateGroup(
        groupName: groupName,
        memberIds: _selectedUserIds.toList(),
      );
      
      EasyLoading.dismiss();
      
      if (result['errorCode'] == 0) {
        EasyLoading.showSuccess('群聊创建成功');
        // 返回并刷新会话列表
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        EasyLoading.showError('创建失败: ${result['message']}');
      }
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError('创建群聊失败');
    }
  }
  
  /// 显示已选成员
  Widget _buildSelectedMembers() {
    if (_selectedUserIds.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final selectedContacts = _contacts.where(
      (c) => _selectedUserIds.contains(c['contact_user_id'])
    ).toList();
    
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '已选择 ${_selectedUserIds.length} 人',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: selectedContacts.length,
              itemBuilder: (context, index) {
                final contact = selectedContacts[index];
                final userId = contact['contact_user_id']?.toString() ?? '';
                final nickname = contact['remark']?.toString().isNotEmpty == true
                    ? contact['remark']
                    : contact['nickname'] ?? '未知';
                final avatar = contact['avatar']?.toString() ?? '';
                
                return GestureDetector(
                  onTap: () => _toggleSelection(userId),
                  child: Container(
                    width: 50,
                    margin: const EdgeInsets.only(right: 8),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.grey[300],
                              backgroundImage: avatar.isNotEmpty
                                  ? NetworkImage(avatar)
                                  : null,
                              child: avatar.isEmpty
                                  ? Text(
                                      nickname.isNotEmpty ? nickname[0] : '?',
                                      style: const TextStyle(color: Colors.white),
                                    )
                                  : null,
                            ),
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nickname,
                          style: const TextStyle(fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('选择联系人'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _selectedUserIds.length >= 2 ? _createGroup : null,
            child: Text(
              '创建(${_selectedUserIds.length})',
              style: TextStyle(
                color: _selectedUserIds.length >= 2 
                    ? Colors.white 
                    : Colors.white54,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 群名称输入
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: TextField(
              controller: _groupNameController,
              decoration: InputDecoration(
                hintText: '群名称（选填，不填则自动生成）',
                prefixIcon: const Icon(Icons.group, color: Colors.blue),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          
          // 搜索框
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索联系人',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          
          // 已选成员
          _buildSelectedMembers(),
          
          // 联系人列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredContacts.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.isEmpty 
                              ? '暂无联系人' 
                              : '未找到匹配的联系人',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredContacts.length,
                        itemBuilder: (context, index) {
                          final contact = _filteredContacts[index];
                          return _buildContactItem(contact);
                        },
                      ),
          ),
        ],
      ),
    );
  }
  
  /// 构建联系人项
  Widget _buildContactItem(Map<String, dynamic> contact) {
    final userId = contact['contact_user_id']?.toString() ?? '';
    final nickname = contact['nickname']?.toString() ?? '未知';
    final remark = contact['remark']?.toString() ?? '';
    final avatar = contact['avatar']?.toString() ?? '';
    final isOnline = contact['is_online'] == true;
    final isSelected = _selectedUserIds.contains(userId);
    
    final displayName = remark.isNotEmpty ? remark : nickname;
    
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.grey[300],
            backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
            child: avatar.isEmpty
                ? Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          if (isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
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
        displayName,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: remark.isNotEmpty
          ? Text(
              nickname,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
              ),
            )
          : null,
      trailing: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[400]!,
            width: 2,
          ),
        ),
        child: isSelected
            ? const Icon(
                Icons.check,
                size: 16,
                color: Colors.white,
              )
            : null,
      ),
      onTap: () => _toggleSelection(userId),
    );
  }
}

