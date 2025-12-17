#ifndef NETWORK_LIB_H
#define NETWORK_LIB_H

#include <cstdint>
#include <functional>
#include "callback_types.h"

// 定义跨平台导出宏
#if defined(_WIN32)
    #ifdef NETWORK_LIB_EXPORTS
        #define NET_API __declspec(dllexport)
    #else
        #define NET_API __declspec(dllimport)
    #endif
#else
    #define NET_API __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif


// 网络数据回调函数类型
typedef void (*DataReceivedCallback)(const char* data, uint32_t length);

// EventReceivedCallback 已移至 callback_types.h

// 初始化网络库（只需调用一次）
NET_API int network_init();

// 启动网络服务
// @return 0表示成功，其他为错误码
NET_API int network_start();

NET_API int network_start_net_check(const char* url);


// 设置IP地址表
NET_API void network_set_ip_table(const char** ips, uint32_t count);

// 添加优化的IP延时状态函数
NET_API void network_get_ip_status(int* latencies, uint32_t count);


// 设置事件回调
NET_API void network_set_event_callback(EventReceivedCallback callback);

// 设置数据回调
NET_API void network_set_data_callback(DataReceivedCallback callback);

// 添加目标到组
NET_API void network_add_target_to_group(const char* ip, int port);

// 从组中移除目标
// @param ip IP地址
// @param port 端口
// @return true表示移除成功，false表示未找到该目标
NET_API bool network_remove_target_from_group(const char* ip, int port);

// 清空所有目标
NET_API void network_clear_all_targets();

// 主线程事件驱动,主要是实现跨线程驱动数据回调
NET_API void network_event_loop();


// 停止网络服务
NET_API void network_stop();

// 反初始化网络库
NET_API void network_cleanup();

/**
 * 立即触发重连（跳过延迟等待）
 * 当上层应用检测到网络恢复正常时，可以调用此接口立即触发重连
 * 
 * @param reset_retry_count 是否重置重试计数
 *   - true: 重置重试计数，重新开始计数
 *   - false: 保持当前重试计数，继续使用当前计数
 * 
 * @return 0 表示成功触发重连
 * @return -1 表示重连管理器未运行
 * @return -2 表示当前状态不允许重连（例如已连接或正在连接中）
 * @return -3 表示重连已在进行中（需要先等待或使用其他方式）
 * @return -4 表示发生异常错误
 */
NET_API int network_trigger_immediate_reconnect(bool reset_retry_count);

NET_API void register_single_message_callback(CB_S_I cCallback);
NET_API void register_group_message_callback(CB_S_I cCallback);
NET_API void register_community_message_callback(CB_S_I cCallback);


NET_API void set_contact_event_listener(CB_S_I cCallback);

// ============================================
// 好友状态回调接口
// ============================================

#include "common_definitions.h"

/**
 * 设置系统消息回调函数
 * @param cCallback 回调函数指针，传NULL表示取消注册
 * 回调函数签名：CB_S_I (const char* data, int dataLen)
 * data: 事件数据（序列化后的protobuf数据，可选）
 * dataLen: 数据长度
 */
NET_API void registe_system_message_listener(CB_S_I cCallback);

/**
 * 设置命令消息回调函数
 * @param cCallback 回调函数指针，传NULL表示取消注册
 * 回调函数签名：CB_I_S_I (int eventType, const char* data, int dataLen)
 * eventType: 命令类型
 * data: 命令数据（序列化后的protobuf数据，可选）
 * dataLen: 数据长度
 */
NET_API void registe_command_message_listener(CB_I_S_I cCallback);

/**
 * 用户登录
 * @param cCallback 回调函数（用于接收登录结果，参数：errorCode, data, dataLen, reqId）
 * @param data 序列化后的 user_pb::AuthUser 数据
 * @param dataLen 数据长度
 * @param reqId 请求ID（输出参数，返回本次请求的唯一标识）
 * @return 0表示成功，其它表示错误码
 * @note 可以在 EXE 中创建 user_pb::AuthUser 对象，调用 SerializeAsString() 或 SerializeToString() 后传递序列化数据
 */
NET_API int login_by_user_id(CB_I_S_I_U cCallback, const char* data, int dataLen, uint64_t &reqId);
/**
 * 用户Token快速登录
 * @param cCallback 回调函数（用于接收登录结果，参数：errorCode, data, dataLen, reqId）
 * @param data 序列化后的 user_pb::AuthUser 数据
 * @param dataLen 数据长度
 * @param reqId 请求ID（输出参数，返回本次请求的唯一标识）
 * @return 0表示成功，其它表示错误码
 */
NET_API int login_by_token(CB_I_S_I_U cCallback, const char* data, int dataLen, uint64_t &reqId);

/**
 * 退出登录
 * Topic: /im/user/{userId}/logout
 * @param cCallback 回调函数（用于接收退出登录结果，参数：errorCode, data, dataLen, reqId）
 * @param data 序列化后的退出登录数据（可选）
 * @param dataLen 数据长度
 * @param reqId 请求ID（输出参数，返回本次请求的唯一标识）
 * @return 0表示成功，其它表示错误码
 * @note userId 自动从 MqttSession 中获取
 */
NET_API int logout(CB_I_S_I_U cCallback, const char* data, int dataLen, uint64_t &reqId);

NET_API int register_user(CB_I_S_I_U cCallback, const char* data, int dataLen, uint64_t &reqId);

