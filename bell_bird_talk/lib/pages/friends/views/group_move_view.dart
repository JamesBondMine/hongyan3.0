import 'dart:convert';

import 'package:bell_bird_talk/controllers/friend_controller.dart';
import 'package:bell_bird_talk/pages/models/friend_model.dart';
import 'package:bell_bird_talk/services/native_bridge.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/state_manager.dart';

class GroupMoveView extends StatelessWidget {
  GroupMoveView({Key? key, required this.contactUserId, required this.onItemClick}) : super(key: key);

  final ValueChanged<String> onItemClick;
  String contactUserId = "";
  

  final IOSNativeService _nativeService = IOSNativeService();

  String _selectedItem = "";

  List<String> items = [
    "群组1",
    "群组2",
    "群组3",
    "群组4",
    "群组5",
    "群组6",
    "群组7",
    "群组8",
    "群组9",
  ];

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        // title: Text("移动群组"),
        leading: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsetsGeometry.only(right: 5),
                child: Icon(Icons.arrow_back_ios),
              ),
              Text(
                '调整分组',
                style: TextStyle(
                  fontSize: 16,
                  color: GbsColors.titleColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
      body: FutureBuilder(
        future: _loadContactGroups(),
        builder: (context, AsyncSnapshot<List<FriendGroup>> snapshot) {
          if (snapshot.hasData) {
            final groups = snapshot.data;
            if (groups != null && groups.isNotEmpty) {
              return GetBuilder<FriendController>(
                id: FriendController.to.friendGropRefreshId,
                builder: (controller) {
                return ListView.builder(
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    return Row(children: [
                      Expanded(child: ListTile(
                      title: Text(group.name),
                      onTap: () {
                        _selectedItem = group.id;
                        controller.updateFriendGroupRefreshId();
                        moveToGroup(() {
                          Navigator.pop(context);
                        });
                      },
                    ),),
                    _selectedItem == group.id ? Icon(Icons.check, color: GbsColors.darkPrimaryButton,) : Container(),
                    ],);
                  },
                );
              });
            }
          }
          return Container();
        },
      ),
    );
  }

  // 移动到分组
  Future<void> moveToGroup(VoidCallback success) async {
    try {
      EasyLoading.show(status: 'loading...')  ;
      final result = await _nativeService.imMoveContactToGroup(
        contactUserId: contactUserId,
        groupId: int.tryParse(_selectedItem) ?? 0,
      );
      await Future.delayed(Duration(milliseconds: 500));
      EasyLoading.dismiss();
      if (result['errorCode'] != 0) {
        print('❌ 移动联系人失败: ${result['errorMsg']}');
      } else {
        print('移动联系人成功');
        EasyLoading.showSuccess('操作成功');
        success();
      }
    } catch (e) {
      print('❌ 移动联系人失败: $e');
      EasyLoading.dismiss();
    }
  }

  // 获取分组数据
  Future<List<FriendGroup>> _loadContactGroups() async {
    List<FriendGroup> _groups = [];
    try {
      final result = await _nativeService.imGetContactGroups(
        page: 1,
        pageSize: 100,
      );
      if (result['errorCode'] == 0) {
        final dataStr = result['data'] as String?;
        if (dataStr != null && dataStr.isNotEmpty) {
          final data = json.decode(dataStr);
          final groupsJson = data['groups'] as List? ?? [];

          for (var json in groupsJson) {
            final group = FriendGroup.fromJson(json);
            if (!_groups.any((g) => g.id == group.id)) {
              _groups.add(group);
            }
          }
        }
      }
      return _groups;
    } catch (e) {
      print('❌ 获取联系人分组失败: $e');
      return [];
    }
  }
}
