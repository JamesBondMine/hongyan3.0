import 'package:bell_bird_talk/config/global.dart';
import 'package:bell_bird_talk/pages/community/pages/community_invate_page.dart';
import 'package:bell_bird_talk/pages/community/pages/community_search_page.dart';
import 'package:bell_bird_talk/pages/community/views/community_setting_view.dart';
import 'package:bell_bird_talk/pages/friends/pages/select_friend_with_group_page.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CommunityChildPage extends StatefulWidget {
  const CommunityChildPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _CommunityChildPageState();
  }
}

class _CommunityChildPageState extends State<CommunityChildPage> {
  Map<String, List<String>> categories = {
    '文字频道': ['情感频道', '理财频道', '科技频道'],
    '语音频道': ['语音聊天1', '语音聊天2'],
    '分类C': ['频道5', '频道6'],
  };

  // 使用分类名作为key管理展开状态（手风琴效果：一次只能展开一个）
  String? _expandedCategory;

  // 分类图标映射
  Map<String, IconData> categoryIcons = {
    '文字频道': Icons.book,
    '语音频道': Icons.mic,
    '分类C': Icons.category,
  };

  // 获取频道图标
  IconData getChannelIcon(String category, String channel) {
    if (category == '文字频道') {
      return Icons.tag; // # 符号
    } else if (category == '语音频道') {
      return Icons.volume_up;
    } else {
      return Icons.chat;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: GbsColors.lightBackgroundA,
        body: Container(
          decoration: BoxDecoration(
            color: GbsColors.lightBackgroundB,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(36)),
          ),
          child: _bodyView(),
        ),
      ),
    );
  }

  Widget _bodyView() {
    return Column(
      children: [
        // 头部
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: GbsColors.lightDivider, width: 0.5),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {},
                    child: Padding(
                      padding: EdgeInsets.only(top: 16, bottom: 16),
                      child: Row(
                        children: [
                          Text(
                            '服务器选择',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CommunitySearchPage(),
                          ),
                        );
                      },
                      child: Container(
                        height: 32,
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              '搜索',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      // 处理添加频道点击
                      _showAddMemberView();
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Image.asset(
                        width: 32,
                        height: 32,
                        'assets/img/community/cunty_add.png',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // 分类列表
        Expanded(
          child: ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories.keys.elementAt(index);
              final channels = categories[category]!;
              final isExpanded = _expandedCategory == category;

              return _buildCategorySection(category, channels, isExpanded);
            },
          ),
        ),
      ],
    );
  }

  // 频道设置
  void _showChannelSettingView(){
    gbs.shower.showScreenViewCustom(context, Get.height-150, Container(
      width: Get.width,
      // padding: EdgeInsets.only(top: 12),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: GbsColors.lightAppBarColorA,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12))
      ),
      child: CommunitySettingView(onConfirm: (value) {
        switch (value) {
          case 1:
            _showAddMemberView();
            break;
          case 2:
            // 处理社群设置
            break;
          case 3:
            // 处理创建频道
            break;
          case 4:
            // 处理创建分类
            break;
          case 5:
            // 处理通知设置
            break;
          case 6:
            // 处理隐私设置
            break;
          case 7:
            // 处理离开社群
            break;
        }
        
      },),
    ));
  }

  // 邀请好友
  void _showAddMemberView(){
    gbs.shower.showScreenViewCustom(context, Get.height-150, Container(
      width: Get.width,
      // padding: EdgeInsets.only(top: 12),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: GbsColors.lightAppBarColorA,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12))
      ),
      child: CommunityInvatePage(onConfirm: (value) {
        if (value.isNotEmpty) {
          // 添加群成员
          // _showAddMemberDialog(value);
        }
        
      },),
    ));
  }

  /// 构建分类区域
  Widget _buildCategorySection(
    String category,
    List<String> channels,
    bool isExpanded,
  ) {
    return ExpansionTile(
      key: ValueKey('category_$category'),
      initiallyExpanded: false,
      backgroundColor: GbsColors.lightBackgroundB,
      collapsedBackgroundColor: GbsColors.lightBackgroundB,
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      childrenPadding: EdgeInsets.zero,
      shape: ShapeBorder.lerp(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        0,
      ),
      onExpansionChanged: (expanded) {
        setState(() {
          if (expanded) {
            _expandedCategory = category; // 展开当前分类
          } else {
            _expandedCategory = null; // 关闭当前分类
          }
        });
      },
      // leading: Icon(
      //   categoryIcons[category] ?? Icons.category,
      //   color: GbsColors.lightTitlePrimary,
      //   size: 20,
      // ),
      title: Text(
        category,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: GbsColors.lightTitlePrimary,
        ),
      ),
      // subtitle: Text(
      //   '${channels.length}个频道',
      //   style: TextStyle(
      //     fontSize: 12,
      //     color: GbsColors.des6Color,
      //   ),
      // ),
      children: channels
          .map((channel) => _buildChannelItem(category, channel))
          .toList(),
    );
  }

  /// 构建频道项
  Widget _buildChannelItem(String category, String channel) {
    return InkWell(
      onLongPress: () {
        _showChannelSettingView();
      },
      onTap: () {
        // 处理频道点击
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('点击了 $channel')));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: GbsColors.lightBackgroundB,
          border: Border(
            bottom: BorderSide(color: GbsColors.lightDivider, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              getChannelIcon(category, channel),
              size: 16,
              color: GbsColors.des6Color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                channel,
                style: TextStyle(
                  fontSize: 14,
                  color: GbsColors.lightTitlePrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
