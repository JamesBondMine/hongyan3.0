

import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:bell_bird_talk/widgets/common_appbar_view.dart';
import 'package:flutter/material.dart';

class CategorySettingView extends StatelessWidget {

  final ValueChanged<int> onConfirm;

  /// 当前分类
  String channelId;
  
  CategorySettingView({
    super.key,
    required this.onConfirm,
    required this.channelId,
  });


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GbsColors.lightBackgroundB,
      appBar:  CommonAppBarView(title: '分类设置', appBarType: AppBarType.close,),
      body: ListView(
        children: [
          _buildCard([
            _buildElement('编辑分类', 'setting_invate', () {
              Navigator.of(context).pop();
              onConfirm(1);
            })
          ]),
          _buildCard([
            _buildElement('删除分类', 'setting_set', () {
              Navigator.of(context).pop();
              onConfirm(2);
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
      child: Row(
        children: [
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
