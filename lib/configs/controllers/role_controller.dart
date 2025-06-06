//Librerías
import 'dart:convert';
import 'dart:io';
import 'package:http/io_client.dart';
import 'package:jmas_movil_lecturas/configs/service/auth_service.dart';

class RoleController {
  final AuthService _authService = AuthService();

  IOClient _createHttpClient() {
    final ioClient = HttpClient();
    ioClient.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    return IOClient(ioClient);
  }

  //ListRole
  Future<List<Role>> listRole() async {
    try {
      final IOClient client = _createHttpClient();
      final response = await client.get(
        Uri.parse('${_authService.apiURL}/Roles'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((role) => Role.fromMap(role)).toList();
      } else {
        print(
          'Error al obtener roles | Ife | Controller: ${response.statusCode} - ${response.body}',
        );
        return [];
      }
    } catch (e) {
      print('Error al listar roles | Ife | Controller: $e');
      return [];
    }
  }

  //EditRole
  Future<bool> editRole(Role role) async {
    try {
      final IOClient client = _createHttpClient();
      final response = await client.put(
        Uri.parse('${_authService.apiURL}/Roles/${role.idRole}'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: role.toJson(),
      );

      if (response.statusCode == 204) {
        return true;
      } else {
        print(
          'Error editRole | Ife | Controller: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Error editRole | Try | Controller: $e');
      return false;
    }
  }

  //Add
  Future<bool> addRol(Role role) async {
    try {
      final IOClient client = _createHttpClient();
      final response = await client.post(
        Uri.parse('${_authService.apiURL}/Roles'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: role.toJson(),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        print(
          'Error addRol | Ife | Controller: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Error addRole | Try | Controller: $e');
      return false;
    }
  }
}

class Role {
  int? idRole;
  String? roleNombre;
  String? roleDescr;
  bool? canView;
  bool? canAdd;
  bool? canEdit;
  bool? canDelete;
  bool? canManageUsers;
  bool? canManageRoles;
  bool? canEvaluar;
  Role({
    this.idRole,
    this.roleNombre,
    this.roleDescr,
    this.canView,
    this.canAdd,
    this.canEdit,
    this.canDelete,
    this.canManageUsers,
    this.canManageRoles,
    this.canEvaluar,
  });

  Role copyWith({
    int? idRole,
    String? roleNombre,
    String? roleDescr,
    bool? canView,
    bool? canAdd,
    bool? canEdit,
    bool? canDelete,
    bool? canManageUsers,
    bool? canManageRoles,
    bool? canEvaluar,
  }) {
    return Role(
      idRole: idRole ?? this.idRole,
      roleNombre: roleNombre ?? this.roleNombre,
      roleDescr: roleDescr ?? this.roleDescr,
      canView: canView ?? this.canView,
      canAdd: canAdd ?? this.canAdd,
      canEdit: canEdit ?? this.canEdit,
      canDelete: canDelete ?? this.canDelete,
      canManageUsers: canManageUsers ?? this.canManageUsers,
      canManageRoles: canManageRoles ?? this.canManageRoles,
      canEvaluar: canEvaluar ?? this.canEvaluar,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'idRole': idRole,
      'roleNombre': roleNombre,
      'roleDescr': roleDescr,
      'canView': canView,
      'canAdd': canAdd,
      'canEdit': canEdit,
      'canDelete': canDelete,
      'canManageUsers': canManageUsers,
      'canManageRoles': canManageRoles,
      'canEvaluar': canEvaluar,
    };
  }

  factory Role.fromMap(Map<String, dynamic> map) {
    return Role(
      idRole: map['idRole'] != null ? map['idRole'] as int : null,
      roleNombre:
          map['roleNombre'] != null ? map['roleNombre'] as String : null,
      roleDescr: map['roleDescr'] != null ? map['roleDescr'] as String : null,
      canView: map['canView'] != null ? map['canView'] as bool : null,
      canAdd: map['canAdd'] != null ? map['canAdd'] as bool : null,
      canEdit: map['canEdit'] != null ? map['canEdit'] as bool : null,
      canDelete: map['canDelete'] != null ? map['canDelete'] as bool : null,
      canManageUsers:
          map['canManageUsers'] != null ? map['canManageUsers'] as bool : null,
      canManageRoles:
          map['canManageRoles'] != null ? map['canManageRoles'] as bool : null,
      canEvaluar: map['canEvaluar'] != null ? map['canEvaluar'] as bool : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Role.fromJson(String source) =>
      Role.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Role(idRole: $idRole, roleNombre: $roleNombre, roleDescr: $roleDescr, canView: $canView, canAdd: $canAdd, canEdit: $canEdit, canDelete: $canDelete, canManageUsers: $canManageUsers, canManageRoles: $canManageRoles, canEvaluar: $canEvaluar)';
  }

  @override
  bool operator ==(covariant Role other) {
    if (identical(this, other)) return true;

    return other.idRole == idRole &&
        other.roleNombre == roleNombre &&
        other.roleDescr == roleDescr &&
        other.canView == canView &&
        other.canAdd == canAdd &&
        other.canEdit == canEdit &&
        other.canDelete == canDelete &&
        other.canManageUsers == canManageUsers &&
        other.canManageRoles == canManageRoles &&
        other.canEvaluar == canEvaluar;
  }

  @override
  int get hashCode {
    return idRole.hashCode ^
        roleNombre.hashCode ^
        roleDescr.hashCode ^
        canView.hashCode ^
        canAdd.hashCode ^
        canEdit.hashCode ^
        canDelete.hashCode ^
        canManageUsers.hashCode ^
        canManageRoles.hashCode ^
        canEvaluar.hashCode;
  }
}
