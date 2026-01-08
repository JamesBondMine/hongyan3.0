import 'package:bell_bird_talk/controllers/community_controller.dart';
import 'package:bell_bird_talk/pages/community/models/community_model.dart';
import 'package:bell_bird_talk/pages/community/pages/community_child_page.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:flutter/material.dart';
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
  
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  final CommunityController _communityController = CommunityController.to;
  
  int _currentPage = 1;
  final int _pageSize = 12;
  bool _isLoading = false;
  bool _hasMore = true;

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
      List<CommunityModel> newCommunities = await _communityController.getCommunityList(
        page: page,
        pageSize: _pageSize,
      );

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
          Expanded(child: CommunityChildPage()),
        ],
      ),
    );
  }

  // 左侧社群列表
  Widget _buildCommunityList() { 
    return SafeArea(child: Container(
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
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCommunityIndex = index;
                      });
                    },
                    child: Row(
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
                        SizedBox(width: 6,),
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
                              child: Image.asset(
                                width: 32,
                                height: 32,
                                'assets/img/community/cunty_logo.png',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),);
  }
}
