#ifndef COMMON_DEFINITIONS_H
#define COMMON_DEFINITIONS_H

#ifdef __cplusplus
extern "C" {
#endif

/**
 * 好友状态事件类型
 */
// typedef enum {
//     FRIEND_STATUS_ADDED = 1,        // 好友添加成功
//     FRIEND_STATUS_DELETED = 2,      // 好友删除
//     FRIEND_STATUS_REQUEST_RECEIVED = 3,  // 收到好友请求
//     FRIEND_STATUS_REQUEST_ACCEPTED = 4, // 好友请求被接受
//     FRIEND_STATUS_REQUEST_REJECTED = 5,  // 好友请求被拒绝
//     CONTACT_INFO_UPDATED = 6  // 联系人信息更新
    
// } FriendStatusEventType;
typedef enum {
    CONVERSION_CREATE = 1,            // 创建会话
} FriendStatusEventType;

// 网络事件类型定义
typedef enum {
    NET_EVENT_DATA  = 0,          // 网络数据
    NET_EVENT_CONNECTED = 1,      // 连接建立
    NET_EVENT_DISCONNECTED,       // 连接断开
    NET_EVENT_CONNECT_FAILED,     // 连接失败
    NET_EVENT_ERROR,              // 错误事件
    NET_EVENT_TCP_CONNECT_ERROR,   //TCP连接错误
    NET_EVENT_AUTH,               // 安全通道创建成功
    NET_USER_AUTH_SUCCESS,         // 用户认证成功
    NET_TOKEN_INVALID,             // Token 无效
    NET_HTTPDNS_RESOLVE_FAILED,          // HttpDns 解析失败
} NetworkEventType;

#ifdef __cplusplus
}
#endif

#endif // COMMON_DEFINITIONS_H

