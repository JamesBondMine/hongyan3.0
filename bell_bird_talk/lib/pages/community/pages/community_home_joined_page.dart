import 'package:bell_bird_talk/controllers/global_controller.dart';
import 'package:bell_bird_talk/pages/community/models/community_model.dart';
import 'package:bell_bird_talk/pages/community/pages/community_child_page.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:flutter/material.dart';

class CommunityHomeJoinedPage extends StatefulWidget {
  const CommunityHomeJoinedPage({Key? key}) : super(key: key);

  @override
  _CommunityHomeJoinedPageState createState() =>
      _CommunityHomeJoinedPageState();
}

class _CommunityHomeJoinedPageState extends State<CommunityHomeJoinedPage> {
  int _selectedCommunityIndex = 0;
  List<CommunityModel> communities = []; // 示例社群列表

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    communities = GlobalController.to.joinedCommunitys;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GbsColors.lightBackgroundA,
      body: Row(
        children: [
          // 左侧社群列表
          Container(
            width: 64,
            color: GbsColors.lightBackgroundA,
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
          // 右侧内容
          Expanded(child: CommunityChildPage()),
        ],
      ),
    );
  }
}
