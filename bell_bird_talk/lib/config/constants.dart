/// 全局常量配置
class AppConstants {
  // 应用信息
  static const String appName = '铃鸟聊天';
  static const String appVersion = '1.0.0';
  
  // API 配置
  static const String baseUrl = 'https://api.bellbird.com'; // 替换为实际的 API 地址
  static const int connectTimeout = 30000; // 30秒
  static const int receiveTimeout = 30000; // 30秒
  static const int sendTimeout = 30000; // 30秒
  
  // WebSocket 配置
  static const String wsUrl = 'wss://ws.bellbird.com'; // WebSocket 地址
  static const int wsReconnectDelay = 3000; // 重连延迟(毫秒)
  static const int wsMaxRetries = 5; // 最大重试次数
  
  // 存储 Key
  static const String keyToken = 'user_token';
  static const String keyRefreshToken = 'user_refresh_token';
  static const String keyUserId = 'user_id';
  static const String keyUserInfo = 'user_info';
  static const String keyLanguage = 'language';
  static const String keyTheme = 'theme';
  static const String keyFirstLaunch = 'first_launch';
  
  // 加密密钥（生产环境应该从服务器获取）
  static const String aesKey = 'bellbird2025key16'; // 16位
  static const String aesIV = 'bellbirdiv123456'; // 16位
  
  // 文件上传配置
  static const int maxImageSize = 10 * 1024 * 1024; // 10MB
  static const int maxVideoSize = 100 * 1024 * 1024; // 100MB
  static const int imageQuality = 85; // 图片压缩质量
  
  // 聊天配置
  static const int messagePageSize = 20;
  static const int maxMessageLength = 5000;
  
  // 权限相关
  static const List<String> imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
  static const List<String> videoExtensions = ['mp4', 'mov', 'avi', 'mkv'];
  static const List<String> audioExtensions = ['mp3', 'wav', 'aac', 'm4a'];
}

/// API 端点
class ApiEndpoints {
  // 用户相关
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String userInfo = '/user/info';
  static const String updateProfile = '/user/update';
  
  // 聊天相关
  static const String sendMessage = '/chat/send';
  static const String messageHistory = '/chat/history';
  static const String chatList = '/chat/list';
  static const String deleteMessage = '/chat/delete';
  
  // 文件上传
  static const String uploadImage = '/upload/image';
  static const String uploadVideo = '/upload/video';
  static const String uploadFile = '/upload/file';
  
  // 通讯录
  static const String contactList = '/contact/list';
  static const String addContact = '/contact/add';
  static const String deleteContact = '/contact/delete';
}

/// 存储配置
class StorageConfig {
  // 缓存目录名称
  static const String cacheDir = 'cache';
  static const String imageDir = 'images';
  static const String videoDir = 'videos';
  static const String audioDir = 'audios';
  static const String fileDir = 'files';
  
  // 缓存过期时间（天）
  static const int imageCacheDays = 7;
  static const int videoCacheDays = 3;
  static const int fileCacheDays = 7;
}

// /// 主题颜色
// class AppColors {
//   // 主色调
//   static const int primaryValue = 0xFF2196F3;
//   static const int accentValue = 0xFF03A9F4;
  
//   // 文本颜色
//   static const int textPrimaryValue = 0xFF212121;
//   static const int textSecondaryValue = 0xFF757575;
//   static const int textHintValue = 0xFF9E9E9E;
  
//   // 背景颜色
//   static const int backgroundValue = 0xFFF5F5F5;
//   static const int cardValue = 0xFFFFFFFF;
  
//   // 状态颜色
//   static const int successValue = 0xFF4CAF50;
//   static const int warningValue = 0xFFFF9800;
//   static const int errorValue = 0xFFF44336;
//   static const int infoValue = 0xFF2196F3;
// }

