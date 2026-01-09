import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:bell_bird_talk/widgets/common_appbar_view.dart';
import 'package:flutter/material.dart';

class CommunityRolesPage extends StatefulWidget {
  const CommunityRolesPage({Key? key}) : super(key: key);

  @override
  State<CommunityRolesPage> createState() => CommunityChildPageState();
}

class CommunityChildPageState extends State<CommunityRolesPage> {
  bool valueCheckChannel = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GbsColors.lightBackgroundA,
      appBar: CommonAppBarView(title: '角色权限管理'),
      body: ListView(
        padding: EdgeInsets.all(0),
        children: [
          _buildRoleCard(),
          _buildTitle('通用社群权限'),
          _buildCard([
            _buildItem('查看频道', '默认允许角色查看频道', valueCheckChannel, (value) {
              setState(() {
                valueCheckChannel = value;
              });
            }),
            _buildDivider(),
            _buildItem('查看频道', '默认允许角色查看频道', valueCheckChannel, (value) {
              setState(() {
                valueCheckChannel = value;
              });
            }),
            _buildDivider(),
            _buildTxtItem('查看频道', '默认允许角色查看频道', (value) {
              setState(() {
                valueCheckChannel = value;
              });
            }),
            _buildDivider(),
            _buildItem('查看频道', '默认允许角色查看频道', valueCheckChannel, (value) {
              setState(() {
                valueCheckChannel = value;
              });
            }),
          ]),
          _buildTitle('通用社群权限'),
          _buildCard([
            _buildItem('查看频道', '默认允许角色查看频道', valueCheckChannel, (value) {
              setState(() {
                valueCheckChannel = value;
              });
            }),
            _buildDivider(),
            _buildItem('查看频道', '默认允许角色查看频道', valueCheckChannel, (value) {
              setState(() {
                valueCheckChannel = value;
              });
            }),
            _buildDivider(),
            _buildItem('查看频道', '默认允许角色查看频道', valueCheckChannel, (value) {
              setState(() {
                valueCheckChannel = value;
              });
            }),
          ]),
          _buildTitle('文字频道权限'),
          _buildCard([
            _buildItem('查看频道', '默认允许角色查看频道', valueCheckChannel, (value) {
              setState(() {
                valueCheckChannel = value;
              });
            }),
            _buildDivider(),
            _buildItem('查看频道', '默认允许角色查看频道', valueCheckChannel, (value) {
              setState(() {
                valueCheckChannel = value;
              });
            }),
            _buildDivider(),
            _buildItem('查看频道', '默认允许角色查看频道', valueCheckChannel, (value) {
              setState(() {
                valueCheckChannel = value;
              });
            }),
          ]),
          _buildTitle('语音频道权限'),
          _buildCard([
            _buildItem('查看频道', '默认允许角色查看频道', valueCheckChannel, (value) {
              setState(() {
                valueCheckChannel = value;
              });
            }),
            _buildDivider(),
            _buildItem('查看频道', '默认允许角色查看频道', valueCheckChannel, (value) {
              setState(() {
                valueCheckChannel = value;
              });
            }),
            _buildDivider(),
            _buildItem('查看频道', '默认允许角色查看频道', valueCheckChannel, (value) {
              setState(() {
                valueCheckChannel = value;
              });
            }),
          ]),
        ],
      ),
    );
  }

  // 角色卡片
  Widget _buildRoleCard() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          height: 28,
          alignment: Alignment.center,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 206, 220, 247),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color:GbsColors.primaryColor, width: 1)
          ),
          child: Text(
            '普通角色',
            style: const TextStyle(fontSize: 14, color: GbsColors.primaryColor),
          ),
        ),
      ],
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

  // 标题
  Widget _buildTitle(String title) {
    return Container(
      padding: const EdgeInsets.only(left: 16, top: 12),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, color: GbsColors.des6Color),
      ),
    );
  }

  //
  Widget _buildItem(
    String title,
    String des,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.only(left: 16, top: 12),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: GbsColors.des1Color,
                  ),
                ),
                Text(
                  des,
                  style: const TextStyle(
                    fontSize: 12,
                    color: GbsColors.des6Color,
                  ),
                ),
              ],
            ),
          ),

          Switch(
            focusColor: GbsColors.primaryColor,
            activeTrackColor: GbsColors.primaryColor,
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // 分割线
  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.only(left: 16, top: 8),
      height: 0.8,
      color: GbsColors.lightDivider,
    );
  }

  // 元素
  Widget _buildTxtItem(String title, String des, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.only(left: 16, top: 12),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: GbsColors.des1Color,
                  ),
                ),
                Text(
                  des,
                  style: const TextStyle(
                    fontSize: 12,
                    color: GbsColors.des6Color,
                  ),
                ),
              ],
            ),
          ),

          Text(
            '文字',
            style: const TextStyle(fontSize: 12, color: GbsColors.des6Color),
          ),
          Padding(
            padding: EdgeInsetsGeometry.only(left: 8),
            child: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: GbsColors.des6Color,
            ),
          ),
        ],
      ),
    );
  }
}
