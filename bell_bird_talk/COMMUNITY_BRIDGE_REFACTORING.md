## 社群管理功能重构说明

### 变更概述
社群管理相关功能已从 `IOSNativeService` 类中分离到独立的 `CommunityBridge` 类中，以改进代码组织和可维护性。

### 文件结构
- **`lib/services/native_bridge.dart`**: 包含主要的 NativeBridge 和 IOSNativeService 类
- **`lib/services/community_bridge.dart`**: 新增的社群管理独立类

### 使用方式

#### 旧方式（已弃用）
```dart
// 不再可用 - 这些方法已被移除
// iosService.imGetCommunityList()
// iosService.imJoinCommunity()
```

#### 新方式
```dart
// 创建服务实例
final iosService = IOSNativeService();

// 通过 community 属性访问社群功能
final communityList = await iosService.community.getCommunityList(page: 1, pageSize: 20);
final communityInfo = await iosService.community.getCommunityInfo(cmtyId: 'xxx');
final joinResult = await iosService.community.joinCommunity(cmtyId: 'xxx');
```

### 迁移指南

如果你的代码中有使用旧的社群方法，请按如下方式更新：

| 旧方法 | 新方法 |
|--------|--------|
| `iosService.imGetCommunityList()` | `iosService.community.getCommunityList()` |
| `iosService.imGetCommunityInfo()` | `iosService.community.getCommunityInfo()` |
| `iosService.imJoinCommunity()` | `iosService.community.joinCommunity()` |
| `iosService.imLeaveCommunity()` | `iosService.community.leaveCommunity()` |
| `iosService.imGetCommunityGroups()` | `iosService.community.getCommunityGroups()` |
| `iosService.imGetChannels()` | `iosService.community.getChannels()` |
| `iosService.imCreateChannel()` | `iosService.community.createChannel()` |
| `iosService.imUpdateChannel()` | `iosService.community.updateChannel()` |
| `iosService.imDeleteChannel()` | `iosService.community.deleteChannel()` |
| `iosService.imEnterChannel()` | `iosService.community.enterChannel()` |
| `iosService.imCreateChannelGroup()` | `iosService.community.createChannelGroup()` |
| `iosService.imUpdateChannelGroup()` | `iosService.community.updateChannelGroup()` |
| `iosService.imDeleteChannelGroup()` | `iosService.community.deleteChannelGroup()` |
| `iosService.imGetCommunityMembers()` | `iosService.community.getCommunityMembers()` |
| `iosService.imGetCommunityBannedMembers()` | `iosService.community.getCommunityBannedMembers()` |
| `iosService.imMuteCommunityMember()` | `iosService.community.muteCommunityMember()` |
| `iosService.imKickCommunityMember()` | `iosService.community.kickCommunityMember()` |

### 功能分类

**CommunityBridge** 中的方法按以下几类组织：

1. **社群基础操作**
   - `getCommunityList()` - 获取社群列表
   - `getCommunityInfo()` - 获取社群信息
   - `joinCommunity()` - 加入社群
   - `leaveCommunity()` - 离开社群

2. **分组管理**
   - `getCommunityGroups()` - 获取分组列表

3. **频道管理**
   - `getChannels()` - 获取频道列表
   - `createChannel()` - 创建频道
   - `updateChannel()` - 更新频道
   - `deleteChannel()` - 删除频道
   - `enterChannel()` - 进入频道

4. **频道分组管理**
   - `createChannelGroup()` - 创建频道分组
   - `updateChannelGroup()` - 更新频道分组
   - `deleteChannelGroup()` - 删除频道分组

5. **成员管理**
   - `getCommunityMembers()` - 获取成员列表
   - `getCommunityBannedMembers()` - 获取封禁成员列表
   - `muteCommunityMember()` - 禁言/解禁成员
   - `kickCommunityMember()` - 踢出成员

### 优势

✅ **更好的代码组织** - 社群功能集中在一个专门的类中  
✅ **便于维护** - 功能职责明确，易于扩展  
✅ **更清晰的 API** - 通过 `.community` 前缀明确表示是社群操作  
✅ **未来可扩展** - 可以轻松添加其他功能类（如 `group`、`channel` 等）