// Search user
// Parameters: callback(errorCode, data, dataLen, reqId), data(序列化后的 user_pb::SearchUser 数据), dataLen(数据长度), reqId(output: request ID)
// Returns: S_SUCCESS on success, error code on failure
// Note: 可以在 EXE 中创建 user_pb::SearchUser 对象，调用 SerializeAsString() 或 SerializeToString() 后传递序列化数据
NET_API int search_user(CB_I_S_I_U cCallback, const char* data, int dataLen, uint64_t &reqId);


/**
 * 精确查找用户
 * @param cCallback 回调函数（用于接收查找用户的结果，参数：errorCode, data, dataLen, reqId）
 * @param data 序列化后的 user_pb::GetUser 数据
 * @param dataLen 数据长度
 * @param reqId 请求ID（输出参数，返回本次请求的唯一标识）
 * @return 0表示成功，其他表示错误码
 */
NET_API int get_user(CB_I_S_I_U cCallback, const char* data, int dataLen, uint64_t &reqId);

/**
 * 更新用户信息
 * Topic: /im/user/{userId}/update
 * @param cCallback 回调函数（用于接收更新用户的结果，参数：errorCode, data, dataLen, reqId）
 * @param data 序列化后的用户更新数据
 * @param dataLen 数据长度
 * @param reqId 请求ID（输出参数，返回本次请求的唯一标识）
 * @return 0表示成功，其他表示错误码
 * @note 需要用户已登录，userId 自动从 MqttSession 中获取
 */
NET_API int update_user(CB_I_S_I_U cCallback, const char* data, int dataLen, uint64_t &reqId);

/**
 * 注销用户
 * Topic: /im/user/{userId}/delete
 * @param cCallback 回调函数（用于接收注销用户的结果，参数：errorCode, data, dataLen, reqId）
 * @param data 序列化后的注销用户请求数据
 * @param dataLen 数据长度
 * @param reqId 请求ID（输出参数，返回本次请求的唯一标识）
 * @return 0表示成功，其他表示错误码
 * @note 需要用户已登录，userId 自动从 MqttSession 中获取
 */
NET_API int delete_user(CB_I_S_I_U cCallback, const char* data, int dataLen, uint64_t &reqId);

/**
 * 修改密码
 * Topic: /im/USER/{userId}/changePassword
 * @param cCallback 回调函数（用于接收修改密码的结果，参数：errorCode, data, dataLen, reqId）
 * @param data 序列化后的修改密码请求数据（包含旧密码、新密码等）
 * @param dataLen 数据长度
 * @param reqId 请求ID（输出参数，返回本次请求的唯一标识）
 * @return 0表示成功，其他表示错误码
 * @note 需要用户已登录，userId 自动从 MqttSession 中获取
 */
NET_API int change_password(CB_I_S_I_U cCallback, const char* data, int dataLen, uint64_t &reqId);

/**
 * 重置密码（忘记密码）
 * Topic: /im/USER/{userId}/resetPassword
 * @param cCallback 回调函数（用于接收重置密码的结果，参数：errorCode, data, dataLen, reqId）
 * @param data 序列化后的重置密码请求数据（包含验证码、新密码等）
 * @param dataLen 数据长度
 * @param reqId 请求ID（输出参数，返回本次请求的唯一标识）
 * @return 0表示成功，其他表示错误码
 * @note 需要用户已登录，userId 自动从 MqttSession 中获取
 */
NET_API int reset_password(CB_I_S_I_U cCallback, const char* data, int dataLen, uint64_t &reqId);

/**
 * 刷新Token
 * Topic: /im/USER/{userId}/refreshToken
 * @param cCallback 回调函数（用于接收刷新Token的结果，参数：errorCode, data, dataLen, reqId）
 * @param data 序列化后的刷新Token请求数据（包含refreshToken等）
 * @param dataLen 数据长度
 * @param reqId 请求ID（输出参数，返回本次请求的唯一标识）
 * @return 0表示成功，其他表示错误码
 * @note 需要用户已登录，userId 自动从 MqttSession 中获取
 */
NET_API int refresh_auth_token(CB_I_S_I_U cCallback, const char* data, int dataLen, uint64_t &reqId);

/**
 * 获取验证码
 * @param cCallback 回调函数（用于接收验证码结果，参数：errorCode, data, dataLen, reqId）
 * @param data 序列化后的 captcha_pb::GetCaptcha 数据
 * @param dataLen 数据长度
 * @param reqId 请求ID（输出参数，返回本次请求的唯一标识）
 * @return 0表示成功，其它表示错误码
 * @note 可以在 EXE 中创建 captcha_pb::GetCaptcha 对象，调用 SerializeAsString() 或 SerializeToString() 后传递序列化数据
 */
NET_API int get_captcha(CB_I_S_I_U cCallback, const char* data, int dataLen, uint64_t &reqId);


NET_API void set_group_listener(CB_I_S_I cCallback);
NET_API void set_conversation_listener(CB_I_S_I cCallback);
NET_API void set_advanced_msg_listener(CB_I_S_I cCallback);
NET_API void set_batch_msg_listener(CB_I_S_I cCallback);
NET_API void set_friend_listener(CB_I_S_I cCallback);
NET_API void set_contact_listener(CB_CONACT_PARSED cCallback);
NET_API void set_custom_business_listener(CB_I_S_I cCallback);
NET_API int init_sdk(CB_I_S_I cCallback, char* operationID, char* config);
NET_API void un_init_sdk(char* operationID);
NET_API void set_app_background_status(CB_S_I_S_S cCallback, char* operationID, int isBackground);
NET_API void network_status_changed(CB_S_I_S_S cCallback, char* operationID);
NET_API int get_login_status(char* operationID);
NET_API const char* get_login_user();

