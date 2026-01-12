import 'package:bell_bird_talk/controllers/community_controller.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:bell_bird_talk/widgets/common_appbar_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CmtSettingMaxModel {
  CmtSettingMaxModel({
    required this.title,
    required this.subTitle,
    required this.value,
    required this.max,
  });

  String title;
  String subTitle;
  int value;
  int max;
}

class CmtSendMaxView extends StatelessWidget {
  CmtSendMaxView({
    super.key,
    required this.items,
    required this.defaultItem,
    required this.controller,
    required this.onTap,
    this.title,
    this.tip,
    this.name,
    this.needCancel = true,
  });

  List<CmtSettingMaxModel> items;
  CmtSettingMaxModel defaultItem;

  final ValueChanged<CmtSettingMaxModel> onTap;
  TextEditingController controller;
  String? title;
  String? tip;
  // 输入框名字
  String? name;
  bool needCancel;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CommunityController>(
      id: CommunityController.to.cmtSendMaxRefreshId,
      builder: (controller) {
        return _bodayView(context);
      },
    );
  }

  Widget _bodayView(BuildContext context) {
    controller.text = defaultItem.max ==0 ? '不限制' : defaultItem.max.toString();
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CommonAppBarView(
            title: title!,
            backgroundColor: GbsColors.lightBackgroundB,
            appBarType: AppBarType.sheetbackAndClose,
            btn: InkWell(
              onTap: () {
                onTap(defaultItem);
              },
              child: Container(
                height: 44,
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '完成',
                  style: TextStyle(
                    color: GbsColors.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          ListTile(
            title: Text(items.first.title),
            onTap: () {
              defaultItem = items.first;
              CommunityController.to.updateCmtSendMax();
            },
            trailing: defaultItem.value == items.first.value
                ? Icon(Icons.check, color: GbsColors.primaryColor)
                : null,
          ),
          name != null
              ? Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    name!,
                    style: TextStyle(fontSize: 14, color: GbsColors.des1Color),
                  ),
                )
              : const SizedBox(),

          _buildTimeView(context),
          // 中：输入框
          Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: 16,
            ),
            child: TextField(
              
              controller: controller,
              // focusNode: focusNode,
              autofocus: true,

              decoration: InputDecoration(
                hintText: tip ?? '请输入备注名',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: GbsColors.primaryColor,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeView(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 10),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Row(
                children: [
                  _timeItem(
                    context,
                    items[1].title,
                    defaultItem.value == items[1].value,
                    () {
                      defaultItem = items[1];
                      CommunityController.to.updateCmtSendMax();
                    },
                  ),
                  _timeItem(
                    context,
                    items[2].title,
                    defaultItem.value == items[2].value,
                    () {
                      defaultItem = items[2];
                      CommunityController.to.updateCmtSendMax();
                    },
                  ),
                  _timeItem(
                    context,
                    items[3].title,
                    defaultItem.value == items[3].value,
                    () {
                      defaultItem = items[3];
                      CommunityController.to.updateCmtSendMax();
                    },
                  ),
                  _timeItem(
                    context,
                    items[4].title,
                    defaultItem.value == items[4].value,
                    () {
                      defaultItem = items[4];
                      CommunityController.to.updateCmtSendMax();
                    },
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 64,
            alignment: Alignment.center,
            child: defaultItem.value != items.first.value
                ? Icon(Icons.check, color: GbsColors.primaryColor)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _timeItem(
    BuildContext context,
    String title,
    bool selected,
    VoidCallback ontap,
  ) {
    return InkWell(
      onTap: () {
        ontap();
      },
      child: Container(
        height: 30,
        padding: EdgeInsets.symmetric(horizontal: 12),
        margin: EdgeInsets.only(right: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: selected
              ? GbsColors.primaryColor.withAlpha(25)
              : GbsColors.lightBackgroundA,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            color: selected ? GbsColors.primaryColor : GbsColors.des6Color,
          ),
        ),
      ),
    );
  }
}
