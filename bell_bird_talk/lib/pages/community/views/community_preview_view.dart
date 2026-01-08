

import 'package:bell_bird_talk/pages/community/models/community_model.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:bell_bird_talk/widgets/common_button.dart';
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class CommunityPreviewView extends StatelessWidget {

  final VoidCallback onConfirm;
  CommunityModel community;
  
  CommunityPreviewView({
    super.key,
    required this.onConfirm,
    required this.community,
  });


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GbsColors.lightBackgroundB,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '社群信息',
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
      body: Column(children: [
        _buildCommunityCard(community)
      ],)
    );
  }

  /// 构建社群卡片
  Widget _buildCommunityCard(CommunityModel community) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: GbsColors.lightDivider,
          width: 0.5,
        ),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.grey.withOpacity(0.1),
        //     spreadRadius: 1,
        //     blurRadius: 5,
        //     offset: const Offset(0, 2), // changes position of shadow
        //   ),
        // ],
      ),
      // elevation: 1,
      // shape: RoundedRectangleBorder(
      //   borderRadius: BorderRadius.circular(12),
      // ),
      child: InkWell(
        onTap: () {
         
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
 
              // 内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 名称和分类
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 头像
              Container(
                width: 32,
                height: 32,
                margin: EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: community.avatar != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          community.avatar!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.group,
                              color: Colors.blue[700],
                              size: 30,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.group,
                        color: Colors.blue[700],
                        size: 30,
                      ),
              ),
                        Text(
                            community.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: GbsColors.des1Color
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                      ],
                    ),
                    
           
                    // 描述
                    Padding(padding: EdgeInsetsGeometry.only(top: 16, bottom: 16), child: Text(
                      community.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: GbsColors.des6Color,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),),
                    
          
                    // 成员数和操作按钮
                    Container(
                      margin: EdgeInsets.only(bottom: 16),
                      padding: EdgeInsetsGeometry.symmetric(horizontal: 32),child: Row(
                      children: [
                        Container(
                          margin: EdgeInsets.only(right: 4),
                          width: 8,
                          height: 8,
                         decoration: BoxDecoration(
                            color: GbsColors.lightPrimaryButton,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Text(
                          '${community.memberCount}在线',
                          style: TextStyle(
                            fontSize: 12,
                            color: GbsColors.lightPrimaryButton,
                          ),
                        ),
                        Spacer(),
                        Container(
                          margin: EdgeInsets.only(right: 4),
                          width: 8,
                          height: 8,
                         decoration: BoxDecoration(
                            color: GbsColors.des9Color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Text(
                          '${community.maxMembers}成员',
                          style: TextStyle(
                            fontSize: 12,
                            color: GbsColors.des9Color,
                          ),
                        )
                      ],
                    ),),
                    CommonButton(
                      enabled: true,
                      text: '加入社群', onPressed: () {
                      onConfirm();
                    }, fontSize: 16,),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


}
