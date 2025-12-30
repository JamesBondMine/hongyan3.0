import 'dart:convert';
import 'package:bell_bird_talk/controllers/chat_controller.dart';
import 'package:bell_bird_talk/pages/models/friend_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../../controllers/global_controller.dart';
import '../../../services/native_bridge.dart';
import '../../../services/message_database.dart';
import '../../chat/chat_page.dart';
import '../../chat/models/chat_model.dart';

/// 好友详情页面
class FriendDetailPageOld extends StatefulWidget {
  final FriendModel friend;
  VoidCallback onDelete;
  
  FriendDetailPageOld({
    super.key,
    required this.friend,
    required this.onDelete,
  });

  @override
  State<FriendDetailPageOld> createState() => _FriendDetailPageOldState();
}

class _FriendDetailPageOldState extends State<FriendDetailPageOld> {
  final IOSNativeService _nativeService = IOSNativeService();
  final MessageDatabase _messageDatabase = MessageDatabase();
  final GlobalController _globalCtrl = Get.find<GlobalController>();
  
  late FriendModel _friend;
  bool _isStarred = false;
  bool _hasChanges = false;  // 标记是否有修改（用于刷新列表）
  bool? _isBlocked;  // 黑名单状态（null=未查询，true=已拉黑，false=未拉黑）
  
  /// 清理UTF-16字符串，移除无效字符
  String _cleanUtf16String(String? input) {
    if (input == null || input.isEmpty) return '';
    
    try {
      // 尝试将字符串转换为UTF-16并验证
      final bytes = utf8.encode(input);
      final decoded = utf8.decode(bytes, allowMalformed: false);
      return decoded;
    } catch (e) {
      // 如果解码失败，移除无效字符
      try {
        final runes = input.runes.toList();
        final validRunes = <int>[];
        
        for (final rune in runes) {
          // 检查是否为有效的Unicode码点
          if (rune >= 0 && rune <= 0x10FFFF && 
              !(rune >= 0xD800 && rune <= 0xDFFF)) { // 排除代理对
            validRunes.add(rune);
          }
        }
        
        return String.fromCharCodes(validRunes);
      } catch (e) {
        // 如果还是失败，返回安全的默认值
        return '无效文本';
      }
    }
  }
  
  @override
  void initState() {
    super.initState();
    _friend = widget.friend;
    _loadUserInfo();
    _loadBlackStatus();
  }
  
  /// 加载用户信息
  Future<void> _loadUserInfo() async {
    try {
      final result = await _nativeService.imGetUsersInfo(userIds: [widget.friend.id]);
      if (!mounted) return;
      
      if (result['errorCode'] == 0) {
        final dataStr = result['data'] as String? ?? '';
        if (dataStr.isNotEmpty) {
          try {
            final users = json.decode(dataStr) as List;
            if (users.isNotEmpty) {
              final userInfo = users[0] as Map<String, dynamic>;
              
              // 更新好友信息
              setState(() {
                String? newAvatar = _friend.avatar;
                String newNickname = _friend.nickname;
                
                // 更新头像
                if (userInfo['avatar'] != null && (userInfo['avatar'] as String).isNotEmpty) {
                  newAvatar = userInfo['avatar'] as String;
                }
                // 更新昵称
                if (userInfo['nickname'] != null && (userInfo['nickname'] as String).isNotEmpty) {
                  newNickname = userInfo['nickname'] as String;
                }
                
                // 使用 copyWith 更新
                _friend = _friend.copyWith(
                  avatar: newAvatar,
                  nickname: newNickname,
                );
                _hasChanges = true;
              });
            }
          } catch (e) {
            print('解析用户信息失败: $e');
          }
        }
      }
    } catch (e) {
      print('获取用户信息失败: $e');
    }
  }
  
