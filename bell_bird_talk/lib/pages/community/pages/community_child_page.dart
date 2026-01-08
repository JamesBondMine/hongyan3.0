import 'package:bell_bird_talk/config/global.dart';
import 'package:bell_bird_talk/pages/community/models/community_model.dart';
import 'package:bell_bird_talk/pages/community/pages/community_invate_page.dart';
import 'package:bell_bird_talk/pages/community/pages/community_search_page.dart';
import 'package:bell_bird_talk/pages/community/pages/community_setting_page.dart';
import 'package:bell_bird_talk/pages/community/views/category_setting_view.dart';
import 'package:bell_bird_talk/pages/community/views/channel_create_view.dart';
import 'package:bell_bird_talk/pages/community/views/channel_edit_view.dart';
import 'package:bell_bird_talk/pages/community/views/channel_setting_view.dart';
import 'package:bell_bird_talk/pages/community/views/community_noti_setting_view.dart';
import 'package:bell_bird_talk/pages/community/views/community_pri_setting_view.dart';
import 'package:bell_bird_talk/pages/community/views/community_setting_view.dart';
import 'package:bell_bird_talk/pages/friends/views/friend_remark_view.dart';
import 'package:bell_bird_talk/services/native_bridge.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:bell_bird_talk/controllers/community_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

class CommunityChildPage extends StatefulWidget {
  final CommunityModel? cmty; // 社群ID（可选，可以从路由参数获取）
  
  const CommunityChildPage({super.key, this.cmty});

  @override
  State<StatefulWidget> createState() {
    return CommunityChildPageState();
  }
}

class CommunityChildPageState extends State<CommunityChildPage> {
  final IOSNativeService _nativeService = IOSNativeService();
  final CommunityController _controller = CommunityController.to;

  Map<String, List<String>> categories = {
    '文字频道': ['情感频道', '理财频道', '科技频道'],
    '语音频道': ['语音聊天1', '语音聊天2'],
    '分类C': ['频道5', '频道6'],
  };

  // 分组ID和分组名称的映射关系（用于创建频道时获取分组ID）
  Map<String, String> categoryIdMap = {}; // key: 分组名称, value: 分组ID

  // 使用分类名作为key管理展开状态（手风琴效果：一次只能展开一个）
  String? _expandedCategory;


  CommunityModel? _cmty;

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
  void initState() {
    super.initState();
  }

  void refreshCommunityInfo(CommunityModel cmty) {
    _loadGroupsAndChannels(cmty);
  }

