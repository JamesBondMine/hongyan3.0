import 'dart:convert';
import 'package:bell_bird_talk/config/global.dart';
import 'package:bell_bird_talk/controllers/chat_controller.dart';
import 'package:bell_bird_talk/pages/friends/views/friend_remark_view.dart';
import 'package:bell_bird_talk/pages/friends/views/group_move_view.dart';
import 'package:bell_bird_talk/pages/models/friend_model.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:bell_bird_talk/widgets/common_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_popup/flutter_popup.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../../controllers/global_controller.dart';
import '../../../controllers/friend_controller.dart';
import '../../../services/native_bridge.dart';
import '../../../services/message_database.dart';
import '../../chat/chat_page.dart';
import '../../chat/models/chat_model.dart';

/// 好友详情页面
class FriendDetailPage extends StatefulWidget {
  final FriendModel friend;
  VoidCallback onDelete;

  FriendDetailPage({super.key, required this.friend, required this.onDelete});

  @override
  State<FriendDetailPage> createState() => _FriendDetailPageState();
}

class _FriendDetailPageState extends State<FriendDetailPage> {
  final IOSNativeService _nativeService = IOSNativeService();
  final MessageDatabase _messageDatabase = MessageDatabase();
  final GlobalController _globalCtrl = Get.find<GlobalController>();
  final FriendController _friendController = FriendController.to;

