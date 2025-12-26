import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'models/community_model.dart';

/// 社群详情页面
class CommunityDetailPage extends StatelessWidget {
  final CommunityModel community;
  
  const CommunityDetailPage({
    super.key,
    required this.community,
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('社群详情'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部信息
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue[400]!,
                    GbsColors.textTapPrimary,
                  ],
                ),
              ),
              child: Column(
                children: [
                  // 头像
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: community.avatar != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              community.avatar!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.group,
                                  color: Colors.white,
                                  size: 40,
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.group,
                            color: Colors.white,
                            size: 40,
                          ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 名称
                  Text(
                    community.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // 分类
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      community.category,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // 描述
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '简介',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    community.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(),
            
            // 统计信息
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.people,
                      label: '成员数',
                      value: community.memberCountText,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.person,
                      label: '创建者',
                      value: community.ownerName ?? '未知',
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(),
            
            // 操作按钮
            Padding(
              padding: const EdgeInsets.all(16),
              child: community.isJoined
                  ? SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          EasyLoading.showInfo('您已加入该社群');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '已加入',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (community.hasApplied) {
                            EasyLoading.showInfo('您已申请加入，请等待审核');
                          } else if (community.isFull) {
                            EasyLoading.showError('该社群已满员');
                          } else {
                            // 申请加入
                            EasyLoading.show(status: '正在申请...');
                            Future.delayed(const Duration(seconds: 1), () {
                              EasyLoading.dismiss();
                              EasyLoading.showSuccess('申请已提交，请等待审核');
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          community.hasApplied ? '已申请' : '申请加入',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.blue,
          size: 32,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

