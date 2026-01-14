
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class Shower {
  Future showScreenViewCustom(BuildContext context, double height, Widget child,
      {double radius = 12.0,
      bool autoDismiss = false,
      bool nobarrierColor = false,
      bool isScrollControlled = true}) async {
    return await showModalBottomSheet<Null>(
        isScrollControlled: isScrollControlled,
        context: context,
        backgroundColor: GbsColors.lightBackgroundA,
        enableDrag: true,
        barrierColor:
            nobarrierColor ? Colors.black.withOpacity(0) : Colors.black54,
        constraints: BoxConstraints(maxHeight: height),
        isDismissible: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(radius),
            topRight: Radius.circular(radius),
          ),
        ),
        elevation: 21,
        builder: (BuildContext context) {
          return AnimatedPadding(
            padding: MediaQuery.of(context).viewInsets,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                autoDismiss ? _dismissView(context) : Container(),
                Flexible(child: child)
              ],
            ),
          );
        });
  }

  // 减号
  Widget _dismissView(
    BuildContext context,
  ) {
    return InkWell(
      child: Container(
        height: 34,
        padding: const EdgeInsets.only(bottom: 0),
        alignment: Alignment.center,
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: GbsColors.lightBackgroundA,
            borderRadius: const BorderRadius.all(Radius.circular(2)),
          ),
        ),
      ),
      onTap: () {
        Navigator.pop(context);
      },
    );
  }

  Future showActionSheet(
    BuildContext context, {
    required String title,
    required String content,
    required List<String> items,
    required ValueChanged<int> onClick,
  }) async {
    return await showModalBottomSheet<Null>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(12.0),
        ),
      ),
      elevation: 21,
      backgroundColor:GbsColors.lightBackgroundA,
      builder: (BuildContext context) {
        List<Widget> titles = [];
        if (title.isNotEmpty) {
          titles.add(Container(
              margin: const EdgeInsets.only(top: 15, bottom: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    title,
                    style: TextStyle(color: GbsColors.titleColor),
                  )
                ],
              )));
        }
        if (content.isNotEmpty) {
          titles.add(Container(
              margin: const EdgeInsets.only(top: 0, bottom: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    content,
                    style: TextStyle(fontSize: 12, color: GbsColors.des6Color),
                  )
                ],
              )));
        }

        if (content.isNotEmpty || title.isNotEmpty) {
          titles.add(
            Container(
              width: MediaQuery.of(context).size.width,
              height: 0.8,
              color: Colors.grey.withAlpha(50),
            ),
          );
        }

        for (var i = 0; i < items.length; i++) {
          String des = items[i];
          titles.add(InkWell(
            onTap: () async {
              Navigator.pop(context);
              await Future.delayed(const Duration(microseconds: 200));
              onClick(i);
            },
            child: Container(
              margin: const EdgeInsets.only(top: 15, bottom: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    des,
                    style: const TextStyle(fontSize: 18),
                  )
                ],
              ),
            ),
          ));

          if (i < items.length - 1) {
            titles.add(
              Container(
                width: Get.width,
                height: 0.8,
                color: Colors.grey.withAlpha(50),
              ),
            );
          }
        }

        titles.add(Container(
          width: MediaQuery.of(context).size.width,
          height: 10,
          color: Colors.grey.withAlpha(40),
        ));
        titles.add(InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: Container(
            margin: const EdgeInsets.only(top: 15, bottom: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  '取消'.tr,
                  style: TextStyle(
                      fontSize: 18,
                      color: GbsColors.textPrimary,
                      fontWeight: FontWeight.w500),
                )
              ],
            ),
          ),
        ));

        return Column(mainAxisSize: MainAxisSize.min, children: titles);
      },
    );
  }
}
