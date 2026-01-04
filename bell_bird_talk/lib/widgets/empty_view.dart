
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:flutter/material.dart';

class EmptyView extends StatelessWidget {
  final String message;

  const EmptyView({super.key, this.message = '暂无数据'});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.only(top: 80),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Image.asset(  'assets/img/common/empty.png',width: 230,fit: BoxFit.fill,),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: GbsColors.des6Color,
            ),
          ),
     
        ],
      ),
    );
  }
  
}