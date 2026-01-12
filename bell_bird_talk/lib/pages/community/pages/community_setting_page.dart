
import 'package:bell_bird_talk/pages/community/pages/community_find_page.dart';
import 'package:bell_bird_talk/pages/community/pages/community_invate_set_page.dart';
import 'package:bell_bird_talk/pages/community/pages/community_member_page.dart';
import 'package:bell_bird_talk/pages/community/pages/community_roles_page.dart';
import 'package:bell_bird_talk/pages/community/pages/community_safe_page.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:bell_bird_talk/widgets/common_appbar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/route_manager.dart';

class CommunitySettingPage extends StatelessWidget {
  final String? cmtyId; // 社群ID（可选）
  
  const CommunitySettingPage({super.key, this.cmtyId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GbsColors.lightBackgroundA,
      appBar:CommonAppBarView(title: '社群设置', backgroundColor: GbsColors.lightBackgroundA),
      body: Column(children: [
        _buildTitle('成员管理'),
        _buildCard([
          _buildElement('成员', 'cunty_member', () {  
            Get.to(CommunityMemberPage(cmtyId: cmtyId));
          },),
          _buildDivider(),
          _buildElement('角色', 'setting_set', () {  
            Get.to(CommunityRolesPage());
          },),
          _buildDivider(),
          _buildElement('邀请', 'setting_invate', () { 
            Get.to(CommunityInvateSettingPage(cmtyId: cmtyId)); 
          },),
          _buildDivider(),
          _buildElement('访问', 'cunty_go', () {  
            Get.to(CommunityFindSettingPage(cmtyId: cmtyId));
          },),
        ]),
        _buildTitle('安全管理'),
        _buildCard([
          _buildElement('安全管理', 'cunty_safe', () {  
            Get.to(CommunitySafePage(cmtyId: cmtyId));
          },),
          _buildDivider(),
          _buildElement('封禁用户', 'cunty_xvxv', () {  
          },),
        ])
      ],),
    );
  }

  // 分割线
  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.only(left: 36),
      height: 0.8,
      color: GbsColors.lightDivider,
    );
  }

  // 元素
  Widget _buildElement(String title, String icon,VoidCallback tap) {
    return InkWell(
      onTap: tap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Image.asset('assets/img/community/$icon.png', width: 20, height: 20),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(fontSize: 16, color: GbsColors.des1Color)),
          ]
        )
      )
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
      child: Column(
        children: children,
      ),
    );
  }


  // 标题
  Widget _buildTitle(String title) {
    return Container(
      padding: const EdgeInsets.only(left: 16, top: 12),
      alignment: Alignment.centerLeft,
      child: Text(title, style: const TextStyle(fontSize: 14, color: GbsColors.des6Color)),
    );
  }
  
}