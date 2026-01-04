import 'package:bell_bird_talk/controllers/friend_controller.dart';
import 'package:bell_bird_talk/pages/models/friend_model.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:bell_bird_talk/widgets/common_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/route_manager.dart';

class CommunityInvatePage extends StatefulWidget {

  final ValueChanged<List<String>> onConfirm;
  
  const CommunityInvatePage({
    super.key,
    required this.onConfirm,
  });

  @override
  State<CommunityInvatePage> createState() => _CommunityInvatePageState();
}

class _CommunityInvatePageState extends State<CommunityInvatePage> {
  final FriendController _friendController = FriendController.to;

  
  List<FriendGroup> _groups = [];
  Map<String, List<Map<String, dynamic>>> _groupContacts = {}; // groupId -> contacts
  Set<String> _selectedUserIds = {}; // 选中的用户ID
  Set<String> _selectedGroupIds = {}; // 选中的分组ID（用于全选分组）
  bool _isLoading = false;
  String _searchKeyword = '';
  String? _expandedGroupId; // 当前展开的分组ID（手风琴效果：一次只能展开一个）
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  
  /// 加载数据
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // 使用 getContactsByGroup 方法获取所有分组及其联系人（包含默认分组）
      final groupedData = await _friendController.getContactsByGroup();
      
      // 构建分组列表和联系人映射
      final List<FriendGroup> finalGroups = [];
      final Map<String, List<Map<String, dynamic>>> groupContacts = {};
      
      for (final entry in groupedData.entries) {
        final groupId = entry.key;
        final groupData = entry.value;
        
        final groupName = groupData['groupName'] as String;
        final count = groupData['count'] as int;
        final contacts = groupData['contacts'] as List<FriendModel>;
        
        // 创建分组对象
        final group = FriendGroup(
          id: groupId,
          name: groupName,
          isDefault: groupId == '0', // 默认分组
          count: count,
          order: groupId == '0' ? -1 : 0, // 默认分组排在前面
        );
        
        // 将 FriendModel 转换为 Map<String, dynamic> 格式
        final contactsMap = contacts.map((friend) {
          return {
            'contact_user_id': friend.id,
            'nickname': friend.nickname,
            'avatar': friend.avatar,
            'remark': friend.remark,
            'account_id': friend.accountId,
            'relationship': friend.relationship,
            'online_status': friend.onlineStatus,
          };
        }).toList();
        
        finalGroups.add(group);
        groupContacts[groupId] = contactsMap;
      }
      
      // 按 order 排序分组（默认分组在前）
      finalGroups.sort((a, b) => a.order.compareTo(b.order));
      
