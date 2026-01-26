import 'package:flutter/material.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:bell_bird_talk/pages/chat/search_message_history.dart';
import 'package:bell_bird_talk/pages/chat/voice_call_page.dart';
import 'package:flutter_popup/flutter_popup.dart';

/// 聊天页面标题栏组件
class ChatTitleView extends StatelessWidget implements PreferredSizeWidget {
  final String convId;
  final String displayName;
  final String? avatar;
  final String targetUserId;
  final int convType; // 0=单聊,2=群聊

  const ChatTitleView({
    super.key,
    required this.convId,
    required this.displayName,
    this.avatar,
    required this.targetUserId,
    this.convType = 0,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            displayName,
            style: const TextStyle(color: GbsColors.des1Color, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
      leading: InkWell(
        onTap: () {
          Navigator.pop(context);
        },
        child: Container(
          padding: const EdgeInsets.only(
            left: 15,
            right: 20,
            top: 6,
            bottom: 6,
          ),
          child: Icon(Icons.arrow_back_ios, color: GbsColors.titleColor),
        ),
      ),
      centerTitle: false,
      backgroundColor: GbsColors.lightAppBarColorA,
      foregroundColor: GbsColors.lightAppBarColorA,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: GbsColors.titleColor),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SearchMessageHistory(
                  convId: convId,
                  targetId: targetUserId,
                  displayName: displayName,
                  avatarUrl: avatar ?? '',
                  convType: convType,
                ),
              ),
            );
          },
        ),
        CustomPopup(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _buildAppBarActions(context),
          ),
          child: Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Image.asset(
              'assets/img/msg/msgmore.png',
              width: 24,
              height: 24,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildAppBarActions(BuildContext context) {
    return [
      _popviewItem(context, '语音聊天', 'msgitemphone', () {
        // 跳转到语音通话页面
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VoiceCallPage(
              userId: targetUserId,
              nickname: displayName,
              avatar: avatar,
              isIncoming: false,
            ),
          ),
        );
      }),
      _popviewItem(context, '发起群聊', 'chataddchat', () {
        print('发起群聊');
      }),
      _popviewItem(context, '关闭免打扰', 'msgitemdistunb', () {
        print('关闭免打扰');
      }),
    ];
  }

  Widget _popviewItem(
    BuildContext context,
    String title,
    String img,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      child: Container(
        alignment: Alignment.center,
        width: 120,
        padding: const EdgeInsets.only(top: 10, bottom: 6, left: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset('assets/img//msg/$img.png', width: 20, height: 20),
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
}
