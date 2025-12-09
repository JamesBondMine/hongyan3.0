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
    
    // TODO: 调用 SDK 获取历史消息
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() => _isLoading = false);
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
            child: _buildMessageList(),
          ),
          // 输入栏
          _buildInputBar(),
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
            icon: Icon(Icons.emoji_emotions_outlined, color: Colors.grey[600]),
            onPressed: () {
              // TODO: 表情选择器
            },
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
}

