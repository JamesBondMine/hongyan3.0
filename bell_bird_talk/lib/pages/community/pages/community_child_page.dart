import 'package:bell_bird_talk/config/global.dart';
import 'package:bell_bird_talk/controllers/global_controller.dart';
import 'package:bell_bird_talk/pages/community/models/community_model.dart';
import 'package:bell_bird_talk/pages/community/models/community_setting_model.dart';
import 'package:bell_bird_talk/pages/community/pages/community_invate_page.dart';
import 'package:bell_bird_talk/pages/community/pages/community_search_page.dart';
import 'package:bell_bird_talk/pages/community/pages/community_setting_page.dart';
import 'package:bell_bird_talk/pages/community/pages/voice_channel_page.dart';
import 'package:bell_bird_talk/pages/community/views/category_setting_view.dart';
import 'package:bell_bird_talk/pages/community/views/channel_create_view.dart';
import 'package:bell_bird_talk/pages/community/views/channel_edit_view.dart';
import 'package:bell_bird_talk/pages/community/views/channel_msg_setting_view.dart';
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
  VoidCallback onCommunityChange;
  CommunityChildPage({super.key, required this.onCommunityChange, this.cmty});

  @override
  State<StatefulWidget> createState() {
    return CommunityChildPageState();
  }
}

class CommunityChildPageState extends State<CommunityChildPage> {
  final IOSNativeService _nativeService = IOSNativeService();
  final CommunityController _controller = CommunityController.to;

  // 分组和频道数据
  CommunityGChannels? groupsWithChannels;

  // 兼容旧代码的访问方式
  List<CmtGroupModel> get categories => groupsWithChannels?.categories ?? [];
  Map<String, dynamic> get categoryIdMap =>
      groupsWithChannels?.categoryIdMap ?? {};

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
  String getChannelIcon(ChannelModel channel) {
    if (channel.channelType == 0) {
      return 'assets/img/community/channel_txt.png'; // # 符号
    }
    return 'assets/img/community/channel_voice.png';
  }

  @override
  void initState() {
    super.initState();
  }

  void refreshCommunityInfo(CommunityModel cmty) {
    _cmty = cmty;
    _loadGroupsAndChannels(cmty);
  }

