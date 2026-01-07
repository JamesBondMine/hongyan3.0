import 'package:bell_bird_talk/controllers/community_controller.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class CustomSliderWithTextOnTrack extends StatefulWidget {
  CustomSliderWithTextOnTrack(
      {Key? key,
      required this.seekStart,
      required this.seekEnd,
      required this.amountList})
      : super(key: key);

  final ValueChanged<String> seekEnd;

  final VoidCallback seekStart;

  // 金额数组
  List amountList = [];

  @override
  State<StatefulWidget> createState() {
    return _CustomSliderWithTextOnTrackState();
  }
}

class _CustomSliderWithTextOnTrackState
    extends State<CustomSliderWithTextOnTrack> {
  // 按钮位移
  Offset _buttonOffset = const Offset(0, 10);
  // 拖动中
  bool gestureing = false;
  // 视图总宽度
  double viewWidth = Get.width - 32;
  // 初始进度
  double value = 0.0;

  // 获取点位的横坐标
  List<double> pxl = [];

  double itemL = 0;

  // 选中的下标
  int selectIndex = 0;

  // 金额数组
  List amountList = ["1", "10", "15", "50", "100", "500", "1000"];

  @override
  void initState() {
    super.initState();
    if (widget.amountList.isNotEmpty) {
      amountList = widget.amountList;
    }

    // 获取点位的横坐标
    itemL = viewWidth / 6;

    double itemx = (viewWidth - 10) / 6;
    pxl = [
      itemx * 0,
      itemx * 1 + 5,
      itemx * 2 + 5,
      itemx * 3,
      itemx * 4,
      itemx * 5,
      itemx * 6
    ];

    CommunityController.to.currentPlaySeconds = 0;

    // 当前横向总位移
    double dx = viewWidth * value;
    _buttonOffset = Offset(dx, 10);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
            width: viewWidth,
            height: 40,
            child: GetBuilder<CommunityController>(
                id: CommunityController.to.menuSliderRefreshId,
                builder: (context) {
                  return _stackView();
                })),
        _labelView()
      ],
    );
  }

  void _onDragEnd(DragEndDetails details) {
    if (_buttonOffset.dx < itemL / 2) {
      selectIndex = 0;
      _buttonOffset = const Offset(0, 10);
    } else if (_buttonOffset.dx >= (viewWidth - 20 - itemL / 2)) {
      _buttonOffset = Offset(viewWidth - 20, 10);
      selectIndex = 6;
    } else {
      for (var i = 0; i < pxl.length; i++) {
        double indexx = pxl[i];
        if (_buttonOffset.dx >= (indexx - itemL / 2) &&
            _buttonOffset.dx < (indexx + itemL / 2)) {
          _buttonOffset = Offset(indexx - 10, 10);
          selectIndex = i;
        }
      }
    }
    CommunityController.to.currentPlaySeconds = 1 / 6 * selectIndex;
    CommunityController.to.updateListenProgressPanRefresh(); // 拖动更新
    widget.seekEnd(amountList[selectIndex]);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _buttonOffset += details.delta;
    _buttonOffset = Offset(_buttonOffset.dx, 10);

    if (_buttonOffset.dx <= 0) {
      _buttonOffset = const Offset(0, 10);
    } else if (_buttonOffset.dx >= viewWidth - 20) {
      _buttonOffset = Offset(viewWidth - 20, 10);
    }
    CommunityController.to.currentPlaySeconds = _buttonOffset.dx / viewWidth;
    CommunityController.to.updateListenProgressPanRefresh(); // 拖动更新
  }

  Widget _lineProgressView() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
      ),
      child: LinearProgressIndicator(
        value: CommunityController.to.sliderValue, // 设置进度条的值，范围从 0.0 到 1.0
        // backgroundColor: Global.kTheme!.text4.withOpacity(0.2), // 背景颜色
        // color: Global.kTheme!.text4, // 进度条的颜色
      ),
    );
  }

  Widget _stackView() {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        // 进度条
        Container(
          padding:
              const EdgeInsets.only(top: 18, bottom: 18, left: 10, right: 10),
          child: _lineProgressView(),
        ),
        // 圆球
        _pointView(),
        // 点击按钮
        _touchView(),
        // 拖动按钮
        _dragView()
      ],
    );
  }

  Widget _dragView() {
    return Positioned(
        left: _buttonOffset.dx,
        top: 0,
        child: GestureDetector(
          onPanUpdate: (details) {
            _onDragUpdate(details);
          },
          onPanEnd: (details) {
            _onDragEnd(details);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            // height: 40,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                  color: GbsColors.primaryColor,
                  borderRadius: const BorderRadius.all(Radius.circular(10))),
            ),
          ),
        ));
  }

  Widget _touchView() {
    double itemx = (viewWidth - 10) / 7 - 2;
    List<Widget> vl = [];
    for (var i = 0; i < 7; i++) {
      vl.add(GestureDetector(
        onTap: () {
          _touuchAction(i);
        },
        child: Container(
          width: itemx,
          height: 40,
          decoration: BoxDecoration(color: Colors.transparent),
        ),
      ));
    }
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 5,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: vl,
      ),
    );
  }

  _touuchAction(int index) {
    if (index == 0) {
      selectIndex = 0;
      _buttonOffset = const Offset(0, 10);
    } else if (index == 6) {
      selectIndex = 6;
      _buttonOffset = Offset(viewWidth - 20, 10);
    } else {
      double indexx = pxl[index];
      _buttonOffset = Offset(indexx - 10, 10);
      selectIndex = index;
    }
    CommunityController.to.currentPlaySeconds = 1 / 6 * selectIndex;
    CommunityController.to.updateListenProgressPanRefresh(); // 拖动更新
    widget.seekEnd(amountList[selectIndex]);
  }

  // 文字视图
  Widget _labelView() {
    double itemx = (viewWidth - 10 - 30 - 40) / 5 - 2;
    List<Widget> vl = [];

    for (var i = 0; i < amountList.length; i++) {
      vl.add(
        SizedBox(
          width: i == 0 ? 30 : (i == 6 ? 30 : itemx),
          child: Text(
            amountList[i],
            textAlign: i == 0
                ? TextAlign.start
                : (i == 6 ? TextAlign.end : TextAlign.center),
            maxLines: 1,
            // style: TextStyle(fontSize: 12, color: Global.kTheme!.text1),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 5,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: vl,
      ),
    );
  }

  Widget _pointView() {
    List<Widget> vl = [];
    for (var i = 0; i < 7; i++) {
      vl.add(Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
            color: selectIndex >= i
                ? GbsColors.primaryColor
                : GbsColors.primaryColor.withOpacity(0.2),
            borderRadius: BorderRadius.all(Radius.circular(5))),
      ));
    }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: vl,
      ),
    );
  }
}
