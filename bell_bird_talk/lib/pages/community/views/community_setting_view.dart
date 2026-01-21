

import 'package:bell_bird_talk/controllers/global_controller.dart';
import 'package:bell_bird_talk/pages/community/models/community_model.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:flutter/material.dart';

class CommunitySettingView extends StatelessWidget {

  final ValueChanged<int> onConfirm;
  CommunityModel cmty;
  
  CommunitySettingView({
    super.key,
    required this.cmty,
    required this.onConfirm,
  });


  @override
  Widget build(BuildContext context) {
    final currentUserId =  GlobalController.to.currentUser.value?.id ?? '';
    return Scaffold(
      backgroundColor: GbsColors.lightBackgroundB,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '社群设置',
              style: TextStyle(
                color: GbsColors.des1Color,
                fontSize: 18,
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
      body: ListView(
        children: [
          if (cmty.allowAddFriend) _buildCard([
            _buildElement('邀请好友', 'setting_invate', () {
              Navigator.of(context).pop();
              onConfirm(1);
            }),
          ]),
          // 只有社群拥有者才能设置社群
          if (cmty.ownerId == currentUserId || cmty.ownerId.isEmpty)  _buildCard([
            _buildElement('社群设置', 'setting_set', () {
              Navigator.of(context).pop();
              onConfirm(2);
            }),
          ]),
          if (cmty.ownerId == currentUserId || cmty.ownerId.isEmpty) _buildCard([
            _buildElement('创建频道', 'setting_create', () {
              Navigator.of(context).pop();
              onConfirm(3);
            }),
          if (cmty.ownerId == currentUserId || cmty.ownerId.isEmpty)  _buildElement('创建分类', 'setting_cg', () {
              Navigator.of(context).pop();
              onConfirm(4);
            }),
          ]),
           _buildCard([
            _buildElement('通知设置', 'setting_noti', () {
              Navigator.of(context).pop();
              onConfirm(5);
            }),
          if (cmty.ownerId == currentUserId)  _buildElement('隐私设置', 'setting_pricy', () {
              Navigator.of(context).pop();
              onConfirm(6);
            }),
          ]),
          _buildCard([
            _buildElement('离开社群', 'setting_logout', () {
              Navigator.of(context).pop();
              onConfirm(7);
            }),
          ]),
            
        ]
      )
    );
  }

  // 元素
  Widget _buildElement(String title, String icon,VoidCallback tap) {
    return InkWell(onTap: () {
      tap();
      
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      // decoration: BoxDecoration(
      //   border: Border(
      //     bottom: BorderSide(color: GbsColors.lightDivider, width: 0.5),
      //   ),
      // ),
      child: Row(
        children: [
          Image.asset('assets/img/community/$icon.png', width: 20, height: 20,), // 示例图标
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              color: GbsColors.des1Color,
              fontSize: 16,
            ),
          ),
        ],
      ),
    ),);
  }


  // 卡片
  Widget _buildCard(List<Widget> children,) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: GbsColors.lightDivider, width: 0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children,)
    );
  }

}
