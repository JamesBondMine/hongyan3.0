import 'package:bell_bird_talk/controllers/community_controller.dart';
import 'package:bell_bird_talk/pages/community/models/community_setting_model.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/state_manager.dart';

class CommunityPriSettingView extends StatelessWidget {
  final ValueChanged<int> onConfirm;

  final int? selectedCategory;
  final String? cmtyId; // 社群ID（可选）
  CommunitySettingsModel cmtSetting;

  CommunityPriSettingView({
    Key? key,
    required this.onConfirm,
    this.selectedCategory,
    this.cmtyId,
    required this.cmtSetting,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GbsColors.lightBackgroundB,
      resizeToAvoidBottomInset:
          false, // 防止 Scaffold 自动调整，由 showScreenViewCustom 的 AnimatedPadding 处理
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '隐私设置',
              style: TextStyle(
                color: GbsColors.des1Color,
                fontSize: 16,
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
      body: _bodyView(),
    );
  }

  Widget _bodyView() {
    return GetBuilder<CommunityController>(
      id: CommunityController.to.cmtPriSettingRefreshId,
      builder: (controller) {
        return Column(
          children: [
            _buildCell(
              '私信',
              '允许社群内发送私信',
              cmtSetting.settings.allowPrivateChat,
              (value) async {
                bool success = await CommunityController.to
                    .updateCommunitySettings(
                      cmtyId: cmtyId!,
                      settings: {"allow_private_chat": value},
                    );
                if (success) {
                  cmtSetting.settings.allowPrivateChat = value;
                  CommunityController.to.updateCmtPriSettingRefresh();
                }
              },
            ),
            Container(
              height: 0.8,
              color: GbsColors.lightDivider,
              margin: EdgeInsets.only(left: 16),
            ),
            _buildCell(
              '添加好友',
              '允许社群内的成员互相添加好友',
              cmtSetting.settings.allowAddFriend,
              (value) async {
                bool success = await CommunityController.to
                    .updateCommunitySettings(
                      cmtyId: cmtyId!,
                      settings: {"allow_add_friend": value},
                    );
                if (success) {
                  cmtSetting.settings.allowAddFriend = value;
                  CommunityController.to.updateCmtPriSettingRefresh();
                }
              },
            ),
          ],
        );
      },
    );
  }

  // cell
  Widget _buildCell(
    String title,
    String des,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: GbsColors.des1Color,
                  ),
                ),
                Text(
                  des,
                  style: TextStyle(fontSize: 12, color: GbsColors.des6Color),
                ),
              ],
            ),
          ),
          Switch(
            activeTrackColor: GbsColors.primaryColor,
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
