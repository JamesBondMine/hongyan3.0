import 'package:bell_bird_talk/controllers/friend_controller.dart';
import 'package:bell_bird_talk/widgets/common_button.dart';
import 'package:flutter/material.dart';
import '../models/friend_model.dart';

/// 分组设置底部弹窗
class GroupSettingsSheet extends StatefulWidget {
  final VoidCallback onAddGroup;
  final Function(FriendGroup) onDeleteGroup;
  final Future<void> Function(FriendGroup) onUpdateGroup;
  
  const GroupSettingsSheet({
    super.key,
    required this.onAddGroup,
    required this.onDeleteGroup,
    required this.onUpdateGroup,
  });

  @override
  State<GroupSettingsSheet> createState() => _GroupSettingsSheetState();
}

class _GroupSettingsSheetState extends State<GroupSettingsSheet> {
  final TextEditingController _nameController = TextEditingController();
  List<FriendGroup> groups = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getGroups();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            Padding(
              padding: const EdgeInsets.only(top: 26, left: 16, right: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Text(
                    '设置分组',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  IconButton(onPressed: (){
                    Navigator.pop(context);
                  }, icon: Icon(Icons.close))
                ],
              ),
            ),
            // 分组列表
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];
                  return _buildGroupItem(group);
                },
              ),
            ),
            Padding(padding: EdgeInsetsGeometry.symmetric(horizontal: 16), child: CommonButton(
              enabled: true,
              onPressed: () {
                // 新建分组
                widget.onAddGroup();
              },
              text: '新增好友分组'),),
            // 底部安全区域
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  // 获取好友分组
  Future<void> _getGroups() async {
    groups = await FriendController.to.getFriendGroups();
    if (mounted) {
      setState(() {});
    }
  }
  
  Widget _buildGroupItem(FriendGroup group) {
    return ListTile(
      title: Text(
        group.name,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        group.isDefault ? '默认分组' : '${group.count} 位好友',
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 13,
        ),
      ),
      trailing: group.isDefault
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '不可删除',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                  onPressed: () async {
                    Navigator.pop(context);
                    await widget.onUpdateGroup(group);
                  },
                ),
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onDeleteGroup(group);
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ],
            ),
    );
  }
}

