
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/utils.dart';

class CommonAppBarView extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color backgroundColor;

  const CommonAppBarView({
    super.key,
    required this.title,
    this.backgroundColor = GbsColors.lightAppBarColorB,
  });

  @override
  Widget build(BuildContext context) {
    return PreferredSize(preferredSize: Size(Get.width, 64), child: Container(
      color: backgroundColor,
      child: SafeArea(child: Row(children: [
      InkWell(onTap: () {
        Get.back();
      },
      child: Container(
        height: 44,
        width: 64,
        padding: EdgeInsetsGeometry.symmetric(horizontal: 16), child: Icon(Icons.arrow_back_ios_new),),),
        Expanded(child: Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: GbsColors.des1Color, fontWeight: FontWeight.w500),),),
        SizedBox(width: 64,),
    ],)),));
  }
  
  @override
  // TODO: implement preferredSize
  Size get preferredSize => Size(Get.width, 64);
  // 
}