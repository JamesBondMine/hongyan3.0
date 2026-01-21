# Protobuf 对象定义规范

## 🎯 目标

建立统一的 Protobuf 定义规范，以领域对象为核心，采用激进简化命名策略，提升代码简洁性和可维护性。

## 📋 核心原则

### 1. 激进简化
- **完全去除** Request/Response/Req/Resp 后缀
- 使用简洁的动词和名词组合
- 减少冗余的命名层次

### 2. 领域驱动设计
- 以领域对象为中心定义消息结构
- 使用业务术语而非技术术语
- 保持与数据库表命名的一致性

### 3. 系统类型优先
- **强制使用** `system_pb.proto` 定义的通用类型
- 避免重复定义相同的响应结构
- 统一错误处理和分页机制

### 4. 操作对象分离
- 为 create/update 定义独立的简化操作对象
- 避免在同一个 message 中混合不同操作的字段
- 保持操作语义的清晰性

## 🏷️ 命名规则

### 领域对象命名
- **格式**: 使用帕斯卡命名法（PascalCase）
- **原则**: 使用完整或标准缩写的名词
- **示例**: `User`, `Conv`, `Group`, `Device`, `Message`

```protobuf
// ✅ 正确示例
message User {
  string user_id = 1;
  string username = 2;
  string nickname = 3;
  // ...
}

// ❌ 错误示例
message UserInfo { ... }  // 冗余后缀
message UserEntity { ... } // 技术术语
```

### 查询操作命名
- **格式**: 使用小写动词或动词短语，格式为 `get${对象名称}`（避免 `get` 关键字冲突）
- **原则**: 直接表达操作意图
- **示例**: `getUser`, `getGroup`, `listQuery`, `search`, `check`

```protobuf
// ✅ 正确示例
message getUser {
  string user_id = 1;  // 必需参数
}

message getGroup {
  string group_id = 1;  // 必需参数
}

message listQuery {
  string keyword = 1;  // 可选参数
  int32 page = 2;      // 分页参数
  int32 size = 3;      // 页面大小
}

// ❌ 错误示例
message get { ... }              // 避免使用关键字
message GetUserRequest { ... }    // 冗余后缀
message UserListQueryRequest { ... } // 过长命名
```

### 操作对象命名
- **格式**: `动词 + 领域对象`
- **原则**: 动词使用帕斯卡命名法，领域对象保持原样
- **示例**: `CreateUser`, `UpdateUser`, `AddMember`, `RemoveMember`

```protobuf
// ✅ 正确示例
message CreateUser {
  string username = 1;     // 必填字段
  string password = 2;     // 必填字段
  string nickname = 3;     // 可选字段
  string email = 4;        // 可选字段
}

message UpdateUser {
  string user_id = 1;      // 必填字段
  string nickname = 2;     // 可选字段
  string email = 3;        // 可选字段
}

// ❌ 错误示例
message CreateUserRequest { ... }  // 冗余后缀
message UserUpdateRequest { ... }  // 顺序错误
```

### 结果对象命名
- **格式**: 简化的小写名词或动词
- **原则**: 直接表达返回内容的类型
- **示例**: `list`, `searchResult`, `stats`, `detail`

```protobuf
// ✅ 正确示例
message list {
  repeated User users = 1;
  int64 total_count = 2;
  int32 page = 3;
  int32 size = 4;
}

message stats {
  int32 total_users = 1;
  int32 active_users = 2;
  int32 new_users_today = 3;
}

// ❌ 错误示例
message UserListResponse { ... }     // 冗余后缀
message GetUserStatsResponse { ... } // 过长命名
```

## 📦 消息类型分类

### 1. 核心领域对象
- **用途**: 完整的业务实体定义
- **命名**: 直接使用业务名词
- **示例**: `User`, `Group`, `Message`, `Device`

```protobuf
message User {
  string user_id = 1;           // 用户ID
  string username = 2;          // 用户名
  string nickname = 3;          // 昵称
  string email = 4;             // 邮箱
  int32 status = 5;             // 状态
  int64 created_at = 6;         // 创建时间
  int64 updated_at = 7;         // 更新时间
}
```

