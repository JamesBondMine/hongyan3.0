import 'package:bell_bird_talk/config/global.dart';
import 'package:bell_bird_talk/controllers/community_controller.dart';
import 'package:bell_bird_talk/pages/community/models/community_model.dart';
import 'package:bell_bird_talk/pages/community/views/community_member_operate_view.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:bell_bird_talk/widgets/common_appbar_view.dart';
import 'package:bell_bird_talk/widgets/empty_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class CmtMemberListPage extends StatefulWidget {
  final String? cmtyId; // 社群ID（可选，如果未提供则从全局获取）

  const CmtMemberListPage({super.key, this.cmtyId});

  @override
  State<StatefulWidget> createState() {
    return CmtMemberListPageState();
  }
}

class CmtMemberListPageState extends State<CmtMemberListPage> {
  final CommunityController _controller = CommunityController.to;
  final RefreshController _refreshController = RefreshController(
    initialRefresh: false,
  );

  final TextEditingController _searchController = TextEditingController();

  List<CommunityMemberModel> _members = [];
  List<CommunityMemberModel> _filteredMembers = [];
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
    // 监听搜索框文本变化
    _searchController.addListener(_filterMembers);
    _loadMembers(isRefresh: true);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterMembers);
    _searchController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  /// 根据搜索关键字过滤成员列表
  void _filterMembers() {
    final keyword = _searchController.text.toLowerCase().trim();
    
    setState(() {
      if (keyword.isEmpty) {
        _filteredMembers = _members;
      } else {
        _filteredMembers = _members.where((member) {
          final nickname = member.nickname?.toLowerCase() ?? '';
          final username = member.username.toLowerCase();
          return nickname.contains(keyword) || username.contains(keyword);
        }).toList();
      }
    });
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

      final members = await _controller.getCommunityMembers(
        cmtyId: _cmtyId!,
        page: page,
        pageSize: _pageSize,
      );

      setState(() {
        if (isRefresh) {
          _members = members;
          _filteredMembers = members;
          _currentPage = 2;
          _hasMore = members.length >= _pageSize;
        } else {
          _members.addAll(members);
          // 重新过滤以获得正确的结果
          _filterMembers();
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
    return Scaffold(
      backgroundColor: GbsColors.lightBackgroundA,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) {
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: '搜索成员昵称或用户名',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(26),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: GbsColors.lightBackgroundB,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _bodyVoew()),
        ],
      ),
    );
  }

  Widget _bodyVoew() {
    return SmartRefresher(
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
          child: _filteredMembers.isEmpty
              ? _buildEmptyView()
              : ListView.builder(
                  itemCount: _filteredMembers.length,
                  itemBuilder: (BuildContext context, int index) {
                    final member = _filteredMembers[index];
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
                                    CommunityController.to.muteCommunityMember(
                                      _cmtyId!,
                                      member.id,
                                      true,
                                    );
                                    break;
                                  case 2:
                                    CommunityController.to.kickCommunityMember(
                                      _cmtyId!,
                                      member.id,
                                    );
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
    );
  }

  /// 空状态视图
  Widget _buildEmptyView() {
    return Center(child: EmptyView(community: true));
  }

  // 分割线
  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.only(left: 36, top: 10),
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
                            style: const TextStyle(
                              fontSize: 16,
                              color: GbsColors.des1Color,
                            ),
                          ),
                          if (roleText != null && roleText.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: GbsColors.des6Color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                roleText,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: GbsColors.des6Color,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        username,
                        style: const TextStyle(
                          fontSize: 14,
                          color: GbsColors.des6Color,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: GbsColors.des6Color),
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GbsColors.lightBackgroundB,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }
}
