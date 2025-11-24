/// 用户模型
class UserModel {
  final String id;
  final String username;
  final String nickname;
  final String? avatar;
  final String? phone;
  final String? email;
  final int? gender; // 0: 未知, 1: 男, 2: 女
  final String? signature;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  UserModel({
    required this.id,
    required this.username,
    required this.nickname,
    this.avatar,
    this.phone,
    this.email,
    this.gender,
    this.signature,
    this.createdAt,
    this.updatedAt,
  });
  
  /// 从 JSON 创建
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      username: json['username'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      avatar: json['avatar'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      gender: json['gender'] as int?,
      signature: json['signature'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }
  
  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'nickname': nickname,
      'avatar': avatar,
      'phone': phone,
      'email': email,
      'gender': gender,
      'signature': signature,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
  
  /// 性别文本
  String get genderText {
    switch (gender) {
      case 1:
        return '男';
      case 2:
        return '女';
      default:
        return '未知';
    }
  }
  
  /// 复制并修改
  UserModel copyWith({
    String? id,
    String? username,
    String? nickname,
    String? avatar,
    String? phone,
    String? email,
    int? gender,
    String? signature,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      nickname: nickname ?? this.nickname,
      avatar: avatar ?? this.avatar,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      signature: signature ?? this.signature,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

