// import 'package:flutter/material.dart';
// import '../../../controllers/community_controller.dart';
// import '../models/community_role_model.dart';

// /// 社群角色权限测试页面
// class CommunityRolesTestPage extends StatefulWidget {
//   final String cmtyId;
//   final String cmtyName;

//   const CommunityRolesTestPage({
//     super.key,
//     required this.cmtyId,
//     required this.cmtyName,
//   });

//   @override
//   State<CommunityRolesTestPage> createState() => _CommunityRolesTestPageState();
// }

// class _CommunityRolesTestPageState extends State<CommunityRolesTestPage> {
//   CommunityRolesAndTemplateModel? _rolesData;
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadRolesAndTemplate();
//   }

//   Future<void> _loadRolesAndTemplate() async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final result = await CommunityController.to.getRolesAndTemplate(widget.cmtyId);
//       setState(() {
//         _rolesData = result;
//       });
//     } catch (e) {
//       print('加载角色权限失败: $e');
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('${widget.cmtyName} - 角色权限'),
//         backgroundColor: Colors.blue,
//         foregroundColor: Colors.white,
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _rolesData == null
//               ? const Center(child: Text('暂无数据'))
//               : SingleChildScrollView(
//                   padding: const EdgeInsets.all(16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // 社群信息
//                       Card(
//                         child: Padding(
//                           padding: const EdgeInsets.all(16),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 '社群信息',
//                                 style: Theme.of(context).textTheme.titleLarge,
//                               ),
//                               const SizedBox(height: 8),
//                               Text('社群ID: ${_rolesData!.cmtyId}'),
//                               Text('角色数量: ${_rolesData!.roles.length}'),
//                               Text('权限模板: ${_rolesData!.template?.templateName ?? "无"}'),
//                             ],
//                           ),
//                         ),
//                       ),

//                       const SizedBox(height: 16),

//                       // 角色列表
//                       Text(
//                         '角色列表',
//                         style: Theme.of(context).textTheme.titleLarge,
//                       ),
//                       const SizedBox(height: 8),
//                       ..._rolesData!.roles.map((role) => _buildRoleCard(role)),

//                       const SizedBox(height: 16),

//                       // 权限模板
//                       if (_rolesData!.template != null) ...[
//                         Text(
//                           '权限模板',
//                           style: Theme.of(context).textTheme.titleLarge,
//                         ),
//                         const SizedBox(height: 8),
//                         _buildTemplateCard(_rolesData!.template!),
//                       ],
//                     ],
//                   ),
//                 ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _loadRolesAndTemplate,
//         child: const Icon(Icons.refresh),
//       ),
//     );
//   }

//   Widget _buildRoleCard(RoleModel role) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 8),
//       child: ExpansionTile(
//         title: Text(role.roleName),
//         subtitle: Text(role.roleDesc),
//         trailing: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             if (role.isDefault)
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: Colors.blue,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: const Text(
//                   '默认',
//                   style: TextStyle(color: Colors.white, fontSize: 12),
//                 ),
//               ),
//             const SizedBox(width: 8),
//             Text('${role.memberCount}人'),
//             const Icon(Icons.expand_more),
//           ],
//         ),
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   '角色ID: ${role.roleId}',
//                   style: const TextStyle(fontSize: 12, color: Colors.grey),
//                 ),
//                 const SizedBox(height: 8),
//                 const Text('权限列表:', style: TextStyle(fontWeight: FontWeight.bold)),
//                 const SizedBox(height: 4),
//                 if (role.permissions.isEmpty)
//                   const Text('无权限', style: TextStyle(color: Colors.grey))
//                 else
//                   Wrap(
//                     spacing: 8,
//                     runSpacing: 4,
//                     children: role.permissions.map((permission) {
//                       return Chip(
//                         label: Text(permission),
//                         backgroundColor: Colors.blue[50],
//                       );
//                     }).toList(),
//                   ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTemplateCard(PermissionTemplateModel template) {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               template.templateName,
//               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               '模板ID: ${template.templateId}',
//               style: const TextStyle(fontSize: 12, color: Colors.grey),
//             ),
//             const SizedBox(height: 12),
//             const Text('权限列表:', style: TextStyle(fontWeight: FontWeight.bold)),
//             const SizedBox(height: 8),
//             if (template.permissions.isEmpty)
//               const Text('无权限定义', style: TextStyle(color: Colors.grey))
//             else
//               ...template.permissions.map((permission) {
//                 return Container(
//                   margin: const EdgeInsets.only(bottom: 8),
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: permission.isEnabled ? Colors.green[50] : Colors.grey[50],
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(
//                       color: permission.isEnabled ? Colors.green : Colors.grey,
//                       width: 1,
//                     ),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(
//                         permission.isEnabled ? Icons.check_circle : Icons.cancel,
//                         color: permission.isEnabled ? Colors.green : Colors.grey,
//                         size: 20,
//                       ),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               permission.permissionName,
//                               style: const TextStyle(fontWeight: FontWeight.bold),
//                             ),
//                             if (permission.permissionDesc.isNotEmpty)
//                               Text(
//                                 permission.permissionDesc,
//                                 style: const TextStyle(fontSize: 12, color: Colors.grey),
//                               ),
//                             Text(
//                               'ID: ${permission.permissionId}',
//                               style: const TextStyle(fontSize: 10, color: Colors.grey),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               }),
//           ],
//         ),
//       ),
//     );
//   }
// }