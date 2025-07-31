// Librerías
import 'dart:convert';
import 'dart:io';
import 'package:http/io_client.dart';
import 'package:jmas_movil_lecturas/configs/service/auth_service.dart';
import 'package:jmas_movil_lecturas/configs/service/database_helper.dart';

class OrdenServicioController {
  final AuthService _authService = AuthService();

  IOClient _createHttpClient() {
    final ioClient = HttpClient();
    ioClient.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    return IOClient(ioClient);
  }

  //GET
  //List
  // En orden_trabajo_controller.dart, modifica el método listOrdenTrabajo:
  Future<List<OrdenServicio>> listOrdenServicio() async {
    try {
      final IOClient client = _createHttpClient();
      final response = await client.get(
        Uri.parse('${_authService.apiURL}/OrdenServicios'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final ordenes =
            data.map((listOT) => OrdenServicio.fromMap(listOT)).toList();

        // Guardar localmente
        final dbHelper = DatabaseHelper();
        for (var orden in ordenes) {
          await dbHelper.insertOrUpdateOrdenServicio(orden);
        }

        return ordenes;
      } else {
        print(
          'Error listOrdenServicio | Ife | Controller: ${response.statusCode} - ${response.body}',
        );
        return [];
      }
    } catch (e) {
      print('Error listOrdenServicio | Try | Controller: $e');
      return [];
    }
  }

  Future<List<OrdenServicio>> listOSXFolio(String folio) async {
    try {
      final IOClient client = _createHttpClient();
      final response = await client.get(
        Uri.parse('${_authService.apiURL}/OrdenServicios/ByFolio/$folio'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData
            .map((listOSXF) => OrdenServicio.fromMap(listOSXF))
            .toList();
      } else {
        print(
          'Error listOSXFolio | Ife | Controller: ${response.statusCode} - ${response.body}',
        );
        return [];
      }
    } catch (e) {
      print('Error listOSXFolio | Try | Controller: $e');
      return [];
    }
  }

  //GetXId
  Future<OrdenServicio?> getOrdenServicioXId(int idOS) async {
    try {
      final IOClient client = _createHttpClient();
      final response = await client.get(
        Uri.parse('${_authService.apiURL}/OrdenServicios/$idOS'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData =
            json.decode(response.body) as Map<String, dynamic>;
        return OrdenServicio.fromMap(jsonData);
      } else {
        print(
          'Error getOrdenServicioXId | Ife | Controller: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Error getOrdenServicioXId | Try | Controller: $e');
      return null;
    }
  }

  //Put
  //Edit
  Future<bool> editOrdenServicio(OrdenServicio ordenServicio) async {
    try {
      final IOClient client = _createHttpClient();
      final response = await client.put(
        Uri.parse(
          '${_authService.apiURL}/OrdenServicios/${ordenServicio.idOrdenServicio}',
        ),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: ordenServicio.toJson(),
      );

      if (response.statusCode == 204) {
        return true;
      } else {
        print(
          'Error editOrdenServicio | Ife | Controller: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Error editOrdenServicio | Try | Controller: $e');
      return false;
    }
  }
}

class OrdenServicio {
  int? idOrdenServicio;
  String? folioOS;
  String? contactoOS;
  String? fechaOS;
  bool? materialOS;
  String? estadoOS;
  String? prioridadOS;
  int? idUser;
  int? idPadron;
  int? idTipoProblema;
  int? idMedio;
  int? idCalle;
  int? idColonia;
  int? idUserAsignado;
  OrdenServicio({
    this.idOrdenServicio,
    this.folioOS,
    this.contactoOS,
    this.fechaOS,
    this.materialOS,
    this.estadoOS,
    this.prioridadOS,
    this.idUser,
    this.idPadron,
    this.idTipoProblema,
    this.idMedio,
    this.idCalle,
    this.idColonia,
    this.idUserAsignado,
  });

  OrdenServicio copyWith({
    int? idOrdenServicio,
    String? folioOS,
    String? contactoOS,
    String? fechaOS,
    bool? materialOS,
    String? estadoOS,
    String? prioridadOS,
    int? idUser,
    int? idPadron,
    int? idTipoProblema,
    int? idMedio,
    int? idCalle,
    int? idColonia,
    int? idUserAsignado,
  }) {
    return OrdenServicio(
      idOrdenServicio: idOrdenServicio ?? this.idOrdenServicio,
      folioOS: folioOS ?? this.folioOS,
      contactoOS: contactoOS ?? this.contactoOS,
      fechaOS: fechaOS ?? this.fechaOS,
      materialOS: materialOS ?? this.materialOS,
      estadoOS: estadoOS ?? this.estadoOS,
      prioridadOS: prioridadOS ?? this.prioridadOS,
      idUser: idUser ?? this.idUser,
      idPadron: idPadron ?? this.idPadron,
      idTipoProblema: idTipoProblema ?? this.idTipoProblema,
      idMedio: idMedio ?? this.idMedio,
      idCalle: idCalle ?? this.idCalle,
      idColonia: idColonia ?? this.idColonia,
      idUserAsignado: idUserAsignado ?? this.idUserAsignado,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'idOrdenServicio': idOrdenServicio,
      'folioOS': folioOS,
      'contactoOS': contactoOS,
      'fechaOS': fechaOS,
      'materialOS': materialOS,
      'estadoOS': estadoOS,
      'prioridadOS': prioridadOS,
      'idUser': idUser,
      'idPadron': idPadron,
      'idTipoProblema': idTipoProblema,
      'idMedio': idMedio,
      'idCalle': idCalle,
      'idColonia': idColonia,
      'idUserAsignado': idUserAsignado,
    };
  }

  factory OrdenServicio.fromMap(Map<String, dynamic> map) {
    return OrdenServicio(
      idOrdenServicio:
          map['idOrdenServicio'] != null ? map['idOrdenServicio'] as int : null,
      folioOS: map['folioOS'] != null ? map['folioOS'] as String : null,
      contactoOS:
          map['contactoOS'] != null ? map['contactoOS'] as String : null,
      fechaOS: map['fechaOS'] != null ? map['fechaOS'] as String : null,
      materialOS: map['materialOS'] != null ? map['materialOS'] as bool : null,
      estadoOS: map['estadoOS'] != null ? map['estadoOS'] as String : null,
      prioridadOS:
          map['prioridadOS'] != null ? map['prioridadOS'] as String : null,
      idUser: map['idUser'] != null ? map['idUser'] as int : null,
      idPadron: map['idPadron'] != null ? map['idPadron'] as int : null,
      idTipoProblema:
          map['idTipoProblema'] != null ? map['idTipoProblema'] as int : null,
      idMedio: map['idMedio'] != null ? map['idMedio'] as int : null,
      idCalle: map['idCalle'] != null ? map['idCalle'] as int : null,
      idColonia: map['idColonia'] != null ? map['idColonia'] as int : null,
      idUserAsignado:
          map['idUserAsignado'] != null ? map['idUserAsignado'] as int : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory OrdenServicio.fromJson(String source) =>
      OrdenServicio.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'OrdenServicio(idOrdenServicio: $idOrdenServicio, folioOS: $folioOS, contactoOS: $contactoOS, fechaOS: $fechaOS, materialOS: $materialOS, estadoOS: $estadoOS, prioridadOS: $prioridadOS, idUser: $idUser, idPadron: $idPadron, idTipoProblema: $idTipoProblema, idMedio: $idMedio, idCalle: $idCalle, idColonia: $idColonia, idUserAsignado: $idUserAsignado)';
  }

  @override
  bool operator ==(covariant OrdenServicio other) {
    if (identical(this, other)) return true;

    return other.idOrdenServicio == idOrdenServicio &&
        other.folioOS == folioOS &&
        other.contactoOS == contactoOS &&
        other.fechaOS == fechaOS &&
        other.materialOS == materialOS &&
        other.estadoOS == estadoOS &&
        other.prioridadOS == prioridadOS &&
        other.idUser == idUser &&
        other.idPadron == idPadron &&
        other.idTipoProblema == idTipoProblema &&
        other.idMedio == idMedio &&
        other.idCalle == idCalle &&
        other.idColonia == idColonia &&
        other.idUserAsignado == idUserAsignado;
  }

  @override
  int get hashCode {
    return idOrdenServicio.hashCode ^
        folioOS.hashCode ^
        contactoOS.hashCode ^
        fechaOS.hashCode ^
        materialOS.hashCode ^
        estadoOS.hashCode ^
        prioridadOS.hashCode ^
        idUser.hashCode ^
        idPadron.hashCode ^
        idTipoProblema.hashCode ^
        idMedio.hashCode ^
        idCalle.hashCode ^
        idColonia.hashCode ^
        idUserAsignado.hashCode;
  }
}
