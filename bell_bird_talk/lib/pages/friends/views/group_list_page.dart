import 'dart:convert';
import 'package:bell_bird_talk/config/global.dart';
import 'package:bell_bird_talk/controllers/chat_controller.dart';
import 'package:bell_bird_talk/pages/chat/create_group_page.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:bell_bird_talk/widgets/empty_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import '../../../services/native_bridge.dart';
import '../../../services/message_database.dart';
import '../../../controllers/global_controller.dart';
import '../../chat/group_chat/group_chat_page.dart';
import '../../chat/models/chat_model.dart';

class GroupListPage extends StatefulWidget {
  const GroupListPage({super.key});

  @override
  State<GroupListPage> createState() => _GroupListPageState();
}

class _GroupListPageState extends State<GroupListPage> {
  final IOSNativeService _nativeService = IOSNativeService();
  final MessageDatabase _database = MessageDatabase();
  final GlobalController _globalCtrl = Get.find<GlobalController>();
  bool _loading = false;
  List<Map<String, dynamic>> _groups = [];

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() => _loading = true);
    final result = await _nativeService.imGetGroupList(page: 1, pageSize: 100);
    if (!mounted) return;
    if (result['errorCode'] == 0) {
      final dataStr = result['data'] as String? ?? '';
      if (dataStr.isNotEmpty) {
        try {
          final map = json.decode(dataStr) as Map<String, dynamic>;
          final list = (map['groups'] as List?) ?? [];
          setState(() {
            _groups = list
                .map((e) => (e as Map).cast<String, dynamic>())
                .toList();
          });
        } catch (e) {
          EasyLoading.showError('解析群组列表失败');
        }
      } else {
        setState(() => _groups = []);
      }
    } else {
      EasyLoading.showError(result['message']?.toString() ?? '获取群组失败');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('群组')),
      body: RefreshIndicator(
        onRefresh: _loadGroups,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _groups.isEmpty
            ? Center(
                child: EmptyView(
                  message: '暂无群聊、去创建',
                  child: Padding(
                    padding: EdgeInsetsGeometry.only(top: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "暂无群聊、",
                          style: TextStyle(
                            color: GbsColors.des6Color,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          "去创建",
                          style: TextStyle(
                            color: GbsColors.primaryColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  click: () {
                    // 创建群聊
                    _createGroup();
                  },
                ),
              )
            : ListView.separated(
                itemCount: _groups.length,
                separatorBuilder: (_, __) => Container(),
                itemBuilder: (context, index) {
                  final item = _groups[index];
                  final name = (item['group_name'] as String?) ?? '群组';
                  final avatar = (item['group_avatar'] as String?) ?? '';
                  final gid = (item['group_id'] as String?) ?? '';
                  final type = (item['group_type'] as num?)?.toInt() ?? 0;

                  String gidLast = '1';
                  if (gid.isNotEmpty) {
                    // 从后往前查找最后一个数字
                    for (int i = gid.length - 1; i >= 0; i--) {
                      if (gid[i].contains(RegExp(r'[0-9]'))) {
                        gidLast = gid[i];
                        break;
                      }
                    }
                  }
                  return Container(
                    height: 52,
                    // margin: EdgeInsets.only(left: 16, right: 16,bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      color: GbsColors.lightBackgroundB,
                    ),
                    child: ListTile(
                      leading: SizedBox(
                        width: 36,
                        height: 36,
                        child: CircleAvatar(
                          backgroundColor: Colors.blue.shade50,
                          backgroundImage: avatar.isNotEmpty
                              ? NetworkImage(avatar)
                              : null,
                          child: Image.asset(
                            'assets/img/group/groplogo$gidLast.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      title: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _enterGroupChat(
                        gid: gid,
                        name: name,
                        avatar: avatar,
                        type: type,
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  /// 创建群聊
  Future<void> _createGroup() async {
    gbs.shower.showScreenViewCustom(
      context,
      Get.height - 150,
      Container(
        width: Get.width,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: CreateGroupPage(
          onCreate: () {
            // 刷新页面
            _loadGroups();
          },
        ),
      ),
    );
  }

  // 获取群头像-assets/img/group/

  Future<void> _enterGroupChat({
    required String gid,
    required String name,
    required String avatar,
    required int type,
  }) async {
    if (gid.isEmpty) {
      EasyLoading.showError('群组ID缺失');
      return;
    }

    final currentUserId = _globalCtrl.currentUser.value?.id ?? '';
    if (currentUserId.isEmpty) {
      EasyLoading.showError('用户未登录');
      return;
    }

    EasyLoading.show(status: '进入群聊...');

    try {
      String? convId;

      // 先查询数据库中是否存在该群组的会话
      final conversations = await _database.getConversations(
        currentUserId,
        convType: 2, // 群聊类型
      );

      // 查找是否有该群组的会话（通过 targetId 匹配）
      ConversationModel? existingConversation;
      try {
        existingConversation = conversations.firstWhere(
          (conv) => conv.targetId == gid,
        );
      } catch (e) {
        // 没有找到匹配的会话
        existingConversation = null;
      }

      if (existingConversation != null &&
          existingConversation.convId.isNotEmpty) {
        // 数据库中已存在该会话，直接使用
        convId = existingConversation.convId;
        print('✅ 从数据库中找到会话: convId=$convId');
      } else {
        // 数据库中不存在，需要创建会话
        print('📝 数据库中不存在会话，创建新会话...');
        final res = await _nativeService.imCreateConversation(
          convType: 2,
          targetId: gid,
          displayName: name,
          avatarUrl: avatar.isNotEmpty ? avatar : null,
        );

        if (res['errorCode'] == 0) {
          final dataStr = res['data'] as String? ?? '';
          if (dataStr.isNotEmpty) {
            try {
              final map = json.decode(dataStr) as Map<String, dynamic>;
              convId =
                  (map['conv_id'] as String?) ?? (map['convId'] as String?);

              // 创建会话对象并保存到数据库
              if (convId != null && convId.isNotEmpty) {
                final conversation = ConversationModel(
                  convId: convId,
                  displayName: name,
                  avatar: avatar.isNotEmpty ? avatar : null,
                  convType: 2,
                  targetId: gid,
                  unreadCount: 0,
                );

                await _database.upsertConversation(currentUserId, conversation);
                print('✅ 会话已保存到数据库: convId=$convId');
              }
            } catch (e) {
              print('❌ 解析会话数据失败: $e');
            }
          }
        } else {
          EasyLoading.showError(res['message']?.toString() ?? '创建会话失败');
          return;
        }
      }

      if (convId == null || convId.isEmpty) {
        EasyLoading.showError('未获取到会话ID');
        return;
      }

      EasyLoading.dismiss();
      if (!mounted) return;

      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (_) => GroupChatPage(
                convId: convId!,
                groupId: gid,
                groupName: name,
                groupAvatar: avatar.isNotEmpty ? avatar : null,
              ),
            ),
          )
          .then((_) {
            // 返回后清除该会话的未读数
            ChatController.to.conversationId = "";
          });
    } catch (e) {
      print('❌ 进入群聊失败: $e');
      EasyLoading.showError('进入群聊失败: $e');
    }
  }
}
