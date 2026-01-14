import 'package:bell_bird_talk/pages/community/models/community_model.dart';
import 'package:bell_bird_talk/services/native_bridge.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CommunityMemberOperateView extends StatelessWidget {
  final ValueChanged<int> onConfirm;
  CommunityMemberModel member;

  CommunityMemberOperateView({
    super.key,
    required this.member,
    required this.onConfirm,
  });

  final IOSNativeService _nativeService = IOSNativeService();

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
              child: member.avatar != null && member.avatar!.isNotEmpty
                  ? CachedNetworkImage(
                      fit: BoxFit.fill,
                      imageUrl: member.avatar!,
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.person, size: 20),
                    )
                  : const Icon(Icons.person, size: 20),
            ),
          ),

          Padding(
            padding: EdgeInsetsGeometry.only(top: 10, bottom: 0),
            child: Text(
              member.nickname ?? member.username,
              style: const TextStyle(
                fontSize: 24,
                color: GbsColors.des1Color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            member.username,
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
        width: (Get.width - 42) / 3,
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Color(0xffF4F4F4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon(iconData, color: GbsColors.des3Color),
            Image.asset(
              'assets/img/community/$icon.png',
              width: 24,
              height: 24,
            ),
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
      margin: EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      // decoration: BoxDecoration(
      //   border: Border(
      //     top: BorderSide(color: GbsColors.lightDivider, width: 0.5),
      //   ),
      // ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildOperateItem('禁言', 'cunty_shutup', () async {
            final result = await _nativeService.showNativeAlert(
              title: '禁言',
              message: '确定要禁言当前账号吗？',
              confirmText: '禁言',
              cancelText: '取消'.tr,
              showCancel: true,
            );

            if (result != null && result['action'] == 'confirm') {
              onConfirm(1);
              Get.back();
            }
          }),
          _buildOperateItem('踢除', 'cunty_over', () async {
            final result = await _nativeService.showNativeAlert(
              title: '踢除',
              message: '确定要踢除当前账号吗？',
              confirmText: '踢除',
              cancelText: '取消'.tr,
              showCancel: true,
            );

            if (result != null && result['action'] == 'confirm') {
              onConfirm(2);
              Get.back();
            }
          }),
          _buildOperateItem('封禁', 'cunty_xvxv', () async {
            final result = await _nativeService.showNativeAlert(
              title: '封禁',
              message: '确定要封禁当前账号吗？',
              confirmText: '封禁',
              cancelText: '取消'.tr,
              showCancel: true,
            );

            if (result != null && result['action'] == 'confirm') {
              onConfirm(3);
              Get.back();
            }
          }),
        ],
      ),
    );
  }
}
