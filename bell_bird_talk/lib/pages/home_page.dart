import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:bell_bird_talk/controllers/chat_controller.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../controllers/global_controller.dart';
import '../services/native_bridge.dart';
import 'friends/views/friends_page.dart';
import 'chat/chat_list_page.dart';
import 'profile/profile_tab_page.dart';
import 'community/community_page.dart';

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
  void _createNotification(int type, String body) async {

    String title = '提示';

    switch (type) {
      case 0:
        title = '提示';
        break;
      default:
        title = '系统通知';
    }

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 10,
        channelKey: 'basic_channel',
        actionType: ActionType.Default,
        title: title,
        body: body,
      )
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
    print('📨 首页收到消息: $message');

    /// 📨 首页收到消息: 
    /// { 
    /// ext: local_1766476862125_736, 
    /// send_time: 1766476862209, 
    /// to: JMFMW7ZY, 
    /// server_msg_id: msg_6e3339f0c7134a0384bb0922cc6c7cd0, 
    /// m_type: 0, conversation_seq: 10, 
    /// conversation_id: 0732485658392742, 
    /// content: 技术同事正在抢修, 
    /// server_seq: 658579808980045824, 
    /// conv_type: 0, 
    /// receive_time: 1766476862276, 
    /// msg_id: 791213767485759488, 
    /// store_time: 0, nick: , 
    /// from: RZNC9ZYS, conversation_type: 0}
    
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
      _createNotification(1, '[$convTypeStr] 来自 $displayName: $content');
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
          const FriendsPage(),
          // Tab 2: 社群页面
          const CommunityPage(),
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
          label: '聊天',
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
          label: '好友',
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
          label: '社群',
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
          label: '我的',
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

  /// 显示退出登录对话框
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              _globalCtrl.logout();
              EasyLoading.dismiss();
              EasyLoading.showSuccess('已退出登录');
              await Future.delayed(const Duration(seconds: 1));
              Get.offAllNamed('/login');
            },
            child: const Text(
              '确定',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
