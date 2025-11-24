/// 统一响应模型
class ResponseModel<T> {
  /// 状态码
  final int code;
  
  /// 消息
  final String message;
  
  /// 数据
  final T? data;
  
  /// 时间戳
  final int? timestamp;
  
  ResponseModel({
    required this.code,
    required this.message,
    this.data,
    this.timestamp,
  });
  
  /// 是否成功
  bool get isSuccess => code == 200 || code == 0;
  
  /// 从 JSON 创建
  factory ResponseModel.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ResponseModel<T>(
      code: json['code'] as int? ?? json['status'] as int? ?? 0,
      message: json['message'] as String? ?? json['msg'] as String? ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      timestamp: json['timestamp'] as int?,
    );
  }
  
  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'message': message,
      'data': data,
      'timestamp': timestamp ?? DateTime.now().millisecondsSinceEpoch,
    };
  }
  
  /// 成功响应
  factory ResponseModel.success({
    T? data,
    String message = '操作成功',
  }) {
    return ResponseModel<T>(
      code: 200,
      message: message,
      data: data,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }
  
  /// 失败响应
  factory ResponseModel.error({
    int code = -1,
    String message = '操作失败',
    T? data,
  }) {
    return ResponseModel<T>(
      code: code,
      message: message,
      data: data,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }
  
  @override
  String toString() {
    return 'ResponseModel(code: $code, message: $message, data: $data)';
  }
}

/// 分页响应模型
class PageResponse<T> {
  /// 当前页
  final int currentPage;
  
  /// 每页数量
  final int pageSize;
  
  /// 总数量
  final int total;
  
  /// 总页数
  final int totalPages;
  
  /// 数据列表
  final List<T> list;
  
  /// 是否有下一页
  bool get hasMore => currentPage < totalPages;
  
  PageResponse({
    required this.currentPage,
    required this.pageSize,
    required this.total,
    required this.totalPages,
    required this.list,
  });
  
  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PageResponse<T>(
      currentPage: json['currentPage'] as int? ?? json['current'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? json['size'] as int? ?? 20,
      total: json['total'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? json['pages'] as int? ?? 0,
      list: (json['list'] as List<dynamic>? ?? json['records'] as List<dynamic>? ?? [])
          .map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'currentPage': currentPage,
      'pageSize': pageSize,
      'total': total,
      'totalPages': totalPages,
      'list': list,
    };
  }
}