  late FriendModel _friend;
  bool _isStarred = false;
  bool _hasChanges = false; // 标记是否有修改（用于刷新列表）
  bool? _isBlocked; // 黑名单状态（null=未查询，true=已拉黑，false=未拉黑）

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Get.back(result: _hasChanges); // 返回是否有修改
      },
      child: Scaffold(
        backgroundColor: GbsColors.lightAppBarColorB,
        appBar: AppBar(
          title: const Text(
            '好友详情',
            style: TextStyle(
              color: GbsColors.des1Color,
              fontSize: 16.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          centerTitle: true,
          backgroundColor: GbsColors.lightAppBarColorB,
          foregroundColor: GbsColors.lightAppBarColorB,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: GbsColors.titleColor),
            onPressed: () => Get.back(result: _hasChanges),
          ),
          actions: [
            CustomPopup(
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: _buildAppBarActions(),
              ),
              child: Image.asset(
                'assets/img/msg/msgmore.png',
                width: 20,
                height: 20,
              ),
            ),
            SizedBox(width: 16),
          ],
        ),
        body: Column(
          children: [
            // 头部信息卡片
            _buildHeaderCard(),

            const SizedBox(height: 12),

            Padding(
              padding: EdgeInsetsGeometry.symmetric(horizontal: 16),
              child: CommonButton(
                enabled: true,
                onPressed: () {
                  _startChat();
                },
                text: '发消息',
              ),
            ),
          ],
        ),
      ), // 关闭 Scaffold
    ); // 关闭 PopScope
  }

  Widget _buildPopItem(String title, String icon, VoidCallback onTap) {
    return GestureDetector(
      child: Container(
        width: 120,
        alignment: Alignment.center,
        margin: EdgeInsets.only(left: 10),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset('assets/img//friend/$icon.png', width: 20, height: 20),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
      ),
      onTap: () {
        Navigator.pop(context); // 先关闭弹出菜单
        onTap();
      },
    );
  }

  List<Widget> _buildAppBarActions() {
    return _isBlocked == null
        ? [
            _buildPopItem('备注', 'edit', () {
              _showSetRemarkDialog();
            }),
            _buildPopItem('调整分组', 'move', () {
              _showMoveGroupDialog();
            }),
            _buildPopItem('屏蔽消息', 'notifi', () {
              // 拉黑
              _confirmBlockFriend();
            }),
            _buildPopItem('删除好友', 'del', () {
              _confirmDeleteFriend();
            }),
          ]
        : [
            _buildPopItem('备注', 'edit', () {
              _showSetRemarkDialog();
            }),
            _buildPopItem('调整分组', 'move', () {
              _showMoveGroupDialog();
            }),
            _buildPopItem('屏蔽消息', 'notifi', () {
              // 拉黑
              _confirmBlockFriend();
            }),
            _buildPopItem(_isBlocked! ? '取消黑名单' : '加黑名单', 'notifi', () {
              _confirmBlockFriend();
            }),
            _buildPopItem('删除好友', 'del', () {
              _confirmDeleteFriend();
            }),
          ];
  }

  // 调整分组
  void _showMoveGroupDialog() async {
    gbs.shower.showScreenViewCustom(
      context,
      400,
      Container(
        width: Get.width,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: GbsColors.lightBackgroundB,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: GroupMoveView(
          contactUserId: _friend.userId,
          onItemClick: (value) {},
        ),
      ),
    );
  }

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
          if (rune >= 0 &&
              rune <= 0x10FFFF &&
              !(rune >= 0xD800 && rune <= 0xDFFF)) {
            // 排除代理对
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
      final result = await _nativeService.imGetUsersInfo(
        userIds: [widget.friend.id],
      );
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
                if (userInfo['avatar'] != null &&
                    (userInfo['avatar'] as String).isNotEmpty) {
                  newAvatar = userInfo['avatar'] as String;
                }
                // 更新昵称
                if (userInfo['nickname'] != null &&
                    (userInfo['nickname'] as String).isNotEmpty) {
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
      bool? result = await FriendController.to.loadBlackStatus(
         widget.friend.id,
      );
      if (result != null) {
        _isBlocked = result;
        
      }
      if (!mounted) return;

      setState(() {
            });
    } catch (e) {
      print('获取黑名单状态失败: $e');
    }
  }

  /// 头部信息卡片
  Widget _buildHeaderCard() {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 30),
      padding: EdgeInsets.only(left: 16),
      height: 92,
      alignment: Alignment.centerLeft,
      decoration: const BoxDecoration(
        color: GbsColors.lightAppBarColorA,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            margin: EdgeInsets.only(right: 10),
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(shape: BoxShape.circle),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue[100],
              backgroundImage:
                  (_friend.avatar != null && _friend.avatar!.isNotEmpty)
                  ? NetworkImage(_friend.avatar!)
                  : null,
              child: (_friend.avatar == null || _friend.avatar!.isEmpty)
                  ? Text(
                      _cleanUtf16String(_friend.displayName).isNotEmpty
                          ? _cleanUtf16String(
                              _friend.displayName,
                            )[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    )
                  : null,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _cleanUtf16String(_friend.displayName),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: GbsColors.titleColor,
                ),
              ),

              // 如果有备注，显示原昵称
              if (_friend.remark != null &&
                  _friend.remark!.isNotEmpty &&
                  _friend.remark != _friend.nickname)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '昵称: ${_cleanUtf16String(_friend.nickname)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '用户名: ${_cleanUtf16String(_friend.userId)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ),
            ],
          ),
        ],
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
        Get.to(
          () => ChatPage(
            convId: existingConv.convId,
            displayName: existingConv.displayName,
            avatar: existingConv.avatar,
            targetUserId: _friend.id,
          ),
        )?.then((_) {
          // 返回后清除该会话的未读数
          ChatController.to.conversationId = "";
        });

        return;
      }

      // 2. 本地没有会话，调用 SDK 创建会话
      EasyLoading.show(status: '创建会话中...');

      final result = await _nativeService.imCreateConversation(
        convType: 1, // 单聊
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
            await _messageDatabase.upsertConversation(
              currentUserId,
              conversation,
            );
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
            await _messageDatabase.upsertConversation(
              currentUserId,
              conversation,
            );
            print('✅ 会话已保存到本地数据库: $convId');
          } catch (e) {
            print('⚠️ 保存会话到数据库失败: $e');
          }
        }

        // 4. 跳转到聊天页面
        Get.to(
          () => ChatPage(
            convId: convId,
            displayName: _friend.displayName,
            avatar: _friend.avatar,
            targetUserId: _friend.id,
          ),
        )?.then((_) {
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

  /// 设置备注对话框
  void _showSetRemarkDialog() {
    final controller = TextEditingController(text: _friend.remark);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: FriendRemarkView(
            controller: controller,
            onTap: () async {
              final newRemark = controller.text.trim();
              Navigator.pop(context);

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
                  _hasChanges = true; // 标记有修改
                });
                // 触发好友列表和聊天列表刷新
                Get.find<GlobalController>().triggerAllListRefresh();
                EasyLoading.showSuccess('备注设置成功');
              } else {
                EasyLoading.showError(result['message'] ?? '设置备注失败');
              }
            },
          ),
        );
      },
    ).then((_) {
      // 确保资源被释放
      // controller.dispose();
      // focusNode.dispose();
    });
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
          TextButton(onPressed: () => Get.back(), child: const Text('取消')),
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
                    _isBlocked = !isBlocked; // 更新黑名单状态
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
            child: Text(
              isBlocked ? '确定' : '确定',
              style: const TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  /// 确认删除好友
  void _confirmDeleteFriend() async {
    final result = await _nativeService.showNativeAlert(
      title: '删除好友',
      message:
          '确定要删除好友「${_cleanUtf16String(_friend.displayName)}」吗？\n\n删除后，聊天记录将被清空，且需要重新添加才能继续聊天。',
      confirmText: '删除',
      cancelText: '取消',
      showCancel: true,
    );

    if (result != null && result['action'] == 'confirm') {
      EasyLoading.show(status: '删除中...');

      try {
        // 使用 FriendController 的删除方法（会同时删除服务器和本地数据库）
        final deleteResult = await _friendController.deleteContact(_friend.id);

        if (deleteResult['errorCode'] == 0) {
          EasyLoading.showSuccess('已删除好友');
          widget.onDelete();
          Get.back(result: true); // 返回并刷新列表
        } else {
          EasyLoading.showError(deleteResult['message'] ?? '删除失败');
        }
      } catch (e) {
        EasyLoading.showError('删除失败');
      }
    }
  }
}
