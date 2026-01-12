import 'package:bell_bird_talk/pages/community/models/community_model.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 语音频道页面
class VoiceChannelPage extends StatefulWidget {
  final ChannelModel channel;

  const VoiceChannelPage({
    super.key,
    required this.channel,
  });

  @override
  State<VoiceChannelPage> createState() => _VoiceChannelPageState();
}

class _VoiceChannelPageState extends State<VoiceChannelPage> {
  // 成员列表（模拟数据，实际应该从 channel 获取）
  List<Map<String, dynamic>> _members = [];
  
  // 麦克风状态
  bool _isMicMuted = false;
  
  // 耳机状态（扬声器/耳机）
  bool _isHeadphoneMode = false;
  
  // 是否显示首次进入弹窗
  bool _showWelcomeDialog = true;
  
  // 成员数量阈值，超过此数量使用宫格显示
  static const int _gridThreshold = 9;

  @override
  void initState() {
    super.initState();
    // 初始化成员列表（模拟数据）
    _loadMockMembers();
  }

  /// 加载模拟成员数据
  void _loadMockMembers() {
    // 这里应该是从 channel 获取成员列表
    // 暂时使用模拟数据
    _members = [
      {
        'user_id': '1',
        'nickname': '用户1',
        'avatar': null,
      },
      {
        'user_id': '2',
        'nickname': '用户2',
        'avatar': null,
      },
      {
        'user_id': '3',
        'nickname': '用户3',
        'avatar': null,
      },
    ];
    setState(() {});
  }

  /// 切换麦克风状态
  void _toggleMicrophone() {
    setState(() {
      _isMicMuted = !_isMicMuted;
    });
  }

  /// 切换耳机状态
  void _toggleHeadphone() {
    setState(() {
      _isHeadphoneMode = !_isHeadphoneMode;
    });
  }

