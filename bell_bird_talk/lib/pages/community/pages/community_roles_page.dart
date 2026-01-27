import 'package:bell_bird_talk/config/global.dart';
import 'package:bell_bird_talk/controllers/community_controller.dart';
import 'package:bell_bird_talk/models/community_role_model.dart';
import 'package:bell_bird_talk/pages/community/models/community_model.dart';
import 'package:bell_bird_talk/pages/community/models/community_role_model.dart';
import 'package:bell_bird_talk/pages/community/views/cmt_role_msgsend_selview.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:bell_bird_talk/widgets/common_appbar_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CommunityRolesPage extends StatefulWidget {
  CommunityRolesPage({Key? key, required this.cmtyModel}) : super(key: key);

  final CommunityModel cmtyModel; // 社群ID（可选）

  @override
  State<CommunityRolesPage> createState() => CommunityChildPageState();
}

class CommunityChildPageState extends State<CommunityRolesPage> {
  MemberSendMsg sendMsgs = MemberSendMsg();

  CommunityRolePermissions? _roleModel;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    sendMsgs = MemberSendMsg();
    _loadRoleConfig();
  }

  void _loadRoleConfig() async {
    _roleModel = await CommunityController.to.getRolesAndTemplate(
      widget.cmtyModel.id,
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    String? messageTsNet =
        _roleModel != null && _roleModel!.messageTypes != null
        ? _roleModel!.messageTypes
        : '';
    if (messageTsNet == null || messageTsNet.isEmpty) {
      sendMsgs.emoji = true;
      sendMsgs.img = true;
      sendMsgs.txt = true;
    } else {
      // List<String> types = [];
      if (messageTsNet.contains('text')) {
        // types.add('文字'.tr);
        sendMsgs.txt = true;
      }
      if (messageTsNet.contains('image')) {
        // types.add('图片'.tr);
        sendMsgs.img = true;
      }
      if (messageTsNet.contains('emoji')) {
        // types.add('表情'.tr);
        sendMsgs.emoji = true;
      }
    }

    return Scaffold(
      backgroundColor: GbsColors.lightBackgroundA,
      appBar: CommonAppBarView(title: '角色权限管理'),
      body: ListView(
        padding: EdgeInsets.only(bottom: 30),
        children: [
          _buildRoleCard(),
          _buildTitle('通用社群权限'),
          _buildCard([
            _buildItem(
              '查看频道',
              '默认允许角色查看频道',
              _roleModel != null && _roleModel!.viewChannel,
              (value) {
                setState(() {
                  _roleModel!.viewChannel = value;
                });
              },
            ),
            _buildDivider(),
            _buildItem(
              '管理频道',
              '允许角色查看、创建、编辑、删除频道',
              _roleModel != null && _roleModel!.manageChannel,
              (value) {
                setState(() {
                  _roleModel!.manageChannel = value;
                });
              },
            ),
            _buildDivider(),
            _buildTxtItem('发送消息类型', '如文字、图片、表情', (value) {
              // 查看频道
              checkChannelEvent();
            }),
            _buildDivider(),
            _buildItem(
              '邀请好友至社群',
              '允许角色角色邀请新人至社群',
              _roleModel != null && _roleModel!.inviteFriend,
              (value) {
                setState(() {
                  _roleModel!.inviteFriend = value;
                });
              },
            ),
          ]),
          _buildTitle('通用社群权限'),
          _buildCard([
            _buildItem(
              '踢出成员',
              '将成员从社群踢出，若成员收到社群邀请可次加入社群。',
              _roleModel != null && _roleModel!.kickMember,
              (value) {
                setState(() {
                  _roleModel!.kickMember = value;
                });
              },
            ),
            _buildDivider(),
            _buildItem(
              '禁言成员',
              '将社群内的成员禁言后，成员无法在各频道发言及发送消息。',
              _roleModel != null && _roleModel!.muteMember,
              (value) {
                setState(() {
                  _roleModel!.muteMember = value;
                });
              },
            ),
            _buildDivider(),
            _buildItem(
              '封禁成员',
              '将社群内的成员封禁后，成员将无法再加入社群。',
              _roleModel != null && _roleModel!.banMember,
              (value) {
                setState(() {
                  _roleModel!.banMember = value;
                });
              },
            ),
          ]),
          _buildTitle('文字频道权限'),
          _buildCard([
            _buildItem(
              '发送消息',
              '允许角色在文字频道中发送消息',
              _roleModel != null && _roleModel!.sendMessage,
              (value) {
                setState(() {
                  _roleModel!.sendMessage = value;
                });
              },
            ),
            _buildDivider(),
            _buildItem(
              '查看历史消息',
              '允许角色查看频道历史消息',
              _roleModel != null && _roleModel!.viewHistory,
              (value) {
                setState(() {
                  _roleModel!.viewHistory = value;
                });
              },
            ),
            _buildDivider(),
            _buildItem(
              '管理消息',
              '允许角色将其他成员发送的消息删除',
              _roleModel != null && _roleModel!.manageChannel,
              (value) {
                setState(() {
                  _roleModel!.manageChannel = value;
                });
              },
            ),
          ]),
          _buildTitle('语音频道权限'),
          _buildCard([
            _buildItem(
              '进入语音频道',
              '允许角色进入语音频道并听到其他成员发言',
              _roleModel != null && _roleModel!.joinVoiceChannel,
              (value) {
                setState(() {
                  _roleModel!.joinVoiceChannel = value;
                });
              },
            ),
            _buildDivider(),
            _buildItem(
              '讲话',
              '允许角色在语音频道中发言',
              _roleModel != null && _roleModel!.speak,
              (value) {
                setState(() {
                  _roleModel!.speak = value;
                });
              },
            ),
            _buildDivider(),
            _buildItem(
              '静音其他成员',
              '允许角色在语音频道中将其他成员静音，静音后成员不可再发言',
              _roleModel != null && _roleModel!.muteOthers,
              (value) {
                setState(() {
                  _roleModel!.muteOthers = value;
                });
              },
            ),
          ]),
        ],
      ),
    );
  }

  // 查看频道
  void checkChannelEvent() {
    gbs.shower.showScreenViewCustom(
      context,
      360,
      Container(
        width: Get.width,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: GbsColors.lightAppBarColorA,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: CmtRoleMsgSendSelView(
          msgs: sendMsgs,
          onConfirm: (msgs) {
            Get.back();
            List<String> types = [];
            if (msgs.txt) {
              types.add('txt');
            }
            if (msgs.img) {
              types.add('img');
            }
            if (msgs.emoji) {
              types.add('emoji');
            }
            _roleModel!.messageTypes = types.join('、');
            sendMsgs = msgs;
            setState(() {});
          },
        ),
      ),
    );
  }

  // 角色卡片
  Widget _buildRoleCard() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          height: 28,
          alignment: Alignment.center,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 206, 220, 247),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: GbsColors.primaryColor, width: 1),
          ),
          child: Text(
            '普通角色',
            style: const TextStyle(fontSize: 14, color: GbsColors.primaryColor),
          ),
        ),
      ],
    );
  }

  // 卡片
  Widget _buildCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GbsColors.lightBackgroundB,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  // 标题
  Widget _buildTitle(String title) {
    return Container(
      padding: const EdgeInsets.only(left: 16, top: 12),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, color: GbsColors.des6Color),
      ),
    );
  }

  //
  Widget _buildItem(
    String title,
    String des,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.only(left: 16, top: 12),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: GbsColors.des1Color,
                  ),
                ),
                Text(
                  des,
                  style: const TextStyle(
                    fontSize: 12,
                    color: GbsColors.des6Color,
                  ),
                ),
              ],
            ),
          ),

          Switch(
            focusColor: GbsColors.primaryColor,
            activeTrackColor: GbsColors.primaryColor,
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // 分割线
  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.only(left: 16, top: 8),
      height: 0.8,
      color: GbsColors.lightDivider,
    );
  }

  // 元素
  Widget _buildTxtItem(String title, String des, Function(bool) onChanged) {
    return InkWell(
      onTap: () {
        onChanged(true);
      },
      child: Container(
        padding: const EdgeInsets.only(left: 16, top: 12),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      color: GbsColors.des1Color,
                    ),
                  ),
                  Text(
                    des,
                    style: const TextStyle(
                      fontSize: 12,
                      color: GbsColors.des6Color,
                    ),
                  ),
                ],
              ),
            ),

            Text(
              '${sendMsgs.txt == true ? '文本' : ''} ${sendMsgs.img == true ? '图片' : ''} ${sendMsgs.emoji == true ? '表情' : ''}',
              style: const TextStyle(fontSize: 12, color: GbsColors.des6Color),
            ),
            Padding(
              padding: EdgeInsetsGeometry.only(left: 8),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: GbsColors.des6Color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
