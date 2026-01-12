
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:bell_bird_talk/widgets/common_appbar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class CmtSettingSelModel {
  CmtSettingSelModel({
    required this.title,
    required this.subTitle,
    required this.value,
  });

  String title;
  String subTitle;
  int value;
}

class CommunitySendSelectView extends StatelessWidget {
  String title;
  CmtSettingSelModel defaultItem;
  final List<CmtSettingSelModel> items;
  final ValueChanged<CmtSettingSelModel> onConfirm;
  CommunitySendSelectView({
    Key? key,
    required this.title,
    required this.defaultItem,
    required this.items,
    required this.onConfirm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GbsColors.lightBackgroundB,
      resizeToAvoidBottomInset:
          false, // 防止 Scaffold 自动调整，由 showScreenViewCustom 的 AnimatedPadding 处理
      appBar: CommonAppBarView(title: title, appBarType: AppBarType.close,),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          CmtSettingSelModel cm = items[index];
          return ListTile(
            title: Text(cm.title),
            onTap: () {
              Navigator.of(context).pop();
              onConfirm(cm);
            },
            trailing: defaultItem.value == cm.value
                ? Icon(Icons.check, color: GbsColors.primaryColor)
                : null,
          );
        },
      ),
    );
  }
}