/**
 * 设置客户端信息
 * @param platform 平台名称（如 "PC", "Android", "iOS" 等）
 * @param platformVersion 平台版本号
 * @param deviceId 设备ID
 * @param tz 时区（如 "Asia/Shanghai"）
 * @return 0表示成功，其它表示错误码
 * @note 这些信息会在 mqttConnect 连接时使用，需要保存到内存中
 */
NET_API int set_client_info(const char* platform, const char* platformVersion, const char* deviceId, const char* tz);

//NET_API void send_message(CB_S_I_S_I cCallback,  char* operationID, unsigned char* message, int len, char* recvID);
NET_API int send_single_message(CB_I_S_I_U cCallback, const char* message, int len, const char* conversationId, int msgType, const char* recvID, uint64_t &reqId);

/**
 * 发送联系人消息
 * Topic: /im/contact/{targetId}/send
 * @param cCallback 回调函数（用于接收发送结果，参数：errorCode, data, dataLen, reqId）
 * @param message 消息数据（序列化后的消息体）
 * @param len 数据长度
 * @param conversationId 会话ID
 * @param msgType 消息类型
 * @param targetId 目标用户ID
 * @param reqId 请求ID（输出参数，返回本次请求的唯一标识）
 * @return 0表示成功，其它表示错误码 
 */
NET_API int send_contact_message(CB_I_S_I_U cCallback, const char* message, int len, const char* conversationId, int msgType, const char* targetId, uint64_t &reqId);
//NET_API int send_message(unsigned char* message, int len, int conversationType);
NET_API void find_message_list(CB_S_I_S_S cCallback, char* operationID, char* findMessageOptions);
NET_API void get_advanced_history_message_list(CB_S_I_S_S cCallback, char* operationID, char* getMessageOptions);
NET_API void get_advanced_history_message_list_reverse(CB_S_I_S_S cCallback, char* operationID, char* getMessageOptions);
NET_API void revoke_message(CB_S_I_S_S cCallback, char* operationID, char* conversationID, char* clientMsgID);
NET_API void typing_status_update(CB_S_I_S_S cCallback, char* operationID, char* recvID, char* msgTip);
NET_API void mark_conversation_message_as_read(CB_S_I_S_S cCallback, char* operationID, char* conversationID);
NET_API void delete_message_from_local_storage(CB_S_I_S_S cCallback, char* operationID, char* conversationID, char* clientMsgID);
NET_API void delete_message(CB_S_I_S_S cCallback, char* operationID, char* conversationID, char* clientMsgID);
NET_API void hide_all_conversations(CB_S_I_S_S cCallback, char* operationID);
NET_API void delete_all_msg_from_local_and_svr(CB_S_I_S_S cCallback, char* operationID);
NET_API void delete_all_msg_from_local(CB_S_I_S_S cCallback, char* operationID);
NET_API void clear_conversation_and_delete_all_msg(CB_S_I_S_S cCallback, char* operationID, char* conversationID);
NET_API void delete_conversation_and_delete_all_msg(CB_S_I_S_S cCallback, char* operationID, char* conversationID);
NET_API void insert_single_message_to_local_storage(CB_S_I_S_S cCallback, char* operationID, char* message, char* recvID, char* sendID);
NET_API void insert_group_message_to_local_storage(CB_S_I_S_S cCallback, char* operationID, char* message, char* groupID, char* sendID);
NET_API void search_local_messages(CB_S_I_S_S cCallback, char* operationID, char* searchParam);
NET_API void set_message_local_ex(CB_S_I_S_S cCallback, char* operationID, char* conversationID, char* clientMsgID, char* localEx);
NET_API void get_users_info(CB_S_I_S_S cCallback, char* operationID, char* userIDs);
NET_API void get_users_info_with_cache(CB_S_I_S_S cCallback, char* operationID, char* userIDs, char* groupID);
NET_API void get_users_info_from_srv(CB_S_I_S_S cCallback, char* operationID, char* userIDs);
NET_API void set_self_info(CB_S_I_S_S cCallback, char* operationID, char* userInfo);
NET_API void set_global_recv_message_opt(CB_S_I_S_S cCallback, char* operationID, int opt);
NET_API void get_self_user_info(CB_S_I_S_S cCallback, char* operationID);
NET_API void update_msg_sender_info(CB_S_I_S_S cCallback, char* operationID, char* nickname, char* faceURL);
NET_API void subscribe_users_status(CB_S_I_S_S cCallback, char* operationID, char* userIDs);
NET_API void unsubscribe_users_status(CB_S_I_S_S cCallback, char* operationID, char* userIDs);
NET_API void get_subscribe_users_status(CB_S_I_S_S cCallback, char* operationID);
NET_API void get_user_status(CB_S_I_S_S cCallback, char* operationID, char* userIDs);