### 2. 查询参数对象
- **用途**: 查询和过滤条件
- **命名**: 使用 `Query` 或 `Filter` 后缀
- **示例**: `listQuery`, `searchQuery`, `UserFilter`

```protobuf
message listQuery {
  string keyword = 1;           // 搜索关键词
  int32 status = 2;             // 状态过滤
  int32 page = 3;               // 页码
  int32 size = 4;               // 页面大小
}
```

### 3. 操作对象
- **用途**: 创建、更新、删除等操作参数
- **命名**: 动词 + 领域对象
- **示例**: `CreateUser`, `UpdateUser`, `DeleteUser`

```protobuf
message CreateUser {
  string username = 1;          // 必填：用户名
  string password = 2;          // 必填：密码
  string nickname = 3;          // 可选：昵称
  string email = 4;             // 可选：邮箱
}

message UpdateUser {
  string user_id = 1;           // 必填：用户ID
  string nickname = 2;          // 可选：昵称
  string email = 3;             // 可选：邮箱
  int32 status = 4;             // 可选：状态
}
```

### 4. 结果对象
- **用途**: 查询和操作的返回结果
- **命名**: 简化的小写名词
- **示例**: `list`, `detail`, `stats`, `result`

```protobuf
message list {
  repeated User users = 1;      // 用户列表
  int64 total_count = 2;        // 总数量
  int32 page = 3;               // 当前页
  int32 size = 4;               // 页面大小
}
```

### 5. 系统响应
- **用途**: 使用 `system_pb.proto` 定义的通用类型
- **原则**: 不重复定义相同的响应结构
- **示例**: `system.EmptyResponse`, `system.Error`, `system.Page`

## 🔧 系统通用类型使用规范

### 强制使用场景

#### 1. 操作成功无返回数据
```protobuf
// ✅ 正确：使用系统类型
import "system_pb.proto";

// 删除用户成功响应
system.EmptyResponse

// ❌ 错误：自定义空响应
message DeleteUserResponse {
  bool success = 1;
  string message = 2;
}
```

#### 2. 错误响应
```protobuf
// ✅ 正确：使用系统错误类型
system.Error {
  code: 400
  message: "用户不存在"
  placeholders: ["user_id"]
}

// ❌ 错误：自定义错误类型
message UserError {
  int32 error_code = 1;
  string error_message = 2;
}
```

#### 3. 分页参数和元数据
```protobuf
// ✅ 正确：使用系统分页类型
message listQuery {
  string keyword = 1;
  system.Page page = 2;  // 分页参数
}

message list {
  repeated User users = 1;
  system.Page page = 2;  // 分页元数据
}

// ❌ 错误：自定义分页类型
message UserListQuery {
  string keyword = 1;
  int32 page = 2;
  int32 size = 3;
}
```

## 📝 字段命名规范

### 1. 基本规则
- **格式**: 使用 snake_case（蛇形命名法）
- **原则**: 保持与数据库字段命名一致
- **示例**: `user_id`, `created_at`, `is_active`

### 2. 标准缩写
- `conversation` → `conv`
- `message` → `msg`
- `information` → `info`
- `identifier` → `id`

### 3. 特殊字段后缀
- **ID 字段**: 统一使用 `_id` 后缀
  - `user_id`, `group_id`, `message_id`
- **时间戳字段**: 使用 `_at` 或 `_time` 后缀
  - `created_at`, `updated_at`, `login_time`
- **状态字段**: 使用 `status` 或 `is_` 前缀
  - `status`, `is_active`, `is_deleted`
- **数量字段**: 使用 `_count` 或 `_num` 后缀
  - `user_count`, `message_num`

### 4. 枚举类型规范（三层统一）
- **强制使用枚举**: 所有状态、类型、分类字段必须使用枚举类型，**禁止使用 int**
- **枚举命名**: 使用帕斯卡命名法，以业务领域开头
- **枚举值命名**: 使用最简洁的英文单词，去掉业务领域前缀
- **禁止 UNKNOWN**: **枚举中禁止定义 `UNKNOWN` 或 `UNSPECIFIED` 值**，第一个枚举值从 0 开始，使用实际业务值
- **三层统一**: 
  - **Protobuf 层**: 定义 `enum DeviceType { ANDROID = 0; IOS = 1; ... }`
  - **数据库层**: 定义 `CREATE TYPE device_type_enum AS ENUM ('ANDROID', 'IOS', ...)`
  - **Java 层**: 使用 Protobuf 生成的枚举类型，通过转换方法映射

