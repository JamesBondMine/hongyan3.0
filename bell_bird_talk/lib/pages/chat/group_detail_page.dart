import 'dart:convert';
import 'dart:io';
import 'package:bell_bird_talk/pages/chat/group_add_member.dart';
import 'package:bell_bird_talk/pages/friends/models/friends_model.dart';
import 'package:bell_bird_talk/pages/models/friend_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../../services/native_bridge.dart';
import '../../controllers/global_controller.dart';
import '../../controllers/group_controller.dart';
import '../friends/group_list_page.dart';

class GroupDetailPage extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String? groupAvatar;

  const GroupDetailPage({
    super.key,
    required this.groupId,
    required this.groupName,
    this.groupAvatar,
  });

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  final IOSNativeService _nativeService = IOSNativeService();
  final GroupController _groupController = GroupController.to;
  final GlobalController _globalCtrl = Get.find<GlobalController>();
  bool _loading = false;
  List<Map<String, dynamic>> _members = [];
  late String _groupName;
  String? _groupAvatar;
  String? _groupDescription;
  String? _creatorUserId; // 群主ID
  bool _isDisturb = false; // 免打扰状态

  // 好友分组
  final List<FriendGroup> _groups = [];
  String? _selectedGroupId;  // 选中的分组ID（null表示不选择分组）

  @override
  void initState() {
    super.initState();
    _groupName = widget.groupName;
    _groupAvatar = widget.groupAvatar;
    _loadMembers();
    _loadDisturbStatus();
  }

  Future<void> _loadMembers() async {
    setState(() => _loading = true);
    
    final result = await _groupController.getGroupMembersFullInfo(
      widget.groupId,
      page: 1,
      pageSize: 200,
    );
    
    if (!mounted) return;
    
    if (result['errorCode'] == 0) {
      final members = result['members'] as List<dynamic>? ?? [];
      final creatorUserId = result['creatorUserId'] as String?;
      
      setState(() {
        _members = members.map((e) => (e as Map).cast<String, dynamic>()).toList();
        _creatorUserId = creatorUserId;
      });
    } else {
      EasyLoading.showError(result['message']?.toString() ?? '获取群成员失败');
      setState(() => _members = []);
    }
    
    await _refreshGroupInfo();
    await _refreshGroupPreview();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _refreshGroupInfo() async {
    final res = await _nativeService.imGetGroupInfo(groupId: widget.groupId);
    if (res['errorCode'] == 0) {
      final dataStr = res['data'] as String? ?? '';
      if (dataStr.isNotEmpty) {
        try {
          final map = json.decode(dataStr) as Map<String, dynamic>;
          final groupName = (map['group_name'] as String?) ?? _groupName;
          final groupAvatar = (map['group_avatar'] as String?) ?? _groupAvatar;
          final groupDescription = map['group_description'] as String?;
          final creatorUserId = map['creator_user_id'] as String?;
          setState(() {
            _groupName = groupName;
            _groupAvatar = groupAvatar;
            _groupDescription = groupDescription;
            _creatorUserId = creatorUserId;
          });
        } catch (_) {}
      }
    }
  }

  Future<void> _refreshGroupPreview() async {
    final res = await _nativeService.imGetGroupPreview(groupId: widget.groupId);
    if (res['errorCode'] == 0) {
      final dataStr = res['data'] as String? ?? '';
      if (dataStr.isNotEmpty) {
        try {
          final map = json.decode(dataStr) as Map<String, dynamic>;
          final groupName = (map['group_name'] as String?) ?? _groupName;
          final groupAvatar = (map['group_avatar'] as String?) ?? _groupAvatar;
          final groupDescription = map['group_description'] as String?;
          final creatorUserId = map['creator_user_id'] as String?;
          setState(() {
            _groupName = groupName;
            _groupAvatar = groupAvatar;
            _groupDescription = groupDescription;
            _creatorUserId = creatorUserId;
          });
        } catch (_) {}
      }
    }
  }


  

  /// 加载群组免打扰状态
  Future<void> _loadDisturbStatus() async {
    final result = await _nativeService.imGetGroupDisturbStatus(groupId: widget.groupId);
    if (!mounted) return;
    if (result['errorCode'] == 0) {
      final dataStr = result['data'] as String? ?? '';
      if (dataStr.isNotEmpty) {
        try {
          final map = json.decode(dataStr) as Map<String, dynamic>;
          // 根据返回的数据解析免打扰状态
          // 假设返回格式为 {"disturb": true} 或 {"is_disturb": true}
          final disturb = map['disturb'] as bool? ?? 
                         map['is_disturb'] as bool? ?? 
                         false;
          if (mounted) {
            setState(() {
              _isDisturb = disturb;
            });
          }
        } catch (e) {
          print('解析免打扰状态失败: $e');
        }
      }
    }
  }

  /// 设置群组免打扰
  Future<void> _setGroupDisturb(bool disturb) async {
    EasyLoading.show(status: disturb ? '开启免打扰...' : '关闭免打扰...');
    final result = await _nativeService.imSetGroupDisturb(
      groupId: widget.groupId,
      disturb: disturb,
    );
    if (!mounted) return;
    if (result['errorCode'] == 0) {
      EasyLoading.showSuccess(disturb ? '已开启免打扰' : '已关闭免打扰');
      setState(() {
        _isDisturb = disturb;
      });
    } else {
      EasyLoading.showError(result['message']?.toString() ?? '设置失败');
    }
  }

  @override
  Widget build(BuildContext context) {
    final memberCount = _members.length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('群聊详情'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadMembers,
        child: ListView(
          children: [
            const SizedBox(height: 12),
            _buildGroupHeader(memberCount),
            const SizedBox(height: 8),
            _buildMemberSection(),
            const Divider(height: 24),
            _buildSettingSection(),
            const SizedBox(height: 24),
            _buildDangerZone(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupHeader(int memberCount) {
    final currentUserId = _globalCtrl.currentUser.value?.id ?? '';
    final isOwner = currentUserId.isNotEmpty && 
                    _creatorUserId != null && 
                    currentUserId == _creatorUserId;
    return ListTile(
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.blue.shade50,
            backgroundImage: (_groupAvatar != null && _groupAvatar!.isNotEmpty)
                ? NetworkImage(_groupAvatar!)
                : null,
            child: (_groupAvatar == null || _groupAvatar!.isEmpty)
                ? Text(
                    _groupName.isNotEmpty ? _groupName.characters.first : '#',
                    style: const TextStyle(color: Colors.blue, fontSize: 20, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          if (isOwner) Positioned(
            right: -4,
            bottom: -4,
            child: GestureDetector(
              onTap: _pickAndUpdateAvatar,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.camera_alt, size: 16, color: Colors.blue),
              ),
            ),
          ),
        ],
      ),
      title: Text(
        _groupName,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '群ID: ${widget.groupId}  ·  成员 $memberCount 人',
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
      trailing: isOwner ? IconButton(
        icon: const Icon(Icons.edit),
        onPressed: _editGroupName,
      ) : null,
    );
  }

  Widget _buildMemberSection() {
    if (_loading && _members.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_members.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('暂无群成员')),
      );
    }
    
    final currentUserId = _globalCtrl.currentUser.value?.id ?? '';
    final isOwner = currentUserId.isNotEmpty && 
                    _creatorUserId != null && 
                    currentUserId == _creatorUserId;
    
    // 构建成员列表，如果是群主则在最后添加"添加"按钮
    final List<Widget> memberWidgets = _members.map((m) => _buildMemberItem(m)).toList();
    if (isOwner) {
      memberWidgets.add(_buildAddMemberButton());
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '群成员',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: memberWidgets,
          ),
        ),
      ],
    );
  }

  // 添加好友
  void _addGroupMember(SearchUserModel user){
    showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('提示'),
            content: _buildUserCard(user),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
            ]
          )
        );
  }

  Widget _buildMemberItem(Map<String, dynamic> m) {
    final userId = (m['user_id'] as String?) ?? '';
    final alias = (m['member_alias'] as String?) ?? '';
    final isAdmin = (m['is_admin'] as bool?) ?? false;

    final avatar = (m['avatar'] as String?) ?? '';
    final nickname = (m['nickname'] as String?) ?? '';
    
    final name = alias.isNotEmpty ? alias : userId;
    final initial = name.isNotEmpty ? name.characters.first : '#';
    return GestureDetector(
      onLongPress: () {
        // 长按 如果我是群主、则可以删除群成员 并且我不能删除自己
        final currentUserId = _globalCtrl.currentUser.value?.id ?? '';
        if (currentUserId.isNotEmpty && 
            _creatorUserId != null && 
            currentUserId != userId &&
            currentUserId != _creatorUserId) {
          // 删除群成员
          _showRemoveMemberDialog(userId);
        }

      },
      onTap: () async{
      //如果是我自己。跳转个人中心
      if (userId == _globalCtrl.currentUser.value?.id) {
        Get.toNamed('/profile');
        return;
      } else {
        final result = await _nativeService.imSearchUser(
        userId: userId,
        accountId: userId,
      );

      if (result['errorCode'] == 0) {
        final dataStr = result['data'] as String?;
        if (dataStr != null && dataStr.isNotEmpty) {
          try {
            final data = json.decode(dataStr);
            if (data is Map) {
              // 单个用户
              if (data['user_id'] != null || data['id'] != null) {
                SearchUserModel user = SearchUserModel.fromJson(data.cast<String, dynamic>());
                _addGroupMember(user);
              }
            }
          } catch (e) {
            
          }
        }
      }
      }
    },
    child: SizedBox(
      width: 64,
      child: Column(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.grey.shade200,
            child: avatar.isNotEmpty ? Container(
              width: 44,
              height: 44,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: CachedNetworkImageProvider(avatar),
                  fit: BoxFit.cover,
                ),
              ),child: CachedNetworkImage(imageUrl: avatar, width: 44, height: 44, fit: BoxFit.cover),
            ) : Text(
              nickname.isNotEmpty ? nickname : initial,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            nickname.isNotEmpty ? nickname : name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
          if (isAdmin)
            Text(
              '群主',
              style: TextStyle(fontSize: 10, color: Colors.orange.shade700),
            ),
        ],
      ),
    ),);
  }
  
  Widget _buildAddMemberButton() {
    return SizedBox(
      width: 64,
      child: Column(
        children: [
          GestureDetector(
            onTap: _showAddMemberDialog,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue.shade300, width: 2),
              ),
              child: Icon(
                Icons.add,
                color: Colors.blue.shade700,
                size: 24,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '添加',
            style: TextStyle(fontSize: 12, color: Colors.blue),
          ),
        ],
      ),
    );
  }
  
  Future<void> _showAddMemberDialog() async {
    // 加载联系人列表
    EasyLoading.show(status: '加载联系人...');
    
    try {
      final result = await _nativeService.imGetContactList(
        page: 1,
        pageSize: 200,
      );
      
      if (!mounted) return;
      EasyLoading.dismiss();
      
      if (result['errorCode'] != 0) {
        EasyLoading.showError('获取联系人失败');
        return;
      }
      
      final dataStr = result['data'] as String? ?? '';
      if (dataStr.isEmpty) {
        EasyLoading.showInfo('暂无联系人可添加');
        return;
      }
      
      final map = json.decode(dataStr) as Map<String, dynamic>;
      final contacts = (map['contacts'] as List?) ?? [];
      
      if (contacts.isEmpty) {
        EasyLoading.showInfo('暂无联系人可添加');
        return;
      }
      
      // 过滤掉已经是群成员的联系人
      final memberUserIds = _members.map((m) => (m['user_id'] as String?) ?? '').toSet();
      final availableContacts = contacts.where((contact) {
        final userId = (contact['contact_user_id'] as String?) ?? '';
        return userId.isNotEmpty && !memberUserIds.contains(userId);
      }).toList();
      
      if (availableContacts.isEmpty) {
        EasyLoading.showInfo('所有联系人已在群中');
        return;
      }
      
      // 显示选择对话框
      if (!mounted) return;
      final selectedUserIds = await showDialog<Set<String>>(
        context: context,
        builder: (context) => AddMemberDialog(contacts: availableContacts),
      );
      
      if (selectedUserIds == null || selectedUserIds.isEmpty) {
        return;
      }
      
      // 调用添加群成员接口
      EasyLoading.show(status: '添加群成员...');
      final addResult = await _nativeService.imAddGroupMembers(
        groupId: widget.groupId,
        userIds: selectedUserIds.toList(),
      );
      
      if (!mounted) return;
      
      if (addResult['errorCode'] == 0) {
        EasyLoading.showSuccess('添加成功');
        // 刷新成员列表
        await _loadMembers();
      } else {
        EasyLoading.showError(addResult['message']?.toString() ?? '添加失败');
      }
    } catch (e) {
      if (!mounted) return;
      EasyLoading.dismiss();
      EasyLoading.showError('操作失败: $e');
    }
  }


  // 移除群成员
  Future<void> _showRemoveMemberDialog(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('移除群成员'),
        content: Text('确定要移除群成员吗？'),
        actions: [
          TextButton(onPressed: () {
            Navigator.pop(context, false);

          }, child: const Text('取消')),
          TextButton(onPressed: () {
            Navigator.pop(context, true);

          }, child: const Text('确定')),
        ],
      ),
    );
    if (confirmed != true) return;
      try {
        // 调用添加群成员接口
      EasyLoading.show(status: '移除群成员...');
      final addResult = await _nativeService.imRemoveGroupMembers(
        groupId: widget.groupId,
        userIds: [userId],
      );
      if (addResult['errorCode'] == 0) {
        EasyLoading.showSuccess('移除成功');
        // 刷新成员列表
        await _loadMembers();
      } else {
        EasyLoading.showError(addResult['message']?.toString() ?? '移除失败');
      }
      } catch (e) {
        if (!mounted) return;
        EasyLoading.showError('操作失败: $e');
      }
  }

  Widget _buildSettingSection() {
    return Column(
      children: [
        
        ListTile(
          leading: const Icon(Icons.description_outlined, color: Colors.orange),
          title: const Text('群描述'),
          subtitle: _groupDescription != null && _groupDescription!.isNotEmpty
              ? Text(
                  _groupDescription!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                )
              : const Text(
                  '未设置',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: _editGroupDescription,
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.person_outline, color: Colors.green),
          title: const Text('设置我的群昵称'),
          onTap: _editGroupAlias,
        ),
        const Divider(height: 1),
        SwitchListTile(
          value: _isDisturb,
          onChanged: (v) {
            _setGroupDisturb(v);
          },
          title: const Text('消息免打扰'),
        ),
      ],
    );
  }

  Widget _buildDangerZone() {
    final currentUserId = _globalCtrl.currentUser.value?.id ?? '';
    final isOwner = currentUserId.isNotEmpty && 
                    _creatorUserId != null && 
                    currentUserId == _creatorUserId;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const Divider(height: 1),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
              ),
              onPressed: () => _handleLeaveOrDissolveGroup(isOwner),
              child: Text(
                isOwner ? '解散群聊' : '退出群聊',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _handleLeaveOrDissolveGroup(bool isOwner) async {
    // 确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isOwner ? '解散群聊' : '退出群聊'),
        content: Text(isOwner 
          ? '确定要解散此群聊吗？解散后所有成员将被移除，且无法恢复。'
          : '确定要退出此群聊吗？退出后将无法接收群聊消息。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    EasyLoading.show(status: isOwner ? '解散群聊中...' : '退出群聊中...');
    
    try {
      final result = isOwner
          ? await _nativeService.imDissolveGroup(groupId: widget.groupId)
          : await _nativeService.imLeaveGroup(groupId: widget.groupId);
      
      if (!mounted) return;
      
      if (result['errorCode'] == 0) {
        EasyLoading.showSuccess(isOwner ? '群聊已解散' : '已退出群聊');
        
        // 一次性返回到 GroupListPage 并刷新列表
        // 使用 pushAndRemoveUntil 清除所有路由直到首页，然后推入 GroupListPage
        if (!mounted) return;
        
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const GroupListPage(),
          ),
          (route) => route.isFirst, // 保留首页路由
        );
      } else {
        EasyLoading.showError(result['message']?.toString() ?? '操作失败');
      }
    } catch (e) {
      if (!mounted) return;
      EasyLoading.showError('操作失败: $e');
    }
  }

  Future<void> _editGroupName() async {
    final controller = TextEditingController(text: _groupName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('修改群名称'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: '输入新的群名称'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('保存')),
          ],
        );
      },
    );
    if (newName == null || newName.isEmpty || newName == _groupName) return;
    EasyLoading.show(status: '修改群名称...');
    final res = await _nativeService.imUpdateGroup(
      groupId: widget.groupId,
      groupName: newName,
      version: 1,
    );
    if (!mounted) return;
    if (res['errorCode'] == 0) {
      EasyLoading.showSuccess('修改成功');
      await _refreshGroupInfo();
    } else {
      EasyLoading.showError(res['message']?.toString() ?? '修改失败');
    }
  }


  Future<void> _editGroupDescription() async {
    final controller = TextEditingController(text: _groupDescription ?? '');
    final description = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('修改群描述'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: '请输入群描述',
              border: OutlineInputBorder(),
            ),
            maxLines: 5,
            maxLength: 200,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
    if (description == null) return; // 允许设置为空
    EasyLoading.show(status: '修改群描述...');
    final res = await _nativeService.imUpdateGroup(
      groupId: widget.groupId,
      groupDescription: description.isEmpty ? null : description,
      version: 1,
    );
    if (!mounted) return;
    if (res['errorCode'] == 0) {
      EasyLoading.showSuccess('修改成功');
      await _refreshGroupInfo();
    } else {
      EasyLoading.showError(res['message']?.toString() ?? '修改失败');
    }
  }

  Future<void> _editGroupAlias() async {
    final controller = TextEditingController();
    final alias = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('设置我的群昵称'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: '请输入群昵称'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('保存')),
          ],
        );
      },
    );
    if (alias == null || alias.isEmpty) return;
    EasyLoading.show(status: '设置群昵称...');
    final res = await _nativeService.imSetGroupAlias(
      groupId: widget.groupId,
      alias: alias,
    );
    if (!mounted) return;
    if (res['errorCode'] == 0) {
      EasyLoading.showSuccess('设置成功');
      _loadMembers();
    } else {
      EasyLoading.showError(res['message']?.toString() ?? '设置失败');
    }
  }

  Future<void> _pickAndUpdateAvatar() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
    if (img == null) return;
    
    EasyLoading.show(status: '上传群头像...');
    
    try {
      // 1. 获取文件信息
      final File imageFile = File(img.path);
      final int fileSize = await imageFile.length();
      final String fileName = 'group_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String contentType = 'image/jpeg';
      
      print('📦 文件信息: fileName=$fileName, size=$fileSize');
      
      // 2. 获取上传凭证
      final prepareResult = await _nativeService.imPrepareUpload(
        businessModule: 'group_avatar',
        fileName: fileName,
        fileSize: fileSize,
        contentType: contentType,
      );
      
      print('📋 上传凭证结果: $prepareResult');
      
      final int errorCode = prepareResult['errorCode'] as int? ?? -1;
      if (errorCode != 0) {
        EasyLoading.showError(prepareResult['message'] ?? '获取上传凭证失败');
        return;
      }
      
      // 3. 解析凭证数据
      final String? dataStr = prepareResult['data'] as String?;
      if (dataStr == null || dataStr.isEmpty) {
        EasyLoading.showError('上传凭证数据为空');
        return;
      }
      
      final Map<String, dynamic> tokenData = json.decode(dataStr);
      print('📦 凭证详情: $tokenData');
      
      final String uploadUrl = tokenData['upload_url'] ?? '';
      final String fileUrl = tokenData['file_url'] ?? '';
      final String method = tokenData['method'] ?? 'POST';
      final String objectKey = tokenData['file_path'] ?? '';
      final String uploadMode = tokenData['upload_mode'] ?? '';
      final String providerCode = tokenData['provider_code'] ?? '';
      final Map<String, dynamic> headers = Map<String, dynamic>.from(tokenData['headers'] ?? {});
      final Map<String, dynamic> formData = Map<String, dynamic>.from(tokenData['form_data'] ?? {});
      
      // STS 凭证（腾讯云等）
      final String bucketName = tokenData['bucket_name'] ?? '';
      final String region = tokenData['region'] ?? '';
      final String stsAccessKeyId = tokenData['sts_access_key_id'] ?? '';
      final String stsAccessKeySecret = tokenData['sts_access_key_secret'] ?? '';
      final String stsSecurityToken = tokenData['sts_security_token'] ?? '';
      
      print('📤 开始上传: uploadMode=$uploadMode, provider=$providerCode');
      
      // 4. 上传图片
      bool uploadSuccess = false;
      
      if (uploadMode == 'STS_SDK' && providerCode == 'tencent') {
        // 腾讯云 STS SDK 上传
        uploadSuccess = await _uploadWithTencentSTS(
          localFilePath: imageFile.path,
          objectKey: objectKey,
          bucketName: bucketName,
          region: region,
          secretId: stsAccessKeyId,
          secretKey: stsAccessKeySecret,
          token: stsSecurityToken,
        );
      } else if (uploadUrl.isNotEmpty) {
        // HTTP 上传（PUT 或 POST）
        if (method.toUpperCase() == 'PUT') {
          uploadSuccess = await _uploadWithPut(uploadUrl, imageFile, headers);
        } else {
          uploadSuccess = await _uploadWithPost(uploadUrl, imageFile, objectKey, headers, formData);
        }
      } else {
        EasyLoading.showError('不支持的上传模式: $uploadMode');
        return;
      }
      
      if (!uploadSuccess) {
        EasyLoading.showError('图片上传失败');
        return;
      }
      
      print('✅ 图片上传成功: fileUrl=$fileUrl');
      
      // 5. 更新群头像
      EasyLoading.show(status: '更新群头像...');
      
      final res = await _nativeService.imUpdateGroup(
        groupId: widget.groupId,
        groupAvatar: fileUrl,
        version: 1,
      );
      
      if (!mounted) return;
      
      if (res['errorCode'] == 0) {
        EasyLoading.showSuccess('群头像已更新');
        await _refreshGroupInfo();
      } else {
        EasyLoading.showError(res['message']?.toString() ?? '更新群头像失败');
      }
    } catch (e) {
      print('❌ 上传群头像异常: $e');
      EasyLoading.showError('上传失败: $e');
    } finally {
      EasyLoading.dismiss();
    }
  }

  /// PUT 方式上传
  Future<bool> _uploadWithPut(String url, File file, Map<String, dynamic> headers) async {
    try {
      final bytes = await file.readAsBytes();
      
      final response = await http.put(
        Uri.parse(url),
        headers: headers.map((k, v) => MapEntry(k, v.toString())),
        body: bytes,
      );
      
      print('📤 PUT 上传响应: ${response.statusCode}');
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('❌ PUT 上传失败: $e');
      return false;
    }
  }

  /// POST 表单方式上传
  Future<bool> _uploadWithPost(
    String url, 
    File file, 
    String filePath,
    Map<String, dynamic> headers, 
    Map<String, dynamic> formData,
  ) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));
      
      // 添加表单字段
      formData.forEach((key, value) {
        request.fields[key] = value.toString();
      });
      
      // 添加文件
      final fileName = filePath.isNotEmpty ? filePath.split('/').last : 'file';
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename: fileName,
      ));
      
      // 添加 headers
      headers.forEach((key, value) {
        request.headers[key] = value.toString();
      });
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('📤 POST 上传响应: ${response.statusCode}');
      print('📤 响应内容: ${response.body}');
      
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('❌ POST 上传失败: $e');
      return false;
    }
  }

  /// 腾讯云 STS SDK 上传
  Future<bool> _uploadWithTencentSTS({
    required String localFilePath,
    required String objectKey,
    required String bucketName,
    required String region,
    required String secretId,
    required String secretKey,
    required String token,
  }) async {
    try {
      print('📤 腾讯云 STS 上传开始...');
      print('  - localFilePath: $localFilePath');
      print('  - objectKey: $objectKey');
      print('  - bucket: $bucketName');
      print('  - region: $region');
      
      final result = await _nativeService.imUploadWithTencentSTS(
        localFilePath: localFilePath,
        objectKey: objectKey,
        bucketName: bucketName,
        region: region,
        secretId: secretId,
        secretKey: secretKey,
        token: token,
      );
      
      final bool success = result['success'] == true;
      if (success) {
        print('✅ 腾讯云上传成功: ${result['url']}');
      } else {
        print('❌ 腾讯云上传失败: ${result['error']}');
      }
      
      return success;
    } catch (e) {
      print('❌ 腾讯云 STS 上传异常: $e');
      return false;
    }
  }


  /// 用户卡片
  Widget _buildUserCard(SearchUserModel user) {
    return Container(
      height: 88,
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


  /// 发送好友申请
  Future<void> _sendFriendRequest(SearchUserModel user, String message, {int? groupId}) async {
    EasyLoading.show(status: '发送中...');
    
    try {
      // 确定添加渠道
      int channel = 0;  // 默认用户ID
      String? targetValue = user.id;
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
        GroupController.to.getGroupMembersFullInfo(widget.groupId, forceRefresh: true);
        Get.back();
      } else {
        EasyLoading.showError(result['message'] ?? '发送失败');
      }
    } catch (e) {
      print('❌ 发送好友申请失败: $e');
      EasyLoading.showError('发送失败');
    }
  }

}
