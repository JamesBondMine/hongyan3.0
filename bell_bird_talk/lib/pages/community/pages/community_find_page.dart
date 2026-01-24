import 'package:bell_bird_talk/controllers/community_controller.dart';
import 'package:bell_bird_talk/pages/community/models/community_setting_model.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:bell_bird_talk/widgets/common_appbar_view.dart';
import 'package:flutter/material.dart';

class CommunityFindSettingPage extends StatefulWidget {
  const CommunityFindSettingPage({Key? key, required this.cmtyId})
    : super(key: key);

  final String? cmtyId;

  @override
  State<CommunityFindSettingPage> createState() => CommunityChildPageState();
}

class CommunityChildPageState extends State<CommunityFindSettingPage> {
  bool valueCheckChannel = true;

  // 社群设置
  CommunitySettingsModel? _communitySettings;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _getCmtSetting();
  }

  // 获取社群设置
  void _getCmtSetting() async {
    // 处理社群设置
    CommunityController.to.loadCommunitySettings(widget.cmtyId!).then((result) {
      if (mounted) {
        setState(() {
          _communitySettings = result;
        });
      }
    });
  }

  // 更新社群设置
  void _updateCmtSetting(int type) async {
    // 处理社群设置
    if (_communitySettings != null) {
      switch (type) {
        case 1:
          CommunityController.to.updateCommunitySettings(
            cmtyId: widget.cmtyId!,
            settings: {
              "allow_access_other_channels":
                  _communitySettings!.settings.allowAccessOtherChannels,
            },
          );
          break;
        case 2:
          CommunityController.to.updateCommunitySettings(
            cmtyId: widget.cmtyId!,
            settings: {"need_verify": _communitySettings!.settings.needVerify},
          );
          break;
        case 3:
          CommunityController.to.updateCommunitySettings(
            cmtyId: widget.cmtyId!,
            settings: {
              "allow_join_by_invite_link": _communitySettings!.settings.allowJoinByInviteLink,
            },
          );
          break;
        default:
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GbsColors.lightBackgroundA,
      appBar: CommonAppBarView(title: '访问管理'),
      body: ListView(
        padding: EdgeInsets.all(0),
        children: [
          _buildCard([
            _buildItem(
              '访问社群其他频道',
              '新人社群加入时，可访问默认频道之外的其他频道',
              _communitySettings != null &&
                  _communitySettings!.settings.allowAccessOtherChannels,
              (value) {
                setState(() {
                  _communitySettings!.settings.allowAccessOtherChannels = value;
                });
                _updateCmtSetting(1);
              },
            ),
            _buildDivider(),
            _buildItem(
              '社群加入审批',
              '新人加入社群时需要经过审批',
              _communitySettings != null &&
                  _communitySettings!.settings.needVerify,
              (value) {
                setState(() {
                  _communitySettings!.settings.needVerify = value;
                });
                _updateCmtSetting(2);
              },
            ),
            _buildDivider(),
            _buildItem(
              '社群邀请加入',
              '新人可通过邀请链接加入社群',
              _communitySettings != null &&
                  _communitySettings!.settings.allowJoinByInviteLink,
              (value) {
                setState(() {
                  _communitySettings!.settings.allowJoinByInviteLink = value;
                });
                _updateCmtSetting(3);
              },
            ),
          ]),
        ],
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
          padding: const EdgeInsets.all(12),
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
      padding: const EdgeInsets.only(left: 16, top: 10),
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
          SizedBox(width: 20),
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

          Text(
            '文字',
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
    );
  }
}
