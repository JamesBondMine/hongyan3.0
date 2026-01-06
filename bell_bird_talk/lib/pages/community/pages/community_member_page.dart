import 'package:bell_bird_talk/config/global.dart';
import 'package:bell_bird_talk/pages/community/views/community_member_operate_view.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:bell_bird_talk/widgets/common_appbar_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class CommunityMemberPage extends StatelessWidget {
  const CommunityMemberPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GbsColors.lightBackgroundA,
      appBar: CommonAppBarView(
        title: '社群成员',
        backgroundColor: GbsColors.lightBackgroundA,
      ),
      body: _buildCard([
        Expanded(
          child: ListView.builder(
            itemCount: 20,
            itemBuilder: (BuildContext context, int index) {
              return _buildElement('成员$index', 'cunty_member', () {
                gbs.shower.showScreenViewCustom(
                  context,
                  400,
                  Container(
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      color: GbsColors.lightBackgroundB,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: CommunityMemberOperateView(onConfirm: (index) {}),
                  ),
                );
              });
            },
          ),
        ),
      ]),
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
  Widget _buildElement(String title, String icon, VoidCallback tap) {
    return InkWell(
      onTap: tap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: GbsColors.lightDivider,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: CachedNetworkImage(
                      fit: BoxFit.fill,
                      imageUrl:
                          'https://gips0.baidu.com/it/u=2946692232,559515331&fm=3028&app=3028&f=JPEG&fmt=auto&q=100&size=f960_1280',

                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        color: GbsColors.des1Color,
                      ),
                    ),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        color: GbsColors.des6Color,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(Icons.chevron_right, color: GbsColors.des6Color),
              ],
            ),
            _buildDivider(),
          ],
        ),
      ),
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
}
