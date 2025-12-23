import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../controllers/global_controller.dart';
import '../services/native_bridge.dart';
import 'friends/friends_page.dart';
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
  void _handleReceivedMessage(Map<String, dynamic> message) {
    print('📨 首页收到消息: $message');
    
    final convType = message['conv_type'] as int?;
    final content = message['content'] as String?;
    final from = message['from'] as String?;
    
    String convTypeStr = '未知';
    switch (convType) {
      case 0: convTypeStr = '单聊'; break;
      case 2: convTypeStr = '群聊'; break;
      case 4: convTypeStr = '社区'; break;
    }
    
    print('📨 [$convTypeStr] 来自 $from: $content');

    _createNotification(1, '[$convTypeStr] 来自 $from: $content');
    
    // 通知 GlobalController 更新聊天列表
    _globalCtrl.onNewMessageReceived(message);
  }
  
  /// 处理系统消息  被加好友  是系统消息
  void _handleSystemMessage(Map<String, dynamic> message) {
    print('📨 首页收到系统消息: $message');
    
    // 收到系统消息，刷新联系人列表和好友申请列表
    // 系统消息可能包括：好友申请、好友通过、好友删除等
    _globalCtrl.triggerContactRefresh();
    
    print('✅ 已触发联系人和好友申请列表刷新');
    _createNotification(2, '系统消息: $message');
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
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      currentIndex: _currentIndex,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline),
          activeIcon: Icon(Icons.chat_bubble),
          label: '聊天',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          activeIcon: Icon(Icons.people),
          label: '好友',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.group_outlined),
          activeIcon: Icon(Icons.group),
          label: '社群',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: '我的',
        ),
      ],
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
    );
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