// =====================================================friend===============================================
//
NET_API void get_specified_friends_info(CB_S_I_S_S cCallback, char* operationID, char* userIDList);
NET_API void get_friend_list(CB_S_I_S_S cCallback, char* operationID);
NET_API void get_friend_list_page(CB_S_I_S_S cCallback, char* operationID, int offset, int count);
NET_API void search_friends(CB_S_I_S_S cCallback, char* operationID, char* searchParam, int len);
NET_API void check_friend(CB_S_I_S_S cCallback, char* operationID, char* userIDList);
NET_API void add_friend(CB_S_I_S_S cCallback, char* operationID, char* userIDReqMsg, int len);
NET_API void set_friend_remark(CB_S_I_S_S cCallback, char* operationID, char* userIDRemark);
NET_API void delete_friend(CB_S_I_S_S cCallback, char* operationID, char* friendUserID);
NET_API void get_friend_application_list_as_recipient(CB_S_I_S_S cCallback, char* operationID);
NET_API void get_friend_application_list_as_applicant(CB_S_I_S_S cCallback, char* operationID);
NET_API void accept_friend_application(CB_S_I_S_S cCallback, char* operationID, char* userIDHandleMsg);
NET_API void refuse_friend_application(CB_S_I_S_S cCallback, char* operationID, char* userIDHandleMsg);
NET_API void add_black(CB_S_I_S_S cCallback, char* operationID, char* blackUserID);
NET_API void get_black_list(CB_S_I_S_S cCallback, char* operationID);
NET_API void remove_black(CB_S_I_S_S cCallback, char* operationID, char* removeUserID);


// ============================================
// 联系人管理接口
// ============================================

/**
 * 搜索联系人
 * @param cCallback 回调函数（用于接收搜索结果，参数：errorCode, data, dataLen, reqId）
 * @param data 搜索参数（序列化后的数据）
 * @param len 数据长度
 * @param reqId 请求ID（输出参数，返回本次请求的唯一标识）
 * @return 0表示成功，其它表示错误码 
 */
NET_API int search_contact(CB_I_S_I_U cCallback, const char* data, int len, const char* targetId, uint64_t &reqId);

/**
 * 添加联系人（发送好友申请）
 * @param cCallback 回调函数（用于接收请求发送结果，参数：errorCode, data, dataLen, reqId）
 *                  errorCode=0 表示请求发送成功，非0表示发送失败
 *                  注意：这只是网络层面的确认，不代表对方已同意
 * @param data 添加参数（序列化后的数据，包含 to_user_id, verify_message 等）
 * @param len 数据长度
 * @param reqId 请求ID（输出参数，返回本次请求的唯一标识）
 * @return 0表示成功，其它表示错误码 
 */
NET_API int add_contact(CB_I_S_I_U cCallback, const char* data, int len, const char* targetId, uint64_t &reqId);

/**
 * 删除联系人
 * @param cCallback 回调函数（用于接收删除结果，参数：errorCode, data, dataLen, reqId）
 * @param data 删除参数（序列化后的数据，包含 user_id）
 * @param len 数据长度
 * @param reqId 请求ID（输出参数，返回本次请求的唯一标识）
 * @return 0表示成功，其它表示错误码 
 */
NET_API int delete_contact(CB_I_S_I_U cCallback, const char* data, int len, const char* targetId, uint64_t &reqId);

/**
 * 拉黑联系人
 * @param cCallback 回调函数（用于接收拉黑结果，参数：errorCode, data, dataLen, reqId）
 * @param data 拉黑参数（序列化后的数据，包含 user_id）
 * @param len 数据长度
 * @param reqId 请求ID（输出参数，返回本次请求的唯一标识）
 * @return 0表示成功，其它表示错误码 
 */
NET_API int block_contact(CB_I_S_I_U cCallback, const char* data, int len, const char* targetId, uint64_t &reqId);

/**
 * 取消拉黑
 * @param cCallback 回调函数（用于接收取消拉黑结果，参数：errorCode, data, dataLen, reqId）
 * @param data 取消拉黑参数（序列化后的数据，包含 user_id）
 * @param len 数据长度
 * @param reqId 请求ID（输出参数，返回本次请求的唯一标识）
 * @return 0表示成功，其它表示错误码 
 */
NET_API int unblock_contact(CB_I_S_I_U cCallback, const char* data, int len, const char* targetId, uint64_t &reqId);

/**
 * 设置联系人备注
 * @param cCallback 回调函数（用于接收设置备注结果，参数：errorCode, data, dataLen, reqId）
 * @param data 设置参数（序列化后的数据，包含 user_id, remark）
 * @param len 数据长度
 * @param reqId 请求ID（输出参数，返回本次请求的唯一标识）
 * @return 0表示成功，其它表示错误码 
 */
NET_API int set_contact_remark(CB_I_S_I_U cCallback, const char* data, int len, const char* targetId, uint64_t &reqId);

/**
 * 获取联系人列表
 * @param cCallback 回调函数（用于接收联系人列表结果，参数：errorCode, data, dataLen, reqId）
 * @param reqId 请求ID（输出参数，返回本次请求的唯一标识）
 * @return 0表示成功，其它表示错误码 
 */
NET_API int get_contact_list(CB_I_S_I_U cCallback, const char* queryData, int queryLen, uint64_t &reqId);



/**
 * 获取好友申请列表
 * @param cCallback 回调函数（用于接收好友申请列表结果，参数：errorCode, data, dataLen, reqId）
 * @param data 查询参数（序列化后的数据，可选，如状态筛选）
 * @param len 数据长度
 * @param reqId 请求ID（输出参数，返回本次请求的唯一标识）
 * @return 0表示成功，其它表示错误码 
 */