  /// 加载分组和频道数据
  Future<void> _loadGroupsAndChannels(CommunityModel cmty) async {
    try {
      CommunityGChannels result = await _controller
          .getCommunityGroupsWithChannels(cmtyId: cmty.id);
      EasyLoading.dismiss();
      setState(() {
        _expandedCategory = '';
        groupsWithChannels = result;
      });
    } catch (e) {
      print('❌ 加载分组和频道数据失败: $e');
      EasyLoading.showError('加载失败'.tr);
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
    String? communityId = _cmty == null ? '' : _cmty!.name;
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
              SizedBox(
                width: Get.width - 110,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        _showCommunitySettingView();
                      },
                      child: Padding(
                        padding: EdgeInsets.only(top: 16, bottom: 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: Get.width - 140,
                              ),
                              child: Text(
                                communityId,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
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
                              '搜索'.tr,
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
              CmtGroupModel category = categories[index];
              // 如果是频道模式。则直接展示频道
              if (category.isChannel) {
                ChannelModel channel = ChannelModel(
                  channelId: category.id,
                  channelName: category.name,
                  channelType: 0,
                  communityId: category.communityId,
                );
                return _buildChannelItem(category.name, channel);
              }
              // 使用 model 的方法获取该分组下的频道列表
              List<ChannelModel> channels =
                  groupsWithChannels!.categoryIdMap[category.id] ?? [];
              // channels = groupsWithChannels?.getChannelsByCategory(category.id) ?? [];
              final isExpanded = _expandedCategory == category.id;

              return _buildCategorySection(category.name, channels, isExpanded);
            },
          ),
        ),
      ],
    );
  }

  // 编辑频道
  void _showChannelEditView(ChannelModel channel) {
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
        child: ChannelEditView(
          onConfirm: (value) {
            // 编辑成功后刷新
            _loadGroupsAndChannels(_cmty!);
          },
          channel: channel,
        ),
      ),
    );
  }

  // 频道设置
  void _showChannelSettingView(ChannelModel channel) {
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
          channel: channel,
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
                  Get.snackbar('复制成功'.tr, '链接已复制到剪贴板'.tr);
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
                _showSettingNotiWithCommunityView(false, channel);
                break;
              case 7:
                // 发言设置
                _showSettingSendMsgWithChannelView(true, channel);
                break;
            }
          },
        ),
      ),
    );
  }

  // 社群设置
  void _showCommunitySettingView() async {
    CommunitySettingsModel? resSetting = await CommunityController.to
        .loadCommunitySettings(_cmty!.id);
    if (resSetting == null) {
      return;
    }
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
          cmty: _cmty!,
          onConfirm: (value) {
            switch (value) {
              case 1:
                _showAddMemberView();
                break;
              case 2:
                // 处理社群设置
                Get.to(CommunitySettingPage(cmtyModel: _cmty!));
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
                _showSettingNotiWithCommunityView(true, null);
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
          cmtSetting: resSetting,
        ),
      ),
    );
  }

  // 删除频道
  void _showDeleteChannelView(ChannelModel channel) async {
    final result = await _nativeService.showNativeAlert(
      title: '删除频道'.tr,
      message: '确定要删除此频道吗？'.tr,
      confirmText: '删除'.tr,
      cancelText: '取消'.tr,
      showCancel: true,
    );

    if (result != null && result['action'] == 'confirm') {
      EasyLoading.show(status: '正在删除频道...'.tr);
      try {
        bool success = await _controller.deleteChannel(
          channelId: channel.channelId,
        );
        EasyLoading.dismiss();
        if (success) {
          // 刷新分组和频道列表
          if (_cmty != null) {
            await _loadGroupsAndChannels(_cmty!);
          }
          EasyLoading.showSuccess('删除成功'.tr);
        } else {
          EasyLoading.showError('删除失败'.tr);
        }
      } catch (e) {
        EasyLoading.dismiss();
        print('删除频道错误: $e');
        EasyLoading.showError('删除失败，请稍后重试'.tr);
      }
    }
  }

  // 离开社群
  void _showLeaveCommunityView() async {
    final currentUserId =  GlobalController.to.currentUser.value?.id ?? '';
    if (_cmty!.ownerId == currentUserId || _cmty!.ownerId.isEmpty) {
      EasyLoading.showToast('超管不能离开社群');
      return;
    }
    final result = await _nativeService.showNativeAlert(
      title: '离开社群'.tr,
      message: '确定要退出当前账号吗？离开后只能通过邀请链接进入'.tr,
      confirmText: '离开'.tr,
      cancelText: '取消'.tr,
      showCancel: true,
    );

    if (result != null && result['action'] == 'confirm') {
      CommunityController.to.leaveCommunity(cmtyId: _cmty!.id).then((success) {
        if (success) {
          widget.onCommunityChange();
        }
      });
    }
  }

  // 隐私设置--CommunityPriSettingView
  void _showPrivacySettingView() async {
    CommunitySettingsModel? resSetting = await CommunityController.to
        .loadCommunitySettings(_cmty!.id);
    if (resSetting == null) {
      return;
    }
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
          cmtSetting: resSetting,
          cmtyId: _cmty!.id,
          selectedCategory: 0,
          onConfirm: (value) {},
        ),
      ),
    );
  }

  // 发言设置
  void _showSettingSendMsgWithChannelView(bool cmty, ChannelModel? channel) {
    gbs.shower.showScreenViewCustom(
      context,
      Get.height - 150,
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
        child: ChannelMsgSettingView(ccmodel: channel!, cmtyId: _cmty!.id),
      ),
    );
  }

  // 通知设置
  void _showSettingNotiWithCommunityView(bool cmty, ChannelModel? channel) {
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
          onConfirm: (value) {
            if (cmty) {
              // 社群的通知设置
              EasyLoading.showError('更新社群通知'.tr);
              return;
            }
            // 频道的通知设置
            CommunityController.to
                .updateChannel(
                  channelId: channel!.channelId,
                  notificationType: value,
                )
                .then((value) {});
          },
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
            tip: '请输入分类名称'.tr,
            title: '分类名称'.tr,
            onTap: () async {
              final gname = controller.text.trim();
              Navigator.pop(context);

              EasyLoading.show(status: '正在创建分组...'.tr);

              try {
                bool result = await CommunityController.to.createChannelGroup(
                  cmtyId: _cmty!.id,
                  categoryName: gname,
                );
                EasyLoading.dismiss();
                if (result == true) {
                  // 刷新分组列表
                  _loadGroupsAndChannels(_cmty!);
                  EasyLoading.showSuccess('分组创建成功'.tr);
                } else {
                  EasyLoading.showError('创建失败'.tr);
                }
              } catch (e) {
                EasyLoading.dismiss();
                print('创建分组错误: $e');
                EasyLoading.showError('创建失败，请稍后重试'.tr);
              }
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
          communityId: _cmty!.id,
          onlyTextChannel: onlyTextChannel,
          onConfirm: (channelData) async {
            if (channelData == null) return;

            // 获取当前社群信息
            final cmty = widget.cmty ?? _cmty;
            if (cmty == null) {
              EasyLoading.showError('未选择社群'.tr);
              return;
            }

            // 获取分类ID（如果用户选择了分类）
            // channelData['categoryId'] 是分类索引（int转String），需要从分组列表中获取对应的分组ID
            String categoryId = channelData['categoryId'] as String? ?? '';
            try {
              EasyLoading.show(status: '创建中...'.tr);

              final success = await _controller.createChannel(
                cmtyId: cmty.id,
                categoryId: categoryId,
                channelName: channelData['channelName'] as String,
                channelType: channelData['channelType'] as int,
                description: channelData['description'] as String?,
                maxMembers: channelData['maxMembers'] as int?,
              );

              if (success) {
                EasyLoading.showSuccess('创建成功'.tr);
                await _loadGroupsAndChannels(cmty);
              } else {
                EasyLoading.showError('创建失败'.tr);
              }
            } catch (e) {
              print('❌ 创建频道失败: $e');
              EasyLoading.showError('创建失败'.tr);
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
    List<ChannelModel> channels,
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
      //   _expandedCategory == category ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
      //   color: GbsColors.lightTitlePrimary,
      //   size: 18,
      // ),
      trailing: const SizedBox.shrink(), // 隐藏右侧默认箭头
      title: Row(
        children: [
          Padding(
            padding: EdgeInsetsGeometry.only(right: 8),
            child: Icon(
              _expandedCategory == category
                  ? Icons.keyboard_arrow_down
                  : Icons.keyboard_arrow_right,
              color: GbsColors.lightTitlePrimary,
              size: 18,
            ),
          ),
          GestureDetector(
            onLongPress: () {
              // 分类设置
              _showCategorySettingView(category);
            },
            child: Text(
              category,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: GbsColors.lightTitlePrimary,
              ),
            ),
          ),
        ],
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
              // 删除分类
              final result = await _nativeService.showNativeAlert(
                title: '删除分类'.tr,
                message: '确定要删除此分类吗？'.tr,
                confirmText: '删除'.tr,
                cancelText: '取消'.tr,
                showCancel: true,
              );

              if (result != null && result['action'] == 'confirm') {
                // 根据分类名称找到对应的分类对象
                CmtGroupModel? category;
                try {
                  category = categories.firstWhere(
                    (cat) => cat.name == channel,
                  );
                } catch (e) {
                  category = null;
                }

                if (category == null || _cmty == null) {
                  EasyLoading.showError('分类不存在'.tr);
                  return;
                }

                EasyLoading.show(status: '正在删除分类...'.tr);
                try {
                  bool success = await _controller.deleteChannelGroup(
                    cmtyId: _cmty!.id,
                    categoryId: category.id,
                  );
                  EasyLoading.dismiss();
                  if (success) {
                    // 刷新分组和频道列表
                    await _loadGroupsAndChannels(_cmty!);
                    EasyLoading.showSuccess('删除成功'.tr);
                  } else {
                    EasyLoading.showError('删除失败'.tr);
                  }
                } catch (e) {
                  EasyLoading.dismiss();
                  print('删除分类错误: $e');
                  EasyLoading.showError('删除失败，请稍后重试'.tr);
                }
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
    final controller = TextEditingController(text: channel);
    // 编辑分组
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
            tip: '请输入分类名称'.tr,
            title: '编辑分类'.tr,
            name: '分类名称'.tr,
            needCancel: false,
            onTap: () async {
              final gname = controller.text.trim();
              if (gname.isEmpty) {
                EasyLoading.showError('分类名称不能为空'.tr);
                return;
              }
              Navigator.pop(context);

              // 根据分类名称找到对应的分类对象
              CmtGroupModel? category;
              try {
                category = categories.firstWhere((cat) => cat.name == channel);
              } catch (e) {
                category = null;
              }

              if (category == null || _cmty == null) {
                EasyLoading.showError('分类不存在'.tr);
                return;
              }

              EasyLoading.show(status: '正在更新分类...'.tr);
              try {
                bool success = await _controller.updateChannelGroup(
                  cmtyId: _cmty!.id,
                  categoryId: category.id,
                  categoryName: gname,
                );
                EasyLoading.dismiss();
                if (success) {
                  // 刷新分组和频道列表
                  await _loadGroupsAndChannels(_cmty!);
                  EasyLoading.showSuccess('更新成功'.tr);
                } else {
                  EasyLoading.showError('更新失败'.tr);
                }
              } catch (e) {
                EasyLoading.dismiss();
                print('更新分类错误: $e');
                EasyLoading.showError('更新失败，请稍后重试'.tr);
              }
            },
          ),
        );
      },
    );
  }

  /// 构建频道项
  Widget _buildChannelItem(String category, ChannelModel channel) {
    return InkWell(
      onLongPress: () {
        _showChannelSettingView(channel);
      },
      onTap: () {
        _enterChannel(channel);
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
            Image.asset(getChannelIcon(channel), width: 16, height: 16),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                channel.channelName,
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

  // 进入频道
  void _enterChannel(ChannelModel channel) async {
    if (channel.channelType == 1) {
      // 语音频道
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VoiceChannelPage(channel: channel),
        ),
      );
      return;
    }
    bool res = await CommunityController.to.enterChannel(
      channelId: channel.channelId,
    );
    if (res) {
      CommunityController.to.startChat(channel.channelId, channel.channelName);
    }
  }
}