  /// 加载黑名单状态
  Future<void> _loadBlackStatus() async {
    try {
      final result = await _nativeService.imGetBlackStatus(userId: widget.friend.id);
      if (!mounted) return;
      
      if (result['errorCode'] == 0) {
        final dataStr = result['data'] as String? ?? '';
        if (dataStr.isNotEmpty) {
          try {
            final data = json.decode(dataStr) as Map<String, dynamic>;
            final isBlocked = data['is_blocked'] as bool? ?? false;
            setState(() {
              _isBlocked = isBlocked;
            });
          } catch (e) {
            print('解析黑名单状态失败: $e');
          }
        }
      }
    } catch (e) {
      print('获取黑名单状态失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Get.back(result: _hasChanges);  // 返回是否有修改
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text('好友详情'),
          centerTitle: true,
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Get.back(result: _hasChanges),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_horiz),
              onPressed: _showMoreOptions,
            ),
          ],
        ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 头部信息卡片
            _buildHeaderCard(),
            
            const SizedBox(height: 12),
            
            // 快捷操作
            _buildQuickActions(),
          ],
        ),
      ),
      ),  // 关闭 Scaffold
    );  // 关闭 PopScope
  }
  
  /// 头部信息卡片
  Widget _buildHeaderCard() {
    return Container(
      color: Colors.blue,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 24),
            
            // 头像
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blue[100],
                  backgroundImage: (_friend.avatar != null && _friend.avatar!.isNotEmpty)
                      ? NetworkImage(_friend.avatar!)
                      : null,
                  child: (_friend.avatar == null || _friend.avatar!.isEmpty)
                      ? Text(
                          _cleanUtf16String(_friend.displayName).isNotEmpty
                              ? _cleanUtf16String(_friend.displayName)[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        )
                      : null,
                ),
                // 在线状态
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _friend.isOnline ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 昵称/备注
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _cleanUtf16String(_friend.displayName),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isStarred) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.star, color: Colors.amber, size: 24),
                ],
              ],
            ),
            
            // 如果有备注，显示原昵称
            if (_friend.remark != null && 
                _friend.remark!.isNotEmpty && 
                _friend.remark != _friend.nickname)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '昵称: ${_cleanUtf16String(_friend.nickname)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
            
            const SizedBox(height: 8),
            
            // 在线状态
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _friend.isOnline 
                        ? Colors.green.withOpacity(0.1) 
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _friend.isOnline ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _friend.isOnline ? '在线' : '离线',
                        style: TextStyle(
                          color: _friend.isOnline ? Colors.green : Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
  
  /// 快捷操作按钮
  Widget _buildQuickActions() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionItem(
            icon: Icons.chat_bubble,
            label: '发消息',
            color: Colors.blue,
            onTap: _startChat,
          ),
          _buildActionItem(
            icon: Icons.videocam,
            label: '视频',
            color: Colors.green,
            onTap: () {
              EasyLoading.showInfo('视频通话开发中');
            },
          ),
          _buildActionItem(
            icon: Icons.phone,
            label: '语音',
            color: Colors.orange,
            onTap: () {
              EasyLoading.showInfo('语音通话开发中');
            },
          ),
          _buildActionItem(
            icon: Icons.share,
            label: '分享',
            color: Colors.purple,
            onTap: () {
              EasyLoading.showInfo('分享名片开发中');
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 详细信息
  Widget _buildDetailInfo() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '详细信息',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          
          // 用户ID
          if (_friend.accountId != null && _friend.accountId!.isNotEmpty)
            _buildInfoRow(
              icon: Icons.badge_outlined,
              label: '账号ID',
              value: _cleanUtf16String(_friend.accountId!),
              canCopy: true,
            ),
          
          // 用户唯一ID
          _buildInfoRow(
            icon: Icons.fingerprint,
            label: '用户ID',
            value: _cleanUtf16String(_friend.id),
            canCopy: true,
          ),
          
          // 备注
          _buildInfoRow(
            icon: Icons.edit_note,
            label: '备注',
            value: _cleanUtf16String(_friend.remark) ?? '未设置',
            onTap: () => _showSetRemarkDialog(),
          ),
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool canCopy = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap ?? (canCopy ? () => _copyToClipboard(value) : null),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[500], size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                ),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (canCopy) ...[
              const SizedBox(width: 8),
              Icon(Icons.copy, color: Colors.grey[400], size: 18),
            ],
            if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
            ],
          ],
        ),
      ),
    );
  }
  
  /// 发起聊天
  Future<void> _startChat() async {
    try {
      // 获取当前用户ID
      final currentUserId = _globalCtrl.currentUser.value?.id ?? '';
      if (currentUserId.isEmpty) {
        EasyLoading.showError('用户未登录');
        return;
      }
      
      // 1. 先查询本地数据库，看是否已有该好友的单聊会话
      final existingConv = await _messageDatabase.getConversationByTargetId(
        currentUserId,
        _friend.id,
        1, // convType: 1 = 单聊
      );
      
      if (existingConv != null) {
        // 如果本地已有会话，直接跳转
        print('📱 使用本地会话: ${existingConv.convId}');
        Get.to(() => ChatPage(
          convId: existingConv.convId,
          displayName: existingConv.displayName,
          avatar: existingConv.avatar,
          targetUserId: _friend.id,
        ))?.then(  (_) {
            // 返回后清除该会话的未读数
            ChatController.to.conversationId = "";
          });

        return;
      }
      
      // 2. 本地没有会话，调用 SDK 创建会话
      EasyLoading.show(status: '创建会话中...');
      
      final result = await _nativeService.imCreateConversation(
        convType: 1,  // 单聊
        targetId: _friend.id,
        displayName: _cleanUtf16String(_friend.displayName),
        avatarUrl: _friend.avatar,
      );
      
      EasyLoading.dismiss();
      
      print('📱 创建会话结果: $result');
      
      if (result['errorCode'] == 0) {
        // 解析返回的会话数据
        String convId = '';
        Map<String, dynamic>? convData;
        
        final dataStr = result['data'] as String?;
        if (dataStr != null && dataStr.isNotEmpty) {
          try {
            convData = json.decode(dataStr) as Map<String, dynamic>;
            convId = convData['conv_id']?.toString() ?? '';
          } catch (e) {
            print('⚠️ 解析会话数据失败: $e');
          }
        }
        
        // 如果没有获取到会话ID，使用默认格式
        if (convId.isEmpty) {
          convId = 'single_${_friend.id}';
        }
        
        // 3. 保存会话到本地数据库
        if (convData != null) {
          try {
            final conversation = ConversationModel.fromJson(convData);
            await _messageDatabase.upsertConversation(currentUserId, conversation);
            print('✅ 会话已保存到本地数据库: $convId');
          } catch (e) {
            print('⚠️ 保存会话到数据库失败: $e');
            // 即使保存失败，也继续跳转
          }
        } else {
          // 如果没有返回完整数据，创建一个基本的会话对象保存
          try {
            final conversation = ConversationModel(
              convId: convId,
              convType: 1,
              targetId: _friend.id,
              displayName: _cleanUtf16String(_friend.displayName),
              avatar: _friend.avatar,
            );
            await _messageDatabase.upsertConversation(currentUserId, conversation);
            print('✅ 会话已保存到本地数据库: $convId');
          } catch (e) {
            print('⚠️ 保存会话到数据库失败: $e');
          }
        }
        
        // 4. 跳转到聊天页面
        Get.to(() => ChatPage(
          convId: convId,
          displayName: _friend.displayName,
          avatar: _friend.avatar,
          targetUserId: _friend.id,
        ))?.then(  (_) {
            // 返回后清除该会话的未读数
            ChatController.to.conversationId = "";
          });
      } else {
        final message = result['message'] ?? '创建会话失败';
        EasyLoading.showError(message);
      }
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError('创建会话异常: $e');
      print('❌ 创建会话异常: $e');
    }
  }
  
  /// 显示更多选项
  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.report_outlined, color: Colors.orange),
                title: const Text('举报'),
                onTap: () {
                  Get.back();
                  EasyLoading.showInfo('举报功能开发中');
                },
              ),
              ListTile(
                leading: const Icon(Icons.qr_code, color: Colors.blue),
                title: const Text('分享名片'),
                onTap: () {
                  Get.back();
                  EasyLoading.showInfo('分享名片开发中');
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                title: const Text('取消', textAlign: TextAlign.center),
                onTap: () => Get.back(),
              ),
            ],
          ),
        );
      },
    );
  }
  
  /// 复制到剪贴板
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    EasyLoading.showSuccess('已复制');
  }
  
  /// 设置备注对话框
  void _showSetRemarkDialog() {
    final controller = TextEditingController(text: _friend.remark);
    
    Get.dialog(
      AlertDialog(
        title: const Text('设置备注'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '请输入备注名',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final newRemark = controller.text.trim();
              Get.back();
              
              // 调用设置备注接口
              EasyLoading.show(status: '设置中...');
              final result = await _nativeService.imSetContactRemark(
                userId: _friend.userId,
                remark: newRemark,
              );
              EasyLoading.dismiss();
              
              if (result['errorCode'] == 0) {
                setState(() {
                  _friend = _friend.copyWith(remark: newRemark);
                  _hasChanges = true;  // 标记有修改
                });
                // 触发好友列表和聊天列表刷新
                Get.find<GlobalController>().triggerAllListRefresh();
                EasyLoading.showSuccess('备注设置成功');
              } else {
                EasyLoading.showError(result['message'] ?? '设置备注失败');
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
  
  /// 确认拉黑/取消拉黑好友
  void _confirmBlockFriend() {
    // 优先使用查询到的黑名单状态，如果没有查询到则使用 relationship
    final bool isBlocked = _isBlocked ?? (_friend.relationship == 3);
    final String title = isBlocked ? '取消黑名单' : '加入黑名单';
    final String content = isBlocked
        ? '确定要将「${_cleanUtf16String(_friend.displayName)}」移出黑名单吗？\n\n移出后，对方可以再次向你发送消息。'
        : '确定要将「${_cleanUtf16String(_friend.displayName)}」加入黑名单吗？\n\n加入黑名单后，对方将无法给你发送消息。';

    Get.dialog(
      AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              EasyLoading.show(status: '处理中...');
              
              try {
                final result = isBlocked
                    ? await _nativeService.imUnblockContact(userId: _friend.id)
                    : await _nativeService.imBlockContact(userId: _friend.id);
                
                if (result['errorCode'] == 0) {
                  EasyLoading.showSuccess(isBlocked ? '已取消黑名单' : '已加入黑名单');
                  setState(() {
                    _isBlocked = !isBlocked;  // 更新黑名单状态
                    _friend = _friend.copyWith(relationship: isBlocked ? 1 : 3);
                    _hasChanges = true;
                  });
                  // 触发全局列表刷新（好友列表、会话列表等）
                  Get.find<GlobalController>().triggerAllListRefresh();
                  // 返回并刷新
                  Get.back(result: true);
                } else {
                  EasyLoading.showError(result['message'] ?? '操作失败');
                }
              } catch (e) {
                EasyLoading.showError('操作失败');
              }
            },
            child: Text(isBlocked ? '确定' : '确定', style: const TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }
  
  /// 确认删除好友
  void _confirmDeleteFriend() {
    Get.dialog(
      AlertDialog(
        title: const Text('删除好友'),
        content: Text('确定要删除好友「${_cleanUtf16String(_friend.displayName)}」吗？\n\n删除后，聊天记录将被清空，且需要重新添加才能继续聊天。'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              EasyLoading.show(status: '删除中...');
              
              try {
                final result = await _nativeService.imDeleteContact(contact_user_id: _friend.id);
                
                if (result['errorCode'] == 0) {
                  EasyLoading.showSuccess('已删除好友');
                  widget.onDelete();
                  Get.back(result: true);  // 返回并刷新列表
                } else {
                  EasyLoading.showError(result['message'] ?? '删除失败');
                }
              } catch (e) {
                EasyLoading.showError('删除失败');
              }
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

