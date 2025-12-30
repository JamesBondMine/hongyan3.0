


import 'package:flutter/material.dart';

/// 添加群成员对话框
class AddMemberDialog extends StatefulWidget {
  final List<dynamic> contacts;
  
  const AddMemberDialog({required this.contacts});
  
  @override
  State<AddMemberDialog> createState() => AddMemberDialogState();
}

class AddMemberDialogState extends State<AddMemberDialog> {
  final TextEditingController _searchController = TextEditingController();
  Set<String> _selectedUserIds = {};
  List<dynamic> _filteredContacts = [];
  
  @override
  void initState() {
    super.initState();
    _filteredContacts = List.from(widget.contacts);
    _searchController.addListener(_filterContacts);
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _filterContacts() {
    final keyword = _searchController.text.toLowerCase().trim();
    setState(() {
      if (keyword.isEmpty) {
        _filteredContacts = List.from(widget.contacts);
      } else {
        _filteredContacts = widget.contacts.where((contact) {
          final nickname = (contact['nickname'] ?? '').toString().toLowerCase();
          final remark = (contact['remark'] ?? '').toString().toLowerCase();
          final userId = (contact['contact_user_id'] ?? '').toString().toLowerCase();
          return nickname.contains(keyword) ||
                 remark.contains(keyword) ||
                 userId.contains(keyword);
        }).toList();
      }
    });
  }
  
  void _toggleSelection(String userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        _selectedUserIds.add(userId);
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            // 标题栏
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    '选择联系人',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _selectedUserIds.isEmpty
                        ? null
                        : () => Navigator.pop(context, _selectedUserIds),
                    child: Text('确定(${_selectedUserIds.length})'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // 搜索框
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '搜索联系人',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            // 联系人列表
            Expanded(
              child: _filteredContacts.isEmpty
                  ? const Center(child: Text('暂无联系人'))
                  : ListView.builder(
                      itemCount: _filteredContacts.length,
                      itemBuilder: (context, index) {
                        final contact = _filteredContacts[index];
                        final userId = (contact['contact_user_id'] as String?) ?? '';
                        final nickname = (contact['nickname'] as String?) ?? '未知';
                        final remark = (contact['remark'] as String?) ?? '';
                        final avatar = (contact['avatar'] as String?) ?? '';
                        final displayName = remark.isNotEmpty ? remark : nickname;
                        final isSelected = _selectedUserIds.contains(userId);
                        
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.grey.shade300,
                            backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                            child: avatar.isEmpty
                                ? Text(
                                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                    style: const TextStyle(color: Colors.white),
                                  )
                                : null,
                          ),
                          title: Text(displayName),
                          subtitle: remark.isNotEmpty ? Text(nickname) : null,
                          trailing: Checkbox(
                            value: isSelected,
                            onChanged: (_) => _toggleSelection(userId),
                          ),
                          onTap: () => _toggleSelection(userId),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

}


