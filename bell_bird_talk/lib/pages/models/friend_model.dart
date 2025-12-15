
import 'package:lpinyin/lpinyin.dart';

/// 好友模型
class FriendModel {
  final String id;
  final String? accountId;
  final String nickname;
  final String? avatar;
  final String? remark;
  final int relationship;  // 0=好友, 1=黑名单等
  final int onlineStatus;  // 0=离线, 1=在线
  final String pinyin;     // 昵称拼音（用于排序）
  
  FriendModel({
    required this.id,
    this.accountId,
    required this.nickname,
    this.avatar,
    this.remark,
    this.relationship = 0,
    this.onlineStatus = 0,
    this.pinyin = '',
  });
  
  /// 从 JSON 构造
  factory FriendModel.fromJson(Map<String, dynamic> json) {
    final nickname = json['nickname'] ?? json['remark'] ?? '未知用户';
    return FriendModel(
      id: json['contact_user_id'] ?? json['user_id'] ?? '',
      accountId: json['account_id'],
      nickname: nickname,
      avatar: json['avatar'],
      remark: json['remark'],
      relationship: json['relationship'] ?? 0,
      onlineStatus: json['online_status'] ?? 0,
      pinyin: _toPinyin(nickname),
    );
  }
  
  /// 是否在线
  bool get isOnline => onlineStatus == 1;
  
  /// 显示名称（优先显示备注）
  String get displayName => (remark != null && remark!.isNotEmpty) ? remark! : nickname;
  
  /// 用户ID别名（兼容字段）
  String get userId => id;
  
  /// 创建副本并更新指定字段
  FriendModel copyWith({
    String? id,
    String? accountId,
    String? nickname,
    String? avatar,
    String? remark,
    int? relationship,
    int? onlineStatus,
    String? pinyin,
  }) {
    final newNickname = nickname ?? this.nickname;
    return FriendModel(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      nickname: newNickname,
      avatar: avatar ?? this.avatar,
      remark: remark ?? this.remark,
      relationship: relationship ?? this.relationship,
      onlineStatus: onlineStatus ?? this.onlineStatus,
      pinyin: pinyin ?? _toPinyin(newNickname),
    );
  }

  /// 拼音转换：优先使用 lpinyin，无结果时回退到简易估算
  static String _toPinyin(String text) {
    try {
      final py = PinyinHelper.getPinyinE(
        text,
        separator: '',
        format: PinyinFormat.WITHOUT_TONE,
      );
      if (py.trim().isNotEmpty) {
        return py.toLowerCase();
      }
    } catch (_) {
      // ignore and fallback
    }
    return _toPinyinFallback(text);
  }

  /// 简易拼音转换（仅首字母估算），非中文直接转小写
  static String _toPinyinFallback(String text) {
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      if (RegExp(r'[A-Za-z0-9]').hasMatch(char)) {
        buffer.write(char.toLowerCase());
      } else if (RegExp(r'[\u4e00-\u9fa5]').hasMatch(char)) {
        buffer.write(_getPinyinFirstLetter(char));
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  /// 参考 friends_page 的首字母估算，简化版
  static String _getPinyinFirstLetter(String char) {
    final code = char.codeUnitAt(0);
    // 中文字符Unicode范围：0x4E00-0x9FFF
    if (code >= 0x4E00 && code <= 0x9FFF) {
      final offset = code - 0x4E00;
      if (offset < 200) return 'a';
      if (offset < 500) return 'b';
      if (offset < 800) return 'c';
      if (offset < 1200) return 'd';
      if (offset < 1500) return 'e';
      if (offset < 1800) return 'f';
      if (offset < 2200) return 'g';
      if (offset < 2600) return 'h';
      if (offset < 3000) return 'j';
      if (offset < 3400) return 'k';
      if (offset < 3800) return 'l';
      if (offset < 4200) return 'm';
      if (offset < 4600) return 'n';
      if (offset < 5000) return 'o';
      if (offset < 5400) return 'p';
      if (offset < 5800) return 'q';
      if (offset < 6200) return 'r';
      if (offset < 6600) return 's';
      if (offset < 7000) return 't';
      if (offset < 7500) return 'w';
      if (offset < 8000) return 'x';
      if (offset < 8500) return 'y';
      if (offset < 9000) return 'z';
    }
    return '#';
  }
}

/// 好友分组模型
class FriendGroup {
  final String id;
  final String name;
  final bool isDefault;  // 是否是默认分组（不可删除）
  int count;  // 分组内好友数量
  final String? color;  // 分组颜色
  final int order;  // 排序顺序
  final String? icon;  // 分组图标
  final String? description;  // 分组描述
  
  FriendGroup({
    required this.id,
    required this.name,
    this.isDefault = false,
    this.count = 0,
    this.color,
    this.order = 0,
    this.icon,
    this.description,
  });
  
  /// 从 JSON 构造
  factory FriendGroup.fromJson(Map<String, dynamic> json) {
    return FriendGroup(
      id: json['group_id']?.toString() ?? '',
      name: json['group_name'] ?? '未命名分组',
      count: json['contact_count'] ?? 0,
      color: json['group_color'],
      order: json['group_order'] ?? 0,
      icon: json['group_icon'],
      description: json['group_description'],
      isDefault: false,
    );
  }
}

/// 好友申请模型
class FriendRequestModel {
  final int requestId;
  final String requesterId;
  final String requesterName;
  final String? requesterAvatar;
  final String? message;
  final int channel;
  final int status;  // 0=待处理, 1=已同意, 2=已拒绝
  final int requestTime;
  final int expireTime;
  
  FriendRequestModel({
    required this.requestId,
    required this.requesterId,
    required this.requesterName,
    this.requesterAvatar,
    this.message,
    this.channel = 0,
    this.status = 0,
    this.requestTime = 0,
    this.expireTime = 0,
  });
  
  factory FriendRequestModel.fromJson(Map<String, dynamic> json) {
    return FriendRequestModel(
      requestId: json['request_id'] ?? 0,
      requesterId: json['requester_id'] ?? '',
      requesterName: json['requester_name'] ?? '未知用户',
      requesterAvatar: json['requester_avatar'],
      message: json['message'],
      channel: json['channel'] ?? 0,
      status: json['status'] ?? 0,
      requestTime: json['request_time'] ?? 0,
      expireTime: json['expire_time'] ?? 0,
    );
  }
  
  /// 是否待处理
  bool get isPending => status == 0;
  
  /// 格式化时间
  String get formattedTime {
    if (requestTime == 0) return '';
    final time = DateTime.fromMillisecondsSinceEpoch(requestTime);
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inDays > 0) return '${diff.inDays}天前';
    if (diff.inHours > 0) return '${diff.inHours}小时前';
    if (diff.inMinutes > 0) return '${diff.inMinutes}分钟前';
    return '刚刚';
  }
}
