import 'package:bell_bird_talk/config/global.dart';
import 'package:bell_bird_talk/controllers/community_controller.dart';
import 'package:bell_bird_talk/pages/community/models/community_model.dart';
import 'package:bell_bird_talk/pages/community/pages/community_child_page.dart';
import 'package:bell_bird_talk/pages/community/views/community_preview_view.dart';
import 'package:bell_bird_talk/services/native_bridge.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class CommunityHomeJoinedPage extends StatefulWidget {
  const CommunityHomeJoinedPage({Key? key}) : super(key: key);

  @override
  _CommunityHomeJoinedPageState createState() =>
      _CommunityHomeJoinedPageState();
}

class _CommunityHomeJoinedPageState extends State<CommunityHomeJoinedPage> {
  int _selectedCommunityIndex = 0;
  List<CommunityModel> communities = []; // 示例社群列表

  final RefreshController _refreshController = RefreshController(
    initialRefresh: false,
  );
  final CommunityController _communityController = CommunityController.to;
  final IOSNativeService _nativeService = IOSNativeService();

  int _currentPage = 1;
  final int _pageSize = 12;
  bool _isLoading = false;
  bool _hasMore = true;

  // 当前社群详情
  // 子页面刷新
  final GlobalKey<CommunityChildPageState> _communityChildPageKey = GlobalKey();
  CommunityModel? currentCommunityInfo;

  @override
  void initState() {
    super.initState();
    _loadCommunities();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  /// 加载社群列表
  Future<void> _loadCommunities({bool isRefresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      int page = isRefresh ? 1 : _currentPage;
      List<CommunityModel> newCommunities = await _communityController
          .getCommunityList(page: page, pageSize: _pageSize);

      setState(() {
        if (isRefresh) {
          communities = newCommunities;
          _currentPage = 2;
          _hasMore = newCommunities.length >= _pageSize;
        } else {
          communities.addAll(newCommunities);
          _currentPage++;
          _hasMore = newCommunities.length >= _pageSize;
        }
      });

      if (isRefresh) {
        _refreshController.refreshCompleted();
      } else {
        _refreshController.loadComplete();
      }
      // 如果 加载成功有社群数据--则请求当前社群的详情信息
      if (newCommunities.isNotEmpty) {
        currentCommunityInfo = newCommunities.first;
        // currentCommunityInfo = await _communityController.getCommunityInfo(
        //   cmtyId: newCommunities.first.id,
        // );
        // 刷新社群详情
        _communityChildPageKey.currentState?.refreshCommunityInfo(
          currentCommunityInfo!,
        );
      }
    } catch (e) {
      print('加载社群列表失败: $e');
      if (isRefresh) {
        _refreshController.refreshFailed();
      } else {
        _refreshController.loadFailed();
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 下拉刷新
  Future<void> _onRefresh() async {
    await _loadCommunities(isRefresh: true);
  }

  /// 上拉加载更多
  Future<void> _onLoading() async {
    if (_hasMore) {
      await _loadCommunities(isRefresh: false);
    } else {
      _refreshController.loadNoData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GbsColors.lightBackgroundA,
      body: Row(
        children: [
          // 左侧社群列表
          _buildCommunityList(),
          // 右侧内容
          Expanded(
            child: CommunityChildPage(
              key: _communityChildPageKey,
              cmty: currentCommunityInfo,
              onCommunityChange: () {
                _refreshController.requestRefresh();
              },
            ),
          ),
        ],
      ),
    );
  }

  // 左侧社群列表
  Widget _buildCommunityList() {
    return SafeArea(
      child: Container(
        width: 64,
        color: GbsColors.lightBackgroundA,
        child: SmartRefresher(
          controller: _refreshController,
          onRefresh: _onRefresh,
          onLoading: _onLoading,
          enablePullUp: true,
          header: const ClassicHeader(
            idleText: '',
            releaseText: '',
            refreshingText: '',
            completeText: '',
            failedText: '',
          ),
          footer: const ClassicFooter(
            idleText: '',
            loadingText: '',
            noDataText: '',
            failedText: '',
            canLoadingText: '',
          ),
          child: ListView.builder(
            itemCount: communities.length,
            itemBuilder: (context, index) {
              bool isSelected = index == _selectedCommunityIndex;

              bool needLine = false;
              // 判断是否需要添加横线-如果不是最后一个社群、并且当前社群已加入下一个社群未加入、则显示分割线
              if (index < communities.length - 1 &&
                  communities[index].isJoined &&
                  !communities[index + 1].isJoined) {
                needLine = true;
              }

              CommunityModel cm = communities[index];
              return GestureDetector(
                onTap: () async {
                  if (cm.isJoined == false) {
                    // 弹出社群预览
                    _showCommunitySettingView(cm);
                    return;
                  }

                  setState(() {
                    currentCommunityInfo = cm;
                    _selectedCommunityIndex = index;
                  });
                  _communityChildPageKey.currentState?.refreshCommunityInfo(cm);
                  currentCommunityInfo = await _communityController
                      .getCommunityInfo(cmtyId: cm.id);
                },
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                            color: isSelected
                                ? GbsColors.lightPrimaryButton
                                : Colors.transparent,
                          ),
                        ),
                        SizedBox(width: 6),
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: Container(
                            // padding: const EdgeInsets.all(8),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? GbsColors.lightPrimaryButton
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: cm.avatar != null && cm.avatar!.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: cm.avatar!,
                                      width: 32,
                                      fit: BoxFit.fill,
                                      errorWidget: (context, url, error) {
                                        return Image.asset(
                                          width: 32,
                                          height: 32,
                                          'assets/img/community/cunty_member.png',
                                        );
                                      },
                                    )
                                  : Image.asset(
                                      width: 32,
                                      height: 32,
                                      'assets/img/community/cunty_logo.png',
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // 如果需要 加载横线
                    if (needLine)
                      Container(
                        margin: EdgeInsets.only(
                          left: 12,
                          right: 12,
                          top: 10,
                          bottom: 6,
                        ),
                        height: 2,
                        color: Color.fromARGB(255, 194, 194, 194),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // 社群设置
  void _showCommunitySettingView(CommunityModel cm) {
    gbs.shower.showScreenViewCustom(
      context,
      350,
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
        child: CommunityPreviewView(
          onConfirm: () {
            _applyToJoin(cm);
          },
          community: cm,
        ),
      ),
    );
  }

  /// 申请加入社群
  Future<void> _applyToJoin(CommunityModel community) async {
    if (community.isJoined) {
      EasyLoading.showInfo('您已加入该社群');
      return;
    }

    if (community.hasApplied) {
      EasyLoading.showInfo('您已申请加入，请等待审核');
      return;
    }

    if (community.isFull) {
      EasyLoading.showError('该社群已满员');
      return;
    }

    final result = await _nativeService.showNativeAlert(
      title: '申请加入社群',
      message: '社群将会给你发消息',
      confirmText: '确认'.tr,
      cancelText: '取消'.tr,
      showCancel: true,
    );
    bool confirmed = result != null && result['action'] == 'confirm';

    if (confirmed == true) {
      EasyLoading.show(status: '正在申请...');
      bool res = await CommunityController.to.joinCommunity(
        cmtyId: community.id,
      );
      if (res == true) {
        EasyLoading.dismiss();
        EasyLoading.showSuccess('申请已提交，请等待审核');
        // 刷新页面
        _refreshController.requestRefresh();
      }
    }
  }
}