```protobuf
// ✅ 正确示例 - 最简洁的枚举值命名，禁止使用 UNKNOWN
enum UserStatus {
  ACTIVE = 0;                     // 启用（默认值）
  DISABLED = 1;                   // 禁用
  SUSPENDED = 2;                  // 暂停
}

enum DeviceType {
  ANDROID = 0;                    // Android 设备（默认值）
  IOS = 1;                        // iOS 设备
  PC = 2;                         // PC 桌面端
  WEB = 3;                        // Web 浏览器端
}

enum MessageType {
  TEXT = 0;                       // 文本消息（默认值）
  IMAGE = 2;                      // 图片消息
  AUDIO = 3;                      // 音频消息
  VIDEO = 4;                      // 视频消息
  FILE = 5;                       // 文件消息
}

// 在消息中使用枚举
message User {
  string user_id = 1;
  string username = 2;
  UserStatus status = 3;          // ✅ 使用枚举类型
  DeviceType device_type = 4;     // ✅ 使用枚举类型
}

// ❌ 错误示例
message User {
  string user_id = 1;
  string username = 2;
  int32 status = 3;               // ❌ 禁止使用 int 表示状态
  int32 device_type = 4;          // ❌ 禁止使用 int 表示类型
}
```

### 5. 字段注释规范

#### 5.1 必填/选填标注规范

**强制要求**：所有字段必须在注释中明确标注是"必填"还是"可选"，以便开发者清楚了解字段的使用要求。

**标注格式**：
- **必填字段**：标注 `（必填）`
- **可选字段**：标注 `（可选）`
- **返回字段**：标注 `（返回字段）` 或 `（返回字段，请求时不需要）`
- **系统字段**：标注 `（系统自动生成）` 或 `（系统自动更新）`

**标注位置**：必填/选填说明应紧跟在字段描述之后，用括号标注。

```protobuf
message User {
  string user_id = 1;           // 用户ID（必填）
  string username = 2;          // 用户名（必填，最大长度20字符）
  string nickname = 3;          // 昵称（可选，最大长度50字符）
  string email = 4;             // 邮箱（可选，邮箱格式验证）
  UserStatus status = 5;        // 状态（必填，使用枚举类型）
  int64 created_at = 6;         // 创建时间（返回字段，系统自动生成）
  int64 updated_at = 7;         // 更新时间（返回字段，系统自动更新）
}
```

#### 5.2 字段分类说明

**请求字段**：客户端发送给服务端的字段
- 必须明确标注"必填"或"可选"
- 必填字段：业务逻辑必需，缺少会导致验证失败
- 可选字段：可以省略，有默认值或业务逻辑允许为空

**返回字段**：服务端返回给客户端的字段
- 标注为"返回字段"或"返回字段，请求时不需要"
- 客户端在请求时不需要填写这些字段
- 服务端会自动填充这些字段

**系统字段**：由系统自动管理的字段
- 标注为"系统自动生成"或"系统自动更新"
- 如创建时间、更新时间等

#### 5.3 字段约束说明

在标注必填/选填的同时，还应说明字段的约束条件：
- **长度限制**：`（必填，最大长度20字符）`
- **格式要求**：`（可选，邮箱格式验证）`
- **默认值**：`（可选，默认30分钟）`
- **取值范围**：`（可选，1-100之间）`
- **条件依赖**：`（可选，当渠道为GROUP_MEMBER时使用）`

#### 5.4 完整示例

```protobuf
// Contact 领域对象 - add 方法的请求参数
message Contact {
  // 返回字段（系统自动填充，请求时不需要）
  string contact_user_id = 1;        // 联系人用户ID（返回字段，请求时不需要）
  string nickname = 3;              // 昵称（返回字段）
  int64 create_time = 10;           // 添加时间（返回字段，系统自动生成）
  
  // add 方法请求字段
  AddChannel add_channel = 8;       // 添加渠道（必填）
  string target_value = 12;         // 目标值（必填，用户ID/用户名/手机号等）
  string message = 13;              // 申请消息（可选，最大长度500字符）
  int64 group_id = 14;              // 所属群组ID（可选，当渠道为GROUP_MEMBER时使用）
  repeated int64 tag_ids = 16;      // 标签ID列表（可选，为新好友添加的标签）
}
```

