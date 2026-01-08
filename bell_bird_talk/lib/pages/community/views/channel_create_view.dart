import 'package:bell_bird_talk/config/global.dart';
import 'package:bell_bird_talk/pages/community/views/channel_btn_view.dart';
import 'package:bell_bird_talk/pages/community/views/channel_category_sel_view.dart';
import 'package:bell_bird_talk/pages/community/views/slider_label_view.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:bell_bird_talk/widgets/common_button.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/instance_manager.dart';

class ChannelCreateView extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>?> onConfirm;
  bool onlyTextChannel = false;

  ChannelCreateView({super.key, required this.onConfirm, this.onlyTextChannel = false});
  
  @override
  State<StatefulWidget> createState() {
    return _ChannelCreateViewState();
  }

}

class _ChannelCreateViewState extends State<ChannelCreateView> {

  bool createTextChannel = true;
  
  // 频道名称输入框控制器
  final TextEditingController _channelNameController = TextEditingController();
  
  // 频道简介输入框控制器
  final TextEditingController _channelDescriptionController = TextEditingController();
  
  // 选中的分类（null 表示暂不选择）
  String _selectedCategory = '';

  // 频道最大人数
  bool channelMaxOpen = true;
  
  @override
  void dispose() {
    _channelNameController.dispose();
    _channelDescriptionController.dispose();
    super.dispose();
  }

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
              '创建频道',
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
      body: Stack(children: [
        Positioned.fill(child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMiddle(),
            
          ],
        ),
      )),
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: // 底部
            Container(
              padding: const EdgeInsets.all(16),
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom,
              ),
              child: CommonButton(
                enabled: true,
                text: '创建频道',
                onPressed: () {
                  // 验证频道名称
                  final channelName = _channelNameController.text.trim();
                  if (channelName.isEmpty) {
                    // 可以显示错误提示
                    return;
                  }
                  
                  // 准备创建频道的数据
                  final channelData = {
                    'channelName': channelName,
                    'description': _channelDescriptionController.text.trim(),
                    'channelType': createTextChannel ? 0 : 1, // 0=文字频道，1=语音频道
                    'categoryId': _selectedCategory.isEmpty ? '' : _selectedCategory,
                    'maxMembers': channelMaxOpen ? 50 : 0, // 这里可以根据实际需求设置
                  };
                  
                  Navigator.of(context).pop();
                  widget.onConfirm(channelData);
                },
              ),
            ),)
      ],),
    );
  }

  // 中间部分
  Widget _buildMiddle() {
    return Padding(padding: EdgeInsetsGeometry.only(left: 16, right: 16), child:  Column(
      // padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // header
          SizedBox(
            width: Get.width,
            height: 32,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ChannelBtnView(
                  width: (Get.width - 44) / 2,
                  height: 32,
                  enabled: createTextChannel ,
                  text: '文字频道',
                  onPressed: () {
                    if (mounted) {
                      setState(() {
                        createTextChannel = true;
                      });
                    }
                  },
                ),
                ChannelBtnView(
                  width: (Get.width - 44) / 2,
                  height: 32,
                  enabled: !createTextChannel,
                  text: '语音频道',
                  onPressed: () {
                    if (widget.onlyTextChannel == true) {
                      return;
                    }
                    if (mounted) {
                      setState(() {
                        createTextChannel = false;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 16, top: 10, bottom: 16),
            alignment: Alignment.centerLeft,
            child: Text(createTextChannel ? '成员可在频道内通过文字聊天' : '成员可在频道内通过语音聊天', style: TextStyle(fontSize: 12, color: GbsColors.des6Color)),
          ),
        // 1. 频道名称输入框
        _buildChannelNameField(),
        const SizedBox(height: 24),
        
        // 2. 频道简介输入框 -- 如果是语音频道。则展示语音频道最大人数
        createTextChannel ? _buildChannelDescriptionField() : _buildMaxMemberCount(),
        const SizedBox(height: 24),
        
        // 3. 所属分类选择
        _buildCategorySelector(),
      ],
    ));
  }

  // 语音频道最大人数
  Widget _buildMaxMemberCount() {
    return Container(
      // padding: const EdgeInsets.symmetric(vertical: 8),
      // decoration: BoxDecoration(
      //   color: GbsColors.lightInputBackground,
      //   borderRadius: BorderRadius.circular(8),
      //   border: Border.all(
      //     color: GbsColors.lightDivider,
      //     width: 0.5,
      //   )
      // ), 
      child: Column(children: [
        Row(children: [
          Text(
            '最大人数',
            style: TextStyle(
              fontSize: 14,
              color: GbsColors.des1Color,
              fontWeight: FontWeight.w500,
            ),
          ),
          Spacer(),
          Switch(
            focusColor: GbsColors.primaryColor,
            activeTrackColor:  GbsColors.primaryColor,
            value: channelMaxOpen, onChanged: (value) {
            setState(() {
              channelMaxOpen = value;
            });
          })
        ],),
        SizedBox(height: 10,),
        // 滑杆
        CustomSliderWithTextOnTrack(
                seekStart: () {},
                seekEnd: (String value) {
                  // _amountController.text = value;
                  // _amountEvent(_amountController.text);
                },
                amountList: [],
              )
      ],),
    );
  }
  
  // 频道名称输入框
  Widget _buildChannelNameField() {
    return Column(
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
    );
  }
  
  // 频道简介输入框
  Widget _buildChannelDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        Text(
          '频道简介',
          style: TextStyle(
            fontSize: 14,
            color: GbsColors.des1Color,
            fontWeight: FontWeight.w500,
          ),
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
            controller: _channelDescriptionController,
            style: TextStyle(
              fontSize: 16,
              color: GbsColors.des1Color,
            ),
            decoration: InputDecoration(
              hintText: '请输入频道说明',
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
    );
  }
  
  // 所属分类选择
  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        Text(
          '所属分类',
          style: TextStyle(
            fontSize: 14,
            color: GbsColors.des1Color,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        // 选择框
        GestureDetector(
          onTap: () {
            // TODO: 打开分类选择弹窗或页面
            // 这里暂时先不做具体实现，只提供一个占位
            _showSelCategoryChannelView();
          },
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: GbsColors.lightInputBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: GbsColors.lightDivider,
                width: 0.5,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedCategory.isEmpty ? '暂不选择' : _selectedCategory,
                  style: TextStyle(
                    fontSize: 14,
                    color: GbsColors.des1Color,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: GbsColors.des9Color,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 创建频道
  void _showSelCategoryChannelView(){
    gbs.shower.showScreenViewCustom(context, 400, Container(
      width: Get.width,
      clipBehavior: Clip.hardEdge,
       decoration: BoxDecoration(
        color: GbsColors.lightAppBarColorA,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12))
      ),
      child: ChannelCategorySelView(
        selectedCategory: _selectedCategory.isEmpty ? -1 : int.parse(_selectedCategory) ,
        onConfirm:   (value) {
        if (mounted) {
          setState(() {
            _selectedCategory = value.toString();
          });
        }
      }),
    ));
  }
}
