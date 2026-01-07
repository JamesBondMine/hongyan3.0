
import 'dart:ffi';

import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:flutter/material.dart';

class EmptyView extends StatelessWidget {
  final String message;
  final bool? community;
  VoidCallback? click;

  Widget? child;

  EmptyView({super.key, this.click, this.child, this.community = false, this.message = '暂无数据'});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.only(top: 80),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Image.asset( community!=null && community==true ? 'assets/img/common/empty_cunity.png' : 'assets/img/common/empty.png',width: 230,fit: BoxFit.fill,),
          InkWell(onTap: () {
            if (click != null) {
              click!();
            }
          },
          child: child ?? Padding(padding: EdgeInsetsGeometry.only(top: 16,bottom: 20), child: Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: click != null ? GbsColors.primaryColor : GbsColors.des6Color,
            ),
          ),),)
        ],
      ),
    );
  }
  
}