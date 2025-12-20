/// 消息类型枚举
enum MessageType {
  text(0),        // 文本消息
  image(1),       // 图片消息
  video(2),       // 视频消息
  voice(3),       // 语音消息
  file(4),        // 文件消息
  location(5),    // 位置消息
  card(6),        // 名片消息
  shareUrl(7),    // 分享链接
  sticker(8),     // 表情贴纸
  custom(9),      // 自定义消息
  at(10),         // @消息
  forward(11),    // 转发消息
  reply(12),      // 回复消息
  edit(13),       // 编辑消息
  netCall(14),    // 网络通话
  redPacket(15),  // 红包消息
  notification(16), // 通知消息
  poll(17),       // 投票消息
  announcement(18), // 公告消息
  system(21),     // 系统消息
  status(30),     // 状态消息
  encrypted(33);  // 加密消息

  final int value;
  const MessageType(this.value);

  static MessageType fromValue(int value) {
    return MessageType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MessageType.text,
    );
  }
}

/// 消息发送状态
enum MessageStatus {
  pending(0),   // 等待发送
  sending(1),   // 发送中
  sent(2),      // 已发送
  delivered(3), // 已送达
  read(4),      // 已读
  failed(5);    // 发送失败

  final int value;
  const MessageStatus(this.value);

  static MessageStatus fromValue(int value) {
    return MessageStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MessageStatus.pending,
    );
  }
}

/// 聊天消息模型
class ChatMessage {
  /// 本地消息ID
  final String localId;
  
  /// 服务器消息ID
  String? serverId;
  
  /// 会话ID
  final String convId;

  /// 消息ID
  final String msgId;
  
  /// 发送者ID
  final String senderId;
  
  /// 接收者ID
  final String receiverId;
  
  /// 消息类型
  final MessageType type;
  
  /// 消息状态
  MessageStatus status;
  
  /// 是否是自己发的消息
  final bool isMine;
  
  /// 创建时间（毫秒时间戳）
  final int createdAt;
  
  /// 发送时间（毫秒时间戳）
  int? sentAt;
  
  /// 是否已读
  bool isRead;
  
  /// ==================== 消息内容字段 ====================
  
  /// 文本内容（文本消息）
  String? textContent;
  
  /// 图片本地路径
  String? imageLocalPath;
  
  /// 图片远程URL
  String? imageUrl;
  
  /// 图片缩略图URL
  String? imageThumbnailUrl;
  
  /// 图片宽度
  int? imageWidth;
  
  /// 图片高度
  int? imageHeight;
  
  /// 文件本地路径
  String? fileLocalPath;
  
  /// 文件远程URL
  String? fileUrl;
  
  /// 文件名
  String? fileName;
  
  /// 文件大小（字节）
  int? fileSize;
  
  /// 文件MIME类型
  String? fileMimeType;
  
  /// 语音时长（秒）
  int? voiceDuration;
  
  /// 视频时长（秒）
  int? videoDuration;
  
  /// 视频封面URL
  String? videoCoverUrl;
  
  /// 扩展字段（JSON字符串）
  String? ext;
  
  /// 错误信息（发送失败时）
  String? errorMessage;
  
  /// 重试次数
  int retryCount;

  ChatMessage({
    required this.localId,
    this.serverId,
    required this.convId,
    required this.msgId,
    
    required this.senderId,
    required this.receiverId,
    required this.type,
    this.status = MessageStatus.pending,
    required this.isMine,
    required this.createdAt,
    this.sentAt,
    this.isRead = false,
    this.textContent,
    this.imageLocalPath,
    this.imageUrl,
    this.imageThumbnailUrl,
    this.imageWidth,
    this.imageHeight,
    this.fileLocalPath,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.fileMimeType,
    this.voiceDuration,
    this.videoDuration,
    this.videoCoverUrl,
    this.ext,
    this.errorMessage,
    this.retryCount = 0,
  });

  /// 创建文本消息
  factory ChatMessage.text({
    required String convId,
    required String senderId,
    String msgId =  "",
    required String receiverId,
    required String content,
  }) {
    return ChatMessage(
      msgId:msgId ,
      localId: _generateLocalId(),
      convId: convId,
      senderId: senderId,
      receiverId: receiverId,
      type: MessageType.text,
      isMine: true,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      textContent: content,
    );
  }

  /// 创建图片消息
  factory ChatMessage.image({
    required String convId,
    String msgId =  "",
    required String senderId,
    required String receiverId,
    required String localPath,
    int? width,
    int? height,
  }) {
    return ChatMessage(
      localId: _generateLocalId(),
      convId: convId,
      msgId:msgId ,
      senderId: senderId,
      receiverId: receiverId,
      type: MessageType.image,
      isMine: true,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      imageLocalPath: localPath,
      imageWidth: width,
      imageHeight: height,
    );
  }
  
  /// 创建语音消息
  factory ChatMessage.voice({
    required String convId,
    String msgId =  "",
    required String senderId,
    required String receiverId,
    required String localPath,
    required int duration,
  }) {
    return ChatMessage(
      localId: _generateLocalId(),
      convId: convId,
      msgId:msgId ,
      senderId: senderId,
      receiverId: receiverId,
      type: MessageType.voice,
      isMine: true,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      fileLocalPath: localPath,
      voiceDuration: duration,
    );
  }