#### 5.5 多用途 Message 的字段说明

当一个 message 用于多个方法时，需要明确说明每个字段在不同方法中的用途：

```protobuf
// ContactQuery - list/search/get 方法的查询参数
message ContactQuery {
  // list 方法字段（全部可选）
  Relationship relationship = 1;     // 关系类型过滤（可选）
  int32 page = 3;                   // 分页（可选，默认1）
  
  // get 方法字段
  string contact_user_id = 7;        // 联系人用户ID（get方法必填，list/search方法不需要）
}
```

## 💬 注释规范

### 1. Message 级别注释
```protobuf
// 用户信息 - 核心领域对象
// 用于用户的基本信息存储和传输
message User {
  // 字段定义...
}

// 创建用户 - 操作对象
// 用于用户注册，必填字段：username, password
message CreateUser {
  // 字段定义...
}
```

### 2. 字段级别注释

**强制要求**：所有字段必须在注释中明确标注必填/选填状态。

**标注规则**：
- **必填字段**: 标注 `（必填）`，必须提供，否则验证失败
- **可选字段**: 标注 `（可选）`，可以省略，有默认值或允许为空
- **返回字段**: 标注 `（返回字段）` 或 `（返回字段，请求时不需要）`，客户端请求时不需要填写
- **系统字段**: 标注 `（系统自动生成）` 或 `（系统自动更新）`，由系统自动管理
- **约束条件**: 说明长度限制、格式要求、默认值、取值范围等
- **业务含义**: 解释字段的业务用途和使用场景
- **条件依赖**: 说明字段的使用条件，如 `（可选，当渠道为GROUP_MEMBER时使用）`

**示例**：
```protobuf
message Contact {
  // 返回字段
  string contact_user_id = 1;        // 联系人用户ID（返回字段，请求时不需要）
  int64 create_time = 10;           // 添加时间（返回字段，系统自动生成）
  
  // 请求字段
  AddChannel add_channel = 8;       // 添加渠道（必填）
  string target_value = 12;         // 目标值（必填，用户ID/用户名/手机号等）
  string message = 13;              // 申请消息（可选，最大长度500字符）
  int64 group_id = 14;              // 所属群组ID（可选，当渠道为GROUP_MEMBER时使用）
}
```

### 3. 枚举注释
```protobuf
// 用户状态枚举 - 定义用户账户的各种状态
enum UserStatus {
  ACTIVE = 0;                   // 启用状态（正常使用，默认值）
  DISABLED = 1;                 // 禁用状态（账户被禁用）
  SUSPENDED = 2;                // 暂停状态（临时暂停）
  DELETED = 3;                  // 删除状态（逻辑删除）
}

// 设备类型枚举 - 定义支持的设备类型
enum DeviceType {
  ANDROID = 0;                  // Android 设备（默认值）
  IOS = 1;                      // iOS 设备
  PC = 2;                       // PC 桌面端
  WEB = 3;                      // Web 浏览器端
}

// 消息类型枚举 - 定义消息的类型
enum MessageType {
  TEXT = 0;                     // 文本消息（默认值）
  IMAGE = 1;                    // 图片消息
  AUDIO = 2;                    // 音频消息
  VIDEO = 3;                    // 视频消息
  FILE = 4;                     // 文件消息
}
```

## 📚 完整示例

### 用户模块重构示例

#### 原始定义（❌ 错误示例）
```protobuf
message UserInfo {
  string user_id = 1;
  string user_name = 2;
  // ... 很多字段
}

message CreateUserRequest {
  string username = 1;
  string password = 2;
  string nickname = 3;
  // ... 很多字段
}

message CreateUserResponse {
  UserInfo user_info = 1;
  string token = 2;
}

message GetUserRequest {
  string user_id = 1;
}

message GetUserResponse {
  UserInfo user_info = 1;
}

message UserListRequest {
  string keyword = 1;
  int32 page = 2;
  int32 size = 3;
}

message UserListResponse {
  repeated UserInfo users = 1;
  int32 total_count = 2;
}
```

