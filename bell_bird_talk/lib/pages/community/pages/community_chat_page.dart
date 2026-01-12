import 'dart:convert';
import 'dart:io';
import 'package:bell_bird_talk/controllers/chat_controller.dart';
import 'package:bell_bird_talk/controllers/global_controller.dart';
import 'package:bell_bird_talk/controllers/group_controller.dart';
import 'package:bell_bird_talk/models/chat_message.dart';
import 'package:bell_bird_talk/pages/chat/at_member_select_page.dart';
import 'package:bell_bird_talk/pages/chat/image_preview_page.dart';
import 'package:bell_bird_talk/pages/chat/user_info_page.dart';
import 'package:bell_bird_talk/pages/chat/views/chat_gas_arrow.dart';
import 'package:bell_bird_talk/pages/chat/views/chat_title_view.dart';
import 'package:bell_bird_talk/pages/friends/views/friend_detail_page.dart';
import 'package:bell_bird_talk/pages/models/friend_model.dart';
import 'package:bell_bird_talk/services/file_path_helper.dart';
import 'package:bell_bird_talk/services/message_database.dart';
import 'package:bell_bird_talk/services/message_queue.dart';
import 'package:bell_bird_talk/services/native_bridge.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:bell_bird_talk/widgets/messages/image_msg_view.dart';
import 'package:bell_bird_talk/widgets/messages/video_msg_view.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// 单人聊天页面
class CommunityChatPage extends StatefulWidget {
  final String convId;
  final String displayName;
  final String? avatar;
  final String targetUserId;
  final int convType; // 0=单聊,2=群聊
  final PreferredSizeWidget? customAppBar;
  final List<Map<String, dynamic>>? groupMembers; // 群成员列表（群聊时使用）
  final bool? isMuted; // 是否禁言（群聊时使用）

  const CommunityChatPage({
    super.key,
    required this.convId,
    required this.displayName,
    this.avatar,
    required this.targetUserId,
    this.convType = 0,
    this.customAppBar,
    this.groupMembers,
    this.isMuted,
  });

  @override
  State<CommunityChatPage> createState() => _CommunityChatPageState();
}

class _CommunityChatPageState extends State<CommunityChatPage> {
  final IOSNativeService _nativeService = IOSNativeService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  bool _showEmojiPicker = false;
  bool _showMorePanel = false;

  final ImagePicker _imagePicker = ImagePicker();
  final MessageQueueManager _messageQueue = MessageQueueManager();
  final MessageDatabase _messageDatabase = MessageDatabase();
  final GlobalController _globalCtrl = Get.find<GlobalController>();

  /// 新消息监听器
  Worker? _newMessageWorker;

  /// 当前用户ID
  String get _currentUserId => _globalCtrl.currentUser.value?.id ?? '';

  // @功能相关
  List<Map<String, dynamic>> _atMembers = []; // 已@的成员列表

  @override
  void initState() {
    super.initState();

    // 初始化文件路径助手（解决iOS沙盒路径变化问题）
    FilePathHelper.instance.init();

    _loadMessages();

    // 监听消息状态变化
    _messageQueue.addStatusListener(_onMessageStatusChanged);

    // 监听 GlobalController 的新消息通知
    _newMessageWorker = ever(_globalCtrl.newMessage, _onNewMessageFromCallback);

    // 监听输入框内容变化，检测@符号
    _messageController.addListener(_onTextChanged);

    // 定位当前会话ID
    ChatController.to.conversationId = widget.convId;

    // 标记会话已读
    _markConversationRead();
  }