NET_API int get_friend_requests(CB_I_S_I_U cCallback, const char* data, int len, uint64_t &reqId);

/**
 * 接受好友申请
 * @param cCallback 回调函数（用于接收接受申请结果，参数：errorCode, data, dataLen, reqId）
 * @param data 接受参数（序列化后的数据，包含 request_id, remark）
 * @param len 数据长度
 * @param reqId 请求ID（输出参数，返回本次请求的唯一标识）
 * @return 0表示成功，其它表示错误码 
 */
NET_API int accept_friend_request(CB_I_S_I_U cCallback, const char* data, int len, uint64_t &reqId);

/**
 * 拒绝好友申请
 * @param cCallback 回调函数（用于接收拒绝申请结果，参数：errorCode, data, dataLen, reqId）
 * @param data 拒绝参数（序列化后的数据，包含 request_id, reason）
 * @param len 数据长度
 * @param reqId 请求ID（输出参数，返回本次请求的唯一标识）
 * @return 0表示成功，其它表示错误码 
 */
NET_API int reject_friend_request(CB_I_S_I_U cCallback, const char* data, int len, uint64_t &reqId);

// ============================================
// 黑名单管理接口
// ============================================

/**
 * 查询黑名单状态
 * @param cCallback 回调函数（用于接收查询结果，参数：errorCode, data, dataLen, reqId）
 * @param data 查询参数（序列化后的数据）
 * @param len 数据长度
 * @param reqId 请求ID（输出参数，返回本次请求的唯一标识）
 * @return 0表示成功，其它表示错误码 
 */
NET_API int get_black_status(CB_I_S_I_U cCallback, const char* data, int len, uint64_t &reqId);

// ============================================
// 联系人分组管理接口
// ============================================

/**
 * 创建联系人分组
 * Topic: /im/CONTACT/{currentUserId}/createGroup
 * @param cCallback 回调函数（用于接收创建分组结果，参数：errorCode, data, dataLen, reqId）
 * @param data 序列化后的分组数据（如分组名称等）
 * @param len 数据长度
 * @param reqId 请求ID（输出参数，返回本次请求的唯一标识）
 * @return 0表示成功，其它表示错误码 
 */
NET_API int create_contact_group(CB_I_S_I_U cCallback, const char* data, int len, uint64_t &reqId);

/**
 * 更新联系人分组
 * Topic: /im/CONTACT/{currentUserId}/updateGroup
 * @param cCallback 回调函数（用于接收更新分组结果，参数：errorCode, data, dataLen, reqId）
 * @param data 序列化后的分组数据（如分组ID、分组名称等）
 * @param len 数据长度
 * @param reqId 请求ID（输出参数，返回本次请求的唯一标识）
 * @return 0表示成功，其它表示错误码 
 */
NET_API int update_contact_group(CB_I_S_I_U cCallback, const char* data, int len, uint64_t &reqId);

/**
 * 删除联系人分组
 * Topic: /im/CONTACT/{currentUserId}/deleteGroup
 * @param cCallback 回调函数（用于接收删除分组结果，参数：errorCode, data, dataLen, reqId）
 * @param data 序列化后的分组数据（如分组ID）
 * @param len 数据长度
 * @param reqId 请求ID（输出参数，返回本次请求的唯一标识）
 * @return 0表示成功，其它表示错误码 
 */
NET_API int delete_contact_group(CB_I_S_I_U cCallback, const char* data, int len, uint64_t &reqId);

/**
 * 获取联系人分组列表
 * Topic: /im/CONTACT/{currentUserId}/listGroups
 * @param cCallback 回调函数（用于接收分组列表结果，参数：errorCode, data, dataLen, reqId）
 * @param data 序列化后的查询参数（可选，如分页信息）
 * @param len 数据长度
 * @param reqId 请求ID（输出参数，返回本次请求的唯一标识）
 * @return 0表示成功，其它表示错误码 
 */
NET_API int list_contact_groups(CB_I_S_I_U cCallback, const char* data, int len, uint64_t &reqId);

/**
 * 移动联系人到分组
 * Topic: /im/CONTACT/{currentUserId}/moveToGroup
 * @param cCallback 回调函数（用于接收移动结果，参数：errorCode, data, dataLen, reqId）
 * @param data 序列化后的数据（包含联系人ID和目标分组ID）
 * @param len 数据长度
 * @param reqId 请求ID（输出参数，返回本次请求的唯一标识）
 * @return 0表示成功，其它表示错误码 
 */
NET_API int move_contact_to_group(CB_I_S_I_U cCallback, const char* data, int len, uint64_t &reqId);

/**
 * 从分组中移除联系人
 * Topic: /im/CONTACT/{currentUserId}/removeFromGroup
 * @param cCallback 回调函数（用于接收移除结果，参数：errorCode, data, dataLen, reqId）
 * @param data 序列化后的数据（包含联系人ID和分组ID）
 * @param len 数据长度
 * @param reqId 请求ID（输出参数，返回本次请求的唯一标识）
 * @return 0表示成功，其它表示错误码 
 */
NET_API int remove_contact_from_group(CB_I_S_I_U cCallback, const char* data, int len, uint64_t &reqId);

