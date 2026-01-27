class PermissionConfigAll {
  final bool handleInviteFriend;

  PermissionConfigAll({
    required this.handleInviteFriend,
  });

  factory PermissionConfigAll.fromJson(Map<String, dynamic> json) {
    return PermissionConfigAll(
      handleInviteFriend: json['handleInviteFriend'] == 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'handleInviteFriend': handleInviteFriend,
    };
  }
}

// First, let's define the PermissionConfigModel since it's used in roles
class PermissionConfigModel {
  final String status;
  final int expireTime;
  final String configDesc;
  final String methodName;
  final Map<String, dynamic>? attributes;

  PermissionConfigModel({
    required this.status,
    required this.expireTime,
    required this.configDesc,
    required this.methodName,
    this.attributes,
  });

  factory PermissionConfigModel.fromJson(Map<String, dynamic> json) {
    return PermissionConfigModel(
      status: json['status'] ?? '',
      expireTime: json['expire_time'] ?? -1,
      configDesc: json['config_desc'] ?? '',
      methodName: json['method_name'] ?? '',
      attributes: json['attributes'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'expire_time': expireTime,
      'config_desc': configDesc,
      'method_name': methodName,
      if (attributes != null) 'attributes': attributes,
    };
  }
}

// Define the RoleModel
class RoleModel {
  final String status;
  final int assignedTime;
  final bool isDefault;
  final int expireTime;
  final int createdAt;
  final String roleId;
  final int memberCount;
  final String roleName;
  final String roleDesc;
  final List<PermissionConfigModel> permissions;

  RoleModel({
    required this.status,
    required this.assignedTime,
    required this.isDefault,
    required this.expireTime,
    required this.createdAt,
    required this.roleId,
    required this.memberCount,
    required this.roleName,
    required this.roleDesc,
    required this.permissions,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    final permissionsJson = json['permissions'] as List<dynamic>?;
    final permissions = permissionsJson != null 
        ? permissionsJson.map((p) => PermissionConfigModel.fromJson(p as Map<String, dynamic>)).toList()
        : <PermissionConfigModel>[];

    return RoleModel(
      status: json['status'] ?? '',
      assignedTime: json['assigned_time'] ?? 0,
      isDefault: json['is_default'] ?? false,
      expireTime: json['expire_time'] ?? -1,
      createdAt: json['created_at'] ?? 0,
      roleId: json['role_id'] ?? '',
      memberCount: json['member_count'] ?? 0,
      roleName: json['role_name'] ?? '',
      roleDesc: json['role_desc'] ?? '',
      permissions: permissions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'assigned_time': assignedTime,
      'is_default': isDefault,
      'expire_time': expireTime,
      'created_at': createdAt,
      'role_id': roleId,
      'member_count': memberCount,
      'role_name': roleName,
      'role_desc': roleDesc,
      'permissions': permissions.map((p) => p.toJson()).toList(),
    };
  }
}

// Now the main CommunityRolesAndTemplateModel
class CommunityRolesAndTemplateModel {
  final List<RoleModel> roles;
  final List<dynamic> templates; // Based on your logs, we don't have template details

  CommunityRolesAndTemplateModel({
    required this.roles,
    required this.templates,
  });

  factory CommunityRolesAndTemplateModel.fromJson(Map<String, dynamic> json) {
    final rolesJson = json['roles'] as List<dynamic>?;
    final templatesJson = json['templates'] as List<dynamic>?;
    
    final roles = rolesJson != null 
        ? rolesJson.map((r) => RoleModel.fromJson(r as Map<String, dynamic>)).toList()
        : <RoleModel>[];
    
    final templates = templatesJson != null 
        ? templatesJson 
        : <dynamic>[];

    return CommunityRolesAndTemplateModel(
      roles: roles,
      templates: templates,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roles': roles.map((role) => role.toJson()).toList(),
      'templates': templates,
    };
  }
}