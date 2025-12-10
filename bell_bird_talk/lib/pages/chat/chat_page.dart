import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../../services/native_bridge.dart';

/// 单人聊天页面
class ChatPage extends StatefulWidget {
  final String convId;
  final String displayName;
  final String? avatar;
  final String targetUserId;
  
  const ChatPage({
    super.key,
    required this.convId,
    required this.displayName,
    this.avatar,
    required this.targetUserId,
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
    _loadHistory();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 加载历史消息
  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    
    try {
      // 使用 pull_messages 接口拉取历史消息
      final result = await _nativeService.imPullMessages(
        conversationId: widget.convId,
        convType: 0,  // 单聊
        targetId: widget.targetUserId,
        lastSeq: 0,   // 0 表示从最新开始
        limit: 50,
      );
      
      print('📥 拉取历史消息结果: $result');
      
      if (result['errorCode'] == 0) {
        final data = result['data'];
        if (data != null && data is String && data.isNotEmpty) {
          try {
            final dataMap = json.decode(data) as Map<String, dynamic>;
            print('📥 历史消息数据: $dataMap');
            
            // 打印所有字段
            print('📥 返回字段: ${dataMap.keys.toList()}');
            
            // 解析消息列表
            final messages = dataMap['messages'] as List<dynamic>?;
            if (messages != null && messages.isNotEmpty) {
              print('📥 获取到 ${messages.length} 条历史消息');
              _parseAndDisplayMessages(messages);
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
  void _parseAndDisplayMessages(List<dynamic> messages) {
    final parsedMessages = <Map<String, dynamic>>[];
    
    for (final msg in messages) {
      if (msg is Map<String, dynamic>) {
        // 尝试解析消息结构
        final msgId = msg['msg_id'] ?? msg['message_id'] ?? msg['id'] ?? '';
        final content = msg['content'] ?? msg['text'] ?? msg['body'] ?? '';
        final senderId = msg['sender_id'] ?? msg['from'] ?? msg['from_id'] ?? '';
        final timestamp = msg['send_time'] ?? msg['timestamp'] ?? msg['created_at'] ?? 0;
        
        // 判断是否是自己发的消息
        final isMine = senderId == widget.targetUserId ? false : true;
        
        parsedMessages.add({
          'id': msgId.toString(),
          'content': content.toString(),
          'isMine': isMine,
          'timestamp': timestamp is int ? timestamp : 0,
          'status': 'sent',
          'raw': msg, // 保留原始数据供调试
        });
        
        print('📝 消息: content=$content, isMine=$isMine, senderId=$senderId');
      }
    }
    
    if (parsedMessages.isNotEmpty) {
      setState(() {
        _messages.clear();
        _messages.addAll(parsedMessages);
      });
      _scrollToBottom();
    }
  }

  /// 发送消息
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;
    
    setState(() {
      _isSending = true;
    });
    
    // 先添加到本地列表（显示发送中状态）
    final localMsgId = DateTime.now().millisecondsSinceEpoch.toString();
    final newMessage = {
      'id': localMsgId,
      'content': text,
      'isMine': true,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'status': 'sending', // sending, sent, failed
    };
    
    setState(() {
      _messages.add(newMessage);
    });
    _messageController.clear();
    _scrollToBottom();
    
    try {
      // 调用 SDK 发送消息
      final result = await _nativeService.imSendTextMessage(
        content: text,
        conversationId: widget.convId,
        receiverId: widget.targetUserId,
      );
      
      print('📤 发送消息结果: $result');
      
      if (result['errorCode'] == 0) {
        // 发送成功，更新消息状态
        setState(() {
          final index = _messages.indexWhere((m) => m['id'] == localMsgId);
          if (index != -1) {
            _messages[index]['status'] = 'sent';
            // 更新服务器返回的消息ID
            if (result['data'] != null) {
              try {
                final data = result['data'] is String 
                    ? (result['data'] as String).isNotEmpty 
                        ? result['data'] 
                        : null
                    : result['data'];
                if (data != null) {
                  // 可以解析服务器返回的消息ID等信息
                }
              } catch (e) {
                print('解析发送结果失败: $e');
              }
            }
          }
        });
      } else {
        // 发送失败
        setState(() {
          final index = _messages.indexWhere((m) => m['id'] == localMsgId);
          if (index != -1) {
            _messages[index]['status'] = 'failed';
          }
        });
        EasyLoading.showError('发送失败: ${result['message']}');
      }
    } catch (e) {
      print('发送消息异常: $e');
      setState(() {
        final index = _messages.indexWhere((m) => m['id'] == localMsgId);
        if (index != -1) {
          _messages[index]['status'] = 'failed';
        }
      });
      EasyLoading.showError('发送失败');
    } finally {
      setState(() {
        _isSending = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // 消息列表
          Expanded(
            child: GestureDetector(
              onTap: () {
                // 点击消息列表区域时收起表情面板和键盘
                if (_showEmojiPicker) {
                  setState(() => _showEmojiPicker = false);
                }
                _focusNode.unfocus();
              },
              child: _buildMessageList(),
            ),
          ),
          // 输入栏
          _buildInputBar(),
          // 表情选择器
          if (_showEmojiPicker) _buildEmojiPicker(),
        ],
      ),
    );
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
          icon: const Icon(Icons.more_horiz),
          onPressed: () {
            // TODO: 显示聊天设置
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
        return _buildMessageItem(message);
      },
    );
  }

  Widget _buildMessageItem(Map<String, dynamic> message) {
    final isMine = message['isMine'] as bool? ?? false;
    final content = message['content'] as String? ?? '';
    final status = message['status'] as String? ?? 'sent';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            // 对方头像
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[300],
              backgroundImage: widget.avatar != null && widget.avatar!.isNotEmpty
                  ? NetworkImage(widget.avatar!)
                  : null,
              child: widget.avatar == null || widget.avatar!.isEmpty
                  ? Text(
                      widget.displayName.isNotEmpty ? widget.displayName[0] : '?',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          
          // 发送状态（我的消息显示在左侧）
          if (isMine) ...[
            _buildMessageStatus(status),
            const SizedBox(width: 4),
          ],
          
          // 消息气泡
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.65,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMine ? Colors.blue : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMine ? 16 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                content,
                style: TextStyle(
                  fontSize: 15,
                  color: isMine ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
          
          if (isMine) ...[
            const SizedBox(width: 8),
            // 我的头像
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.blue[100],
              child: Icon(
                Icons.person,
                size: 20,
                color: Colors.blue[400],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建消息状态指示器
  Widget _buildMessageStatus(String status) {
    switch (status) {
      case 'sending':
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
            // TODO: 重新发送
            EasyLoading.showInfo('重发功能开发中');
          },
          child: Icon(
            Icons.error_outline,
            size: 16,
            color: Colors.red[400],
          ),
        );
      case 'sent':
      default:
        return Icon(
          Icons.done,
          size: 14,
          color: Colors.grey[400],
        );
    }
  }

  Widget _buildInputBar() {
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
      child: Row(
        children: [
          // 语音按钮
          IconButton(
            icon: Icon(Icons.mic, color: Colors.grey[600]),
            onPressed: () {
              // TODO: 语音消息
            },
          ),
          
          // 输入框
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                decoration: const InputDecoration(
                  hintText: '输入消息...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          
          // 表情按钮
          IconButton(
            icon: Icon(
              _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined,
              color: _showEmojiPicker ? Colors.blue : Colors.grey[600],
            ),
            onPressed: _toggleEmojiPicker,
          ),
          
          // 更多/发送按钮
          IconButton(
            icon: Icon(
              _messageController.text.trim().isEmpty ? Icons.add_circle_outline : Icons.send,
              color: _messageController.text.trim().isEmpty ? Colors.grey[600] : Colors.blue,
            ),
            onPressed: () {
              if (_messageController.text.trim().isNotEmpty) {
                _sendMessage();
              } else {
                // TODO: 显示更多选项（图片、文件等）
              }
            },
          ),
        ],
      ),
    );
  }

  /// 切换表情选择器
  void _toggleEmojiPicker() {
    if (_showEmojiPicker) {
      // 关闭表情面板，打开键盘
      setState(() => _showEmojiPicker = false);
      _focusNode.requestFocus();
    } else {
      // 关闭键盘，打开表情面板
      _focusNode.unfocus();
      setState(() => _showEmojiPicker = true);
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
}

