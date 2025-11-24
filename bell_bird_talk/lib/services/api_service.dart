import '../network/http_client.dart';
import '../models/response_model.dart';
import '../models/user_model.dart';
import '../config/constants.dart';

/// API 服务层 - 封装所有 HTTP 请求
class ApiService {
  static ApiService? _instance;
  final HttpClient _http = HttpClient();
  
  // 单例模式
  factory ApiService() {
    _instance ??= ApiService._internal();
    return _instance!;
  }
  
  ApiService._internal();
  
  // ==================== 用户相关 ====================
  
  /// 登录
  Future<ResponseModel<Map<String, dynamic>>> login({
    required String username,
    required String password,
  }) async {
    return await _http.post<Map<String, dynamic>>(
      ApiEndpoints.login,
      data: {
        'username': username,
        'password': password,
      },
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
  }
  
  /// 注册
  Future<ResponseModel<Map<String, dynamic>>> register({
    required String username,
    required String password,
    required String nickname,
  }) async {
    return await _http.post<Map<String, dynamic>>(
      ApiEndpoints.register,
      data: {
        'username': username,
        'password': password,
        'nickname': nickname,
      },
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
  }
  
  /// 获取用户信息
  Future<ResponseModel<UserModel>> getUserInfo(String userId) async {
    return await _http.get<UserModel>(
      ApiEndpoints.userInfo,
      queryParameters: {'userId': userId},
      fromJsonT: (json) => UserModel.fromJson(json as Map<String, dynamic>),
    );
  }
  
  /// 更新用户信息
  Future<ResponseModel<UserModel>> updateUserInfo(Map<String, dynamic> data) async {
    return await _http.put<UserModel>(
      ApiEndpoints.updateProfile,
      data: data,
      fromJsonT: (json) => UserModel.fromJson(json as Map<String, dynamic>),
    );
  }
  
  /// 退出登录
  Future<ResponseModel<void>> logout() async {
    return await _http.post(ApiEndpoints.logout);
  }
  
  // ==================== 聊天相关 ====================
  
  /// 发送消息
  Future<ResponseModel<Map<String, dynamic>>> sendMessage({
    required String toUserId,
    required String content,
    required String type, // text, image, video, voice, file
  }) async {
    return await _http.post<Map<String, dynamic>>(
      ApiEndpoints.sendMessage,
      data: {
        'toUserId': toUserId,
        'content': content,
        'type': type,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
  }
  
  /// 获取聊天历史
  Future<ResponseModel<PageResponse<dynamic>>> getChatHistory({
    required String userId,
    int page = 1,
    int pageSize = 20,
  }) async {
    return await _http.get<PageResponse<dynamic>>(
      ApiEndpoints.messageHistory,
      queryParameters: {
        'userId': userId,
        'page': page,
        'pageSize': pageSize,
      },
      fromJsonT: (json) => PageResponse.fromJson(
        json as Map<String, dynamic>,
        (item) => item,
      ),
    );
  }
  
  /// 获取会话列表
  Future<ResponseModel<List<dynamic>>> getChatList() async {
    return await _http.get<List<dynamic>>(
      ApiEndpoints.chatList,
      fromJsonT: (json) => json as List<dynamic>,
    );
  }
  
  /// 删除消息
  Future<ResponseModel<void>> deleteMessage(String messageId) async {
    return await _http.delete(
      ApiEndpoints.deleteMessage,
      queryParameters: {'messageId': messageId},
    );
  }
  
  // ==================== 文件上传 ====================
  
  /// 上传图片
  Future<ResponseModel<Map<String, dynamic>>> uploadImage(
    String imagePath, {
    Function(int, int)? onProgress,
  }) async {
    return await _http.uploadFile<Map<String, dynamic>>(
      ApiEndpoints.uploadImage,
      imagePath,
      fileKey: 'image',
      onSendProgress: (sent, total) {
        onProgress?.call(sent, total);
      },
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
  }
  
  /// 上传视频
  Future<ResponseModel<Map<String, dynamic>>> uploadVideo(
    String videoPath, {
    Function(int, int)? onProgress,
  }) async {
    return await _http.uploadFile<Map<String, dynamic>>(
      ApiEndpoints.uploadVideo,
      videoPath,
      fileKey: 'video',
      onSendProgress: (sent, total) {
        onProgress?.call(sent, total);
      },
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
  }
  
  /// 上传多个文件
  Future<ResponseModel<List<dynamic>>> uploadFiles(
    List<String> filePaths, {
    Function(int, int)? onProgress,
  }) async {
    return await _http.uploadFiles<List<dynamic>>(
      ApiEndpoints.uploadFile,
      filePaths,
      fileKey: 'files',
      onSendProgress: (sent, total) {
        onProgress?.call(sent, total);
      },
      fromJsonT: (json) => json as List<dynamic>,
    );
  }
  
  /// 下载文件
  Future<ResponseModel<String>> downloadFile(
    String url,
    String savePath, {
    Function(int, int)? onProgress,
  }) async {
    return await _http.downloadFile(
      url,
      savePath,
      onReceiveProgress: (received, total) {
        if (total > 0) {
          onProgress?.call(received, total);
        }
      },
    );
  }
  
  // ==================== 通讯录相关 ====================
  
  /// 获取联系人列表
  Future<ResponseModel<List<dynamic>>> getContactList() async {
    return await _http.get<List<dynamic>>(
      ApiEndpoints.contactList,
      fromJsonT: (json) => json as List<dynamic>,
    );
  }
  
  /// 添加联系人
  Future<ResponseModel<void>> addContact(String userId) async {
    return await _http.post(
      ApiEndpoints.addContact,
      data: {'userId': userId},
    );
  }
  
  /// 删除联系人
  Future<ResponseModel<void>> deleteContact(String userId) async {
    return await _http.delete(
      ApiEndpoints.deleteContact,
      queryParameters: {'userId': userId},
    );
  }
  
  // ==================== 自定义请求示例 ====================
  
  /// 示例：带有进度回调的请求
  Future<ResponseModel<T>> requestWithProgress<T>({
    required String method,
    required String path,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic) fromJsonT,
    Function(int, int)? onProgress,
  }) async {
    // 根据不同的方法类型调用
    switch (method.toUpperCase()) {
      case 'GET':
        return await _http.get<T>(
          path,
          queryParameters: queryParameters,
          fromJsonT: fromJsonT,
        );
      case 'POST':
        return await _http.post<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          fromJsonT: fromJsonT,
        );
      case 'PUT':
        return await _http.put<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          fromJsonT: fromJsonT,
        );
      case 'DELETE':
        return await _http.delete<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          fromJsonT: fromJsonT,
        );
      default:
        throw Exception('不支持的请求方法: $method');
    }
  }
}