  // 标记会话已读
  void _markConversationRead() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (_messages.isNotEmpty) {
      List<Map<String, dynamic>> unreadMessages = _messages
          .where((msg) => msg['isMine'] == false)
          .toList();
      if (unreadMessages.isNotEmpty) {
        List<String> unreadMsgIds = unreadMessages
            .map((msg) => msg['id'].toString())
            .toList();
        _nativeService.imMarkConversationRead(
          convId: widget.convId,
          msgIds: unreadMsgIds.join(','),
        );
      }
    }
  }

  /// 监听输入框内容变化，检测@符号
  void _onTextChanged() {
    if (widget.convType != 2 ||
        widget.groupMembers == null ||
        widget.groupMembers!.isEmpty) {
      return; // 非群聊或没有群成员列表，不处理@功能
    }

    final text = _messageController.text;
    final cursorPosition = _messageController.selection.baseOffset;

    // 检查光标位置前是否有@符号
    if (cursorPosition > 0) {
      final beforeCursor = text.substring(0, cursorPosition);
      final lastAtIndex = beforeCursor.lastIndexOf('@');

      if (lastAtIndex != -1) {
        // 找到@符号，检查@后面是否有空格或其他@符号
        final afterAt = beforeCursor.substring(lastAtIndex + 1);
        if (afterAt.isEmpty ||
            (!afterAt.contains(' ') && !afterAt.contains('@'))) {
          // @后面没有空格或其他@，跳转到@成员选择页面
          _openAtMemberSelectPage();
          return;
        }
      }
    }
  }

  /// 打开@成员选择页面
  Future<void> _openAtMemberSelectPage() async {
    if (widget.convType != 2 || widget.groupMembers == null) {
      return; // 非群聊，不处理
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AtMemberSelectPage(
          groupId: widget.targetUserId,
          currentUserId: _currentUserId,
          onMembersSelected: (value) {
            if (value.isNotEmpty) {
              _selectAtMembers(value);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar:
          widget.customAppBar ??
          ChatTitleView(
            convId: widget.convId,
            displayName: widget.displayName,
            avatar: widget.avatar,
            targetUserId: widget.targetUserId,
            convType: widget.convType,
          ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/img/chat/chat_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            // 消息列表
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // 点击消息列表区域时收起面板和键盘
                  if (_showEmojiPicker || _showMorePanel) {
                    setState(() {
                      _showEmojiPicker = false;
                      _showMorePanel = false;
                    });
                  }
                  _focusNode.unfocus();
                },
                child: _buildMessageList(),
              ),
            ),

            // 输入区域：语音面板 或 文字输入栏
            _buildInputBar(),
            // 表情选择器
            if (_showEmojiPicker) _buildEmojiPicker(),
            // 更多面板
            // if (_showMorePanel) _buildMorePanel(),
          ],
        ),
      ),
    );
  }

  /// 加载消息（对方消息只从网络获取；自己发送的消息合并本地+网络）
  Future<void> _loadMessages() async {
    // 1. 先加载本地仅自己发送的消息（用于发送中/失败的展示与重发）
    await _loadLocalMyMessages();

    // 2. 再从 API 拉取最新消息，确保对方消息来自网络
    await _loadHistory();

    // 按时间排序
    _sortMessagesByTime();
  }

  @override
  void dispose() {
    _newMessageWorker?.dispose();
    _messageQueue.removeStatusListener(_onMessageStatusChanged);
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 仅加载本地“我发送的”消息，用于与网络消息合并展示
  Future<void> _loadLocalMyMessages() async {
    final localMessages = await _messageDatabase.getMessages(widget.convId);
    if (localMessages.isEmpty) return;

    final myMessages = localMessages
        .where((msg) => msg.senderId == _currentUserId)
        .toList();
    if (myMessages.isEmpty) return;

    print('📦 加载本地我发送的消息: ${myMessages.length} 条');
    for (final msg in myMessages) {
      _addChatLocalMessageToList(msg);
    }
    _sortMessagesByTime();
    setState(() {});
    _scrollToBottom();
  }

  /// 按时间排序消息列表
  void _sortMessagesByTime() {
    _messages.sort((a, b) {
      final timeA = a['timestamp'] as int? ?? 0;
      final timeB = b['timestamp'] as int? ?? 0;
      return timeA.compareTo(timeB); // 升序，旧消息在前
    });
  }

  /// 消息状态变化回调
  void _onMessageStatusChanged(ChatMessage message) {
    if (message.convId != widget.convId) return;

    setState(() {
      final index = _messages.indexWhere(
        (m) => m['localId'] == message.localId,
      );
      if (index != -1) {
        _messages[index]['status'] = message.status.name;
        _messages[index]['errorMessage'] = message.errorMessage;
        if (message.imageUrl != null) {
          _messages[index]['imageUrl'] = message.imageUrl;
        }
      }
    });
  }

  /// 处理从 GlobalController 收到的新消息回调
  void _onNewMessageFromCallback(Map<String, dynamic>? message) {
    if (message == null) return;

    // 解析消息数据
    final convId = message['conv_id'] as String? ?? '';
    final senderId =
        message['from'] as String? ?? message['sender_id'] as String? ?? '';

    // 只处理当前会话的消息
    if (convId != widget.convId && senderId != widget.targetUserId) {
      print('📨 聊天页忽略非当前会话消息: convId=$convId, targetId=${widget.targetUserId}');
      return;
    }

    // 如果是自己发的消息，忽略（已通过发送流程处理）
    if (senderId == _currentUserId) {
      print('📨 聊天页忽略自己发送的消息');
      return;
    }

    print('📨 聊天页收到新消息: $message');

    // 解析消息内容
    final msgId =
        message['msg_id'] as String? ??
        message['message_id'] as String? ??
        DateTime.now().millisecondsSinceEpoch.toString();
    final content =
        message['content'] as String? ?? message['text'] as String? ?? '';
    final timestamp =
        message['send_time'] as int? ??
        message['timestamp'] as int? ??
        DateTime.now().millisecondsSinceEpoch;
    final mType = message['m_type'] as int? ?? 0;
    final imageUrl = message['image_url'] as String?;

    // 创建 ChatMessage 对象
    final messageType = MessageType.fromValue(mType);
    final chatMessage = ChatMessage(
      localId: msgId,
      serverId: msgId,
      msgId: msgId,
      convId: widget.convId,
      senderId: senderId,
      receiverId: _currentUserId,
      type: messageType,
      textContent: messageType == MessageType.text ? content : null,
      imageUrl: messageType == MessageType.image ? imageUrl : null,
      isMine: false,
      createdAt: timestamp,
      status: MessageStatus.sent,
    );

    // 检查是否已存在（避免重复）
    final existIndex = _messages.indexWhere(
      (m) => m['id'] == msgId || m['localId'] == msgId,
    );

    if (existIndex != -1) {
      print('📨 消息已存在，跳过: $msgId');
      return;
    }

    // 添加到消息列表
    setState(() {
      _addChatLocalMessageToList(chatMessage);
      _sortMessagesByTime();
    });
    _scrollToBottom();

    // 保存到本地数据库
    _messageDatabase
        .insertMessage(chatMessage)
        .then((msg) {
          print('💾 新消息已保存到本地数据库: $msgId.  ${msg.localId}');
        })
        .catchError((e) {
          print('❌ 保存消息到数据库失败: $e');
        });
  }

  /// 将 ChatMessage 添加到消息列表
  void _addChatLocalMessageToList(ChatMessage message) {
    final msgMap = {
      'id': message.localId,
      'serverId': message.serverId,
      'localId': message.localId,
      'content': message.type == MessageType.at
          ? message.textContent
          : message.displayContent,
      'type': message.type.name,
      'isMine': message.isMine,
      'timestamp': message.createdAt,
      'status': message.status.name,
      'senderId': message.senderId,
      'imageLocalPath': message.imageLocalPath,
      'fileLocalPath': message.fileLocalPath,
      'imageUrl': message.imageUrl,
      'errorMessage': message.errorMessage,
      'voiceDuration': message.voiceDuration,
      'atInfoList': message.atInfoList,
      'isAll': message.isAll,
    };
    // 检查是否已存在
    final existIndex = _messages.indexWhere(
      (m) => m['localId'] == message.localId,
    );
    if (existIndex != -1) {
      _messages[existIndex] = msgMap;
    } else {
      print("添加数据库消息到列表: $msgMap");
      _messages.add(msgMap);
    }
  }

  /// 加载历史消息
  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    try {
      // 根据会话类型选择不同的拉取方法
      final result =
          widget.convType ==
              2 // 群聊
          ? await GroupController.to.getGroupMessages(
              widget.convId,
              widget.targetUserId,
              lastSeq: 0, // 0 表示从最新开始
              limit: 50,
            )
          : await _nativeService.imPullMessages(
              conversationId: widget.convId,
              convType: widget.convType,
              targetId: widget.targetUserId,
              lastSeq: 0, // 0 表示从最新开始
              limit: 50,
            );

      print('📥 拉取网络🛜历史消息结果: $result');

      if (result['errorCode'] == 0) {
        final data = result['data'];
        if (data != null && data is String && data.isNotEmpty) {
          try {
            final dataMap = json.decode(data) as Map<String, dynamic>;

            print("组装消息: $dataMap");

            // 解析消息列表
            final messages = dataMap['messages'] as List<dynamic>?;
            if (messages != null && messages.isNotEmpty) {
              print('📥 获取到 ${messages.length} 条历史消息');
              await _parseAndDisplayMessages(messages);
            } else {
              print('📥 暂无历史消息');
            }

            // 打印统计信息
            final totalCount = dataMap['total_count'];
            final hasMore = dataMap['has_more'];
            print('📥 总数: $totalCount, 还有更多: $hasMore');
          } catch (e) {
            print('❌ 解析历史消息失败: $e');
          }
        }
      } else {
        print('❌ 拉取历史消息失败: ${result['message']}');
      }
    } catch (e) {
      print('❌ 拉取历史消息异常: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 解析并显示历史消息
  Future<void> _parseAndDisplayMessages(List<dynamic> messages) async {
    // 判断会话在本地是否已有消息
    final bool convHasLocal = (await _messageDatabase.getMessages(
      widget.convId,
      limit: 1,
    )).isNotEmpty;
    final List<ChatMessage> toInsertBatch = [];

    for (final msg in messages) {
      // print("\n\n\n解析并显示历史消息:\n $msg \n\n\n\n");
      if (msg is Map<String, dynamic>) {
        // 尝试解析消息结构
        final msgId = msg['msg_id'] ?? msg['message_id'] ?? msg['id'] ?? '';
        final serverId = msg['server_msg_id'] ?? '';
        final content = msg['content'] ?? msg['text'] ?? msg['body'] ?? '';
        final senderId =
            msg['sender_id'] ?? msg['from'] ?? msg['from_id'] ?? '';
        final timestamp =
            msg['send_time'] ?? msg['timestamp'] ?? msg['created_at'] ?? 0;
        final mType = msg['m_type'] as int? ?? 0;
        final type = msg['type'] as String? ?? 'text';
        final imageUrl = msg['image_url'] as String?;
        final fileUrl = msg['file_url'] as String?;
        final ext = msg['ext'] as String?;
        final audioUrl = msg['audio_url'] as String?;
        final voiceDuration =
            msg['voice_duration'] as int? ?? msg['duration'] as int? ?? 0;
        final videoUrl = msg['video_url'] as String?;
        final thumbnailUrl = msg['thumbnail_url'] as String?;
        final videoDuration = msg['duration'] as int? ?? 0;
        final timestampInt = timestamp is int ? timestamp : 0;

        final isAll = false;
        List<Map<String, dynamic>> atInfoList = [];

        if (type == 'at') {
          final rawAtInfoList = msg['atInfoList'] as List<dynamic>?;
          if (rawAtInfoList != null && rawAtInfoList.isNotEmpty) {
            for (final info in rawAtInfoList) {
              if (info is Map<String, dynamic>) {
                atInfoList.add(info);
              }
            }
          }
        }

        // 发送者昵称和头像（如果有，主要用于群聊展示）
        final dynamic rawSenderName =
            msg['sender_name'] ??
            msg['nickname'] ??
            msg['from_nick'] ??
            msg['from_name'];
        final String? senderName = rawSenderName != null
            ? rawSenderName.toString()
            : null;
        final dynamic rawSenderAvatar =
            msg['sender_avatar'] ??
            msg['avatar'] ??
            msg['face_url'] ??
            msg['faceURL'];
        final String? senderAvatar = rawSenderAvatar != null
            ? rawSenderAvatar.toString()
            : null;

        // 判断是否是自己发的消息（根据发送者ID判断）
        final isMine = senderId == _currentUserId;

        // 解析消息类型
        String msgType = 'text';
        if (mType == 16) {
          // 通知消息
          msgType = 'notification';
        } else if (mType == 10) {
          // 通知消息
          msgType = 'at';
        } else if (mType == 1 || imageUrl != null && videoUrl == null) {
          msgType = 'image';
        } else if (mType == 2 || videoUrl != null) {
          msgType = 'video';
        }

        final msgMap = {
          'id': msgId.toString(),
          'serverId': serverId.toString(),
          'content': content.toString(),
          'type': msgType,
          'isMine': isMine,
          'timestamp': timestampInt,
          'status': 'sent',
          'senderId': senderId.toString(),
          'senderName': senderName,
          'senderAvatar': senderAvatar,
          'imageUrl': imageUrl ?? thumbnailUrl,
          'fileUrl': fileUrl,
          'audioUrl': audioUrl,
          'voiceDuration': voiceDuration,
          'videoUrl': videoUrl,
          'thumbnailUrl': thumbnailUrl,
          'videoDuration': videoDuration,
          'ext': ext,
        };

        if (type == 'at') {
          // 处理@消息
          msgMap['atInfoList'] = atInfoList;
          msgMap['isAll'] = isAll;
        }

        // 检查是否已存在（通过 id 去重）
        final existIndex = _messages.indexWhere(
          (m) => m['serverId'] == serverId.toString(),
        );
        if (existIndex == -1) {
          print("组装消息aa. 是否已经添加过?   未添加: $msgMap");
          _messages.add(msgMap);
        } else {
          print("组装消息bb. 是否已经添加过?   已经添加: $msgMap");
          // 更新已有消息
          _messages[existIndex] = msgMap;
        }

        // 组装数据库实体
        final msgTypeEnum = msgType == 'image'
            ? MessageType.image
            : msgType == 'video'
            ? MessageType.video
            : MessageType.text;
        final chatMessage = ChatMessage(
          localId: msgId.toString(),
          msgId: msgId.toString(),
          ext: ext.toString(),
          serverId: serverId.toString(),
          convId: widget.convId,
          senderId: senderId.toString(),
          receiverId: isMine ? widget.targetUserId : _currentUserId,
          type: msgTypeEnum,
          status: MessageStatus.sent,
          isMine: isMine,
          createdAt: timestampInt,
          sentAt: timestampInt,
          isRead: isMine ? true : false,
          textContent: msgTypeEnum == MessageType.text
              ? content.toString()
              : null,
          imageUrl: msgTypeEnum == MessageType.image
              ? imageUrl
              : msgTypeEnum == MessageType.video
              ? (thumbnailUrl ?? imageUrl)
              : null,
          fileUrl: msgTypeEnum == MessageType.voice
              ? (audioUrl ?? fileUrl)
              : msgTypeEnum == MessageType.video
              ? videoUrl ?? fileUrl
              : fileUrl,
          voiceDuration: msgTypeEnum == MessageType.voice
              ? voiceDuration
              : null,
          videoDuration: msgTypeEnum == MessageType.video
              ? videoDuration
              : null,
        );
        if (convHasLocal) {
          // 会话已有消息，逐条插入（replace）
          ChatMessage res = await _messageDatabase.insertMessage(chatMessage);
          print("插入消息: $res");
        } else {
          toInsertBatch.add(chatMessage);
        }

        // 格式化时间戳用于日志
        final dateTime = DateTime.fromMillisecondsSinceEpoch(timestampInt);
        final formattedTime = DateFormat(
          'yyyy-MM-dd HH:mm:ss',
        ).format(dateTime);
        print(
          '\n*****************\n 🛜 网络消息:  content=$content, msgId=$msgId, senderId=$senderId, fileUrl=$fileUrl,audioUrl=$audioUrl time=$formattedTime\n*****************\n',
        );
      }
    }

    // 如果此前没有本地消息，则批量插入
    if (!convHasLocal && toInsertBatch.isNotEmpty) {
      await _messageDatabase.insertMessages(toInsertBatch);
    }

    // 排序并更新UI
    _sortMessagesByTime();
    setState(() {});
    _scrollToBottom();
  }

  /// 发送消息
  Future<void> _sendMessage() async {
    // 检查是否禁言（群聊时）
    if (widget.convType == 2 && (widget.isMuted == true)) {
      EasyLoading.showInfo('该群已禁言，无法发送消息');
      return;
    }

    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      // 检查是否有@成员（群聊且已@成员列表不为空）
      final hasAtMembers =
          widget.convType == 2 &&
          widget.groupMembers != null &&
          _atMembers.isNotEmpty;

      if (hasAtMembers) {
        // 直接使用已存储的@成员信息发送@消息
        await _sendAtMessage(text, _atMembers);
      } else {
        // 发送普通文本消息
        await _sendNormalTextMessage(text);
      }
    } catch (e) {
      print('发送消息异常: $e');
      EasyLoading.showError('发送失败');
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  /// 发送普通文本消息（频道发言）
  Future<void> _sendNormalTextMessage(String text) async {
    final message = ChatMessage.text(
      convId: widget.convId,
      senderId: _currentUserId,
      receiverId: widget.targetUserId,
      content: text,
    );

    setState(() {
      _addChatLocalMessageToList(message);
    });
    _scrollToBottom();
    _messageController.clear();
    _atMembers.clear(); // 清空@成员列表

    // 频道发言：直接调用频道发言接口
    try {
      // 保存消息到数据库
      await _messageDatabase.insertMessage(message);

      // 更新消息状态为发送中
      message.status = MessageStatus.sending;
      await _messageDatabase.updateMessageStatus(
        message.localId,
        MessageStatus.sending,
      );

      // 调用频道发言接口
      // widget.targetUserId 就是社群ID（cmtyId）
      final result = await _nativeService.imSendChannelMessage(
        content: text,
        cid: widget.convId,
        ext: message.ext,
      );

      if (result['errorCode'] == 0) {
        // 更新消息状态为已发送
        message.status = MessageStatus.sent;
        message.sentAt = DateTime.now().millisecondsSinceEpoch;

        // 更新服务器消息ID
        if (result['data'] != null) {
          try {
            final dataStr = result['data'] as String?;
            if (dataStr != null && dataStr.isNotEmpty) {
              final data = json.decode(dataStr);
              if (data is Map && data['server_msg_id'] != null) {
                message.serverId = data['server_msg_id'].toString();
              }
            }
          } catch (e) {
            print('解析频道消息ID失败: $e');
          }
        }

        await _messageDatabase.updateMessage(message);
      } else {
        // 发送失败
        message.status = MessageStatus.failed;
        message.errorMessage = result['message'] ?? '发送失败';
        await _messageDatabase.updateMessageStatus(
          message.localId,
          MessageStatus.failed,
          errorMessage: message.errorMessage,
        );
        EasyLoading.showError(message.errorMessage ?? '发送失败');
      }
    } catch (e) {
      print('发送频道消息异常: $e');
      message.status = MessageStatus.failed;
      message.errorMessage = e.toString();
      await _messageDatabase.updateMessageStatus(
        message.localId,
        MessageStatus.failed,
        errorMessage: e.toString(),
      );
      EasyLoading.showError('发送失败: $e');
    }
  }

  /// 发送@消息
  Future<void> _sendAtMessage(
    String text,
    List<Map<String, dynamic>> atInfoList,
  ) async {
    try {
      // 检查是否是@所有人
      bool isAll = false;
      final filteredAtInfoList = <Map<String, dynamic>>[];

      for (final atInfo in atInfoList) {
        final nickname = atInfo['nickname'] as String? ?? '';

        // 检查是否是@所有人
        if (nickname == '所有人' || nickname == '@所有人') {
          isAll = true;
          break;
        }

        filteredAtInfoList.add(atInfo);
      }
      // 创建消息对象（用于本地显示）
      final message = ChatMessage.at(
        convId: widget.convId,
        senderId: _currentUserId,
        receiverId: widget.targetUserId,
        content: text,
        atInfoList: isAll ? [] : filteredAtInfoList,
        isAll: isAll,
      );
      setState(() {
        _addChatLocalMessageToList(message);
      });
      _scrollToBottom();
      _messageController.clear();
      _atMembers.clear(); // 清空@成员列表
      await _messageQueue.sendMessage(message);
    } catch (e) {
      print('发送@消息异常: $e');
      EasyLoading.showError('发送失败: $e');
    }
  }

  /// 处理头像点击事件
  Future<void> _onAvatarTap(
    String userId, {
    String? displayName,
    String? avatarUrl,
  }) async {
    try {
      // 检查是否是好友
      final result = await _nativeService.imGetContactList(
        page: 1,
        pageSize: 1000,
        relationship: 0, // 只获取好友关系
      );

      bool isFriend = false;
      FriendModel? friendInfo;

      if (result['errorCode'] == 0) {
        final dataStr = result['data'] as String?;
        if (dataStr != null && dataStr.isNotEmpty) {
          try {
            final data = json.decode(dataStr);
            final contacts = data['contacts'] as List? ?? [];

            // 查找是否是该用户的好友
            for (final contact in contacts) {
              final contactUserId =
                  contact['contact_user_id']?.toString() ?? '';
              if (contactUserId == userId) {
                isFriend = true;
                friendInfo = FriendModel.fromJson(contact);
                break;
              }
            }
          } catch (e) {
            print('❌ 解析好友列表失败: $e');
          }
        }
      }

      // 根据是否是好友跳转到不同页面
      if (isFriend && friendInfo != null) {
        // 是好友，跳转到好友详情页面
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FriendDetailPage(
              friend: friendInfo!,
              onDelete: () {
                // 删除好友后返回
                Navigator.pop(context);
              },
            ),
          ),
        );
      } else {
        // 不是好友，跳转到用户信息页面
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserInfoPage(
              userId: userId,
              displayName: displayName ?? userId,
              avatar: avatarUrl,
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ 处理头像点击失败: $e');
      // 如果检查失败，默认跳转到用户信息页面
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserInfoPage(
            userId: userId,
            displayName: displayName ?? userId,
            avatar: avatarUrl,
          ),
        ),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildMessageList() {
    if (_isLoading && _messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_messages.isEmpty) {
      return Center();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_shouldShowTimeSeparator(index))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildTimeSeparator(message['timestamp'] as int? ?? 0),
              ),
            _buildMessageItem(message),
          ],
        );
      },
    );
  }

  /// 判断是否需要显示时间分隔（与上一条消息间隔>=1小时或是第一条）
  bool _shouldShowTimeSeparator(int index) {
    if (index == 0) return true;
    final curr = _messages[index]['timestamp'] as int? ?? 0;
    final prev = _messages[index - 1]['timestamp'] as int? ?? 0;
    if (curr == 0 || prev == 0) return false;
    return (curr - prev).abs() >= 3600 * 1000;
  }

  /// 时间分隔组件
  Widget _buildTimeSeparator(int timestamp) {
    if (timestamp <= 0) return const SizedBox.shrink();
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    String formatted;
    final isSameDay =
        dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday =
        dateTime.year == yesterday.year &&
        dateTime.month == yesterday.month &&
        dateTime.day == yesterday.day;

    if (isSameDay) {
      // 今天：只显示时间
      formatted = DateFormat('HH:mm').format(dateTime);
    } else if (isYesterday) {
      // 昨天：显示“昨天 HH:mm”
      formatted = '昨天 ${DateFormat('HH:mm').format(dateTime)}';
    } else if (dateTime.year == now.year) {
      // 今年其他日期：MM-dd HH:mm
      formatted = DateFormat('MM-dd HH:mm').format(dateTime);
    } else {
      // 其他年份：完整日期
      formatted = DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        formatted,
        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
      ),
    );
  }

  Widget _buildMessageItem(Map<String, dynamic> message) {
    // print('\n\n----------------------------------\n\n 消息体构建: \n$message \n\n----------------------------------');
    final status = message['status'] as String? ?? 'sent';
    final type = message['type'] as String? ?? 'text';
    final localId = message['localId'] as String?;
    final senderId = message['senderId'] as String? ?? '';
    final timestamp = message['timestamp'] as int? ?? 0;
    final isImageMessage = type == 'image';
    final bool isGroupChat = widget.convType == 2;

    // 当前这条消息的发送人信息
    final String messageSenderId = senderId;
    final String senderName =
        ((message['senderName'] as String?)?.trim().isNotEmpty ?? false)
        ? (message['senderName'] as String)
        : messageSenderId;
    final String? senderAvatar = message['senderAvatar'] as String?;

    // 用 senderId 判断是否是自己发的消息（更可靠）
    final isMine = messageSenderId.isNotEmpty
        ? messageSenderId == _currentUserId
        : (message['isMine'] as bool? ?? false);

    // 判断是否是通知消息
    final isNotification = type == 'notification';

    // 通知消息使用特殊布局（居中，不显示头像）
    if (isNotification) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Center(child: _buildMessageContent(message, false)),
      );
    }

    // 对方发的消息如果是发送失败状态，则不显示（不合逻辑的数据）
    if (!isMine && status == 'failed') {
      return const SizedBox.shrink();
    }

    // 格式化时间
    String formattedTime = '';
    if (timestamp > 0) {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      if (dateTime.year == now.year &&
          dateTime.month == now.month &&
          dateTime.day == now.day) {
        // 今天只显示时间
        formattedTime = DateFormat('HH:mm').format(dateTime);
      } else if (dateTime.year == now.year) {
        // 今年显示月日时间
        formattedTime = DateFormat('MM-dd HH:mm').format(dateTime);
      } else {
        // 其他显示完整日期
        formattedTime = DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isMine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isMine
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMine) ...[
                // 对方头像（可点击）
                Builder(
                  builder: (context) {
                    // 单聊：使用会话级头像；群聊：使用每条消息发送人的头像/昵称
                    final String? avatarUrlToUse = isGroupChat
                        ? senderAvatar
                        : widget.avatar;
                    final String displayNameForInitial = isGroupChat
                        ? senderName
                        : widget.displayName;

                    return GestureDetector(
                      onTap: () => _onAvatarTap(
                        messageSenderId,
                        displayName: displayNameForInitial,
                        avatarUrl: avatarUrlToUse,
                      ),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.grey[300],
                        backgroundImage:
                            avatarUrlToUse != null && avatarUrlToUse.isNotEmpty
                            ? NetworkImage(avatarUrlToUse)
                            : null,
                        child:
                            (avatarUrlToUse == null || avatarUrlToUse.isEmpty)
                            ? Text(
                                displayNameForInitial.isNotEmpty
                                    ? displayNameForInitial[0]
                                    : '?',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],

              // 发送状态（我的消息显示在左侧，非图片消息）
              // if (isMine && !isImageMessage) ...[
              //   _buildMessageStatus(status, localId: localId),
              //   const SizedBox(width: 4),
              // ],

              // 消息气泡
              Flexible(
                child: GestureDetector(
                  onTap: () {
                    // 图片消息的点击在 _buildImageMessage 中处理
                    if (isImageMessage) {
                      return;
                    }
                    // 点击失败的消息重新发送
                    if (status == 'failed' && localId != null) {
                      _showResendDialog(localId, type);
                    }
                  },
                  onLongPress: () => _showMessageMenu(message, isMine),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: isMine
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      // 绘制一个直角三角形
                      isMine || isImageMessage
                          ? Container()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                CustomPaint(
                                  painter: VideoTrianglePainter(
                                    Colors.white,
                                    false,
                                  ), // 提供必需的颜色参数
                                  size: Size(10, 8), // 根据需要调整大小
                                ),
                              ],
                            ),
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.65,
                        ),
                        padding: isImageMessage
                            ? const EdgeInsets.all(4)
                            : const EdgeInsets.only(
                                left: 14,
                                right: 14,
                                top: 10,
                                bottom: 4,
                              ),
                        decoration: BoxDecoration(
                          color: isImageMessage
                              ? Colors.transparent
                              : (isMine
                                    ? Color.fromARGB(255, 182, 203, 254)
                                    : Colors.white),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: Radius.circular(isMine ? 12 : 0),
                            bottomRight: Radius.circular(isMine ? 0 : 12),
                          ),
                        ),
                        child: Stack(
                          children: [
                            // 消息内容
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: isImageMessage
                                    ? 0
                                    : 18, // 为时间留出空间（图片消息不需要）
                              ),
                              child: type == "at"
                                  ? _buildAtMessage(message, isMine, status)
                                  : _buildMessageContent(message, isMine),
                            ),
                            // 时间显示在底部角落
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: isImageMessage
                                    ? const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      )
                                    : EdgeInsets.zero,
                                decoration: isImageMessage
                                    ? BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(4),
                                      )
                                    : null,
                                child: Text(
                                  formattedTime,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: GbsColors.des9Color,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 绘制一个直角三角形
                      !isMine || isImageMessage
                          ? Container()
                          : Container(
                              // color: Colors.red,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  CustomPaint(
                                    painter: VideoTrianglePainter(
                                      Color.fromARGB(255, 182, 203, 254),
                                      true,
                                    ), // 提供必需的颜色参数
                                    size: Size(10, 8), // 根据需要调整大小
                                  ),
                                ],
                              ),
                            ),
                    ],
                  ),
                ),
              ),

              if (isMine) ...[const SizedBox(width: 8)],
            ],
          ),
        ],
      ),
    );
  }

  /// 显示重发确认对话框
  /// 显示消息长按菜单
  void _showMessageMenu(Map<String, dynamic> message, bool isMine) {
    final type = message['type'] as String? ?? 'text';
    final content = message['content'] as String? ?? '';
    final localId = message['localId'] as String?;
    final imageLocalPath = message['imageLocalPath'] as String?;
    final imageUrl = message['imageUrl'] as String?;
    final fileLocalPath = message['fileLocalPath'] as String?;
    final fileUrl = message['fileUrl'] as String?;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 拖动条
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),

              // 复制（文本消息）
              if (type == 'text' && content.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.copy, color: Colors.blue),
                  title: const Text('复制'),
                  onTap: () {
                    Navigator.pop(context);
                    Clipboard.setData(ClipboardData(text: content));
                    EasyLoading.showSuccess('已复制');
                  },
                ),

              // 分享
              ListTile(
                leading: const Icon(Icons.share, color: Colors.green),
                title: const Text('分享'),
                onTap: () async {
                  Navigator.pop(context);
                  await _shareMessage(
                    type,
                    content,
                    imageLocalPath,
                    imageUrl,
                    fileLocalPath,
                    fileUrl,
                  );
                },
              ),

              // 转发
              ListTile(
                leading: const Icon(Icons.forward, color: Colors.orange),
                title: const Text('转发'),
                onTap: () {
                  Navigator.pop(context);
                  EasyLoading.showInfo('转发功能开发中');
                },
              ),

              // 收藏
              ListTile(
                leading: const Icon(Icons.star_border, color: Colors.amber),
                title: const Text('收藏'),
                onTap: () {
                  Navigator.pop(context);
                  EasyLoading.showInfo('收藏功能开发中');
                },
              ),

              // 删除（自己的消息）
              if (message['id'] != null)
                ListTile(
                  leading: Icon(Icons.delete_outline, color: Colors.red[400]),
                  title: const Text('删除'),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteMessageDialog(localId ?? '', message['id']);
                  },
                ),

              // 撤回（自己的消息，2分钟内）
              if (isMine && localId != null)
                ListTile(
                  leading: Icon(Icons.undo, color: Colors.grey[600]),
                  title: const Text('撤回'),
                  onTap: () {
                    Navigator.pop(context);
                    EasyLoading.showInfo('撤回功能开发中');
                  },
                ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// 分享消息
  Future<void> _shareMessage(
    String type,
    String content,
    String? imageLocalPath,
    String? imageUrl,
    String? fileLocalPath,
    String? fileUrl,
  ) async {
    try {
      final pathHelper = FilePathHelper.instance;

      if (type == 'text') {
        // 分享文本
        await Share.share(content);
      } else if (type == 'image') {
        // 分享图片
        String? filePath;
        if (imageLocalPath != null) {
          filePath = await pathHelper.toFullPath(imageLocalPath);
        }

        if (filePath != null && File(filePath).existsSync()) {
          await Share.shareXFiles([XFile(filePath)]);
        } else if (imageUrl != null) {
          // 分享图片链接
          await Share.share(imageUrl);
        } else {
          EasyLoading.showError('无法分享此图片');
        }
      } else {
        EasyLoading.showInfo('暂不支持分享此类型消息');
      }
    } catch (e) {
      print('分享失败: $e');
      EasyLoading.showError('分享失败');
    }
  }

  /// 显示删除消息确认对话框
  void _showDeleteMessageDialog(String localId, String msgId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除消息'),
        content: const Text('确定要删除此消息吗？删除后不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteMessage(localId, msgId);
            },
            child: Text('删除', style: TextStyle(color: Colors.red[400])),
          ),
        ],
      ),
    );
  }

  /// 删除消息
  Future<void> _deleteMessage(String localId, String msgId) async {
    try {
      bool res = await ChatController.to.deleteMessage(localId, widget.convId);
      if (res) {
        EasyLoading.showSuccess('已删除');
      }
      // 从数据库删除
      if (localId.isNotEmpty) {
        await _messageDatabase.deleteMessage(localId);
      }

      // 从列表中移除
      setState(() {
        _messages.removeWhere((msg) => msg['localId'] == localId);
      });

      EasyLoading.showSuccess('已删除');
    } catch (e) {
      print('删除消息失败: $e');
      EasyLoading.showError('删除失败');
    }
  }

  /// 显示重发确认对话框
  void _showResendDialog(String localId, String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('发送失败'),
        content: const Text('是否重新发送此消息？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resendMessage(localId);
            },
            child: const Text('重发'),
          ),
        ],
      ),
    );
  }

  /// 重新发送消息
  Future<void> _resendMessage(String localId) async {
    try {
      await _messageQueue.resendMessage(localId);
    } catch (e) {
      print('重发消息失败: $e');
      EasyLoading.showError('重发失败');
    }
  }


  Widget _buildInputBar() {
    // 检查是否禁言（群聊时）
    final bool isMuted = widget.convType == 2 && (widget.isMuted == true);

    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Color(0xffE7ECF7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: isMuted
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.block, color: Colors.grey[400], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '该群已禁言',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            )
          : Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: GbsColors.lightBackgroundB,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _showEmojiPicker
                                ? Icons.keyboard
                                : Icons.emoji_emotions_outlined,
                            color: _showEmojiPicker
                                ? Colors.blue
                                : Colors.grey[600],
                          ),
                          onPressed: isMuted ? null : _toggleEmojiPicker,
                        ),

                        // 输入框
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                // decoration: BoxDecoration(
                                //   color: Colors.grey[100],
                                //   borderRadius: BorderRadius.circular(20),
                                // ),
                                child: TextField(
                                  controller: _messageController,
                                  focusNode: _focusNode,
                                  enabled: !isMuted,
                                  decoration: const InputDecoration(
                                    hintText: '输入消息...',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                  ),
                                  textInputAction: TextInputAction.send,
                                  onSubmitted: (_) => _sendMessage(),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 更多/发送按钮
                        InkWell(
                          onTap: isMuted
                              ? null
                              : () {
                                  _pickImageFromGallery();
                                },
                          child: Padding(
                            padding: EdgeInsetsGeometry.only(left: 8),
                            child: Image.asset(
                              'assets/img/msg/img.png',
                              width: 22,
                              height: 22,
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 更多/发送按钮
                InkWell(
                  onTap: isMuted
                      ? null
                      : () {
                          _sendMessage();
                        },
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 10),
                    width: 40,
                    height: 40,
                    child: Image.asset(
                      'assets/img/msg/send.png',
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  /// 选择@成员（支持多个成员）
  void _selectAtMembers(List<Map<String, dynamic>> selectedMembers) {
    if (selectedMembers.isEmpty) return;

    final text = _messageController.text;
    final cursorPosition = _messageController.selection.baseOffset;

    // 找到最后一个@符号的位置
    final beforeCursor = text.substring(0, cursorPosition);
    final lastAtIndex = beforeCursor.lastIndexOf('@');

    if (lastAtIndex != -1) {
      // 检查是否是@所有人
      final firstMember = selectedMembers[0];
      final userId = (firstMember['user_id'] as String?) ?? '';

      if (userId == 'all') {
        // @所有人
        final beforeAt = text.substring(0, lastAtIndex + 1);
        final afterCursor = text.substring(cursorPosition);
        final newText = '${beforeAt}所有人 $afterCursor';

        _messageController.text = newText;
        final newCursorPosition = lastAtIndex + 1 + '所有人'.length + 1;
        _messageController.selection = TextSelection.collapsed(
          offset: newCursorPosition,
        );

        // 记录@所有人
        _atMembers.add({'user_id': 'all', 'nickname': '所有人'});
      } else {
        // @多个成员
        final beforeAt = text.substring(0, lastAtIndex + 1);
        final afterCursor = text.substring(cursorPosition);

        // 构建@多个成员的文本，用空格分隔
        final memberNames = selectedMembers
            .map((member) {
              final alias = (member['member_alias'] as String?) ?? '';
              final nickname = (member['nickname'] as String?) ?? '';
              final memberUserId = (member['user_id'] as String?) ?? '';
              return alias.isNotEmpty
                  ? alias
                  : (nickname.isNotEmpty ? nickname : memberUserId);
            })
            .join(' ');

        final newText = '$beforeAt$memberNames $afterCursor';
        _messageController.text = newText;
        final newCursorPosition = lastAtIndex + 1 + memberNames.length + 1;
        _messageController.selection = TextSelection.collapsed(
          offset: newCursorPosition,
        );

        // 记录@的成员信息
        for (final member in selectedMembers) {
          final memberUserId = (member['user_id'] as String?) ?? '';
          final alias = (member['member_alias'] as String?) ?? '';
          final nickname = (member['nickname'] as String?) ?? '';
          final displayName = alias.isNotEmpty
              ? alias
              : (nickname.isNotEmpty ? nickname : memberUserId);

          _atMembers.add({'user_id': memberUserId, 'nickname': displayName});
        }
      }

      setState(() {
        // 触发UI更新
      });
    }
  }

  // /// 从输入框文本中解析@成员信息
  // List<Map<String, dynamic>> _parseAtMembersFromText(String text) {

  //   print(_atMembers);

  //   final atMembers = <Map<String, dynamic>>[];

  //   if (widget.groupMembers == null || widget.groupMembers!.isEmpty) {
  //     return atMembers;
  //   }

  //   // 使用正则表达式匹配@昵称（匹配@后面直到空格或@符号的内容）
  //   final regex = RegExp(r'@([^\s@]+)');
  //   final matches = regex.allMatches(text);

  //   for (final match in matches) {
  //     final atNickname = match.group(1) ?? '';
  //     if (atNickname.isEmpty) continue;

  //     // 检查是否是@所有人
  //     if (atNickname == '所有人') {
  //       // 检查是否已添加（避免重复）
  //       final exists = atMembers.any((m) => m['user_id'] == 'all');
  //       if (!exists) {
  //         atMembers.add({
  //           'user_id': 'all',
  //           'nickname': '所有人',
  //         });
  //       }
  //       continue;
  //     }

  //     // 在群成员列表中查找匹配的成员
  //     for (final member in widget.groupMembers!) {
  //       final userId = (member['user_id'] as String?) ?? '';
  //       final alias = (member['member_alias'] as String?) ?? '';
  //       final nickname = alias.isNotEmpty ? alias : userId;

  //       if (nickname == atNickname) {
  //         // 检查是否已添加（避免重复）
  //         final exists = atMembers.any((m) => m['user_id'] == userId);
  //         if (!exists) {
  //           atMembers.add({
  //             'user_id': userId,
  //             'nickname': nickname,
  //           });
  //         }
  //         break;
  //       }
  //     }
  //   }

  //   return atMembers;
  // }

  void _toggleEmojiPicker() {
    if (_showEmojiPicker) {
      // 关闭表情面板，打开键盘
      setState(() => _showEmojiPicker = false);
      _focusNode.requestFocus();
    } else {
      // 检查是否禁言（群聊时）
      if (widget.convType == 2 && (widget.isMuted == true)) {
        EasyLoading.showInfo('该群已禁言，无法发送消息');
        return;
      }

      // 关闭键盘，打开表情面板
      _focusNode.unfocus();
      setState(() {
        _showEmojiPicker = true;
      });
    }
  }

  /// 插入表情到输入框
  void _insertEmoji(String emoji) {
    final text = _messageController.text;
    final selection = _messageController.selection;

    // 获取光标位置
    final cursorPos = selection.baseOffset >= 0
        ? selection.baseOffset
        : text.length;

    // 在光标位置插入表情
    final newText =
        text.substring(0, cursorPos) + emoji + text.substring(cursorPos);
    _messageController.text = newText;

    // 移动光标到表情后面
    _messageController.selection = TextSelection.collapsed(
      offset: cursorPos + emoji.length,
    );

    // 触发重建以更新发送按钮状态
    setState(() {});
  }

  /// 构建表情选择器
  Widget _buildEmojiPicker() {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!, width: 0.5)),
      ),
      child: Column(
        children: [
          // 表情分类标签（可扩展）
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                _buildEmojiTab('😀', true),
                const Spacer(),
                // 删除按钮
                GestureDetector(
                  onTap: _deleteLastChar,
                  onLongPress: () {
                    // 长按清空输入
                    _messageController.clear();
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Icon(
                      Icons.backspace_outlined,
                      color: Colors.grey[600],
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 表情网格
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: ChatController.to.emojis.length,
              itemBuilder: (context, index) {
                return _buildEmojiItem(ChatController.to.emojis[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 构建表情分类标签
  Widget _buildEmojiTab(String emoji, bool isSelected) {
    return GestureDetector(
      onTap: () {
        // TODO: 切换表情分类
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 20)),
      ),
    );
  }

  /// 构建单个表情项
  Widget _buildEmojiItem(String emoji) {
    return GestureDetector(
      onTap: () => _insertEmoji(emoji),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
        child: Text(emoji, style: const TextStyle(fontSize: 26)),
      ),
    );
  }

  /// 删除最后一个字符
  void _deleteLastChar() {
    final text = _messageController.text;
    if (text.isEmpty) return;

    final selection = _messageController.selection;
    final cursorPos = selection.baseOffset >= 0
        ? selection.baseOffset
        : text.length;

    if (cursorPos > 0) {
      // 处理 emoji（可能占用多个字符）
      final beforeCursor = text.substring(0, cursorPos);
      final beforeChars = beforeCursor.characters.toList();

      if (beforeChars.isNotEmpty) {
        beforeChars.removeLast();
        final newBefore = beforeChars.join();
        final newText = newBefore + text.substring(cursorPos);
        _messageController.text = newText;
        _messageController.selection = TextSelection.collapsed(
          offset: newBefore.length,
        );
        setState(() {});
      }
    }
  }



  /// 从相册选择图片
  Future<void> _pickImageFromGallery() async {
    try {
      final List<XFile>? images = await _imagePicker.pickMultipleMedia(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
        limit: 9,
        requestFullMetadata: false,
      );
      if (images != null) {
        for (var media in images) {
          final path = media.path;
          final ext = path.split('.').last.toLowerCase();
          final isImage = [
            'jpg',
            'jpeg',
            'png',
            'gif',
            'webp',
            'heic',
          ].contains(ext);
          if (isImage) {
            await _sendImageMessage(path);
          } else {
            await _sendVideoMessage(path);
          }
        }
      }
    } catch (e) {
      print('选择媒体失败: $e');
      EasyLoading.showError('选择媒体失败');
    }
  }

  /// 发送图片消息
  Future<void> _sendImageMessage(String imagePath) async {
    // 检查是否禁言（群聊时）
    if (widget.convType == 2 && (widget.isMuted == true)) {
      EasyLoading.showInfo('该群已禁言，无法发送消息');
      return;
    }

    // 收起面板
    setState(() => _showMorePanel = false);

    try {
      // 先压缩图片
      final compressedPath = await ChatController.to.compressImage(imagePath);
      final pathToUse = compressedPath ?? imagePath;

      // 获取图片尺寸
      final file = File(pathToUse);
      if (!await file.exists()) {
        print('❌ 图片文件不存在: $pathToUse');
        return;
      }
      final decodedImage = await decodeImageFromList(await file.readAsBytes());

      // 将图片复制到永久存储目录（避免临时缓存被清理）
      final pathHelper = FilePathHelper.instance;
      final relativePath = await pathHelper.copyToPermanentStorage(
        pathToUse,
        'images',
      );

      print('📷 图片已保存: $relativePath');

      // 创建图片消息（存储相对路径）
      final message = ChatMessage.image(
        convId: widget.convId,
        senderId: _currentUserId,
        receiverId: widget.targetUserId,
        localPath: relativePath,
        width: decodedImage.width,
        height: decodedImage.height,
      );

      // 添加到消息列表
      setState(() {
        _addChatLocalMessageToList(message);
      });
      _scrollToBottom();

      // 通过队列发送（队列中会用完整路径读取文件）
      _messageQueue.sendMessage(message);
    } catch (e) {
      print('❌ 发送图片失败: $e');
    }
  }


  /// 发送视频消息
  Future<void> _sendVideoMessage(String videoPath) async {
    // 检查是否禁言（群聊时）
    if (widget.convType == 2 && (widget.isMuted == true)) {
      EasyLoading.showInfo('该群已禁言，无法发送消息');
      return;
    }

    // 收起面板
    setState(() => _showMorePanel = false);

    try {
      // 尝试压缩视频
      String finalVideoPath = videoPath;
      final compressedPath = await ChatController.to.compressVideo(videoPath);
      if (compressedPath != null) {
        finalVideoPath = compressedPath;
        print('✅ 使用压缩后的视频: $finalVideoPath');
      } else {
        print('⚠️ 压缩失败，使用原视频: $videoPath');
      }

      // 获取视频时长
      int? durationSeconds;
      try {
        final controller = VideoPlayerController.file(File(finalVideoPath));
        await controller.initialize();
        durationSeconds = controller.value.duration.inSeconds;
        await controller.dispose();
      } catch (_) {}

      // 生成缩略图（使用最终视频路径）
      String? thumbTemp;
      int? thumbWidth;
      int? thumbHeight;
      try {
        thumbTemp = await VideoThumbnail.thumbnailFile(
          video: finalVideoPath,
          imageFormat: ImageFormat.PNG,
          maxWidth: 512,
          quality: 75,
        );
        if (thumbTemp != null) {
          final bytes = await File(thumbTemp).readAsBytes();
          final decoded = await decodeImageFromList(bytes);
          thumbWidth = decoded.width;
          thumbHeight = decoded.height;
        }
      } catch (e) {
        print('⚠️ 生成视频缩略图失败: $e');
      }

      // 将视频复制到永久存储目录（避免临时缓存被清理）
      final pathHelper = FilePathHelper.instance;
      final relativePath = await pathHelper.copyToPermanentStorage(
        finalVideoPath,
        'videos',
      );
      String? thumbRelativePath;
      if (thumbTemp != null) {
        thumbRelativePath = await pathHelper.copyToPermanentStorage(
          thumbTemp,
          'images',
        );
      }

      print('🎬 视频已保存: $relativePath');

      // 创建视频消息（存储相对路径）
      final message = ChatMessage.video(
        convId: widget.convId,
        senderId: _currentUserId,
        receiverId: widget.targetUserId,
        localPath: relativePath,
        coverLocalPath: thumbRelativePath,
        duration: durationSeconds,
        coverWidth: thumbWidth,
        coverHeight: thumbHeight,
      );

      // 添加到消息列表
      setState(() {
        _addChatLocalMessageToList(message);
      });
      _scrollToBottom();

      // 通过队列发送（队列中会用完整路径读取文件）
      _messageQueue.sendMessage(message);
    } catch (e) {
      print('❌ 发送视频失败: $e');
      EasyLoading.showError('发送视频失败');
    }
  }

  /// 构建消息内容（支持图片）
  Widget _buildMessageContent(Map<String, dynamic> message, bool isMine) {
    final type = message['type'] as String? ?? 'text';
    final content = message['content'] as String? ?? '';
    final status = message['status'] as String? ?? 'sent';

    if (type == 'image') {
      return ImageMsgView(
        message: message,
        isMine: isMine,
        status: status,
        onTap: () {
          _onImageTap(message);
        },
      );
    }

    if (type == 'video') {
      return VideoMsgView(message: message, isMine: isMine, status: status);
    }

    if (type == 'notification') {
      return _buildNotificationMessage(message);
    }
    if (type == 'at') {
      return _buildAtMessage(message, isMine, status);
    }

    // 默认文本消息
    return Text(
      content,
      style: TextStyle(fontSize: 15, color: GbsColors.titleColor),
    );
  }

  // 点击图片
  void _onImageTap(Map<String, dynamic> message) {
    // 收集所有图片消息
    final imageMessages = _messages.where((m) {
      final msgType = m['type'] as String? ?? '';
      final msgLocalPath = m['imageLocalPath'] as String?;
      final msgImageUrl = m['imageUrl'] as String?;
      return msgType == 'image' &&
          (msgLocalPath != null || msgImageUrl != null);
    }).toList();

    if (imageMessages.isEmpty) {
      return;
    }

    // 找到当前图片的索引
    final currentIndex = imageMessages.indexWhere(
      (m) => m['id'] == message['id'],
    );
    final initialIndex = currentIndex >= 0 ? currentIndex : 0;

    // 跳转到预览页面
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImagePreviewPage(
          imageMessages: imageMessages,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  /// 构建@消息
  Widget _buildAtMessage(
    Map<String, dynamic> message,
    bool isMine,
    String status,
  ) {
    List<Map<String, dynamic>> atInfoList = [];
    if (message['atInfoList'] != null &&
        message['atInfoList'] is List<Map<String, dynamic>>) {
      atInfoList = message['atInfoList'];
    }
    final isAll = message['isAll'] as bool? ?? false;
    final content = message['content'] as String? ?? '';

    // 解析@消息内容，构建RichText
    return _buildAtMessageContent(content, atInfoList, isAll, isMine);
  }

  /// 构建@消息内容（支持高亮和点击）
  Widget _buildAtMessageContent(
    String content,
    List<Map<String, dynamic>> atInfoList,
    bool isAll,
    bool isMine,
  ) {
    if (atInfoList.isEmpty && !isAll) {
      // 普通文本消息
      return Text(
        content,
        style: TextStyle(
          fontSize: 15,
          color: isMine ? Colors.white : Colors.black87,
        ),
      );
    }

    // 使用更精确的解析方式
    List<TextSpan> spans = [];
    int currentIndex = 0;

    // 创建@用户映射，用于快速查找
    Map<String, Map<String, dynamic>> atUserMap = {};
    for (final atInfo in atInfoList) {
      final nickname = atInfo['nickname'] as String?;
      if (nickname != null) {
        atUserMap['@$nickname'] = atInfo;
      }
    }

    // 按顺序处理所有@提及
    while (currentIndex < content.length) {
      int earliestIndex = content.length;
      String? foundAtText;
      Map<String, dynamic>? foundAtInfo;

      // 查找最早出现的@文本
      for (final atText in atUserMap.keys) {
        final index = content.indexOf(atText, currentIndex);
        if (index != -1 && index < earliestIndex) {
          earliestIndex = index;
          foundAtText = atText;
          foundAtInfo = atUserMap[atText];
        }
      }

      // 检查@所有人
      if (isAll) {
        final atAllText = '@所有人';
        final index = content.indexOf(atAllText, currentIndex);
        if (index != -1 && index < earliestIndex) {
          earliestIndex = index;
          foundAtText = atAllText;
          foundAtInfo = null; // @所有人特殊处理
        }
      }

      if (foundAtText != null && earliestIndex < content.length) {
        // 添加@之前的普通文本
        if (earliestIndex > currentIndex) {
          spans.add(
            TextSpan(text: content.substring(currentIndex, earliestIndex)),
          );
        }

        // 添加高亮的@部分
        if (foundAtText == '@所有人') {
          spans.add(
            TextSpan(
              text: foundAtText,
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  print('点击了@所有人');
                  // TODO: 可以滚动到消息位置或执行其他操作
                },
            ),
          );
        } else if (foundAtInfo != null) {
          final userId = foundAtInfo['user_id'] as String;
          final nickname = foundAtInfo['nickname'] as String;

          spans.add(
            TextSpan(
              text: foundAtText,
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  _onAtUserTapped(userId, nickname);
                },
            ),
          );
        }

        currentIndex = earliestIndex + foundAtText.length;
      } else {
        // 没有更多@，添加剩余文本
        spans.add(TextSpan(text: content.substring(currentIndex)));
        break;
      }
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 15,
          color: isMine ? Colors.white : Colors.black87,
        ),
        children: spans,
      ),
    );
  }

  /// @用户点击处理
  void _onAtUserTapped(String userId, String nickname) {
    print('点击了@$nickname (ID: $userId)');
    // TODO: 可以跳转到用户详情页或在聊天框中@该用户
    // 例如：跳转到用户资料页
    // Get.to(() => UserProfilePage(userId: userId));
  }

  /// 构建通知消息
  Widget _buildNotificationMessage(Map<String, dynamic> message) {
    final content = message['content'] as String? ?? '';

    // 如果内容为空，显示默认提示
    final displayContent = content.isEmpty ? '系统通知' : content;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        displayContent,
        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
        textAlign: TextAlign.center,
      ),
    );
  }
}
