import 'package:bell_bird_talk/controllers/friend_controller.dart';
import 'package:bell_bird_talk/utils/gbs_colors.dart';
import 'package:bell_bird_talk/widgets/common_button.dart';
import 'package:bell_bird_talk/services/native_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
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
  final TextEditingController _editController = TextEditingController();
  final IOSNativeService _nativeService = IOSNativeService();
  List<FriendGroup> groups = [];
  String? _editingGroupId; // 正在编辑的分组ID

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getGroups();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _editController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: Column(
        children: [
          // 标题栏
          Padding(
            padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '设置分组',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 分组列表
                  Flexible(
                    child: ReorderableListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      onReorder: _editingGroupId == null
                          ? _onReorder
                          : (_oldIndex, _newIndex) {},
                      children: groups.asMap().entries.map((entry) {
                        return _buildGroupItem(entry.value, entry.key);
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsetsGeometry.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: 38,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
              Text(
              '按住右侧顺序按钮可拖动调整分组顺序',
              style: TextStyle(fontSize: 12, color: GbsColors.des9Color),
            ),
            ],)
          ),
          Padding(
            padding: EdgeInsetsGeometry.symmetric(horizontal: 16),
            child: CommonButton(
              enabled: true,
              onPressed: () {
                // 新建分组
                widget.onAddGroup();
              },
              text: '新增好友分组',
            ),
          ),
          // 底部安全区域
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
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

  Widget _buildGroupItem(FriendGroup group, int index) {
    final isEditing = _editingGroupId == group.id;

    return ListTile(
      key: ValueKey(group.id),
      title: isEditing
          ? TextField(
              controller: _editController,
              autofocus: true,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            )
          : Text(
              group.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            )
          : isEditing
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: _cancelEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.check, color: GbsColors.darkPrimaryButton),
                  onPressed: () => _saveEdit(group),
                ),
              ],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Image.asset(
                    'assets/img/friend/group_edit.png',
                    width: 20,
                    height: 20,
                  ),
                  onPressed: () => _startEdit(group),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onDeleteGroup(group);
                  },
                  icon: Image.asset(
                    'assets/img/friend/group_del.png',
                    width: 20,
                    height: 20,
                  ),
                ),
                if (_editingGroupId == null)
                  ReorderableDragStartListener(
                    index: index,
                    child: Image.asset(
                      'assets/img/friend/group_mov.png',
                      width: 20,
                      height: 20,
                    ),
                  ),
              ],
            ),
    );
  }

  // 开始编辑
  void _startEdit(FriendGroup group) {
    setState(() {
      _editingGroupId = group.id;
      _editController.text = group.name;
    });
  }

  // 取消编辑
  void _cancelEdit() {
    setState(() {
      _editingGroupId = null;
      _editController.clear();
    });
  }

  // 保存编辑
  Future<void> _saveEdit(FriendGroup group) async {
    final newName = _editController.text.trim();
    if (newName.isEmpty) {
      EasyLoading.showError('分组名称不能为空');
      return;
    }
    if (newName == group.name) {
      _cancelEdit();
      return;
    }

    EasyLoading.show(status: '更新分组中...');
    try {
      final gid = int.tryParse(group.id) ?? 0;
      final result = await _nativeService.imUpdateContactGroup(
        groupId: gid,
        groupName: newName,
      );
      if (result['errorCode'] == 0) {
        EasyLoading.showSuccess('分组已更新');
        widget.onUpdateGroup(group);
        _cancelEdit();
        await _getGroups();
      } else {
        EasyLoading.showError(result['message'] ?? '更新失败');
      }
    } catch (e) {
      EasyLoading.showError('更新失败，请稍后重试');
    }
  }

  // 处理拖动排序
  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    setState(() {
      final item = groups.removeAt(oldIndex);
      groups.insert(newIndex, item);
    });

    // 更新所有分组的顺序
    for (int i = 0; i < groups.length; i++) {
      final group = groups[i];
      final groupId = int.tryParse(group.id) ?? 0;
      if (groupId > 0) {
        try {
          await _nativeService.imUpdateContactGroup(
            groupId: groupId,
            groupOrder: i,
          );
        } catch (e) {
          print('更新分组顺序失败: $e');
        }
      }
    }

    // 刷新列表
    await _getGroups();
  }
}