#### 重构后定义（✅ 正确示例）
```protobuf
syntax = "proto3";
package im.user;

option java_package = "com.cloud.im.common.core.protocol.user";
option java_outer_classname = "UserProtos";

import "system_pb.proto";

// ============ 核心领域对象 ============

// 用户状态枚举 - 定义用户账户的各种状态
enum UserStatus {
  ACTIVE = 0;                   // 启用状态（正常使用，默认值）
  DISABLED = 1;                 // 禁用状态（账户被禁用）
  SUSPENDED = 2;                // 暂停状态（临时暂停）
  DELETED = 3;                  // 删除状态（逻辑删除）
}

// 用户信息 - 核心领域对象
message User {
  string user_id = 1;           // 用户ID（必填）
  string username = 2;          // 用户名（必填，最大长度20字符）
  string nickname = 3;          // 昵称（可选，最大长度50字符）
  string email = 4;             // 邮箱（可选，邮箱格式验证）
  string phone = 5;             // 手机号（可选）
  UserStatus status = 6;        // 状态（必填，使用枚举类型）
  int64 created_at = 7;         // 创建时间（系统自动生成）
  int64 updated_at = 8;         // 更新时间（系统自动更新）
}

// ============ 查询操作 ============

// 获取用户 - 查询操作
message getUser {
  string user_id = 1;           // 用户ID（必需）
}

// 用户列表查询 - 查询操作
message listQuery {
  string keyword = 1;           // 搜索关键词（可选）
  UserStatus status = 2;        // 状态过滤（可选，使用枚举类型）
  system.Page page = 3;         // 分页参数（使用系统类型）
}

// ============ 操作对象 ============

// 创建用户 - 操作对象
message CreateUser {
  string username = 1;          // 用户名（必填）
  string password = 2;          // 密码（必填）
  string nickname = 3;          // 昵称（可选）
  string email = 4;             // 邮箱（可选）
  string phone = 5;             // 手机号（可选）
}

// 更新用户 - 操作对象
message UpdateUser {
  string user_id = 1;           // 用户ID（必填）
  string nickname = 2;          // 昵称（可选）
  string email = 3;             // 邮箱（可选）
  string phone = 4;             // 手机号（可选）
  int32 status = 5;             // 状态（可选）
}

// ============ 结果对象 ============

// 用户列表 - 结果对象
message list {
  repeated User users = 1;      // 用户列表
  system.Page page = 2;         // 分页元数据（使用系统类型）
}

// 用户统计 - 结果对象
message stats {
  int32 total_users = 1;        // 总用户数
  int32 active_users = 2;       // 活跃用户数
  int32 new_users_today = 3;    // 今日新增用户数
}
```

### 设备模块重构示例

#### 原始定义（❌ 错误示例）
```protobuf
message DeviceInfo {
  string device_id = 1;
  string device_name = 2;
  DeviceType device_type = 3;
  // ... 30多个字段
}

message CheckDeviceRequest {
  string user_id = 1;
  string device_id = 2;
  DeviceInfo device_info = 3;
}

message CheckDeviceResult {
  bool device_exists = 1;
  bool auth_required = 2;
  bool limit_exceeded = 3;
  int32 current_count = 4;
  int32 max_count = 5;
}
```

