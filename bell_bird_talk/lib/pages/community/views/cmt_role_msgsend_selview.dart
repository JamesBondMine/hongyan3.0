import 'package:bell_bird_talk/controllers/community_controller.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:bell_bird_talk/widgets/common_appbar_view.dart';
import 'package:flutter/material.dart';
import 'package:get/state_manager.dart';

class MemberSendMsg {
  MemberSendMsg({this.txt = false, this.img = false, this.emoji = false});

  bool txt = false;
  bool img = false;
  bool emoji = false;
}

class CmtRoleMsgSendSelView extends StatelessWidget {
  final ValueChanged<MemberSendMsg> onConfirm;

  MemberSendMsg msgs;

  CmtRoleMsgSendSelView({
    super.key,
    required this.msgs,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GbsColors.lightBackgroundB,
      resizeToAvoidBottomInset:
          false, // 防止 Scaffold 自动调整，由 showScreenViewCustom 的 AnimatedPadding 处理
      appBar: CommonAppBarView(
        title: '发送消息权限',
        backgroundColor: Colors.white,
        appBarType: AppBarType.sheetbackAndClose,
        btn: InkWell(
          onTap: () {
            onConfirm(msgs);
          },
          child: Container(
            height: 44,
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '完成',
              style: TextStyle(
                color: GbsColors.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
      body: _buildListView(),
    );
  }

  Widget _buildListView() {
    return GetBuilder<CommunityController>(
      id: CommunityController.to.roleSendMsgSelRefreshId,
      builder: (controller) {
        return Column(
          children: [
            _buildCell('文字', msgs.txt, (value) {
              msgs.txt = value;
              CommunityController.to.updateRoleSendMsgSel();
            }),
            Container(
              height: 0.8,
              color: GbsColors.lightDivider,
              margin: EdgeInsets.only(left: 16),
            ),
            _buildCell('图片', msgs.img, (value) {
              msgs.img = value;
              CommunityController.to.updateRoleSendMsgSel();
            }),
            Container(
              height: 0.8,
              color: GbsColors.lightDivider,
              margin: EdgeInsets.only(left: 16),
            ),
            _buildCell('表情', msgs.emoji, (value) {
              msgs.emoji = value;
              CommunityController.to.updateRoleSendMsgSel();
            }),
          ],
        );
      },
    );
  }

  // cell
  Widget _buildCell(String title, bool value, ValueChanged<bool> onChanged) {
    return InkWell(
      onTap: () {
        onChanged(!value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: GbsColors.des1Color,
                ),
              ),
            ),
            Image.asset(
              value
                  ? 'assets/img/community/cunty_sel_ed.png'
                  : 'assets/img/community/cunty_sel_un.png',
              width: 20,
              height: 20,
            ),
          ],
        ),
      ),
    );
  }
}
