

import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:bell_bird_talk/widgets/common_appbar_view.dart';
import 'package:flutter/material.dart';

class ChannelEditView extends StatefulWidget {

  final ValueChanged<int> onConfirm;

  /// 当前频道
  String channelId;
  
  ChannelEditView({
    super.key,
    required this.onConfirm,
    required this.channelId,
  });
  
  @override
  State<StatefulWidget> createState() {
    return _ChannelEditViewState();
  }

}
class _ChannelEditViewState extends State<ChannelEditView> {


  final TextEditingController _channelNameController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _channelNameController.text = widget.channelId;
  }


  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _channelNameController.dispose();
  }
  


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GbsColors.lightBackgroundB,
      appBar:  CommonAppBarView(title: '# ${widget.channelId}', appBarType: AppBarType.close,),
      body: ListView(
        children: [
          _buildChannelNameField(),
          _buildCell('暂停邀请', '暂停邀请后，除超级管理员和频道创建人外，其他成员不可邀请新人加入频道', true, (value) {

          }),
          _buildCell('禁止发言', '禁止发言后，除超级管理员和频道创建人外，其他成员不可在频道中发言', true, (value) {

          })
        ]
      )
    );
  }

   // 频道名称输入框
  Widget _buildChannelNameField() {
    return Padding(padding: EdgeInsetsGeometry.only(left: 16, right: 16, bottom: 16), child:  Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题（带红色必填星号）
        Row(
          children: [
            Text(
              '频道名称',
              style: TextStyle(
                fontSize: 14,
                color: GbsColors.des1Color,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '*',
              style: TextStyle(
                fontSize: 14,
                color: GbsColors.lightError,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 输入框
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: GbsColors.lightInputBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: GbsColors.lightDivider,
              width: 0.5,
            ),
          ),
          child: TextField(
            controller: _channelNameController,
            style: TextStyle(
              fontSize: 16,
              color: GbsColors.des1Color,
            ),
            decoration: InputDecoration(
              hintText: '请输入频道名称',
              hintStyle: TextStyle(
                fontSize: 16,
                color: GbsColors.des9Color,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    ));
  }


  // cell
  Widget _buildCell(String title, String des,  bool value, ValueChanged<bool> onChanged) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text(title, style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: GbsColors.des1Color,
              )),
              SizedBox(height: 4,),
              Text(des, style: TextStyle(
                fontSize: 12,
                color: GbsColors.des6Color,
              )),
            ],)),
            Switch(
              activeTrackColor:  GbsColors.primaryColor,
              value: value, onChanged: onChanged)
          ]
        )
      );
  }

}