#### 重构后定义（✅ 正确示例）
```protobuf
syntax = "proto3";
package im.device;

option java_package = "com.cloud.im.common.core.protocol.device";
option java_outer_classname = "DeviceProtos";

import "system_pb.proto";

// ============ 核心领域对象 ============

// 设备信息 - 核心领域对象
message Device {
  string device_id = 1;         // 设备ID（必填）
  string device_name = 2;       // 设备名称（必填）
  DeviceType device_type = 3;   // 设备类型（必填）
  string app_version = 4;       // 应用版本（可选）
  string client_ip = 5;         // 客户端IP（可选）
  int64 last_active_time = 6;   // 最后活跃时间（可选）
  int64 created_time = 7;       // 创建时间（系统自动生成）
  
  // 系统信息（可选）
  string system_name = 8;       // 系统名称（可选）
  string system_version = 9;    // 系统版本（可选）
  
  // 硬件信息（可选）
  string brand = 10;            // 设备品牌（可选）
  string model = 11;            // 设备型号（可选）
}

// 设备类型枚举
enum DeviceType {
  ANDROID = 0;                  // Android 设备（默认值）
  IOS = 1;                      // iOS 设备
  PC = 2;                       // PC 桌面端
  WEB = 3;                      // Web 浏览器端
}

// ============ 查询操作 ============

// 检查设备 - 查询操作
message check {
  string user_id = 1;           // 用户ID（必需）
  string device_id = 2;         // 设备ID（必需）
  Device device_info = 3;       // 设备信息（可选）
}

// 设备列表查询 - 查询操作
message listQuery {
  string user_id = 1;           // 用户ID（必需）
  DeviceType device_type = 2;   // 设备类型过滤（可选）
  system.Page page = 3;         // 分页参数（使用系统类型）
}

// ============ 操作对象 ============

// 注册设备 - 操作对象
message RegisterDevice {
  string user_id = 1;           // 用户ID（必填）
  Device device_info = 2;       // 设备信息（必填）
}

// 更新设备信息 - 操作对象
message UpdateDevice {
  string user_id = 1;           // 用户ID（必填）
  string device_id = 2;         // 设备ID（必填）
  string device_name = 3;       // 设备名称（可选）
  string app_version = 4;       // 应用版本（可选）
}

// ============ 结果对象 ============

// 设备检查结果 - 结果对象
message checkResult {
  bool device_exists = 1;       // 设备是否存在
  bool auth_required = 2;       // 是否需要认证
  bool limit_exceeded = 3;      // 是否超过设备限制
  int32 current_count = 4;      // 当前设备数量
  int32 max_count = 5;          // 最大设备数量
}

// 设备列表 - 结果对象
message list {
  repeated Device devices = 1;  // 设备列表
  system.Page page = 2;         // 分页元数据（使用系统类型）
}
```

## 🎯 枚举类型三层统一最佳实践

### 1. Protobuf 层定义枚举
```protobuf
enum DeviceType {
  UNKNOWN = 0;                  // 未知设备（默认值）
  ANDROID = 1;                  // Android 设备
  IOS = 2;                      // iOS 设备
  PC = 3;                       // PC 桌面端
  WEB = 4;                      // Web 浏览器端
}
```

### 2. 数据库层创建枚举类型
```sql
CREATE TYPE device_type_enum AS ENUM (
    'ANDROID',      -- 0: Android 设备
    'IOS',          -- 1: iOS 设备
    'PC',           -- 2: PC 桌面端
    'WEB'           -- 3: Web 浏览器端
);

CREATE TABLE im_user_device (
    device_type device_type_enum NOT NULL DEFAULT 'ANDROID'
);
```

### 3. Java 层枚举转换
```java
// Record 定义使用 Protobuf 枚举
public record ImDeviceInfo(
    DeviceProtos.DeviceType deviceType,
    DeviceProtos.DeviceStatus deviceStatus
) {}

// RowMapper 转换：数据库 → Java 枚举
private DeviceProtos.DeviceType mapDeviceType(String dbValue) {
    return switch (dbValue.toUpperCase()) {
        case "ANDROID" -> DeviceProtos.DeviceType.ANDROID;
        case "IOS" -> DeviceProtos.DeviceType.IOS;
        // ... 更多映射
        default -> DeviceProtos.DeviceType.ANDROID; // 默认值
    };
}

// 数据库写入：Java 枚举 → 字符串
.bind("deviceType", deviceInfo.deviceType().name())
```

### 4. 数据迁移：int → 枚举
```sql
-- 添加临时枚举列
ALTER TABLE im_user_device ADD COLUMN device_type_new device_type_enum;

-- 迁移数据
UPDATE im_user_device SET device_type_new = 
    CASE device_type
        WHEN 0 THEN 'ANDROID'::device_type_enum  -- 原 UNKNOWN 映射为 ANDROID
        WHEN 1 THEN 'IOS'::device_type_enum
        WHEN 2 THEN 'PC'::device_type_enum
        WHEN 3 THEN 'WEB'::device_type_enum
        ELSE 'ANDROID'::device_type_enum  -- 默认值
    END;

-- 删除旧列，重命名新列
ALTER TABLE im_user_device DROP COLUMN device_type;
ALTER TABLE im_user_device RENAME COLUMN device_type_new TO device_type;
```

