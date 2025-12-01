#ifndef CALLBACK_TYPES_H
#define CALLBACK_TYPES_H

#include <cstdint>
#include <functional>

#ifdef __cplusplus
extern "C" {
#endif

// ============================================
// 通用回调函数类型定义
// ============================================
// 命名规则：CB_<参数类型>_<参数类型>...
// S = const char* (String)
// I = int
// B = bool
// U = uint64_t

// 基础回调类型
typedef void (*CB_S)(const char*);
typedef void (*CB_S_I)(const char*, int);
typedef void (*CB_I_S)(int, const char*);
typedef void (*CB_I_S_I)(int, const char*, int);
typedef void (*CB_S_I_S)(const char*, int, const char*);
typedef void (*CB_S_I_I)(const char*, int, int);
typedef void (*CB_S_S_I_I)(const char*, const char*, int, int);
typedef void (*CB_S_S_S_S)(const char*, const char*, const char*, const char*);
typedef void (*CB_S_I_S_S)(const char*, int, const char*, const char*);
typedef void (*CB_S_I_S_I)(const char*, int, const char*, int);
typedef void (*CB_I_S_I_S)(int, const char*, int, const char*);
// Modern C++ callback type using std::function (allows capturing lambdas)
// This provides better type safety, flexibility, and integrates with modern C++ features
using CB_I_S_I_U = std::function<void(int, const char*, int, uint64_t)>;  // errorCode, data, dataLen, reqId

// 消息相关回调类型
// Message send result callback type
// Parameters: messageId(business message ID), success(is successful), errorCode(error code)
typedef void (*CB_MESSAGE_SEND_RESULT)(const char* messageId, bool success, int errorCode);

// 消息解析完成回调类型
// Parameters: messageId(消息ID), content(消息内容), contentLen(内容长度), msgType(消息类型), senderId(发送者ID), receiverId(接收者ID)
typedef void (*CB_MESSAGE_PARSED)(const char* messageId, const char* content, int contentLen, int msgType, const char* senderId, const char* receiverId);

// 联系人相关回调类型
typedef void (*CB_CONACT_PARSED)(const char* content, int contentLen, int msgType);

// Contact event listener callback type (for passively receiving contact events)
// Parameters: data(message data), dataLen(data length), msgType(message type)
typedef void (*CB_CONTACT_EVENT)(const char* data, int dataLen, int msgType);

// 本地消息结构体
typedef struct {
    const char* messageId;      // 消息ID（业务ID）
    const char* content;         // 消息内容（序列化后的protobuf数据）
    int contentLen;              // 内容长度
    int msgType;                 // 消息类型
    const char* senderId;        // 发送者ID
    const char* receiverId;      // 接收者ID
    int64_t sentTime;            // 发送时间（毫秒时间戳）
    int status;                  // 消息状态
} LocalMessage;

// 本地消息回调类型
// Parameters: messages(消息数组), count(消息数量)
typedef void (*CB_LOCAL_MESSAGE)(const LocalMessage* messages, int count);

// 网络事件回调类型
// Parameters: event_code(事件代码), event_desc(事件描述), length(描述长度)
typedef void (*EventReceivedCallback)(uint8_t event_code, const char* event_desc, uint32_t length);

#ifdef __cplusplus
}
#endif

#endif // CALLBACK_TYPES_H