  /// 创建视频消息
  factory ChatMessage.video({
    required String convId,
    String msgId =  "",
    required String senderId,
    required String receiverId,
    required String localPath,
    String? coverLocalPath,
    int? duration,
    int? coverWidth,
    int? coverHeight,
  }) {
    return ChatMessage(
      localId: _generateLocalId(),
      convId: convId,
      msgId:msgId ,
      senderId: senderId,
      receiverId: receiverId,
      type: MessageType.video,
      isMine: true,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      fileLocalPath: localPath,
      videoDuration: duration,
      imageLocalPath: coverLocalPath,
      imageWidth: coverWidth,
      imageHeight: coverHeight,
    );
  }

  /// 生成本地消息ID
  static String _generateLocalId() {
    return 'local_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  /// 获取显示内容（用于消息列表）
  String get displayContent {
    switch (type) {
      case MessageType.text:
        return textContent ?? '';
      case MessageType.image:
        return '[图片]';
      case MessageType.video:
        return '[视频]';
      case MessageType.voice:
        return '[语音]';
      case MessageType.file:
        return '[文件] ${fileName ?? ''}';
      case MessageType.location:
        return '[位置]';
      case MessageType.card:
        return '[名片]';
      case MessageType.sticker:
        return '[表情]';
      case MessageType.redPacket:
        return '[红包]';
      default:
        return '[消息]';
    }
  }

  /// 转换为数据库 Map
  Map<String, dynamic> toDbMap() {
    return {
      'local_id': localId,
      'server_id': serverId,
      'conv_id': convId,
      'msg_id': msgId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'type': type.value,
      'status': status.value,
      'is_mine': isMine ? 1 : 0,
      'created_at': createdAt,
      'sent_at': sentAt,
      'is_read': isRead ? 1 : 0,
      'text_content': textContent,
      'image_local_path': imageLocalPath,
      'image_url': imageUrl,
      'image_thumbnail_url': imageThumbnailUrl,
      'image_width': imageWidth,
      'image_height': imageHeight,
      'file_local_path': fileLocalPath,
      'file_url': fileUrl,
      'file_name': fileName,
      'file_size': fileSize,
      'file_mime_type': fileMimeType,
      'voice_duration': voiceDuration,
      'video_duration': videoDuration,
      'video_cover_url': videoCoverUrl,
      'ext': ext,
      'error_message': errorMessage,
      'retry_count': retryCount,
    };
  }

  /// 从数据库 Map 创建
  factory ChatMessage.fromDbMap(Map<String, dynamic> map) {
    return ChatMessage(
      localId: map['local_id'] as String,
      serverId: map['server_id'] as String?,
      convId: map['conv_id'] as String,
      msgId: map['msg_id'] ?? "",
      senderId: map['sender_id'] as String,
      receiverId: map['receiver_id'] as String,
      type: MessageType.fromValue(map['type'] as int),
      status: MessageStatus.fromValue(map['status'] as int),
      isMine: (map['is_mine'] as int) == 1,
      createdAt: map['created_at'] as int,
      sentAt: map['sent_at'] as int?,
      isRead: (map['is_read'] as int?) == 1,
      textContent: map['text_content'] as String?,
      imageLocalPath: map['image_local_path'] as String?,
      imageUrl: map['image_url'] as String?,
      imageThumbnailUrl: map['image_thumbnail_url'] as String?,
      imageWidth: map['image_width'] as int?,
      imageHeight: map['image_height'] as int?,
      fileLocalPath: map['file_local_path'] as String?,
      fileUrl: map['file_url'] as String?,
      fileName: map['file_name'] as String?,
      fileSize: map['file_size'] as int?,
      fileMimeType: map['file_mime_type'] as String?,
      voiceDuration: map['voice_duration'] as int?,
      videoDuration: map['video_duration'] as int?,
      videoCoverUrl: map['video_cover_url'] as String?,
      ext: map['ext'] as String?,
      errorMessage: map['error_message'] as String?,
      retryCount: map['retry_count'] as int? ?? 0,
    );
  }

  /// 复制并修改
  ChatMessage copyWith({
    String? serverId,
    MessageStatus? status,
    int? sentAt,
    bool? isRead,
    String? imageUrl,
    String? imageThumbnailUrl,
    String? fileUrl,
    String? errorMessage,
    int? retryCount,
  }) {
    return ChatMessage(
      localId: localId,
      serverId: serverId ?? this.serverId,
      convId: convId,
      msgId: msgId,
      senderId: senderId,
      receiverId: receiverId,
      type: type,
      status: status ?? this.status,
      isMine: isMine,
      createdAt: createdAt,
      sentAt: sentAt ?? this.sentAt,
      isRead: isRead ?? this.isRead,
      textContent: textContent,
      imageLocalPath: imageLocalPath,
      imageUrl: imageUrl ?? this.imageUrl,
      imageThumbnailUrl: imageThumbnailUrl ?? this.imageThumbnailUrl,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      fileLocalPath: fileLocalPath,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName,
      fileSize: fileSize,
      fileMimeType: fileMimeType,
      voiceDuration: voiceDuration,
      videoDuration: videoDuration,
      videoCoverUrl: videoCoverUrl,
      ext: ext,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

