


import 'package:get/get.dart';

class FriendController extends GetxController { 

  static FriendController get to => Get.put(FriendController());

  String friendGropRefreshId = '';
  void updateFriendGroupRefreshId() {
    update([friendGropRefreshId]);
  }
}