/**
 * 创建联系人标签
 * Topic: /im/CONTACT/{currentUserId}/tag
 * @param cCallback 回调函数（用于接收创建标签结果，参数：errorCode, data, dataLen, reqId）
 * @param data 序列化后的标签数据（如标签名称等）
 * @param len 数据长度
 * @param reqId 请求ID（输出参数，返回本次请求的唯一标识）
 * @return 0表示成功，其它表示错误码
 */
NET_API int create_contact_tag(CB_I_S_I_U cCallback, const char* data, int len, uint64_t &reqId);

// ============================================
// 会话管理接口
// ============================================

/**
 * 获取会话列表
 * @param cCallback 回调函数（用于接收结果，参数：errorCode, data, dataLen, reqId）
 * @param data 查询参数（序列化后的数据，可选，如分页、筛选条件等）
 * @param len 数据长度
 * @param reqId 输出参数，返回消息ID
 * @return 错误码
 */
NET_API int get_conversation_list(CB_I_S_I_U cCallback, const char* data, int len, uint64_t &reqId);

/**
 * 获取单个会话
 * @param cCallback 回调函数（用于接收结果，参数：errorCode, data, dataLen, reqId）
 * @param data 查询参数（序列化后的数据，包含 conversation_id 或 user_id/group_id）
 * @param len 数据长度
 * @param reqId 输出参数，返回消息ID
 * @return 错误码
 */
NET_API int get_conversation(CB_I_S_I_U cCallback, const char* data, int len, uint64_t &reqId);

/**
 * 创建会话
 * @param cCallback 回调函数（用于接收结果，参数：errorCode, data, dataLen, reqId）
 * @param data 创建参数（序列化后的数据，包含 conversation_type, target_id 等）
 * @param len 数据长度
 * @param reqId 输出参数，返回消息ID
 * @return 错误码
 */
NET_API int create_conversation(CB_I_S_I_U cCallback, const char* data, int len, uint64_t &reqId);

/**
 * 删除会话
 * @param cCallback 回调函数（用于接收结果，参数：errorCode, data, dataLen, reqId）
 * @param data 删除参数（序列化后的数据，包含 conversation_id）
 * @param len 数据长度
 * @param reqId 输出参数，返回消息ID
 * @return 错误码
 */
NET_API int delete_conversation(CB_I_S_I_U cCallback, const char* data, int len, uint64_t &reqId);

/**
 * 清空会话消息
 * @param cCallback 回调函数（用于接收结果，参数：errorCode, data, dataLen, reqId）
 * @param data 清空参数（序列化后的数据，包含 conversation_id）
 * @param len 数据长度
 * @param reqId 输出参数，返回消息ID
 * @return 错误码
 */
NET_API int clear_conversation_messages(CB_I_S_I_U cCallback, const char* data, int len, uint64_t &reqId);

// /**
//  * 设置会话静音
//  * @param cCallback 回调函数
//  * @param data 设置参数（序列化后的数据，包含 conversation_id, is_mute）
//  * @param len 数据长度
//  */
// NET_API void set_conversation_mute(CB_I_S_I cCallback, const char* data, int len);

/**
 * 标记会话已读
 * @param cCallback 回调函数（用于接收结果，参数：errorCode, data, dataLen, reqId）
 * @param data 标记参数（序列化后的数据，包含 conversation_id）
 * @param len 数据长度
 * @param reqId 输出参数，返回消息ID
 * @return 错误码
 */
NET_API int mark_conversation_read(CB_I_S_I_U cCallback, const char* data, int len, uint64_t &reqId);

/**
 * 更新会话信息
 * @param cCallback 回调函数（用于接收结果，参数：errorCode, data, dataLen, reqId）
 * @param data 更新参数（序列化后的数据，包含 conversation_id 和需要更新的字段）
 * @param len 数据长度
 * @param reqId 输出参数，返回消息ID
 * @return 错误码
 */
NET_API int update_conversation(CB_I_S_I_U cCallback, const char* data, int len, uint64_t &reqId);

/**
 * 获取未读会话列表
 * Topic: /im/CONVERSATION/{appId}/listUnread
 * @param cCallback 回调函数（用于接收结果，参数：errorCode, data, dataLen, reqId）
 * @param data 查询参数（序列化后的数据，可选）
 * @param len 数据长度
 * @param reqId 输出参数，返回消息ID
 * @return 错误码
 */
NET_API int list_unread_conversations(CB_I_S_I_U cCallback, const char* data, int len, uint64_t &reqId);

// ============================================
// 群组管理接口
// ============================================

/**
 * 创建群组
 * @param cCallback 回调函数（用于接收响应，参数：errorCode, data, dataLen, reqId）
 * @param data 创建群组参数（序列化后的数据，包含群组名称、成员列表等）
 * @param len 数据长度
 * @param reqId 请求ID（输出参数，返回本次请求的唯一标识）
 * @return 0表示成功，其它表示错误码 
 */
NET_API int create_group(CB_I_S_I_U cCallback, const char* data, int len, uint64_t &reqId);

/**
 * 加入群组
 * @param cCallback 回调函数（用于接收响应，参数：errorCode, data, dataLen, reqId）
 * @param data 加入群组参数（序列化后的数据，包含群组ID等）
 * @param len 数据长度
 * @param reqId 请求ID（输出参数，返回本次请求的唯一标识）
 * @return 0表示成功，其它表示错误码 
 */
