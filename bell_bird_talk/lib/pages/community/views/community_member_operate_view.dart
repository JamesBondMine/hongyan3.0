import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CommunityMemberOperateView extends StatelessWidget {
  final ValueChanged<int> onConfirm;

  const CommunityMemberOperateView({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: GbsColors.lightBackgroundB,
      child: Column(
        children: [
          // 标题栏
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 16, right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '设置分组',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                IconButton(
                  onPressed: () {
                    Get.back();
                  },
                  icon: Icon(Icons.close),
                ),
              ],
            ),
          ),
          // 头像
          Container(
            width: 104,
            height: 104,

            child: ClipRRect(
              borderRadius: BorderRadius.circular(52),
              child: CachedNetworkImage(
                fit: BoxFit.fill,
                imageUrl:
                    'https://gips0.baidu.com/it/u=2946692232,559515331&fm=3028&app=3028&f=JPEG&fmt=auto&q=100&size=f960_1280',

                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsetsGeometry.only(top: 10, bottom: 8),
            child: Text(
              '昵称',
              style: const TextStyle(
                fontSize: 24,
                color: GbsColors.des1Color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            'title',
            style: const TextStyle(fontSize: 16, color: GbsColors.des6Color),
          ),
          _buildBottom(context),
        ],
      ),
    );
  }

  // 操作烂Item
  Widget _buildOperateItem(String title, String icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: (Get.width - 42)/3,
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16,),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Color(0xffF4F4F4)
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon(iconData, color: GbsColors.des3Color),
            Image.asset(  'assets/img/community/$icon.png', width: 24, height: 24,),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, color: GbsColors.des1Color),
            ),
          ],
        ),
      ),
    );
  }

  // 底部 操作烂
  Widget _buildBottom(BuildContext context) {
    return Container(
      width: Get.width,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: GbsColors.lightDivider, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
         _buildOperateItem('禁言', 'cunty_shutup', () {
           Get.back();
         }),
         _buildOperateItem('剔除', 'cunty_over', () {
           Get.back();
         }),
         _buildOperateItem('封禁', 'cunty_xvxv', () {
           Get.back();
         }),
        ],
      ),
    );
  }
}
