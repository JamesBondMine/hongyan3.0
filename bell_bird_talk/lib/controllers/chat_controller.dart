import 'package:get/get.dart';
import '../services/native_bridge.dart';
class ChatController extends GetxController { 

  static ChatController get to => Get.put(ChatController());


  final IOSNativeService _nativeService = IOSNativeService();

  Future<bool> deleteMessage(String messageId, String conversationId) async {
    final res = await _nativeService.imDeleteMessage(messageId: messageId, conversationId: conversationId);
    if (res['errorCode'] == 0) {
      return true;
    } else {
      return false;
    }
  }
}