NET_API int join_group(CB_I_S_I_U cCallback, const char* data, int len, uint64_t &reqId);

/**
 * 获取群组信息
 * @param cCallback 回调函数（用于接收响应，参数：errorCode, data, dataLen, reqId）
 * @param data 获取群组信息参数（序列化后的数据，包含群组ID等）
 * @param len 数据长度
 * @param reqId 请求ID（输出参数，返回本次请求的唯一标识）
 * @return 0表示成功，其它表示错误码 
 */
NET_API int get_group_info(CB_I_S_I_U cCallback, const char* data, int len, uint64_t &reqId);

/**
 * 添加群组成员
 * @param cCallback 回调函数（用于接收响应，参数：errorCode, data, dataLen, reqId）
 * @param data 添加成员参数（序列化后的数据）
 * @param len 数据长度
 * @param reqId 请求ID（输出参数，返回本次请求的唯一标识）
 * @return 0表示成功，其它表示错误码 
 */
NET_API int add_group_member(CB_I_S_I_U cCallback, const char* data, int len, uint64_t &reqId);

/**
 * 移除群组成员
 * @param cCallback 回调函数（用于接收响应，参数：errorCode, data, dataLen, reqId）
 * @param data 移除成员参数（序列化后的数据）
 * @param len 数据长度
 * @param reqId 请求ID（输出参数，返回本次请求的唯一标识）
 * @return 0表示成功，其它表示错误码 
 */
NET_API int remove_group_member(CB_I_S_I_U cCallback, const char* data, int len, uint64_t &reqId);

/**
 * 发送群消息
 * @param cCallback 回调函数（用于接收发送结果，参数：errorCode, data, dataLen, reqId）
 * @param message 序列化的消息体（IM body 体的数据）
 * @param len 消息长度
 * @param conversationId 会话ID
 * @param msgType 消息类型
 * @param groupId 群组ID（必需）
 * @param outReqId 请求ID（输出参数，返回本次请求的唯一标识）
 * @return 0表示成功，其它表示错误码 
 */
NET_API int send_group_message(CB_I_S_I_U cCallback, const char* message, int len, const char* conversationId, int msgType, const char* groupId, uint64_t* outReqId);

/**
 * 获取群组列表
 * Topic: /im/group/{userId}/listGroups
 * @param cCallback 回调函数（用于接收群组列表结果，参数：errorCode, data, dataLen, reqId）
 * @param data 序列化后的查询参数
 * @param len 数据长度
 * @param reqId 请求ID（输出参数，返回本次请求的唯一标识）
 * @return 0表示成功，其它表示错误码 
 * @note 需要用户已登录，userId 自动从 MqttSession 中获取
 */
NET_API int list_groups(CB_I_S_I_U cCallback, const char* data, int len, uint64_t &reqId);

/**
 * 更新群组信息
 */
NET_API int update_group(CB_I_S_I_U cCallback, const char* data, int len, uint64_t &reqId);

/**
 * 解散群组
 */
NET_API int dissolve_group(CB_I_S_I_U cCallback, const char* data, int len, uint64_t &reqId);

/**
 * 退出群组
 */
NET_API int leave_group(CB_I_S_I_U cCallback, const char* data, int len, uint64_t &reqId);

/**
 * 获取群组成员列表
 */
NET_API int get_group_members(CB_I_S_I_U cCallback, const char* data, int len, uint64_t &reqId);

/**
 * 设置群内昵称
 */
NET_API int set_group_alias(CB_I_S_I_U cCallback, const char* data, int len, uint64_t &reqId);

/**
 * 申请加入群组
 */
NET_API int apply_join_group(CB_I_S_I_U cCallback, const char* data, int len, uint64_t &reqId);

/**
 * 审批加入申请
 */
NET_API int approve_join_group(CB_I_S_I_U cCallback, const char* data, int len, uint64_t &reqId);

/**
 * 拒绝加入申请
 */
NET_API int reject_join_group(CB_I_S_I_U cCallback, const char* data, int len, uint64_t &reqId);

/**
 * 获取群组申请列表
 */
NET_API int get_group_application_list(CB_I_S_I_U cCallback, const char* data, int len, uint64_t &reqId);

/**
 * 分配群组角色
 */
NET_API int assign_group_role(CB_I_S_I_U cCallback, const char* data, int len, uint64_t &reqId);

/**
 * 撤销群组角色
 */
NET_API int revoke_group_role(CB_I_S_I_U cCallback, const char* data, int len, uint64_t &reqId);

/**
 * 转让群主
 */
NET_API int transfer_group_owner(CB_I_S_I_U cCallback, const char* data, int len, uint64_t &reqId);

/**
 * 设置群组策略
 */
NET_API int set_group_policy(CB_I_S_I_U cCallback, const char* data, int len, uint64_t &reqId);

/**
 * 获取群组策略
 */
NET_API int get_group_policy(CB_I_S_I_U cCallback, const char* data, int len, uint64_t &reqId);

/**
 * 群组静音
 */
NET_API int mute_group(CB_I_S_I_U cCallback, const char* data, int len, uint64_t &reqId);

/**
 * 查询群组禁言状态
 */
NET_API int get_group_mute_status(CB_I_S_I_U cCallback, const char* data, int len, uint64_t &reqId);

// ============================================
// 消息拉取接口
// ============================================

