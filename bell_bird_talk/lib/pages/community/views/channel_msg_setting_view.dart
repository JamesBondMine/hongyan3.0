
import 'package:bell_bird_talk/config/global.dart';
import 'package:bell_bird_talk/controllers/community_controller.dart';
import 'package:bell_bird_talk/pages/community/models/community_model.dart';
import 'package:bell_bird_talk/pages/community/views/cmt_role_msgsend_selview.dart';
import 'package:bell_bird_talk/pages/community/views/cmt_send_max_view.dart';
import 'package:bell_bird_talk/pages/community/views/cmt_send_sel_view.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:bell_bird_talk/widgets/common_appbar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/route_manager.dart';
import 'package:get/state_manager.dart';

class ChannelMsgSettingView extends StatelessWidget {
  final String? cmtyId; // 社群ID（可选）

  ChannelModel ccmodel;

  ChannelMsgSettingView({super.key, this.cmtyId, required this.ccmodel});

  MemberSendMsg sendMsgs = MemberSendMsg(txt: true);

  CmtSettingSelModel defaultSendItem = CmtSettingSelModel(
    title: '加入社群时间超过10分钟',
    subTitle: '',
    value: 1,
  );

  CmtSettingSelModel defaultSendPingItem = CmtSettingSelModel(
    title: '不限制',
    subTitle: '',
    value: 2,
  );

  CmtSettingMaxModel defaultSendMaxItem = CmtSettingMaxModel(
    title: '不限制',
    subTitle: '',
    value: 0,
    max: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GbsColors.lightBackgroundB,
      appBar: _buildCustomBar(context),
      body: _bodyView(context),
    );
  }

  PreferredSize _buildCustomBar(BuildContext context,) {
      return PreferredSize(
        preferredSize: Size(Get.width, 64),
        child: Container(
          color: GbsColors.lightAppBarColorA,
          margin: EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: EdgeInsetsGeometry.only(top: 10, left: 16),
            child: Row(
              children: [
                Image.asset('assets/img/community/channel_txt.png', width: 20.w, height: 20.h,),
                Text(
                  '${ccmodel.channelName}发言设置',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: GbsColors.des1Color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: GbsColors.titleColor),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      );
    }

  Widget _bodyView(BuildContext context) {
    return GetBuilder<CommunityController>(
      id: CommunityController.to.cmtSendMsgSelRefreshId,
      builder: (controller) {
        return Column(
          children: [
            _buildTitle('文字频道发言限制'),
            _buildCard([
              _buildElement(defaultSendItem.title, 'cunty_member', () {
                _sendLimitSetting(context);
              }),
            ]),
            _buildTitle('文字频道发言频率限制'),
            _buildCard([
              _buildElement(defaultSendPingItem.title, 'cunty_member', () {
                _sendPinLimitSetting(context);
              }),
            ]),
            _buildTitle('文字频道发言类型限制'),
            _buildCard([
              _buildElement(
                '${sendMsgs.txt == true ? '文本' : ''} ${sendMsgs.img == true ? '图片' : ''} ${sendMsgs.emoji == true ? '表情' : ''}',
                'cunty_member',
                () {
                  checkChannelEvent(context);
                },
              ),
            ]),
            _buildTitle('文字频道发言上限限制'),
            _buildCard([
              _buildElement(defaultSendMaxItem.max ==0 ? '不限制' : '每${defaultSendMaxItem.title}${defaultSendMaxItem.max}条', 'cunty_member', () {
                _showCreateCategoryView(context);
              }),
            ]),
          ],
        );
      },
    );
  }

  // 创建分类
  void _showCreateCategoryView(BuildContext context) {
    final controller = TextEditingController(text: '');
    List<CmtSettingMaxModel> items = [
      CmtSettingMaxModel(title: '不设置', subTitle: '', value: 0, max: 0),
      CmtSettingMaxModel(title: '分钟', subTitle: '', value: 1, max: 100),
      CmtSettingMaxModel(title: '小时', subTitle: '', value: 2, max: 100),
      CmtSettingMaxModel(title: '天', subTitle: '', value: 3, max: 100),
      CmtSettingMaxModel(title: '月', subTitle: '', value: 4, max: 100),
    ];
    // 新增分组
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: CmtSendMaxView(
            controller: controller,
            defaultItem: defaultSendMaxItem,
            items: items,
            tip: '发言上限限制',
            title: '发言上限限制',
            onTap: (item) async {
              final gname = controller.text.trim();
              defaultSendMaxItem = item;
              CommunityController.to.updateCmtSendMsgSel();
              Get.back();

              // EasyLoading.show(status: '正在创建分组...');

              // try {
              //   bool result = await CommunityController.to.createChannelGroup(cmtyId: _cmty!.id, categoryName: gname);
              //    EasyLoading.dismiss();
              //   if (result == true) {
              //     // 刷新分组列表
              //     _loadGroupsAndChannels(_cmty!);
              //     EasyLoading.showSuccess('分组创建成功');
              //   } else {
              //     EasyLoading.showError('创建失败');
              //   }
              // } catch (e) {
              //   EasyLoading.dismiss();
              //   print('创建分组错误: $e');
              //   EasyLoading.showError('创建失败，请稍后重试');

              // }
            },
          ),
        );
      },
    );
  }

  // 查看频道
  void checkChannelEvent(BuildContext context) {
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
            sendMsgs = msgs;
            CommunityController.to.updateCmtSendMsgSel();
            Get.back();
          },
        ),
      ),
    );
  }

  // 发言频率限制
  void _sendPinLimitSetting(BuildContext context) {
    final List<CmtSettingSelModel> items = [
      CmtSettingSelModel(title: '不限制', subTitle: '', value: 0),
      CmtSettingSelModel(title: '1分钟内发送1条', subTitle: '', value: 1),
      CmtSettingSelModel(title: '5分钟内发送1条', subTitle: '', value: 2),
    ];
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
        child: CommunitySendSelectView(
          title: '发言频率限制',
          items: items,
          defaultItem: defaultSendPingItem,
          onConfirm: (value) {
            defaultSendPingItem = value;
            CommunityController.to.updateCmtSendMsgSel();
          },
        ),
      ),
    );
  }

  // 发言限制
  void _sendLimitSetting(BuildContext context) {
    final List<CmtSettingSelModel> items = [
      CmtSettingSelModel(title: '加入社群时间超过5分钟', subTitle: '', value: 0),
      CmtSettingSelModel(title: '加入社群时间超过10分钟', subTitle: '', value: 1),
      CmtSettingSelModel(title: '不限制', subTitle: '', value: 2),
    ];
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
        child: CommunitySendSelectView(
          title: '发言限制',
          items: items,
          defaultItem: defaultSendItem,
          onConfirm: (value) {
            defaultSendItem = value;
            CommunityController.to.updateCmtSendMsgSel();
          },
        ),
      ),
    );
  }

  // 元素
  Widget _buildElement(String title, String icon, VoidCallback tap) {
    return InkWell(
      onTap: tap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, color: GbsColors.des1Color),
          ),
          Spacer(),
          Icon(Icons.arrow_forward_ios, size: 16, color: GbsColors.des9Color),
        ],
      ),
    );
  }

  // 卡片
  Widget _buildCard(List<Widget> children) {
    return Container(
      height: 52,
      margin: const EdgeInsets.only(left: 16, right: 16, top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: GbsColors.lightBackgroundA,
        borderRadius: BorderRadius.circular(12),
      ),
      child: children.first,
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
}
