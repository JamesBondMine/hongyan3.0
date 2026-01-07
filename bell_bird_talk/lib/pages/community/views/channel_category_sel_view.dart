
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ChannelCategorySelView extends StatelessWidget {

   final ValueChanged<int> onConfirm;

   final int?  selectedCategory;

   ChannelCategorySelView({Key? key , required this.onConfirm, this.selectedCategory} ) : super(key: key);

  
   @override
    Widget build(BuildContext context) { 
      return Scaffold(
      backgroundColor: GbsColors.lightBackgroundB,
      resizeToAvoidBottomInset: false, // 防止 Scaffold 自动调整，由 showScreenViewCustom 的 AnimatedPadding 处理
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '所属分类',
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
      body: ListView.builder(
        itemCount: 12,
        itemBuilder:  (context, index){
        return  ListTile(
          title: Text('分类${index}'),
          onTap: () {
            Navigator.of(context).pop();
            onConfirm(index);
          },
           trailing: selectedCategory == index ? Icon(Icons.check, color: GbsColors.titleColor,) : null,
        );
      }));
   }

  
}