/**
 * 拉取消息（用于消息同步和漏消息补偿）
 * @param cCallback 回调函数，返回拉取到的消息列表
 * @param data 获取消息参数（序列化后的数据）
 * @param len 数据长度
 * @param reqId 请求ID（输出参数，返回本次请求的唯一标识）
 * @return 0表示成功，其它表示错误码 
 */
NET_API int pull_messages(CB_I_S_I_U cCallback, const char* data, int len, uint64_t& reqId);

/**
 * 拉取通知消息
 * Topic: /im/CHAT/{userId}/pullNotification
 * @param cCallback 回调函数（用于接收拉取到的通知消息列表，参数：errorCode, data, dataLen, reqId）
 * @param data 拉取参数（序列化后的数据）
 * @param len 数据长度
 * @param reqId 请求ID（输出参数，返回本次请求的唯一标识）
 * @return 0表示成功，其它表示错误码
 * @note userId 自动从 MqttSession 中获取
 */
NET_API int pull_notification(CB_I_S_I_U cCallback, const char* data, int len, uint64_t &reqId);

/**
 * 标记通知已读
 * Topic: /im/CHAT/{userId}/markNotificationRead
 * @param cCallback 回调函数（用于接收标记结果，参数：errorCode, data, dataLen, reqId）
 * @param data 标记参数（序列化后的数据，包含通知ID等）
 * @param len 数据长度
 * @param reqId 请求ID（输出参数，返回本次请求的唯一标识）
 * @return 0表示成功，其它表示错误码
 * @note userId 自动从 MqttSession 中获取
 */
NET_API int mark_notification_read(CB_I_S_I_U cCallback, const char* data, int len, uint64_t &reqId);

/**
 * 标记全部通知已读
 * Topic: /im/CHAT/{userId}/markAllNotificationRead
 * @param cCallback 回调函数（用于接收标记结果，参数：errorCode, data, dataLen, reqId）
 * @param data 标记参数（序列化后的数据，可选）
 * @param len 数据长度
 * @param reqId 请求ID（输出参数，返回本次请求的唯一标识）
 * @return 0表示成功，其它表示错误码
 * @note userId 自动从 MqttSession 中获取
 */
NET_API int mark_all_notification_read(CB_I_S_I_U cCallback, const char* data, int len, uint64_t &reqId);

/**
 * 删除通知
 * Topic: /im/CHAT/{userId}/deleteNotification
 * @param cCallback 回调函数（用于接收删除结果，参数：errorCode, data, dataLen, reqId）
 * @param data 删除参数（序列化后的数据，包含通知ID等）
 * @param len 数据长度
 * @param reqId 请求ID（输出参数，返回本次请求的唯一标识）
 * @return 0表示成功，其它表示错误码
 * @note userId 自动从 MqttSession 中获取
 */
NET_API int delete_notification(CB_I_S_I_U cCallback, const char* data, int len, uint64_t &reqId);

/**
 * 获取未读通知数量
 * Topic: /im/CHAT/{userId}/getNotificationUnreadCount
 * @param cCallback 回调函数（用于接收未读数量，参数：errorCode, data, dataLen, reqId）
 * @param data 查询参数（序列化后的数据，可选）
 * @param len 数据长度
 * @param reqId 请求ID（输出参数，返回本次请求的唯一标识）
 * @return 0表示成功，其它表示错误码
 * @note userId 自动从 MqttSession 中获取
 */
NET_API int get_notification_unread_count(CB_I_S_I_U cCallback, const char* data, int len, uint64_t &reqId);

// ============================================
// 本地消息查询接口
// ============================================

/**
 * 本地消息结构体
 */
// LocalMessage 结构体和 CB_LOCAL_MESSAGE 回调类型已移至 callback_types.h

/**
 * 获取本地消息
 * @param cCallback 回调函数，查询完成后一次性回调所有消息
 * @param conversationType 会话类型 (1私聊 2群 3聊天室)
 * @param targetId 目标ID
 * @param baseMessageId 基准消息ID（本地数据库主键id），-1表示从最新开始
 * @param count 查询数量
 * @return 0表示成功，其它表示错误码
 * @note 回调函数中的messages数组在回调返回后会被释放，如需保存数据请复制
 */
NET_API int get_local_messages(CB_LOCAL_MESSAGE cCallback,
                               int conversationType,
                               const char* targetId,
                               int64_t baseMessageId,
                               int count);

/**
 * 取消异步请求
 * @param reqId 请求ID（在发起异步请求时返回的唯一标识）
 * @return 0表示成功，其它表示错误码
 * @note 用于取消正在进行的异步操作，如发送消息、登录等
 *       取消后，对应的回调函数将不再被调用
 */
NET_API int cancel_request(uint64_t reqId);

// ============================================
// 文件上传接口
// ============================================

/**
 * 准备上传文件
 * Topic: /im/FILE/{appId}/prepareUpload
 * @param cCallback 回调函数（用于接收准备上传的结果，参数：errorCode, data, dataLen, reqId）
 * @param data 序列化后的准备上传请求数据（包含文件信息等）
 * @param len 数据长度
 * @param reqId 请求ID（输出参数，返回本次请求的唯一标识）
 * @return 0表示成功，其它表示错误码 
 * @note appId 自动从 MqttSession 中获取
 */
NET_API int prepare_upload(CB_I_S_I_U cCallback, const char* data, int len, uint64_t &reqId);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // NETWORK_LIB_H