  /// 加载分组和频道数据
  Future<void> _loadGroupsAndChannels(CommunityModel cmty) async {

    try {
      EasyLoading.show(status: '加载中...');
      final result = await _controller.getCommunityGroupsWithChannels(
        cmtyId: cmty.id,
      );
      
      if (result['categories'] != null && (result['categories'] as Map).isNotEmpty) {
        setState(() {
          categories = Map<String, List<String>>.from(result['categories']);
          categoryIdMap = Map<String, String>.from(result['categoryIdMap'] ?? {});
        });
      } else {
        print('⚠️ 未获取到分组和频道数据');
      }
    } catch (e) {
      print('❌ 加载分组和频道数据失败: $e');
      EasyLoading.showError('加载失败');
    } finally {
      EasyLoading.dismiss();
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
                    onTap: () {
                      _showCommunitySettingView();
                    },
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

  // 编辑频道
  void _showChannelEditView(String channel) {
    gbs.shower.showScreenViewCustom(
      context,
      Get.height - 260,
      Container(
        width: Get.width,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: GbsColors.lightAppBarColorA,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: ChannelEditView(onConfirm: (value) {}, channelId: channel),
      ),
    );
  }

  // 频道设置
  void _showChannelSettingView(String channel) {
    gbs.shower.showScreenViewCustom(
      context,
      Get.height - 260,
      Container(
        width: Get.width,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: GbsColors.lightAppBarColorA,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: ChannelSettingView(
          channelId: channel,
          onConfirm: (value) {
            switch (value) {
              case 1:
                _showAddMemberView();
                break;
              case 2:
                // 复制链接
                Clipboard.setData(
                  ClipboardData(text: 'https://example.com'),
                ).then((value) {
                  Get.snackbar('复制成功', '链接已复制到剪贴板');
                });

                break;
              case 3:
                // 编辑频道
                _showChannelEditView(channel);
                break;
              case 4:
                // 删除频道
                _showDeleteChannelView(channel);
                break;
              case 5:
                // 创建文字频道
                _showCreateChannelView(true);
                break;
              case 6:
                // 频道通知
                _showSettingNotiWithCommunityView();
                break;
            }
          },
        ),
      ),
    );
  }

  // 社群设置
  void _showCommunitySettingView() {
    gbs.shower.showScreenViewCustom(
      context,
      Get.height - 150,
      Container(
        width: Get.width,
        // padding: EdgeInsets.only(top: 12),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: GbsColors.lightAppBarColorA,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: CommunitySettingView(
          onConfirm: (value) {
            switch (value) {
              case 1:
                _showAddMemberView();
                break;
              case 2:
                // 处理社群设置
                Get.to(CommunitySettingPage());
                break;
              case 3:
                // 处理创建频道
                _showCreateChannelView(false);
                break;
              case 4:
                // 处理创建分类
                _showCreateCategoryView();
                break;
              case 5:
                // 处理通知设置
                _showSettingNotiWithCommunityView();
                break;
              case 6:
                // 处理隐私设置
                _showPrivacySettingView();
                break;
              case 7:
                // 处理离开社群
                _showLeaveCommunityView();
                break;
            }
          },
        ),
      ),
    );
  }

  // 删除频道
  void _showDeleteChannelView(String channel) async {
    final result = await _nativeService.showNativeAlert(
      title: '删除频道',
      message: '确定要删除此频道吗？',
      confirmText: '删除',
      cancelText: '取消',
      showCancel: true,
    );

    if (result != null && result['action'] == 'confirm') {
      EasyLoading.showSuccess('success');
    }
  }

  // 离开社群
  void _showLeaveCommunityView() async {
    final result = await _nativeService.showNativeAlert(
      title: '退出登录',
      message: '确定要退出当前账号吗？',
      confirmText: '退出',
      cancelText: '取消',
      showCancel: true,
    );

    if (result != null && result['action'] == 'confirm') {
      EasyLoading.showSuccess('success');
    }
  }

  // 隐私设置--CommunityPriSettingView
  void _showPrivacySettingView() {
    gbs.shower.showScreenViewCustom(
      context,
      360,
      Container(
        width: Get.width,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: GbsColors.lightAppBarColorA,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: CommunityPriSettingView(
          selectedCategory: 0,
          onConfirm: (value) {},
        ),
      ),
    );
  }

  // 通知设置
  void _showSettingNotiWithCommunityView() {
    gbs.shower.showScreenViewCustom(
      context,
      400,
      Container(
        width: Get.width,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: GbsColors.lightAppBarColorA,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: CommunityNotiSettingView(
          selectedCategory: 0,
          onConfirm: (value) {},
        ),
      ),
    );
  }

  // 创建分类
  void _showCreateCategoryView() {
    final controller = TextEditingController(text: '');
    // 新增分组
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: FriendRemarkView(
            controller: controller,
            tip: '请输入分类名称',
            title: '分类名称',
            onTap: () async {
              final gname = controller.text.trim();
              Navigator.pop(context);

              EasyLoading.show(status: '正在创建分组...');

              // try {
              //   final result = await _nativeService.imCreateContactGroup(
              //     groupName: gname,
              //   );
              //   if (result['errorCode'] == 0) {
              //     // 刷新分组列表
              //     await _loadFriendGroups(refresh: true);
              //     EasyLoading.showSuccess('分组创建成功');
              //   } else {
              //     EasyLoading.showError(result['message'] ?? '创建失败');
              //   }
              // } catch (e) {
              //   print('创建分组错误: $e');
              //   EasyLoading.showError('创建失败，请稍后重试');
              // }
            },
          ),
        );
      },
    );
  }

  // 创建频道
  void _showCreateChannelView(bool onlyTextChannel) {
    gbs.shower.showScreenViewCustom(
      context,
      Get.height - 120,
      Container(
        width: Get.width,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: GbsColors.lightAppBarColorA,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: ChannelCreateView(
          onlyTextChannel: onlyTextChannel,
          onConfirm: (channelData) async {
            if (channelData == null) return;
            
            // 获取当前社群信息
            final cmty = widget.cmty ?? _cmty;
            if (cmty == null) {
              EasyLoading.showError('未选择社群');
              return;
            }
            
            // 获取分类ID（如果用户选择了分类）
            // channelData['categoryId'] 是分类索引（int转String），需要从分组列表中获取对应的分组ID
            String categoryId = channelData['categoryId'] as String? ?? '';
            try {
              EasyLoading.show(status: '创建中...');
              
              final success = await _controller.createChannel(
                cmtyId: cmty.id,
                categoryId: categoryId,
                channelName: channelData['channelName'] as String,
                channelType: channelData['channelType'] as int,
                description: channelData['description'] as String?,
                maxMembers: channelData['maxMembers'] as int?,
              );
              
              if (success) {
                EasyLoading.showSuccess('创建成功');
                await _loadGroupsAndChannels(cmty);
              } else {
                EasyLoading.showError('创建失败');
              }
            } catch (e) {
              print('❌ 创建频道失败: $e');
              EasyLoading.showError('创建失败');
            }
          },
        ),
      ),
    );
  }

  // 邀请好友
  void _showAddMemberView() {
    gbs.shower.showScreenViewCustom(
      context,
      Get.height - 150,
      Container(
        width: Get.width,
        // padding: EdgeInsets.only(top: 12),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: GbsColors.lightAppBarColorA,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: CommunityInvatePage(
          onConfirm: (value) {
            if (value.isNotEmpty) {
              // 添加群成员
              // _showAddMemberDialog(value);
            }
          },
        ),
      ),
    );
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
      title: GestureDetector(
        onLongPress: () {
          // 分类设置
          _showCategorySettingView(category);
        },
        child: Container(
          child: Text(
            category,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: GbsColors.lightTitlePrimary,
            ),
          ),
        ),
      ),
      children: channels
          .map((channel) => _buildChannelItem(category, channel))
          .toList(),
    );
  }

  // 分类设置
  void _showCategorySettingView(String channel) {
    gbs.shower.showScreenViewCustom(
      context,
      300,
      Container(
        width: Get.width,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: GbsColors.lightAppBarColorA,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: CategorySettingView(
          channelId: channel,
          onConfirm: (value) async {
            if (value == 2) {
              final result = await _nativeService.showNativeAlert(
                title: '删除频道',
                message: '确定要删除此频道吗？',
                confirmText: '删除',
                cancelText: '取消',
                showCancel: true,
              );

              if (result != null && result['action'] == 'confirm') {
                EasyLoading.showSuccess('success');
              }
              return;
            }
            // 编辑分类
            _showEditCategoryView(channel);
          },
        ),
      ),
    );
  }

  // 编辑分类
  void _showEditCategoryView(String channel) {
    final controller = TextEditingController(text: '');
    // 新增分组
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: FriendRemarkView(
            controller: controller,
            tip: '请输入分类名称',
            title: '编辑分类',
            name: '分类名称',
            needCancel: false,
            onTap: () async {
              final gname = controller.text.trim();
              Navigator.pop(context);

              EasyLoading.show(status: '正在创建分组...');

              // try {
              //   final result = await _nativeService.imCreateContactGroup(
              //     groupName: gname,
              //   );
              //   if (result['errorCode'] == 0) {
              //     // 刷新分组列表
              //     await _loadFriendGroups(refresh: true);
              //     EasyLoading.showSuccess('分组创建成功');
              //   } else {
              //     EasyLoading.showError(result['message'] ?? '创建失败');
              //   }
              // } catch (e) {
              //   print('创建分组错误: $e');
              //   EasyLoading.showError('创建失败，请稍后重试');
              // }
            },
          ),
        );
      },
    );
  }

  /// 构建频道项
  Widget _buildChannelItem(String category, String channel) {
    return InkWell(
      onLongPress: () {
        _showChannelSettingView(channel);
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