## 💎 最佳实践

### 1. 设计原则
- **单一职责**: 每个 message 只负责一个明确的业务功能
- **最小化**: 只包含必要的字段，避免冗余
- **一致性**: 保持命名和结构的一致性
- **可读性**: 优先考虑代码的可读性和维护性
- **类型安全**: 强制使用枚举类型，避免魔法数字

### 2. 性能考虑
- **字段编号**: 使用连续的字段编号，避免跳跃
- **可选字段**: 合理使用 optional 字段，减少传输开销
- **重复字段**: 使用 repeated 字段处理列表数据

### 3. 版本兼容
- **字段编号**: 不要重用已删除的字段编号
- **新增字段**: 新字段使用新的编号，保持向后兼容
- **废弃字段**: 使用 `[deprecated = true]` 标记废弃字段

### 4. 文档维护
- **及时更新**: 修改 proto 文件时同步更新注释
- **示例代码**: 提供完整的使用示例
- **变更记录**: 记录重要的变更和迁移说明

## 📋 检查清单

在创建或修改 proto 文件时，请检查以下项目：

### 命名检查
- [ ] 是否去除了 Request/Response/Req/Resp 后缀？
- [ ] 领域对象是否使用帕斯卡命名法？
- [ ] 查询操作是否使用小写动词（如 `getUser`、`getGroup`，避免使用 `get` 关键字）？
- [ ] 操作对象是否使用动词+领域对象格式？
- [ ] 结果对象是否使用简化的小写名词？

### 类型检查
- [ ] 是否使用了 system_pb.proto 的通用类型？
- [ ] 是否避免了重复定义相同的响应结构？
- [ ] 分页是否使用了 system.Page 类型？
- [ ] 错误响应是否使用了 system.Error 类型？

### 枚举检查
- [ ] 所有状态字段是否使用枚举类型而不是 int？
- [ ] 所有类型字段是否使用枚举类型而不是 int？
- [ ] 枚举值命名是否最简洁（如 `ACTIVE` 而不是 `USER_ACTIVE`）？
- [ ] **枚举中是否禁止使用 `UNKNOWN` 或 `UNSPECIFIED`？**（⚠️ 强制要求）
- [ ] 枚举第一个值是否从 0 开始，使用实际业务值？
- [ ] 枚举值是否有清晰的中文注释？
- [ ] 枚举命名是否使用帕斯卡命名法？
- [ ] 数据库是否使用 PostgreSQL 枚举类型（CREATE TYPE ... AS ENUM）？
- [ ] Java Repository 是否实现了枚举转换方法？
- [ ] 是否在三层（Protobuf、Database、Java）保持枚举值一致？

### 字段检查
- [ ] 字段是否使用 snake_case 命名？
- [ ] ID 字段是否使用 _id 后缀？
- [ ] 时间戳字段是否使用 _at 或 _time 后缀？
- [ ] 状态、类型字段是否使用枚举类型而不是 int？
- [ ] 是否添加了必要的字段注释？

### 注释检查
- [ ] 每个 message 是否有用途说明？
- [ ] **所有字段是否明确标注了必填/选填状态？**（⚠️ 强制要求）
- [ ] 必填字段是否标注了（必填）？
- [ ] 可选字段是否标注了（可选）？
- [ ] 返回字段是否标注了（返回字段）或（返回字段，请求时不需要）？
- [ ] 系统字段是否标注了（系统自动生成）或（系统自动更新）？
- [ ] 是否说明了字段的业务含义和约束？
- [ ] 多用途 message 是否说明了字段在不同方法中的用途？
- [ ] 条件依赖字段是否说明了使用条件？

### 结构检查
- [ ] 是否按照消息类型分类组织？
- [ ] 是否保持了逻辑的清晰性？
- [ ] 是否避免了过度嵌套？
- [ ] 是否提供了完整的使用示例？

---

遵循本规范，可以显著提升 Protobuf 定义的简洁性、一致性和可维护性。建议在团队中建立代码审查机制，确保所有新的 proto 文件都符合本规范要求。
