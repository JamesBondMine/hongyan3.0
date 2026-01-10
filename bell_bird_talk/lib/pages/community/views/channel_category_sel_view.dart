import 'package:bell_bird_talk/controllers/community_controller.dart';
import 'package:bell_bird_talk/pages/community/models/community_model.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ChannelCategorySelView extends StatelessWidget {
  final ValueChanged<CmtGroupModel> onConfirm;

  final String? selectedCategoryId;

  String communityId;

  ChannelCategorySelView({
    Key? key,
    required this.communityId,
    required this.onConfirm,
    this.selectedCategoryId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GbsColors.lightBackgroundB,
      resizeToAvoidBottomInset:
          false, // 防止 Scaffold 自动调整，由 showScreenViewCustom 的 AnimatedPadding 处理
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '所属分类',
              style: TextStyle(
                color: GbsColors.des1Color,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        leadingWidth: 100,
        backgroundColor: GbsColors.lightAppBarColorA,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: GbsColors.titleColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: FutureBuilder(
        future: getCategory(),
        builder: (context, AsyncSnapshot<List<CmtGroupModel>> snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Container();
          }
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              CmtGroupModel cm =  snapshot.data![index];
              return ListTile(
                title: Text(cm.name),
                onTap: () {
                  Navigator.of(context).pop();
                  onConfirm(cm);
                },
                trailing: selectedCategoryId == cm.id
                    ? Icon(Icons.check, color: GbsColors.titleColor)
                    : null,
              );
            },
          );
        },
      ),
    );
  }

  // 获取分类信息
  Future<List<CmtGroupModel>> getCategory() async {
    return await CommunityController.to.getChannelGroups(communityId);
  }
}
