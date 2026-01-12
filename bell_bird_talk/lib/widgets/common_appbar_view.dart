import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/utils.dart';

// 不同风格的appBar
enum AppBarType { normal, close, backAndClose, sheetbackAndClose }

class CommonAppBarView extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color backgroundColor;
  final Widget? btn;

  //
  final AppBarType appBarType;

  const CommonAppBarView({
    super.key,
    required this.title,
    this.backgroundColor = GbsColors.lightAppBarColorB,
    this.appBarType = AppBarType.normal,
    this.btn,
  });

  @override
  Widget build(BuildContext context) {
    if (appBarType == AppBarType.close) {
      return PreferredSize(
        preferredSize: Size(Get.width, 64),
        child: Container(
          color: GbsColors.lightAppBarColorA,
          margin: EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: EdgeInsetsGeometry.only(top: 10, left: 16),
            child: Row(
              children: [
                Text(
                  title,
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

    if (appBarType == AppBarType.sheetbackAndClose) {
      return PreferredSize(
        preferredSize: Size(Get.width, 64),
        child: Container(
          color: backgroundColor,
          padding: EdgeInsets.only(top: 8),
          child: SafeArea(
            child: Row(
              children: [
                InkWell(
                  onTap: () {
                    Get.back();
                  },
                  child: Container(
                    height: 44,
                    width: Get.width * 2 / 3,
                    padding: EdgeInsetsGeometry.only(right: 12, left: 12),
                    child: Row(
                      children: [
                        Icon(Icons.arrow_back_ios_new),
                        SizedBox(width: 12),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: GbsColors.des1Color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Spacer(),
                btn!,
              ],
            ),
          ),
        ),
      );
    }

    if (btn != null) {
      return PreferredSize(
        preferredSize: Size(Get.width, 64),
        child: Container(
          color: backgroundColor,
          child: SafeArea(
            child: Row(
              children: [
                InkWell(
                  onTap: () {
                    Get.back();
                  },
                  child: Container(
                    height: 44,
                    width: 64,
                    padding: EdgeInsetsGeometry.symmetric(horizontal: 16),
                    child: Icon(Icons.arrow_back_ios_new),
                  ),
                ),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: GbsColors.des1Color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                btn!,
              ],
            ),
          ),
        ),
      );
    }
    return PreferredSize(
      preferredSize: Size(Get.width, 64),
      child: Container(
        color: backgroundColor,
        child: SafeArea(
          child: Row(
            children: [
              InkWell(
                onTap: () {
                  Get.back();
                },
                child: Container(
                  height: 44,
                  width: 64,
                  padding: EdgeInsetsGeometry.symmetric(horizontal: 16),
                  child: Icon(Icons.arrow_back_ios_new),
                ),
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: GbsColors.des1Color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(width: 64),
            ],
          ),
        ),
      ),
    );
  }

  @override
  // TODO: implement preferredSize
  Size get preferredSize => Size(Get.width, 64);
  //
}
