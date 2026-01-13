import 'package:bell_bird_talk/config/global.dart';
import 'package:bell_bird_talk/controllers/community_controller.dart';
import 'package:bell_bird_talk/pages/community/models/community_model.dart';
import 'package:bell_bird_talk/pages/community/views/community_member_operate_view.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:bell_bird_talk/widgets/common_appbar_view.dart';
import 'package:bell_bird_talk/widgets/empty_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class CommunityMemberBanPage extends StatefulWidget {
  final String? cmtyId; // 社群ID（可选，如果未提供则从全局获取）

  const CommunityMemberBanPage({super.key, this.cmtyId});

  @override
  State<StatefulWidget> createState() {
    return CommunityMemberBanPageState();
  }
}

class CommunityMemberBanPageState extends State<CommunityMemberBanPage> {
  final CommunityController _controller = CommunityController.to;
  final RefreshController _refreshController = RefreshController(
    initialRefresh: false,
  );

  List<CommunityMemberModel> _members = [];
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _cmtyId;

  @override
  void initState() {
    super.initState();
    // 获取社群ID：优先使用传入的参数，否则从全局状态获取
    _cmtyId = widget.cmtyId ?? _getCurrentCommunityId();
    _loadMembers(isRefresh: true);
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  /// 获取当前社群ID（从全局状态或其他地方获取）
  String? _getCurrentCommunityId() {
    // 尝试从 CommunityController 获取当前社群ID
    // 如果 CommunityController 有当前选中的社群，可以从那里获取
    // 这里暂时返回 null，需要从外部传入
    return null;
  }

  /// 加载成员列表
  Future<void> _loadMembers({bool isRefresh = false}) async {
    if (_isLoading || _cmtyId == null || _cmtyId!.isEmpty) {
      if (isRefresh) {
        _refreshController.refreshCompleted();
      } else {
        _refreshController.loadComplete();
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      int page = isRefresh ? 1 : _currentPage;

      final members = await _controller.getCommunityBannedMembers(
        cmtyId: _cmtyId!,
        page: page,
        pageSize: _pageSize,
      );

      setState(() {
        if (isRefresh) {
          _members = members;
          _currentPage = 2;
          _hasMore = members.length >= _pageSize;
        } else {
          _members.addAll(members);
          _currentPage++;
          _hasMore = members.length >= _pageSize;
        }
        _isLoading = false;
      });

      if (isRefresh) {
        _refreshController.refreshCompleted();
      } else {
        if (_hasMore) {
          _refreshController.loadComplete();
        } else {
          _refreshController.loadNoData();
        }
      }
    } catch (e) {
      print('加载成员列表失败: $e');
      setState(() {
        _isLoading = false;
      });

      if (isRefresh) {
        _refreshController.refreshFailed();
      } else {
        _refreshController.loadFailed();
      }

      EasyLoading.showError('加载失败，请稍后重试');
    }
  }

  /// 下拉刷新
  void _onRefresh() {
    _loadMembers(isRefresh: true);
  }

  /// 上拉加载更多
  void _onLoading() {
    _loadMembers(isRefresh: false);
  }

  @override
  Widget build(BuildContext context) {
    if (_cmtyId == null || _cmtyId!.isEmpty) {
      return Scaffold(
        backgroundColor: GbsColors.lightBackgroundB,
        appBar: CommonAppBarView(
          title: '封禁用户',
          backgroundColor: GbsColors.lightBackgroundB,
        ),
        body: Center(
          child: Text('未选择社群', style: TextStyle(color: GbsColors.des6Color)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: GbsColors.lightBackgroundB,
      appBar: CommonAppBarView(
        title: '封禁用户',
        backgroundColor: GbsColors.lightBackgroundB,
      ),
      body: SmartRefresher(
        controller: _refreshController,
        enablePullDown: true,
        enablePullUp: _hasMore,
        onRefresh: _onRefresh,
        onLoading: _onLoading,
        header: const ClassicHeader(
          refreshingText: '正在刷新...',
          completeText: '刷新完成',
          idleText: '下拉刷新',
          releaseText: '释放刷新',
        ),
        footer: ClassicFooter(
          loadingText: '正在加载...',
          noDataText: '没有更多数据',
          canLoadingText: '释放加载',
          idleText: '上拉加载更多',
        ),
        child: _buildCard([
          Expanded(
            child: _members.isEmpty
                ? _buildEmptyView()
                : ListView.builder(
                    itemCount: _members.length,
                    itemBuilder: (BuildContext context, int index) {
                      final member = _members[index];
                      final avatar = member.avatar;
                      final roleText = member.roleText;

                      return _buildElement(
                        member.nickname!,
                        member.username,
                        avatar,
                        roleText,
                        () {
                          gbs.shower.showScreenViewCustom(
                            context,
                            400,
                            Container(
                              clipBehavior: Clip.hardEdge,
                              decoration: BoxDecoration(
                                color: GbsColors.lightBackgroundB,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                              ),
                              child: CommunityMemberOperateView(
                                member: member,
                                onConfirm: (index) {
                                  switch (index) {
                                    case 1:
                                      CommunityController.to
                                          .muteCommunityMember(
                                            _cmtyId!,
                                            member.id,
                                            true,
                                          );
                                      break;
                                    case 2:
                                    CommunityController.to.kickCommunityMember(_cmtyId!, member.id);
                                      break;
                                    case 3:
                                      break;
                                    default:
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }

  /// 空状态视图
  Widget _buildEmptyView() {
    return Center(child: EmptyView(community: true));
  }

  // 分割线
  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.only(left: 16, top: 10),
      height: 0.8,
      color: GbsColors.lightDivider,
    );
  }

  // 元素
  Widget _buildElement(
    String nickname,
    String username,
    String? avatarUrl,
    String? roleText,
    VoidCallback tap,
  ) {
    return InkWell(
      onTap: tap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: GbsColors.lightDivider,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: avatarUrl != null && avatarUrl.isNotEmpty
                        ? CachedNetworkImage(
                            fit: BoxFit.fill,
                            imageUrl: avatarUrl,
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.person, size: 20),
                          )
                        : const Icon(Icons.person, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            nickname,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: GbsColors.des1Color,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: GbsColors.des6Color,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  // margin: const EdgeInsets.only(right: 12),
                  width: 72.w,
                  height: 28.h,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(width: 1, color: GbsColors.primaryColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                      '申请解封',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: GbsColors.primaryColor,
                    ),
                  ),
                ),
                // Icon(Icons.chevron_right, color: GbsColors.des6Color),
              ],
            ),
            _buildDivider(),
          ],
        ),
      ),
    );
  }

  // 卡片
  Widget _buildCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric( vertical: 8),
      padding: const EdgeInsets.all(12),
      // decoration: BoxDecoration(
      //   color: GbsColors.lightBackgroundB,
      //   borderRadius: BorderRadius.circular(12),
      // ),
      child: Column(children: children),
    );
  }
}
