import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import '../../services/native_bridge.dart';
import '../../models/user_model.dart';
import 'chat_page.dart';
import '../friends/friend_detail_page.dart';
import '../models/friend_model.dart';

/// 用户信息页面（用于显示非好友的用户信息）
class UserInfoPage extends StatefulWidget {
  final String userId;
  final String? displayName;
  final String? avatar;
  
  const UserInfoPage({
    super.key,
    required this.userId,
    this.displayName,
    this.avatar,
  });

  @override
  State<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  final IOSNativeService _nativeService = IOSNativeService();
  
  UserModel? _userInfo;
  bool _isLoading = true;
  bool _isFriend = false;
  FriendModel? _friendInfo;
  
  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _checkFriendStatus();
  }
  
  /// 加载用户信息
  Future<void> _loadUserInfo() async {
    setState(() => _isLoading = true);
    
    try {
      // 使用 imSearchUser 获取用户信息
      final result = await _nativeService.imSearchUser(
        userId: widget.userId,
      );
      
      print('📊 获取用户信息结果: $result');
      
      if (result['errorCode'] == 0) {
        final dataStr = result['data'] as String?;
        if (dataStr != null && dataStr.isNotEmpty) {
          try {
            final data = json.decode(dataStr);
            setState(() {
              if (data is Map) {
                _userInfo = UserModel.fromJson(data.cast<String, dynamic>());
              } else if (data is List && data.isNotEmpty) {
                _userInfo = UserModel.fromJson(data[0] as Map<String, dynamic>);
              }
            });
          } catch (e) {
            print('❌ 解析用户信息失败: $e');
          }
        }
      } else {
        EasyLoading.showError(result['message'] ?? '获取用户信息失败');
      }
    } catch (e) {
      print('❌ 获取用户信息异常: $e');
      EasyLoading.showError('获取用户信息失败');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  /// 检查是否是好友
  Future<void> _checkFriendStatus() async {
    try {
      // 获取好友列表，检查是否包含该用户
      final result = await _nativeService.imGetContactList(
        page: 1,
        pageSize: 1000, // 获取足够多的好友来检查
        relationship: 0, // 只获取好友关系
      );
      
      if (result['errorCode'] == 0) {
        final dataStr = result['data'] as String?;
        if (dataStr != null && dataStr.isNotEmpty) {
          try {
            final data = json.decode(dataStr);
            final contacts = data['contacts'] as List? ?? [];
            
            // 查找是否是该用户的好友
            for (final contact in contacts) {
              final contactUserId = contact['contact_user_id']?.toString() ?? '';
              if (contactUserId == widget.userId) {
                setState(() {
                  _isFriend = true;
                  _friendInfo = FriendModel.fromJson(contact);
                });
                break;
              }
            }
          } catch (e) {
            print('❌ 解析好友列表失败: $e');
          }
        }
      }
    } catch (e) {
      print('❌ 检查好友状态失败: $e');
    }
  }
  
  /// 跳转到好友详情页面
  void _navigateToFriendDetail() {
    if (_friendInfo != null) {
      Get.to(() => FriendDetailPage(
        friend: _friendInfo!,
        onDelete: () {
          // 删除好友后返回
          Get.back();
        },
      ));
    }
  }
  
  /// 发送好友申请
  Future<void> _sendFriendRequest() async {
    if (_userInfo == null) return;
    
    final messageController = TextEditingController(text: '你好，我想加你为好友');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    backgroundImage: (_userInfo!.avatar != null && _userInfo!.avatar!.isNotEmpty)
                        ? NetworkImage(_userInfo!.avatar!)
                        : null,
                    child: (_userInfo!.avatar == null || _userInfo!.avatar!.isEmpty)
                        ? Text(
                            _userInfo!.nickname.isNotEmpty
                                ? _userInfo!.nickname[0].toUpperCase()
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
                          _userInfo!.nickname,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_userInfo!.username.isNotEmpty)
                          Text(
                            'ID: ${_userInfo!.username}',
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
                  onPressed: () async {
                    Navigator.pop(context);
                    EasyLoading.show(status: '发送中...');
                    
                    try {
                      final result = await _nativeService.imAddContact(
                        targetUserId: _userInfo!.id,
                        channel: 0, // 用户ID
                        message: messageController.text.trim().isNotEmpty 
                            ? messageController.text.trim() 
                            : null,
                        targetValue: _userInfo!.id,
                        targetPhone: _userInfo!.phone,
                        targetEmail: _userInfo!.email,
                      );
                      
                      if (result['errorCode'] == 0) {
                        EasyLoading.showSuccess('申请已发送');
                        // 重新检查好友状态
                        await _checkFriendStatus();
                        setState(() {});
                      } else {
                        EasyLoading.showError(result['message'] ?? '发送失败');
                      }
                    } catch (e) {
                      print('❌ 发送好友申请失败: $e');
                      EasyLoading.showError('发送失败');
                    }
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
    );
  }
  
  /// 发起聊天
  Future<void> _startChat() async {
    try {
      final displayName = _userInfo?.nickname ?? widget.displayName ?? '用户';
      final avatar = _userInfo?.avatar ?? widget.avatar;
      
      // 调用 SDK 创建会话
      final result = await _nativeService.imCreateConversation(
        convType: 0,  // 单聊
        targetId: widget.userId,
        displayName: displayName,
        avatarUrl: avatar,
      );
      
      print('📱 创建会话结果: $result');
      
      if (result['errorCode'] == 0) {
        String convId = '';
        
        final dataStr = result['data'] as String?;
        if (dataStr != null && dataStr.isNotEmpty) {
          try {
            final data = json.decode(dataStr);
            convId = data['conv_id']?.toString() ?? '';
          } catch (e) {
            print('⚠️ 解析会话数据失败: $e');
          }
        }
        
        if (convId.isEmpty) {
          convId = 'single_${widget.userId}';
        }
        
        // 跳转到聊天页面
        Get.to(() => ChatPage(
          convId: convId,
          displayName: displayName,
          avatar: avatar,
          targetUserId: widget.userId,
        ));
      } else {
        final message = result['message'] ?? '创建会话失败';
        EasyLoading.showError(message);
      }
    } catch (e) {
      EasyLoading.showError('创建会话异常: $e');
      print('❌ 创建会话异常: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final displayName = _userInfo?.nickname ?? widget.displayName ?? '用户';
    final avatar = _userInfo?.avatar ?? widget.avatar;
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('用户信息'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // 头部信息卡片
                  _buildHeaderCard(displayName, avatar),
                  
                  const SizedBox(height: 12),
                  
                  // 快捷操作
                  _buildQuickActions(),
                  
                  const SizedBox(height: 12),
                  
                  // 详细信息
                  if (_userInfo != null) _buildDetailInfo(),
                  
                  const SizedBox(height: 12),
                  
                  // 操作按钮
                  _buildActionButtons(),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
  
  /// 头部信息卡片
  Widget _buildHeaderCard(String displayName, String? avatar) {
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
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue[100],
              backgroundImage: (avatar != null && avatar.isNotEmpty)
                  ? NetworkImage(avatar)
                  : null,
              child: (avatar == null || avatar.isEmpty)
                  ? Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    )
                  : null,
            ),
            
            const SizedBox(height: 16),
            
            // 昵称
            Text(
              displayName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
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
    if (_userInfo == null) return const SizedBox.shrink();
    
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
          if (_userInfo!.username.isNotEmpty)
            _buildInfoRow(
              icon: Icons.badge_outlined,
              label: '账号ID',
              value: _userInfo!.username,
              canCopy: true,
            ),
          
          // 用户唯一ID
          _buildInfoRow(
            icon: Icons.fingerprint,
            label: '用户ID',
            value: _userInfo!.id,
            canCopy: true,
          ),
          
          // 性别
          if (_userInfo!.gender != null)
            _buildInfoRow(
              icon: Icons.person_outline,
              label: '性别',
              value: _userInfo!.genderText,
            ),
          
          // 手机号
          if (_userInfo!.phone != null && _userInfo!.phone!.isNotEmpty)
            _buildInfoRow(
              icon: Icons.phone_outlined,
              label: '手机号',
              value: _userInfo!.phone!,
              canCopy: true,
            ),
          
          // 邮箱
          if (_userInfo!.email != null && _userInfo!.email!.isNotEmpty)
            _buildInfoRow(
              icon: Icons.email_outlined,
              label: '邮箱',
              value: _userInfo!.email!,
              canCopy: true,
            ),
          
          // 个性签名
          if (_userInfo!.signature != null && _userInfo!.signature!.isNotEmpty)
            _buildInfoRow(
              icon: Icons.edit_note,
              label: '个性签名',
              value: _userInfo!.signature!,
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
  }) {
    return InkWell(
      onTap: canCopy ? () => _copyToClipboard(value) : null,
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (canCopy) ...[
              const SizedBox(width: 8),
              Icon(Icons.copy, color: Colors.grey[400], size: 18),
            ],
          ],
        ),
      ),
    );
  }
  
  /// 操作按钮
  Widget _buildActionButtons() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_isFriend) ...[
            // 如果是好友，显示"查看好友详情"按钮
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _navigateToFriendDetail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '查看好友详情',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ] else ...[
            // 如果不是好友，显示"加好友"按钮
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _sendFriendRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '加好友',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  /// 复制到剪贴板
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    EasyLoading.showSuccess('已复制');
  }
}