      setState(() {
        _groups = finalGroups;
        _groupContacts = groupContacts;
      });
    } catch (e) {
      print('❌ 加载数据失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  

  
  /// 切换用户选择状态
  void _toggleUserSelection(String userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
        // 如果取消选择，检查所有分组，移除不再全选的分组
        for (final groupId in _selectedGroupIds.toList()) {
          if (!_isGroupAllSelectedInternal(groupId)) {
            _selectedGroupIds.remove(groupId);
          }
        }
      } else {
        _selectedUserIds.add(userId);
        // 检查是否有分组因为邀请这个用户而变成全选
        for (final entry in _groupContacts.entries) {
          if (!_selectedGroupIds.contains(entry.key) && _isGroupAllSelectedInternal(entry.key)) {
            _selectedGroupIds.add(entry.key);
          }
        }
      }
    });
  }
  
  /// 切换分组选择状态（全选/取消全选分组）
  void _toggleGroupSelection(String groupId) {
    setState(() {
      final contacts = _groupContacts[groupId] ?? [];
      final contactIds = contacts
          .map((c) => c['contact_user_id'] as String?)
          .whereType<String>()
          .toSet();
      
      if (_isGroupAllSelectedInternal(groupId)) {
        // 取消全选：移除该分组的所有用户
        _selectedGroupIds.remove(groupId);
        _selectedUserIds.removeWhere((id) => contactIds.contains(id));
      } else {
        // 全选：邀请该分组的所有用户
        _selectedGroupIds.add(groupId);
        _selectedUserIds.addAll(contactIds);
      }
    });
  }
  
  /// 检查分组是否全选（内部方法，不修改状态）
  bool _isGroupAllSelectedInternal(String groupId) {
    final contacts = _groupContacts[groupId] ?? [];
    if (contacts.isEmpty) return false;
    
    final contactIds = contacts
        .map((c) => c['contact_user_id'] as String?)
        .whereType<String>()
        .toSet();
    
    return contactIds.isNotEmpty && contactIds.every((id) => _selectedUserIds.contains(id));
  }
  
  /// 检查分组是否全选（用于UI显示）
  bool _isGroupAllSelected(String groupId) {
    return _isGroupAllSelectedInternal(groupId);
  }
  
  /// 过滤联系人
  bool _matchesSearch(Map<String, dynamic> contact) {
    if (_searchKeyword.isEmpty) return true;
    
    final keyword = _searchKeyword.toLowerCase();
    final nickname = (contact['nickname'] ?? '').toString().toLowerCase();
    final remark = (contact['remark'] ?? '').toString().toLowerCase();
    final userId = (contact['contact_user_id'] ?? '').toString().toLowerCase();
    
    return nickname.contains(keyword) ||
           remark.contains(keyword) ||
           userId.contains(keyword);
  }
  
  /// 确认邀请
  void _handleConfirm() {
    if (widget.onConfirm != null) {
      widget.onConfirm!(_selectedUserIds.toList());
    }
    Navigator.of(context).pop();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: GbsColors.lightBackgroundB,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '邀请好友',
              style: TextStyle(
                color: GbsColors.des1Color,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        leadingWidth: 100,
        backgroundColor: GbsColors.lightAppBarColorA,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: GbsColors.titleColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 好友列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildFriendList(),
          ),
          _buildInviteLinkCard(),
          // 底部邀请按钮
          _buildBottomButton(),
        ],
      ),
    );
  }

  // 邀请链接卡片
  Widget _buildInviteLinkCard() {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text(
            '邀请链接',
            style: TextStyle(
              color: GbsColors.des6Color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              // color: GbsColors.lightBackgroundA,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: GbsColors.lightBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: Text(
                      'https://example.com/invite/abcdefg',
                      style: TextStyle(
                        color: GbsColors.des6Color,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Image.asset(  
                    'assets/img/community/cunty_copy.png',
                    width: 20,
                    height: 20,
                  ),
                  onPressed: () {
                     // 复制链接到剪贴板的逻辑
                Clipboard.setData(ClipboardData(text: 'https://example.com/invite/abcdefg'));
                // Optional: Show a snackbar to confirm the copy action
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('邀请链接已复制到剪贴板')),
                );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Text(
            '你的邀请链接将在24小时后失效',
            style: TextStyle(
              color: GbsColors.des6Color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '重新生成',
            style: TextStyle(
              color: GbsColors.darkPrimaryButton,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          ],)
          
        ],)
      );
  }
  

  /// 构建好友列表
  Widget _buildFriendList() {
    if (_groups.isEmpty) {
      return Center(
        child: Text(
          '暂无好友',
          style: TextStyle(color: GbsColors.des6Color, fontSize: 14),
        ),
      );
    }
    
    return ListView.builder(
      itemCount: _groups.length,
      itemBuilder: (context, index) {
        final group = _groups[index];
        final contacts = _groupContacts[group.id] ?? [];
        final filteredContacts = contacts.where(_matchesSearch).toList();
        
        // 如果搜索时该分组没有匹配的联系人，则不显示该分组
        if (_searchKeyword.isNotEmpty && filteredContacts.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return _buildGroupSection(group, filteredContacts);
      },
    );
  }
  
  /// 构建分组区域
  Widget _buildGroupSection(FriendGroup group, List<Map<String, dynamic>> contacts) {
    final isGroupSelected = _isGroupAllSelected(group.id);
    final isExpanded = _expandedGroupId == group.id;
    
    return ExpansionTile(
      key: ValueKey('group_${group.id}_${isExpanded}'),
      initiallyExpanded: isExpanded,
      backgroundColor: GbsColors.lightBackgroundB,
      collapsedBackgroundColor: GbsColors.lightBackgroundB,
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      childrenPadding: EdgeInsets.zero,
      onExpansionChanged: (expanded) {
        setState(() {
          if (expanded) {
            // 展开当前分组，关闭其他分组（通过重建所有ExpansionTile实现）
            _expandedGroupId = group.id;
          } else {
            // 关闭当前分组
            _expandedGroupId = null;
          }
        });
      },
      leading: GestureDetector(
        onTap: () => _toggleGroupSelection(group.id),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isGroupSelected ? GbsColors.lightPrimaryButton : GbsColors.lightBorder,
              width: 2,
            ),
            color: isGroupSelected ? GbsColors.lightPrimaryButton : Colors.transparent,
          ),
          child: isGroupSelected
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : null,
        ),
      ),
      title: Text(
        group.name,
        style: TextStyle(
          color: GbsColors.titleColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Container(
        width: 100,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
          Text(
        '${contacts.length}人',
        style: TextStyle(
          color: GbsColors.des6Color,
          fontSize: 12,
        ),
      ),
      SizedBox(width: 8,),
      Icon(isExpanded ? Icons.keyboard_arrow_down : Icons.arrow_forward_ios_sharp, size:isExpanded? 26 : 16,)
        ],),
      ),
      // splashColor: Colors.transparent,
      shape: ShapeBorder.lerp(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        0,
      ),
      children: contacts.map((contact) => _buildFriendItem(contact)).toList(),
    );
  }
  
  /// 构建好友项
  Widget _buildFriendItem(Map<String, dynamic> contact) {
    final userId = contact['contact_user_id'] as String? ?? '';
    final nickname = contact['nickname'] as String? ?? '未知用户';
    final remark = contact['remark'] as String?;
    final avatar = contact['avatar'] as String?;
    final displayName = (remark != null && remark.isNotEmpty) ? remark : nickname;
    final isSelected = _selectedUserIds.contains(userId);
    
    return InkWell(
      onTap: () => _toggleUserSelection(userId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: GbsColors.lightBackgroundB,
          border: Border(
            bottom: BorderSide(color: GbsColors.lightDivider, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            // 选择圆圈
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? GbsColors.lightPrimaryButton : GbsColors.lightBorder,
                  width: 2,
                ),
                color: isSelected ? GbsColors.lightPrimaryButton : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            
            // 头像
            CircleAvatar(
              radius: 20,
              backgroundImage: avatar != null && avatar.isNotEmpty
                  ? NetworkImage(avatar)
                  : null,
              backgroundColor: GbsColors.lightDivider,
              child: avatar == null || avatar.isEmpty
                  ? Text(
                      displayName.isNotEmpty ? displayName[0] : '?',
                      style: TextStyle(
                        color: GbsColors.des6Color,
                        fontSize: 16,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            
            // 名称
            Expanded(
              child: Text(
                displayName,
                style: TextStyle(
                  color: GbsColors.titleColor,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 构建底部按钮
  Widget _buildBottomButton() {
    final selectedCount = _selectedUserIds.length;

    return Container(
      padding: EdgeInsets.all(16),
      child: SafeArea(
        
        child: CommonButton(
      enabled: selectedCount > 0,
      onPressed: () {
        widget.onConfirm(_selectedUserIds.toList());
        Navigator.pop(context);
      },
      text: '邀请${selectedCount > 0 ? '($selectedCount)' : ''}')),
    );
    
    // return Container(
    //   padding: const EdgeInsets.all(16),
    //   decoration: BoxDecoration(
    //     color: GbsColors.lightBackgroundB,
    //     border: Border(
    //       top: BorderSide(color: GbsColors.lightDivider, width: 0.5),
    //     ),
    //   ),
    //   child: SafeArea(
    //     child: SizedBox(
    //       width: double.infinity,
    //       height: 44,
    //       child: ElevatedButton(
    //         onPressed: selectedCount > 0 ? _handleConfirm : null,
    //         style: ElevatedButton.styleFrom(
    //           backgroundColor: GbsColors.lightPrimaryButton,
    //           disabledBackgroundColor: GbsColors.lightDisabled,
    //           shape: RoundedRectangleBorder(
    //             borderRadius: BorderRadius.circular(8),
    //           ),
    //         ),
    //         child: Text(
    //           '邀请${selectedCount > 0 ? '($selectedCount)' : ''}',
    //           style: TextStyle(
    //             color: GbsColors.lightButtonTextPrimary,
    //             fontSize: 16,
    //             fontWeight: FontWeight.w500,
    //           ),
    //         ),
    //       ),
    //     ),
    //   ),
    // );
  }
}
