


import 'package:bell_bird_talk/pages/models/friend_model.dart';
import 'package:flutter/material.dart';

/// 移动到分组底部弹窗
class MoveToGroupSheet extends StatelessWidget {
  final FriendModel friend;
  final List<FriendGroup> groups;
  final String? currentGroupId;
  final Function(String) onMoveToGroup;
  final VoidCallback onShowGroupSettings;
  
  const MoveToGroupSheet({
    required this.friend,
    required this.groups,
    required this.currentGroupId,
    required this.onMoveToGroup,
    required this.onShowGroupSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖动条
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // 标题栏
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text(
                  '移动到分组',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: onShowGroupSettings,
                  tooltip: '添加分组',
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // 分组列表
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                final isCurrentGroup = currentGroupId != null && 
                    (currentGroupId == group.id || 
                     (currentGroupId == 'all' && group.id == 'all'));
                
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: group.isDefault ? Colors.blue[50] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      group.id == 'special' ? Icons.star : Icons.folder,
                      color: group.isDefault ? Colors.blue : Colors.grey[600],
                      size: 20,
                    ),
                  ),
                  title: Text(
                    group.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isCurrentGroup ? Colors.grey[400] : Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    group.isDefault ? '默认分组' : '${group.count} 位好友',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 13,
                    ),
                  ),
                  trailing: isCurrentGroup
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  enabled: !isCurrentGroup,
                  onTap: isCurrentGroup
                      ? null
                      : () {
                          Navigator.pop(context);
                          onMoveToGroup(group.id);
                        },
                );
              },
            ),
          ),
          
          // 底部安全区域
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}
