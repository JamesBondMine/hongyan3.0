
import 'package:get/get.dart';

class CommunityController extends GetxController {
  static CommunityController get to => Get.put(CommunityController());



  // 刷新
  String menuSliderRefreshId = 'menuSliderRefreshId';
  void updateListenProgressPanRefresh() {
    update([menuSliderRefreshId]);
  }


  double sliderValue = 0.0;


  double currentPlaySeconds = 0;


}