  /// 邀请好友
  void _inviteFriend() {
    // TODO: 实现邀请好友逻辑
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('邀请好友')),
    );
  }

  /// 挂断/离开频道
  void _hangUp() {
    Navigator.of(context).pop();
  }

  /// 加入语音频道
  void _joinChannel() {
    setState(() {
      _showWelcomeDialog = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GbsColors.darkBackgroundPrimary,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // 主内容区域
          Column(
            children: [
              // 成员列表/宫格区域
              Expanded(
                child: _buildMembersArea(),
              ),
              // 底部操作栏占位（防止内容被遮挡）
              const SizedBox(height: 100),
            ],
          ),
          // 底部操作栏（浮层）
          _buildBottomActionBar(),
          // 首次进入弹窗
          if (_showWelcomeDialog) _buildWelcomeDialog(),
        ],
      ),
    );
  }

  /// 构建 AppBar
  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Container(
        color: GbsColors.darkAppBarPrimary,
        child: SafeArea(
          child: Row(
            children: [
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  height: 44,
                  width: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: GbsColors.darkTitlePrimary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  widget.channel.channelName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: GbsColors.darkTitlePrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 64),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建成员区域
  Widget _buildMembersArea() {
    if (_members.isEmpty) {
      return Center(
        child: Text(
          '暂无成员',
          style: TextStyle(
            color: GbsColors.darkDescriptionPrimary,
            fontSize: 14,
          ),
        ),
      );
    }

    // 根据成员数量决定使用列表还是宫格
    if (_members.length <= _gridThreshold) {
      return _buildMemberList();
    } else {
      return _buildMemberGrid();
    }
  }

  /// 构建成员列表（成员少时使用）
  Widget _buildMemberList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _members.length,
      itemBuilder: (context, index) {
        final member = _members[index];
        return _buildMemberCard(member);
      },
    );
  }

  /// 构建成员宫格（成员多时使用）
  Widget _buildMemberGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: _members.length,
      itemBuilder: (context, index) {
        final member = _members[index];
        return _buildMemberGridItem(member);
      },
    );
  }

  /// 构建成员卡片（列表模式）
  Widget _buildMemberCard(Map<String, dynamic> member) {
    final nickname = member['nickname'] ?? '未知用户';
    final avatar = member['avatar'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GbsColors.darkCardPrimary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 头像
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: GbsColors.darkDivider,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: avatar != null && avatar.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: avatar,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => const Icon(
                        Icons.person,
                        color: GbsColors.darkDescriptionPrimary,
                        size: 24,
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      color: GbsColors.darkDescriptionPrimary,
                      size: 24,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // 昵称
          Expanded(
            child: Text(
              nickname,
              style: const TextStyle(
                fontSize: 16,
                color: GbsColors.darkTitlePrimary,
              ),
            ),
          ),
          // 加好友图标
          InkWell(
            onTap: () {
              // TODO: 实现加好友逻辑
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('添加 $nickname 为好友')),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: GbsColors.darkSecondaryButton,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.person_add,
                color: GbsColors.darkButtonTextSecondary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建成员宫格项（宫格模式）
  Widget _buildMemberGridItem(Map<String, dynamic> member) {
    final nickname = member['nickname'] ?? '未知用户';
    final avatar = member['avatar'] as String?;

    return Container(
      decoration: BoxDecoration(
        color: GbsColors.darkCardPrimary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 头像
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: GbsColors.darkDivider,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: avatar != null && avatar.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: avatar,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => const Icon(
                        Icons.person,
                        color: GbsColors.darkDescriptionPrimary,
                        size: 30,
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      color: GbsColors.darkDescriptionPrimary,
                      size: 30,
                    ),
            ),
          ),
          const SizedBox(height: 8),
          // 昵称
          Text(
            nickname,
            style: const TextStyle(
              fontSize: 14,
              color: GbsColors.darkTitlePrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // 加好友图标
          InkWell(
            onTap: () {
              // TODO: 实现加好友逻辑
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('添加 $nickname 为好友')),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: GbsColors.darkSecondaryButton,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.person_add,
                color: GbsColors.darkButtonTextSecondary,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建底部操作栏
  Widget _buildBottomActionBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border(
            top: BorderSide(
              color: GbsColors.darkDivider.withOpacity(0.3),
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 麦克风和耳机状态卡片
              _buildAudioControlCard(),
              const SizedBox(width: 12),
              // 邀请好友
              _buildActionButton(
                icon: Icons.person_add_outlined,
                onTap: _inviteFriend,
              ),
              const SizedBox(width: 12),
              // 挂断
              _buildActionButton(
                icon: Icons.call_end,
                onTap: _hangUp,
                isDanger: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建音频控制卡片（麦克风和耳机）
  Widget _buildAudioControlCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: GbsColors.darkCardPrimary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 麦克风图标
          InkWell(
            onTap: _toggleMicrophone,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                _isMicMuted ? Icons.mic_off : Icons.mic,
                color: _isMicMuted
                    ? GbsColors.darkError
                    : GbsColors.darkButtonTextSecondary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 耳机图标
          InkWell(
            onTap: _toggleHeadphone,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                _isHeadphoneMode ? Icons.headphones : Icons.volume_up,
                color: GbsColors.darkButtonTextSecondary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isDanger
              ? GbsColors.darkError
              : GbsColors.darkCardPrimary,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Icon(
          icon,
          color: isDanger
              ? Colors.white
              : GbsColors.darkButtonTextSecondary,
          size: 24,
        ),
      ),
    );
  }

  /// 构建欢迎弹窗
  Widget _buildWelcomeDialog() {
    final onlineCount = _members.length;

    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: GbsColors.darkCardPrimary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 频道名
              Text(
                widget.channel.channelName,
                style: const TextStyle(
                  fontSize: 20,
                  color: GbsColors.darkTitlePrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // 频道在线人数
              Text(
                '在线人数: $onlineCount',
                style: const TextStyle(
                  fontSize: 16,
                  color: GbsColors.darkDescriptionPrimary,
                ),
              ),
              const SizedBox(height: 24),
              // 加入语音频道按钮
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _joinChannel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GbsColors.darkPrimaryButton,
                    foregroundColor: GbsColors.darkButtonTextPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '加入语音频道',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
