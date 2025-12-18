import 'package:flutter/material.dart';
import '../models/friend_model.dart';

/// 分组设置底部弹窗
class GroupSettingsSheet extends StatefulWidget {
  final List<FriendGroup> groups;
  final Future<void> Function(String) onAddGroup;
  final Function(FriendGroup) onDeleteGroup;
  final Future<void> Function(FriendGroup) onUpdateGroup;
  
  const GroupSettingsSheet({
    super.key,
    required this.groups,
    required this.onAddGroup,
    required this.onDeleteGroup,
    required this.onUpdateGroup,
  });

  @override
  State<GroupSettingsSheet> createState() => _GroupSettingsSheetState();
}

class _GroupSettingsSheetState extends State<GroupSettingsSheet> {
  final TextEditingController _nameController = TextEditingController();
  bool _isAdding = false;  // 是否正在添加分组
  
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
                    '分组管理',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _isAdding = !_isAdding;
                        if (!_isAdding) {
                          _nameController.clear();
                        }
                      });
                    },
                    icon: Icon(_isAdding ? Icons.close : Icons.add, size: 18),
                    label: Text(_isAdding ? '取消' : '新建分组'),
                  ),
                ],
              ),
            ),
            
            // 新建分组输入框
            if (_isAdding)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: '输入分组名称',
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        final name = _nameController.text.trim();
                        if (name.isNotEmpty) {
                          await widget.onAddGroup(name);
                          if (mounted) {
                            setState(() {
                              _isAdding = false;
                              _nameController.clear();
                            });
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('创建'),
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
                itemCount: widget.groups.length,
                itemBuilder: (context, index) {
                  final group = widget.groups[index];
                  return _buildGroupItem(group);
                },
              ),
            ),
            
            // 底部安全区域
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGroupItem(FriendGroup group) {
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

