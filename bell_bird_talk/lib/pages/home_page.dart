import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:bell_bird_talk/controllers/chat_controller.dart';
import 'package:bell_bird_talk/pages/community/pages/community_home_joined_page.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/global_controller.dart';
import '../services/native_bridge.dart';
import 'friends/pages/friends_home_page.dart';
import 'chat/chat_list_page.dart';
import 'profile/profile_tab_page.dart';
import 'community/pages/community_home_unjoin_page.dart';

/// 首页（带底部 TabBar）
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final GlobalController _globalCtrl = Get.find<GlobalController>();
  final IOSNativeService _nativeService = IOSNativeService();

  // 注册本地通知
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  // 上传凭证信息
  @override
  void initState() {
    super.initState();
    // 进入首页时注册消息回调
    _registerMessageCallbacks();

    // 注册本地通知
    _registerLocalNotification();

    _registerListeners();
  }

  // 注册业务监听
  void _registerListeners() {
    _globalCtrl.addListenerId(_globalCtrl.communityTabRefreshId, (){
      // 刷新社区列表
      setState(() {
        // 触发刷新
      });
    });
  }

  // 注册本地通知
  void _registerLocalNotification() {
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        // 请求权限
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
      if (isAllowed) {
        
       Future.delayed(  const Duration(seconds: 10), () {
          print('✅ 本地通知权限已授予');
          _createNotification(0, '登录成功！欢迎使用本应用。');
;
        });
      }
    });
  }

  // 创建通知
  void _createNotification(int type, String body, {String title = '提示'}) async {


    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 10,
        channelKey: 'basic_channel',
        actionType: ActionType.Default,
        title: title,
        body: body,
        notificationLayout: NotificationLayout.BigPicture,
        bigPicture: 'asset://assets/img/noti/noti.png',
        // largeIcon: 'asset://assets/img/noti/noti.png',
        // icon: 'asset://assets/img/noti/noti.png',
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'REPLY',
          label: '回复',
        ),
        NotificationActionButton(
          key: 'DISMISS',
          label: '忽略',
          isDangerousOption: true,
        ),
      ],
      schedule: NotificationInterval(
        interval: Duration(seconds: 5),
      ),
    );
  }
  
  @override
  void dispose() {
    // 离开首页时取消注册
    _nativeService.imUnregisterMessageCallbacks();
    super.dispose();
  }
  
  /// 注册消息回调（单聊、群聊、社区、系统、命令）
  Future<void> _registerMessageCallbacks() async {
    // 设置消息接收回调
    _nativeService.onMessageReceived = _handleReceivedMessage;
    
    // 设置系统消息回调
    _nativeService.onSystemMessage = _handleSystemMessage;
    
    // 设置命令消息回调
    _nativeService.onCommandMessage = _handleCommandMessage;
    
    // 注册底层回调
    final result = await _nativeService.imRegisterMessageCallbacks();
    if (result['errorCode'] == 0) {
      print('✅ 消息回调注册成功（单聊、群聊、社区、系统、命令）');
    } else {
      print('❌ 消息回调注册失败: ${result['message']}');
    }
  }
  
  /// 处理收到的消息
  void _handleReceivedMessage(Map<String, dynamic> message) async {
    final convType = message['conv_type'] as int?;
    final content = message['content'] as String?;
    final from = message['from'] as String?;

    // 获取用户信息，如果获取到昵称，则将 from 设置成昵称
    String displayName = from ?? '未知用户';
    if (from != null && from.isNotEmpty) {
      try {
        final userInfo = await _globalCtrl.getUserInfo(from);
        if (userInfo['errorCode'] == 0) {
          final data = userInfo['data'];
          if (data is Map<String, dynamic>) {
            final nickname = data['nickname'] as String?;
            if (nickname != null && nickname.isNotEmpty) {
              displayName = nickname;
            }
          }
        }
      } catch (e) {
        print('⚠️ 获取用户信息失败: $e');
      }
    }
    
    String convTypeStr = '未知';
    switch (convType) {
      case 0: convTypeStr = '单聊'; break;
      case 2: convTypeStr = '群聊'; break;
      case 4: convTypeStr = '社区'; break;
    }
    
    print('📨 [$convTypeStr] 来自 $displayName: $content');

    
    final conversationId = message['conversation_id'] as String?;
    if (conversationId != null && conversationId.isNotEmpty && conversationId == ChatController.to.conversationId) {
      _createNotification(1, '$content', title: displayName);
    }
    
    
    // 通知 GlobalController 更新聊天列表
    _globalCtrl.onNewMessageReceived(message);
  }
  
  /// 处理系统消息  被加好友  是系统消息
  void _handleSystemMessage(Map<String, dynamic> message) {
    print('📨 首页收到系统消息: $message');
    
    // 收到系统消息，刷新联系人列表和好友申请列表
    // 系统消息可能包括：好友申请、好友通过、好友删除等
    _globalCtrl.triggerContactRefresh();
    _createNotification(2, '新好友通知');
  }
  
  /// 处理命令消息
  void _handleCommandMessage(int eventType, Map<String, dynamic> message) {
    print('📨 首页收到命令消息: eventType=$eventType, data=$message');
    
    // TODO: 根据命令类型进行处理
    // 例如：强制更新、配置变更等
    _createNotification(3, '命令消息: $message');
  }
  
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Tab 0: 聊天页面
          const ChatListPage(),
          // Tab 1: 好友页面
          const FriendsHomePage(),
          // Tab 2: 社群页面
          GlobalController.to.joinedCommunitys.isEmpty ? const CommunityHomeUnjoinPage() : const CommunityHomeJoinedPage(),
          // Tab 3: 我的页面
          const ProfileTabPage(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }



  /// 构建底部导航栏
  Widget _buildBottomNavigationBar() {
    return Obx(() => BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: GbsColors.titleColor,
      selectedLabelStyle: TextStyle(fontSize: 12, color: GbsColors.titleColor, fontWeight: FontWeight.w500),
      unselectedItemColor: Colors.grey,
      unselectedLabelStyle: TextStyle(fontSize: 12, color: GbsColors.des6Color, fontWeight: FontWeight.w500),
      currentIndex: _currentIndex,
      items: [
        BottomNavigationBarItem(
          icon: _buildIconWithBadge(
            icon: 'conv_def',
            unreadCount: _globalCtrl.unreadCount.value,
          ),
          activeIcon: _buildIconWithBadge(
            icon: 'conv_act',
            unreadCount: _globalCtrl.unreadCount.value,
            isSelected: _currentIndex==0
          ),
          label: '聊天'.tr,
        ),
        BottomNavigationBarItem(
          icon: _buildIconWithBadge(
            icon: 'friend_def',
            unreadCount: _globalCtrl.groupRequestCount.value,
          ),
          activeIcon: _buildIconWithBadge(
            icon: 'friend_act',
            unreadCount: _globalCtrl.groupRequestCount.value,
            isSelected: _currentIndex==1
          ),
          label: '好友'.tr,
        ),
        BottomNavigationBarItem(
          icon: _buildIconWithBadge(
            icon: 'comm_def',
            unreadCount: 0,
          ),
          activeIcon: _buildIconWithBadge(
            icon: 'comm_act',
            unreadCount:0,
            isSelected: _currentIndex==2
          ),
          label: '社群'.tr,
        ),
        BottomNavigationBarItem(
          icon: _buildIconWithBadge(
            icon: 'friend_def',
            unreadCount: 0,
          ),
          activeIcon: _buildIconWithBadge(
            icon: 'friend_act',
            unreadCount: 0,
            isSelected: _currentIndex==3
          ),
          label: '我的'.tr,
        ),
        // const BottomNavigationBarItem(
        //   icon: Icon(Icons.group_outlined),
        //   activeIcon: Icon(Icons.group),
        //   label: '社群',
        // ),
        // const BottomNavigationBarItem(
        //   icon: Icon(Icons.person_outline),
        //   activeIcon: Icon(Icons.person),
        //   label: '我的',
        // ),
      ],
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
    ));
  }

  /// 构建带角标的图标
  Widget _buildIconWithBadge({required String icon, required int unreadCount, bool isSelected = false}) {
    return Container(width: 58, height: 28,
    margin: EdgeInsets.only(bottom: 5),
    alignment: Alignment.center,
        decoration:isSelected ?  BoxDecoration(
          color: GbsColors.lightPrimaryButton.withOpacity(0.18),
          borderRadius: BorderRadius.circular(15),
        ) : null ,child:  Stack(
      clipBehavior: Clip.none,
      children: [
        Image.asset('assets/img/tab/$icon.png', width: 22, height: 22,),
        if (unreadCount > 0)
          Positioned(
            right: -8,
            top: -8,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: unreadCount > 99 ? 4 : 5,
                vertical: 2,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Center(
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    ));
  }
}
