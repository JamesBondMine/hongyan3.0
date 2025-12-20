import 'dart:convert';
import 'dart:io';
import 'package:bell_bird_talk/pages/chat/search_message_history.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import '../../services/file_path_helper.dart';
import '../../services/native_bridge.dart';
import '../../services/message_queue.dart';
import '../../services/message_database.dart';
import '../../models/chat_message.dart';
import '../../controllers/global_controller.dart';
import '../../widgets/voice_record_panel.dart';
import 'chat_detail_page.dart';
import 'image_preview_page.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:video_compress/video_compress.dart';
import 'user_info_page.dart';
import '../friends/friend_detail_page.dart';
import '../models/friend_model.dart';

/// 单人聊天页面
class ChatPage extends StatefulWidget {
  final String convId;
  final String displayName;
  final String? avatar;
  final String targetUserId;
  final int convType; // 0=单聊,2=群聊
  final PreferredSizeWidget? customAppBar;
  final List<Map<String, dynamic>>? groupMembers; // 群成员列表（群聊时使用）
  final bool? isMuted; // 是否禁言（群聊时使用）
  
  const ChatPage({
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
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final IOSNativeService _nativeService = IOSNativeService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  bool _showEmojiPicker = false;
  bool _showMorePanel = false;
  bool _showVoicePanel = false;
  
  final ImagePicker _imagePicker = ImagePicker();
  final MessageQueueManager _messageQueue = MessageQueueManager();
  final MessageDatabase _messageDatabase = MessageDatabase();
  final GlobalController _globalCtrl = Get.find<GlobalController>();
  final Map<String, String> _voiceCache = {}; // 缓存远程语音的本地路径（key=url）
  
  // 语音播放器
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _playingVoiceId; // 当前正在播放的语音消息ID
  bool _isDownloading = false;
  
  /// 新消息监听器
  Worker? _newMessageWorker;
  
  /// 当前用户ID
  String get _currentUserId => _globalCtrl.currentUser.value?.id ?? '';
  
  // @功能相关
  List<Map<String, dynamic>> _atMembers = []; // 已@的成员列表
  bool _showAtMemberPicker = false; // 是否显示@成员选择器
  String _atKeyword = ''; // @搜索关键词
  
  // 常用表情列表
  static const List<String> _emojis = [
    '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂',
    '🙂', '🙃', '😉', '😊', '😇', '🥰', '😍', '🤩',
    '😘', '😗', '😚', '😙', '🥲', '😋', '😛', '😜',
    '🤪', '😝', '🤑', '🤗', '🤭', '🤫', '🤔', '🤐',
    '🤨', '😐', '😑', '😶', '😏', '😒', '🙄', '😬',
    '🤥', '😌', '😔', '😪', '🤤', '😴', '😷', '🤒',
    '🤕', '🤢', '🤮', '🤧', '🥵', '🥶', '🥴', '😵',
    '🤯', '🤠', '🥳', '🥸', '😎', '🤓', '🧐', '😕',
    '😟', '🙁', '☹️', '😮', '😯', '😲', '😳', '🥺',
    '😦', '😧', '😨', '😰', '😥', '😢', '😭', '😱',
    '😖', '😣', '😞', '😓', '😩', '😫', '🥱', '😤',
    '😡', '😠', '🤬', '😈', '👿', '💀', '☠️', '💩',
    '👍', '👎', '👏', '🙌', '👐', '🤲', '🤝', '🙏',
    '✌️', '🤞', '🤟', '🤘', '🤙', '👈', '👉', '👆',
    '👇', '☝️', '👋', '🤚', '🖐️', '✋', '🖖', '👌',
    '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍',
    '💔', '❣️', '💕', '💞', '💓', '💗', '💖', '💘',
    '💝', '💟', '🔥', '✨', '🎉', '🎊', '🎁', '🎈',
  ];

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
  }
  
  /// 监听输入框内容变化，检测@符号
  void _onTextChanged() {
    if (widget.convType != 2 || widget.groupMembers == null || widget.groupMembers!.isEmpty) {
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
        if (afterAt.isEmpty || (!afterAt.contains(' ') && !afterAt.contains('@'))) {
          // @后面没有空格或其他@，显示成员选择器
          _atKeyword = afterAt;
          if (!_showAtMemberPicker) {
            setState(() {
              _showAtMemberPicker = true;
            });
          } else {
            // 更新搜索关键词
            setState(() {
              _atKeyword = afterAt;
            });
          }
          return;
        }
      }
    }
    
    // 没有找到有效的@符号，隐藏选择器
    if (_showAtMemberPicker) {
      setState(() {
        _showAtMemberPicker = false;
        _atKeyword = '';
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: widget.customAppBar ?? _buildAppBar(),
      body: Column(
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
          if (_showVoicePanel)
            VoiceRecordPanel(
              onSend: _handleVoiceSend,
              onClose: () => setState(() => _showVoicePanel = false),
              autoStart: true,
            )
          else ...[
            _buildInputBar(),
            // 表情选择器
            if (_showEmojiPicker) _buildEmojiPicker(),
            // 更多面板
            if (_showMorePanel) _buildMorePanel(),
          ],
        ],
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
    _audioPlayer.dispose();
    super.dispose();
  }

  /// 仅加载本地“我发送的”消息，用于与网络消息合并展示
  Future<void> _loadLocalMyMessages() async {
    final localMessages = await _messageDatabase.getMessages(widget.convId);
    if (localMessages.isEmpty) return;

    final myMessages = localMessages.where((msg) => msg.senderId == _currentUserId).toList();
    if (myMessages.isEmpty) return;

    print('📦 加载本地我发送的消息: ${myMessages.length} 条');
    for (final msg in myMessages) {
        _addChatMessageToList(msg);
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
      final index = _messages.indexWhere((m) => m['localId'] == message.localId);
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
    final senderId = message['from'] as String? ?? message['sender_id'] as String? ?? '';
    
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
    final msgId = message['msg_id'] as String? ?? message['message_id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString();
    final content = message['content'] as String? ?? message['text'] as String? ?? '';
    final timestamp = message['send_time'] as int? ?? message['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch;
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
    final existIndex = _messages.indexWhere((m) => 
        m['id'] == msgId || m['localId'] == msgId
    );
    
    if (existIndex != -1) {
      print('📨 消息已存在，跳过: $msgId');
      return;
    }
    
    // 添加到消息列表
    setState(() {
      _addChatMessageToList(chatMessage);
      _sortMessagesByTime();
    });
    _scrollToBottom();
    
    // 保存到本地数据库
    _messageDatabase.insertMessage(chatMessage).then((msg) {
      print('💾 新消息已保存到本地数据库: $msgId.  ${msg.localId}');
    }).catchError((e) {
      print('❌ 保存消息到数据库失败: $e');
    });
  }

  /// 将 ChatMessage 添加到消息列表
  void _addChatMessageToList(ChatMessage message) {
    final msgMap = {
      'id': message.serverId ?? message.localId,
      'localId': message.localId,
      'content': message.displayContent,
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
    };
    // 检查是否已存在
    final existIndex = _messages.indexWhere((m) => m['localId'] == message.localId);
    if (existIndex != -1) {
      _messages[existIndex] = msgMap;
    } else {
      print("添加消息到列表: $msgMap");
      _messages.add(msgMap);
    }
  }

  /// 加载历史消息
  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    
    try {
      // 根据会话类型选择不同的拉取方法
      final result = widget.convType == 2  // 群聊
          ? await _nativeService.imPullGroupMessages(
              conversationId: widget.convId,
              groupId: widget.targetUserId,
              lastSeq: 0,   // 0 表示从最新开始
              limit: 50,
            )
          : await _nativeService.imPullMessages(
              conversationId: widget.convId,
              convType: widget.convType,
              targetId: widget.targetUserId,
              lastSeq: 0,   // 0 表示从最新开始
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
    final bool convHasLocal =
        (await _messageDatabase.getMessages(widget.convId, limit: 1)).isNotEmpty;
    final List<ChatMessage> toInsertBatch = [];
    
    for (final msg in messages) {
      print("\n\n\n解析并显示历史消息:\n $msg \n\n\n\n");
      if (msg is Map<String, dynamic>) {
        // 尝试解析消息结构
        final msgId = msg['msg_id'] ?? msg['message_id'] ?? msg['id'] ?? '';
        final content = msg['content'] ?? msg['text'] ?? msg['body'] ?? '';
        final senderId = msg['sender_id'] ?? msg['from'] ?? msg['from_id'] ?? '';
        final timestamp = msg['send_time'] ?? msg['timestamp'] ?? msg['created_at'] ?? 0;
        final mType = msg['m_type'] as int? ?? 0;
        final imageUrl = msg['image_url'] as String?;
        final fileUrl = msg['file_url'] as String?;
        final ext = msg['ext'] as String?;
        final audioUrl = msg['audio_url'] as String?;
        final voiceDuration = msg['voice_duration'] as int? ?? msg['duration'] as int? ?? 0;
        final videoUrl = msg['video_url'] as String?;
        final thumbnailUrl = msg['thumbnail_url'] as String?;
        final videoDuration = msg['duration'] as int? ?? 0;
        final timestampInt = timestamp is int ? timestamp : 0;

        // 发送者昵称和头像（如果有，主要用于群聊展示）
        final dynamic rawSenderName = msg['sender_name'] ??
            msg['nickname'] ??
            msg['from_nick'] ??
            msg['from_name'];
        final String? senderName = rawSenderName != null ? rawSenderName.toString() : null;
        final dynamic rawSenderAvatar =
            msg['sender_avatar'] ?? msg['avatar'] ?? msg['face_url'] ?? msg['faceURL'];
        final String? senderAvatar = rawSenderAvatar != null ? rawSenderAvatar.toString() : null;
        
        // 判断是否是自己发的消息（根据发送者ID判断）
        final isMine = senderId == _currentUserId;
        
        // 解析消息类型
        String msgType = 'text';
        if (mType == 16) {
          // 通知消息
          msgType = 'notification';
        } else if (mType == 1 || imageUrl != null && videoUrl == null) {
          msgType = 'image';
        } else if (mType == 2 || videoUrl != null) {
          msgType = 'video';
        } else if (mType == 3 || (fileUrl != null && voiceDuration > 0)) {
          msgType = 'voice';
        }
        
        final msgMap = {
          'id': msgId.toString(),
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
        
        print("组装消息2: $msgMap");
        // 检查是否已存在（通过 id 去重）
        final existIndex = _messages.indexWhere((m) => m['id'] == msgId.toString());
        if (existIndex == -1) {
          _messages.add(msgMap);
        } else {
          // 更新已有消息
          _messages[existIndex] = msgMap;
        }
        
        // 组装数据库实体
        final msgTypeEnum = msgType == 'image'
            ? MessageType.image
            : msgType == 'voice'
                ? MessageType.voice
                : msgType == 'video'
                    ? MessageType.video
                    : MessageType.text;
        final chatMessage = ChatMessage(
          localId: msgId.toString(),
          msgId: msgId.toString(),
          ext: ext.toString(),
          serverId: msgId.toString(),
          convId: widget.convId,
          senderId: senderId.toString(),
          receiverId: isMine ? widget.targetUserId : _currentUserId,
          type: msgTypeEnum,
          status: MessageStatus.sent,
          isMine: isMine,
          createdAt: timestampInt,
          sentAt: timestampInt,
          isRead: isMine ? true : false,
          textContent: msgTypeEnum == MessageType.text ? content.toString() : null,
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
          voiceDuration: msgTypeEnum == MessageType.voice ? voiceDuration : null,
          videoDuration: msgTypeEnum == MessageType.video ? videoDuration : null,
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
        final formattedTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
        print('\n*****************\n 🛜 网络消息:  content=$content, msgId=$msgId, senderId=$senderId, fileUrl=$fileUrl,audioUrl=$audioUrl time=$formattedTime\n*****************\n');
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
      // 检查是否有@成员（群聊且消息中包含@）
      final hasAtMembers = widget.convType == 2 && 
                           widget.groupMembers != null && 
                           text.contains('@');
      
      if (hasAtMembers) {
        // 从文本中解析@成员信息
        final parsedAtMembers = _parseAtMembersFromText(text);
        
        if (parsedAtMembers.isNotEmpty) {
          // 发送@消息
          await _sendAtMessage(text, parsedAtMembers);
        } else {
          // 没有找到匹配的@成员，发送普通文本消息
          await _sendNormalTextMessage(text);
        }
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
  
  /// 发送普通文本消息
  Future<void> _sendNormalTextMessage(String text) async {
    final message = ChatMessage.text(
      convId: widget.convId,
      senderId: _currentUserId,
      receiverId: widget.targetUserId,
      content: text,
    );
    
    setState(() {
      _addChatMessageToList(message);
    });
    _scrollToBottom();
    _messageController.clear();
    _atMembers.clear(); // 清空@成员列表

    // 通过队列发送（持久化 + 状态统一处理）
    await _messageQueue.sendMessage(message);
  }
  
  /// 发送@消息
  Future<void> _sendAtMessage(String text, List<Map<String, dynamic>> atInfoList) async {
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
      
      // 调用原生方法发送@消息
      final result = await _nativeService.imSendGroupAtMessage(
        content: text,
        conversationId: widget.convId,
        groupId: widget.targetUserId,
        atInfoList: isAll ? [] : filteredAtInfoList,
        isAll: isAll,
      );
      
      if (result['errorCode'] == 0) {
        // 创建消息对象（用于本地显示）
        final message = ChatMessage.text(
          convId: widget.convId,
          senderId: _currentUserId,
          receiverId: widget.targetUserId,
          content: text,
        );
        
        setState(() {
          _addChatMessageToList(message);
        });
        _scrollToBottom();
        _messageController.clear();
        _atMembers.clear(); // 清空@成员列表
      } else {
        EasyLoading.showError(result['message']?.toString() ?? '发送失败');
      }
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
              final contactUserId = contact['contact_user_id']?.toString() ?? '';
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

  
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Column(
        children: [
          Text(
            widget.displayName,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          Text(
            '会话ID: ${widget.convId}',
            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7)),
          ),
        ],
      ),
      centerTitle: true,
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SearchMessageHistory(
                  convId: widget.convId,
                  targetId: widget.targetUserId,
                  displayName: widget.displayName,
                  avatarUrl: widget.avatar ?? '',
                  convType: widget.convType,
                ),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.more_horiz),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatDetailPage(
                  convId: widget.convId,
                  targetId: widget.targetUserId,
                  displayName: widget.displayName,
                  avatarUrl: widget.avatar ?? '',
                  convType: widget.convType,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMessageList() {
    if (_isLoading && _messages.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              '暂无消息',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '发送一条消息开始聊天吧',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      );
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
        dateTime.year == now.year && dateTime.month == now.month && dateTime.day == now.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = dateTime.year == yesterday.year &&
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
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildMessageItem(Map<String, dynamic> message) {
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
        child: Center(
          child: _buildMessageContent(message, false),
        ),
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
      if (dateTime.year == now.year && dateTime.month == now.month && dateTime.day == now.day) {
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
        crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMine) ...[
                // 对方头像（可点击）
                Builder(
                  builder: (context) {
                    // 单聊：使用会话级头像；群聊：使用每条消息发送人的头像/昵称
                    final String? avatarUrlToUse =
                        isGroupChat ? senderAvatar : widget.avatar;
                    final String displayNameForInitial =
                        isGroupChat ? senderName : widget.displayName;

                    return GestureDetector(
                      onTap: () => _onAvatarTap(
                        messageSenderId,
                        displayName: displayNameForInitial,
                        avatarUrl: avatarUrlToUse,
                      ),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: avatarUrlToUse != null &&
                                avatarUrlToUse.isNotEmpty
                            ? NetworkImage(avatarUrlToUse)
                            : null,
                        child: (avatarUrlToUse == null ||
                                avatarUrlToUse.isEmpty)
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
              if (isMine && !isImageMessage) ...[
                _buildMessageStatus(status, localId: localId),
                const SizedBox(width: 4),
              ],
              
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
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.65,
                    ),
                    padding: isImageMessage 
                        ? const EdgeInsets.all(4) 
                        : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isImageMessage ? Colors.transparent : (isMine ? Colors.blue : Colors.white),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMine ? 16 : 4),
                        bottomRight: Radius.circular(isMine ? 4 : 16),
                      ),
                      boxShadow: isImageMessage ? null : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _buildMessageContent(message, isMine),
                  ),
                ),
              ),
              
              if (isMine) ...[
                const SizedBox(width: 8),
                // 我的头像
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.blue[100],
                  backgroundImage: _globalCtrl.currentUser.value?.avatar != null && 
                      _globalCtrl.currentUser.value!.avatar!.isNotEmpty
                      ? NetworkImage(_globalCtrl.currentUser.value!.avatar!)
                      : null,
                  child: _globalCtrl.currentUser.value?.avatar == null || 
                      _globalCtrl.currentUser.value!.avatar!.isEmpty
                      ? Icon(
                          Icons.person,
                          size: 20,
                          color: Colors.blue[400],
                        )
                      : null,
                ),
              ],
            ],
          ),
          // 显示发送时间和发送人ID
          Padding(
            padding: EdgeInsets.only(
              left: isMine ? 0 : 44, // 对齐头像
              right: isMine ? 44 : 0,
              top: 4,
            ),
            child: Text(
              '$formattedTime  ${message['msg_id']}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[400],
              ),
            ),
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
                  await _shareMessage(type, content, imageLocalPath, imageUrl, fileLocalPath, fileUrl);
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
              if (isMine && localId != null)
                ListTile(
                  leading: Icon(Icons.delete_outline, color: Colors.red[400]),
                  title: const Text('删除'),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteMessageDialog(localId);
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
      } else if (type == 'voice') {
        // 分享语音
        String? filePath;
        if (fileLocalPath != null) {
          filePath = await pathHelper.toFullPath(fileLocalPath);
        }
        
        if (filePath != null && File(filePath).existsSync()) {
          await Share.shareXFiles([XFile(filePath)]);
        } else if (fileUrl != null) {
          await Share.share(fileUrl);
        } else {
          EasyLoading.showError('无法分享此语音');
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
  void _showDeleteMessageDialog(String localId) {
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
              await _deleteMessage(localId);
            },
            child: Text('删除', style: TextStyle(color: Colors.red[400])),
          ),
        ],
      ),
    );
  }
  
  /// 删除消息
  Future<void> _deleteMessage(String localId) async {
    try {
      // 从数据库删除
      await _messageDatabase.deleteMessage(localId);
      
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

  /// 构建消息状态指示器
  Widget _buildMessageStatus(String status, {String? localId}) {
    switch (status) {
      case 'sending':
      case 'pending':
        return SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
          ),
        );
      case 'failed':
        return GestureDetector(
          onTap: () {
            if (localId != null) {
              _showResendDialog(localId, 'text');
            }
          },
          child: Icon(
            Icons.error_outline,
            size: 16,
            color: Colors.red[400],
          ),
        );
      case 'sent':
      case 'delivered':
        return Icon(
          Icons.done,
          size: 14,
          color: Colors.grey[400],
        );
      case 'read':
        return Icon(
          Icons.done_all,
          size: 14,
          color: Colors.blue[400],
        );
      default:
        return Icon(
          Icons.done,
          size: 14,
          color: Colors.grey[400],
        );
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
        color: Colors.white,
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
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : Row(
              children: [
                // 语音按钮
                IconButton(
                  icon: Icon(
                    Icons.mic,
                    color: _showVoicePanel ? Colors.blue : Colors.grey[600],
                  ),
                  onPressed: _toggleVoicePanel,
                ),
                
                // 输入框
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          controller: _messageController,
                          focusNode: _focusNode,
                          enabled: !isMuted,
                          decoration: const InputDecoration(
                            hintText: '输入消息...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                          ),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      // @成员选择器
                      if (_showAtMemberPicker && widget.groupMembers != null)
                        _buildAtMemberPicker(),
                    ],
                  ),
                ),
                
                // 表情按钮
                IconButton(
                  icon: Icon(
                    _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined,
                    color: _showEmojiPicker ? Colors.blue : Colors.grey[600],
                  ),
                  onPressed: isMuted ? null : _toggleEmojiPicker,
                ),
                
                // 更多/发送按钮
                IconButton(
                  icon: Icon(
                    _messageController.text.trim().isEmpty 
                        ? (_showMorePanel ? Icons.close : Icons.add_circle_outline)
                        : Icons.send,
                    color: _messageController.text.trim().isEmpty 
                        ? (_showMorePanel ? Colors.blue : Colors.grey[600])
                        : Colors.blue,
                  ),
                  onPressed: isMuted
                      ? null
                      : () {
                          if (_messageController.text.trim().isNotEmpty) {
                            _sendMessage();
                          } else {
                            _toggleMorePanel();
                          }
                        },
                ),
              ],
            ),
    );
  }


  /// 构建@成员选择器
  Widget _buildAtMemberPicker() {
    if (widget.groupMembers == null || widget.groupMembers!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // 过滤群成员（排除当前用户，并根据关键词搜索）
    List<Map<String, dynamic>> filteredMembers = widget.groupMembers!
        .where((member) {
          final userId = (member['user_id'] as String?) ?? '';
          final alias = (member['member_alias'] as String?) ?? '';
          final nickname = alias.isNotEmpty ? alias : userId;
          
          // 排除当前用户
          if (userId == _currentUserId) return false;
          
          // 如果有搜索关键词，进行过滤
          if (_atKeyword.isNotEmpty) {
            return nickname.toLowerCase().contains(_atKeyword.toLowerCase()) ||
                   userId.toLowerCase().contains(_atKeyword.toLowerCase());
          }
          
          return true;
        })
        .toList();
    
    // 限制显示数量
    if (filteredMembers.length > 9) {
      filteredMembers = filteredMembers.sublist(0, 9);
    }
    
    // 构建成员列表项
    final List<Widget> memberItems = [];
    
    // 添加"@所有人"选项（放在最前面）
    memberItems.add(
      ListTile(
        dense: true,
        leading: const CircleAvatar(
          radius: 16,
          backgroundColor: Colors.orange,
          child: Icon(Icons.group, size: 18, color: Colors.white),
        ),
        title: const Text(
          '所有人',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('@所有人', style: TextStyle(fontSize: 12, color: Colors.grey)),
        onTap: () => _selectAtMember('all', '所有人'),
      ),
    );
    
    // 添加分隔线
    if (filteredMembers.isNotEmpty) {
      memberItems.add(const Divider(height: 1));
    }
    
    // 添加成员列表
    for (final member in filteredMembers) {
      final userId = (member['user_id'] as String?) ?? '';
      final alias = (member['member_alias'] as String?) ?? '';
      final nickname = alias.isNotEmpty ? alias : userId;
      final isAdmin = (member['is_admin'] as bool?) ?? false;
      
      memberItems.add(
        ListTile(
          dense: true,
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue.shade50,
            child: Text(
              nickname.isNotEmpty ? nickname.characters.first : '#',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          title: Text(
            nickname,
            style: const TextStyle(fontSize: 14),
          ),
          subtitle: isAdmin
              ? const Text('管理员', style: TextStyle(fontSize: 12, color: Colors.orange))
              : null,
          onTap: () => _selectAtMember(userId, nickname),
        ),
      );
    }
    
    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: memberItems.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Text('未找到匹配的成员', style: TextStyle(color: Colors.grey)),
            )
          : ListView(
              shrinkWrap: true,
              children: memberItems,
            ),
    );
  }
  
  /// 选择@成员
  void _selectAtMember(String userId, String nickname) {
    final text = _messageController.text;
    final cursorPosition = _messageController.selection.baseOffset;
    
    // 找到最后一个@符号的位置
    final beforeCursor = text.substring(0, cursorPosition);
    final lastAtIndex = beforeCursor.lastIndexOf('@');
    
    if (lastAtIndex != -1) {
      // 替换@到光标位置之间的内容为@昵称
      final beforeAt = text.substring(0, lastAtIndex + 1);
      final afterCursor = text.substring(cursorPosition);
      final newText = '$beforeAt$nickname $afterCursor';
      
      // 更新输入框内容
      _messageController.text = newText;
      
      // 设置光标位置到@昵称后面
      final newCursorPosition = lastAtIndex + 1 + nickname.length + 1;
      _messageController.selection = TextSelection.collapsed(offset: newCursorPosition);
      
      // 记录@的成员信息（用于发送时组装AtMessage）
      _atMembers.add({
        'user_id': userId,
        'nickname': nickname,
      });
      
      // 隐藏选择器
      setState(() {
        _showAtMemberPicker = false;
        _atKeyword = '';
      });
    }
  }
  
  /// 从输入框文本中解析@成员信息
  List<Map<String, dynamic>> _parseAtMembersFromText(String text) {
    final atMembers = <Map<String, dynamic>>[];
    
    if (widget.groupMembers == null || widget.groupMembers!.isEmpty) {
      return atMembers;
    }
    
    // 使用正则表达式匹配@昵称（匹配@后面直到空格或@符号的内容）
    final regex = RegExp(r'@([^\s@]+)');
    final matches = regex.allMatches(text);
    
    for (final match in matches) {
      final atNickname = match.group(1) ?? '';
      if (atNickname.isEmpty) continue;
      
      // 检查是否是@所有人
      if (atNickname == '所有人') {
        // 检查是否已添加（避免重复）
        final exists = atMembers.any((m) => m['user_id'] == 'all');
        if (!exists) {
          atMembers.add({
            'user_id': 'all',
            'nickname': '所有人',
          });
        }
        continue;
      }
      
      // 在群成员列表中查找匹配的成员
      for (final member in widget.groupMembers!) {
        final userId = (member['user_id'] as String?) ?? '';
        final alias = (member['member_alias'] as String?) ?? '';
        final nickname = alias.isNotEmpty ? alias : userId;
        
        if (nickname == atNickname) {
          // 检查是否已添加（避免重复）
          final exists = atMembers.any((m) => m['user_id'] == userId);
          if (!exists) {
            atMembers.add({
              'user_id': userId,
              'nickname': nickname,
            });
          }
          break;
        }
      }
    }
    
    return atMembers;
  }

  void _toggleVoicePanel() {
    // 检查是否禁言（群聊时）
    if (widget.convType == 2 && (widget.isMuted == true)) {
      EasyLoading.showInfo('该群已禁言，无法发送消息');
      return;
    }
    
    // 关闭键盘
    _focusNode.unfocus();
    
    setState(() {
      _showVoicePanel = !_showVoicePanel;
      // 关闭其他面板
      if (_showVoicePanel) {
        _showEmojiPicker = false;
        _showMorePanel = false;
      }
    });
  }
  
  /// 处理语音发送
  void _handleVoiceSend(VoiceRecordResult result) {
    // 关闭面板
    setState(() => _showVoicePanel = false);
    
    // 发送语音消息
    _sendVoiceMessage(result.filePath, result.duration);
  }
  
  /// 发送语音消息
  Future<void> _sendVoiceMessage(String voicePath, int duration) async {
    // 检查是否禁言（群聊时）
    if (widget.convType == 2 && (widget.isMuted == true)) {
      EasyLoading.showInfo('该群已禁言，无法发送消息');
      return;
    }
    
    try {
      // 将语音复制到永久存储目录（避免临时缓存被清理）
      final pathHelper = FilePathHelper.instance;
      final relativePath = await pathHelper.copyToPermanentStorage(voicePath, 'voices');
      
      print('🎤 语音已保存: $relativePath');
      
      // 创建语音消息（存储相对路径）
      final message = ChatMessage.voice(
        convId: widget.convId,
        senderId: _currentUserId,
        receiverId: widget.targetUserId,
        localPath: relativePath,
        duration: duration,
      );
      
      // 添加到消息列表
      setState(() {
        _addChatMessageToList(message);
      });
      _scrollToBottom();
      
      // 通过队列发送（队列中会用完整路径读取文件）
      _messageQueue.sendMessage(message);
    } catch (e) {
      print('❌ 发送语音失败: $e');
    }
  }

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
        _showVoicePanel = false;  // 关闭语音面板
      });
    }
  }

  /// 插入表情到输入框
  void _insertEmoji(String emoji) {
    final text = _messageController.text;
    final selection = _messageController.selection;
    
    // 获取光标位置
    final cursorPos = selection.baseOffset >= 0 ? selection.baseOffset : text.length;
    
    // 在光标位置插入表情
    final newText = text.substring(0, cursorPos) + emoji + text.substring(cursorPos);
    _messageController.text = newText;
    
    // 移动光标到表情后面
    _messageController.selection = TextSelection.collapsed(offset: cursorPos + emoji.length);
    
    // 触发重建以更新发送按钮状态
    setState(() {});
  }

  /// 构建表情选择器
  Widget _buildEmojiPicker() {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!, width: 0.5),
        ),
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
                _buildEmojiTab('❤️', false),
                _buildEmojiTab('👍', false),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Icon(Icons.backspace_outlined, color: Colors.grey[600], size: 22),
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
              itemCount: _emojis.length,
              itemBuilder: (context, index) {
                return _buildEmojiItem(_emojis[index]);
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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 26),
        ),
      ),
    );
  }

  /// 删除最后一个字符
  void _deleteLastChar() {
    final text = _messageController.text;
    if (text.isEmpty) return;
    
    final selection = _messageController.selection;
    final cursorPos = selection.baseOffset >= 0 ? selection.baseOffset : text.length;
    
    if (cursorPos > 0) {
      // 处理 emoji（可能占用多个字符）
      final beforeCursor = text.substring(0, cursorPos);
      final beforeChars = beforeCursor.characters.toList();
      
      if (beforeChars.isNotEmpty) {
        beforeChars.removeLast();
        final newBefore = beforeChars.join();
        final newText = newBefore + text.substring(cursorPos);
        _messageController.text = newText;
        _messageController.selection = TextSelection.collapsed(offset: newBefore.length);
        setState(() {});
      }
    }
  }

  /// 切换更多面板
  void _toggleMorePanel() {
    // 检查是否禁言（群聊时）
    if (widget.convType == 2 && (widget.isMuted == true)) {
      EasyLoading.showInfo('该群已禁言，无法发送消息');
      return;
    }
    
    if (_showMorePanel) {
      setState(() => _showMorePanel = false);
      _focusNode.requestFocus();
    } else {
      _focusNode.unfocus();
      setState(() {
        _showMorePanel = true;
        _showEmojiPicker = false;
      });
    }
  }

  /// 构建更多面板
  Widget _buildMorePanel() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[200]!, width: 0.5),
        ),
      ),
      child: GridView.count(
        crossAxisCount: 4,
        padding: const EdgeInsets.all(20),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildMoreItem(
            icon: Icons.photo_library,
            label: '相册',
            color: Colors.orange,
            onTap: _pickImageFromGallery,
          ),
          _buildMoreItem(
            icon: Icons.camera_alt,
            label: '拍照',
            color: Colors.green,
            onTap: _pickImageFromCamera,
          ),
          _buildMoreItem(
            icon: Icons.videocam,
            label: '视频',
            color: Colors.purple,
            onTap: () => EasyLoading.showInfo('视频功能开发中'),
          ),
          _buildMoreItem(
            icon: Icons.folder,
            label: '文件',
            color: Colors.blue,
            onTap: () => EasyLoading.showInfo('文件功能开发中'),
          ),
          _buildMoreItem(
            icon: Icons.location_on,
            label: '位置',
            color: Colors.red,
            onTap: () => EasyLoading.showInfo('位置功能开发中'),
          ),
          _buildMoreItem(
            icon: Icons.contact_page,
            label: '名片',
            color: Colors.teal,
            onTap: () => EasyLoading.showInfo('名片功能开发中'),
          ),
        ],
      ),
    );
  }

  /// 构建更多面板项目
  Widget _buildMoreItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  /// 从相册选择图片
  Future<void> _pickImageFromGallery() async {
    try {
      final List<XFile>? images = await _imagePicker.pickMultipleMedia(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
        limit: 9,
        requestFullMetadata: false
      );
      if (images != null) {
        for (var media in images) {
          final path = media.path;
          final ext = path.split('.').last.toLowerCase();
          final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'].contains(ext);
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

  /// 拍照
  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image != null) {
        await _sendImageMessage(image.path);
      }
    } catch (e) {
      print('拍照失败: $e');
      EasyLoading.showError('拍照失败');
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
      final compressedPath = await _compressImage(imagePath);
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
      final relativePath = await pathHelper.copyToPermanentStorage(pathToUse, 'images');
      
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
        _addChatMessageToList(message);
      });
      _scrollToBottom();
      
      // 通过队列发送（队列中会用完整路径读取文件）
      _messageQueue.sendMessage(message);
    } catch (e) {
      print('❌ 发送图片失败: $e');
    }
  }

  /// 压缩视频，返回压缩后的路径（失败则返回 null）
  Future<String?> _compressVideo(String sourcePath) async {
    try {
      print('🎬 开始压缩视频: $sourcePath');
      EasyLoading.show(status: '正在压缩视频...');
      
      // 压缩视频
      final mediaInfo = await VideoCompress.compressVideo(
        sourcePath,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
      );
      
      if (mediaInfo != null && mediaInfo.path != null && File(mediaInfo.path!).existsSync()) {
        final originalSize = await File(sourcePath).length();
        final compressedSize = mediaInfo.filesize ?? await File(mediaInfo.path!).length();
        final ratio = (compressedSize / originalSize * 100).toStringAsFixed(1);
        print('✅ 视频压缩成功: ${originalSize / 1024 / 1024}MB -> ${compressedSize / 1024 / 1024}MB (${ratio}%)');
        EasyLoading.dismiss();
        return mediaInfo.path;
      } else {
        print('⚠️ 视频压缩失败: 返回路径为空或文件不存在');
        EasyLoading.dismiss();
        return null;
      }
    } catch (e) {
      print('⚠️ 视频压缩失败: $e');
      EasyLoading.dismiss();
      return null;
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
      final compressedPath = await _compressVideo(videoPath);
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
      final relativePath = await pathHelper.copyToPermanentStorage(finalVideoPath, 'videos');
      String? thumbRelativePath;
      if (thumbTemp != null) {
        thumbRelativePath = await pathHelper.copyToPermanentStorage(thumbTemp, 'images');
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
        _addChatMessageToList(message);
      });
      _scrollToBottom();
      
      // 通过队列发送（队列中会用完整路径读取文件）
      _messageQueue.sendMessage(message);
    } catch (e) {
      print('❌ 发送视频失败: $e');
      EasyLoading.showError('发送视频失败');
    }
  }

  /// 压缩图片，返回压缩后的路径（失败则返回 null）。
  /// 规则：仅对大于1MB的文件压缩，目标不超过1MB，分层次降低质量。
  Future<String?> _compressImage(String sourcePath) async {
    const int oneMB = 1024 * 1024;
    try {
      final srcFile = File(sourcePath);
      if (!await srcFile.exists()) return null;
      final srcSize = await srcFile.length();
      if (srcSize <= oneMB) {
        // 小于等于1MB无需压缩
        return null;
      }

      final targetDir = await getTemporaryDirectory();
      final baseName = 'cmp_${DateTime.now().millisecondsSinceEpoch}';
      final tryQualities = [80, 70, 60, 50, 40, 30];

      for (final q in tryQualities) {
        final targetPath = '${targetDir.path}/$baseName\_q$q.jpg';
        final result = await FlutterImageCompress.compressAndGetFile(
          sourcePath,
          targetPath,
          quality: q,
          minWidth: 1280,
          minHeight: 1280,
        );
        if (result != null && File(result.path).existsSync()) {
          final newSize = await File(result.path).length();
          print('✅ 图片压缩: q=$q size=${newSize / 1024}KB path=${result.path}');
          if (newSize <= oneMB) {
            return result.path;
          } else {
            // 继续尝试更低质量
            continue;
          }
        }
      }

      // 最低质量后仍大于1MB，则使用最后结果（已尽力）
      final fallbackPath = '${targetDir.path}/$baseName\_fallback.jpg';
      final fallback = await FlutterImageCompress.compressAndGetFile(
        sourcePath,
        fallbackPath,
        quality: 20,
        minWidth: 1280,
        minHeight: 1280,
      );
      if (fallback != null && File(fallback.path).existsSync()) {
        print('⚠️ 图片压缩未达1MB，使用最低质量结果: ${fallback.path}');
        return fallback.path;
      }

      print('⚠️ 图片压缩失败，使用原图');
      return null;
    } catch (e) {
      print('⚠️ 图片压缩异常，使用原图: $e');
      return null;
    }
  }

  /// 构建消息内容（支持图片）
  Widget _buildMessageContent(Map<String, dynamic> message, bool isMine) {
    final type = message['type'] as String? ?? 'text';
    final content = message['content'] as String? ?? '';
    final status = message['status'] as String? ?? 'sent';
    
    if (type == 'image') {
      return _buildImageMessage(message, isMine, status);
    }
    
    if (type == 'voice') {
      return _buildVoiceMessage(message, isMine, status);
    }

    if (type == 'video') {
      return _buildVideoMessage(message, isMine, status);
    }
    
    if (type == 'notification') {
      return _buildNotificationMessage(message);
    }
    
    // 默认文本消息
    return Text(
      content,
      style: TextStyle(
        fontSize: 15,
        color: isMine ? Colors.white : Colors.black87,
      ),
    );
  }
  
  /// 构建语音消息
  Widget _buildVoiceMessage(Map<String, dynamic> message, bool isMine, String status) {
    final duration = message['voiceDuration'] as int? ?? 0;
    final localPath = message['fileLocalPath'] as String?;
    final audioUrl = message['audioUrl'] as String?;
    
    // 生成唯一标识用于判断播放状态
    final voiceId = localPath ?? audioUrl ?? '';
    final isPlaying = _playingVoiceId == voiceId && voiceId.isNotEmpty;
    
    // 根据时长计算宽度（1-60秒对应120-220宽度）
    final width = 120.0 + (duration.clamp(1, 60) / 60.0 * 100.0);
    
    // 声波条数量
    final waveCount = ((width - 80) / 6).floor().clamp(4, 12);
    
    return GestureDetector(
      onTap: () => _playVoiceMessage(localPath, audioUrl),
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isMine ? null : Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            // 播放/暂停图标（带背景圆圈）
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isPlaying 
                    ? (isMine ? Colors.white.withOpacity(0.3) : Colors.blue.withOpacity(0.15))
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: isMine ? Colors.white : Colors.blue,
                size: 22,
              ),
            ),
            const SizedBox(width: 8),
            // 声波动画
            Expanded(
              child: SizedBox(
                height: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(
                    waveCount,
                    (index) {
                      // 播放时有动画效果的高度
                      double height;
                      if (isPlaying) {
                        // 播放时模拟声波动画（基于索引的伪随机高度）
                        height = 6 + ((index * 3 + DateTime.now().millisecond ~/ 150) % 5) * 3.0;
                      } else {
                        // 静止时的固定高度模式
                        height = 4 + (index % 3) * 4.0;
                      }
                      
                      return Container(
                        width: 3,
                        height: height,
                        decoration: BoxDecoration(
                          color: isMine 
                              ? Colors.white.withOpacity(isPlaying ? 1.0 : 0.6)
                              : Colors.blue.withOpacity(isPlaying ? 0.9 : 0.5),
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 时长（播放时显示不同颜色）
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: isPlaying ? BoxDecoration(
                color: isMine ? Colors.white.withOpacity(0.2) : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ) : null,
              child: Text(
                '${duration}″',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isPlaying ? FontWeight.w600 : FontWeight.normal,
                  color: isMine ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 播放语音消息
  Future<void> _playVoiceMessage(String? localPath, String? audioUrl) async {
    print('🔊 播放语音: localPath=$localPath, fileUrl=$audioUrl');
    
    // 生成唯一标识
    final voiceId = localPath ?? audioUrl ?? '';
    if (voiceId.isEmpty || (audioUrl != null && audioUrl.isEmpty)) {
      // audioUrl 为空，可能是回调解析不完整；尝试刷新历史消息补全
      _loadHistory();
      return;
    }
    
    // 如果正在播放同一个文件，则暂停
    if (_playingVoiceId == voiceId) {
      await _audioPlayer.stop();
      setState(() => _playingVoiceId = null);
      return;
    }
    
    final pathHelper = FilePathHelper.instance;
    
    // 1. 检查本地文件是否存在（支持相对路径）
    if (localPath != null && localPath.isNotEmpty) {
      // 将相对路径转换为完整路径
      final fullPath = await pathHelper.toFullPath(localPath);
      final file = File(fullPath);
      if (await file.exists()) {
        await _playLocalVoice(fullPath, voiceId);
        return;
      }
    }
    
    // 2. 检查已缓存的远程语音
    if (audioUrl != null && audioUrl.isNotEmpty && _voiceCache.containsKey(audioUrl)) {
      final cachedPath = _voiceCache[audioUrl]!;
      if (File(cachedPath).existsSync()) {
        await _playLocalVoice(cachedPath, voiceId);
      return;
      } else {
        _voiceCache.remove(audioUrl);
      }
    }
    
    // 3. 尝试从网络下载
    if (audioUrl != null && audioUrl.isNotEmpty) {
      await _downloadAndPlayVoice(audioUrl, voiceId);
      return;
    }
    
    // 4. 都没有，尝试刷新历史消息以补齐资源
    _loadHistory();
  }
  
  /// 播放本地语音文件
  Future<void> _playLocalVoice(String path, String voiceId) async {
    try {
      // 停止之前的播放
      await _audioPlayer.stop();
      
      // 开始播放
      await _audioPlayer.play(DeviceFileSource(path));
      setState(() => _playingVoiceId = voiceId);
      
      // 监听播放完成
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() => _playingVoiceId = null);
        }
      });
      
    } catch (e) {
      print('❌ 播放语音失败: $e');
      setState(() => _playingVoiceId = null);
      EasyLoading.showError('播放失败');
    }
  }
  
  /// 下载并播放语音
  Future<void> _downloadAndPlayVoice(String url, String voiceId) async {
    if (_isDownloading) {
      return;
    }
    
    try {
      setState(() => _isDownloading = true);
      
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('下载失败: ${response.statusCode}');
      }
      
      // 保存到本地持久目录（voices_cache）
      final docDir = await getApplicationDocumentsDirectory();
      final voicesDir = Directory('${docDir.path}/voices_cache');
      if (!voicesDir.existsSync()) {
        voicesDir.createSync(recursive: true);
      }
      String fileName;
      try {
        final parsed = Uri.parse(url);
        fileName = parsed.pathSegments.isNotEmpty ? parsed.pathSegments.last : '';
      } catch (_) {
        fileName = '';
      }
      if (fileName.isEmpty) {
        fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      }
      final filePath = '${voicesDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes, flush: true);
      
      // 缓存路径用于下次直接播放
      _voiceCache[url] = filePath;
      
      // 播放
      await _playLocalVoice(file.path, voiceId);
      
    } catch (e) {
      print('❌ 下载语音失败: $e');
      setState(() => _playingVoiceId = null);
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  /// 构建图片消息
  Widget _buildImageMessage(Map<String, dynamic> message, bool isMine, String status) {
    final localPath = message['imageLocalPath'] as String?;
    final imageUrl = message['imageUrl'] as String?;
    print("localPath: $localPath");
    print("imageUrl: $imageUrl");
    Widget imageWidget;
    
    // 将相对路径转换为完整路径
    final pathHelper = FilePathHelper.instance;
    final fullPath = localPath != null ? pathHelper.toFullPathSync(localPath) : null;
    print("fullPath: $fullPath");

    if (fullPath != null && File(fullPath).existsSync()) {
      // 显示本地图片
      imageWidget = Image.file(
        File(fullPath),
        width: 150,
        height: 150,
        fit: BoxFit.cover,
      );
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      // 显示网络图片
      imageWidget = Image.network(
        imageUrl,
        width: 150,
        height: 150,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            width: 150,
            height: 150,
            child: Center(
              child: CircularProgressIndicator(
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 150,
            height: 150,
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
          );
        },
      );
    } else {
      // 无图片显示占位
      imageWidget = Container(
        width: 150,
        height: 150,
        color: Colors.grey[300],
        child: const Icon(Icons.image, size: 40, color: Colors.grey),
      );
    }
    // print("\n\n---------------------------------\n构建图片消息\n message: ${message['id']} content: ${message['content']} localPath: $localPath imageUrl: $imageUrl \n---------------------------------\n\n");
    return GestureDetector(
      onTap: () {
        // 收集所有图片消息
        final imageMessages = _messages.where((m) {
          final msgType = m['type'] as String? ?? '';
          final msgLocalPath = m['imageLocalPath'] as String?;
          final msgImageUrl = m['imageUrl'] as String?;
          return msgType == 'image' && (msgLocalPath != null || msgImageUrl != null);
        }).toList();
        
        if (imageMessages.isEmpty) {
          return;
        }
        
        // 找到当前图片的索引
        final currentIndex = imageMessages.indexWhere((m) => m['id'] == message['id']);
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
      },
      child: Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: imageWidget,
        ),
        // 发送中遮罩
        if (status == 'sending' || status == 'pending')
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
        // 发送失败遮罩
        if (status == 'failed')
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 36,
                ),
              ),
            ),
          ),
      ],
      ),
    );
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
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[700],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// 构建视频消息（显示缩略图并可点击播放/预览）
  Widget _buildVideoMessage(Map<String, dynamic> message, bool isMine, String status) {
    print("message视频: $message");
    final localThumbPath = message['imageLocalPath'] as String?;
    final thumbUrl = message['imageUrl'] as String?;
    final videoUrl = message['videoUrl'] as String? ?? message['fileUrl'] as String?;
    final duration = message['videoDuration'] as int? ?? 0;
    Widget thumbWidget;

    // 将相对路径转换为完整路径
    final pathHelper = FilePathHelper.instance;
    final fullThumbPath = localThumbPath != null ? pathHelper.toFullPathSync(localThumbPath) : null;

    if (fullThumbPath != null && File(fullThumbPath).existsSync()) {
      thumbWidget = Image.file(
        File(fullThumbPath),
        width: 180,
        height: 120,
        fit: BoxFit.cover,
      );
    } else if (thumbUrl != null && thumbUrl.isNotEmpty) {
      thumbWidget = Image.network(
        thumbUrl,
        width: 180,
        height: 120,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            width: 180,
            height: 120,
            child: Center(
              child: CircularProgressIndicator(
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 180,
            height: 120,
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
          );
        },
      );
    } else {
      thumbWidget = Container(
        width: 180,
        height: 120,
        color: Colors.grey[300],
        child: const Icon(Icons.videocam, size: 40, color: Colors.grey),
      );
    }

    // 显示时长
    String durationText = '';
    if (duration > 0) {
      final d = Duration(seconds: duration);
      final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
      final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      durationText = '$mm:$ss';
    }

    return GestureDetector(
      onTap: () {
        // 预览或播放视频
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ImagePreviewPage(
              imageMessages: [
                {
                  'type': 'video',
                  'videoUrl': videoUrl,
                  'coverUrl': thumbUrl,
                  'thumbnailUrl': thumbUrl,
                  'imageLocalPath': localThumbPath,
                  'videoLocalPath': message['fileLocalPath'],
                  'fileLocalPath': message['fileLocalPath'],
                  'id': message['id'],
                }
              ],
              initialIndex: 0,
            ),
          ),
        );
      },
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: thumbWidget,
          ),
          // 播放按钮
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(Icons.play_circle_fill, color: Colors.white, size: 48),
              ),
            ),
          ),
          // 时长角标
          if (durationText.isNotEmpty)
            Positioned(
              right: 8,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  durationText,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ),
          // 发送中遮罩
          if (status == 'sending' || status == 'pending')
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
          // 发送失败遮罩
          if (status == 'failed')
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 36,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

