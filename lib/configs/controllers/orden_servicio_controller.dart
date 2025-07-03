// ignore_for_file: public_member_api_docs, sort_constructors_first
// Librerías
import 'dart:convert';
import 'dart:io';

import 'package:http/io_client.dart';

import 'package:jmas_movil_lecturas/configs/controllers/padron_controller.dart';
import 'package:jmas_movil_lecturas/configs/controllers/tipo_problema_controller.dart';
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

          // Si hay padron, guardarlo
          if (orden.idPadron != null) {
            final padron = await PadronController().getPadronXId(
              orden.idPadron!,
            );
            if (padron != null) {
              await dbHelper.insertOrUpdatePadron(padron);
            }
          }

          // Si hay tipo problema, guardarlo
          if (orden.idTipoProblema != null) {
            final tipoProblema = await TipoProblemaController().tipoProblemaXId(
              orden.idTipoProblema!,
            );
            if (tipoProblema != null) {
              await dbHelper.insertOrUpdateTipoProblema(tipoProblema);
            }
          }
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
  String? fechaOS;
  bool? materialOS;
  String? estadoOS;
  String? prioridadOS;
  int? contactoOS;
  int? idUser;
  int? idPadron;
  int? idTipoProblema;
  int? idMedio;
  OrdenServicio({
    this.idOrdenServicio,
    this.folioOS,
    this.fechaOS,
    this.materialOS,
    this.estadoOS,
    this.prioridadOS,
    this.contactoOS,
    this.idUser,
    this.idPadron,
    this.idTipoProblema,
    this.idMedio,
  });

  OrdenServicio copyWith({
    int? idOrdenServicio,
    String? folioOS,
    String? fechaOS,
    bool? materialOS,
    String? estadoOS,
    String? prioridadOS,
    int? contactoOS,
    int? idUser,
    int? idPadron,
    int? idTipoProblema,
    int? idMedio,
  }) {
    return OrdenServicio(
      idOrdenServicio: idOrdenServicio ?? this.idOrdenServicio,
      folioOS: folioOS ?? this.folioOS,
      fechaOS: fechaOS ?? this.fechaOS,
      materialOS: materialOS ?? this.materialOS,
      estadoOS: estadoOS ?? this.estadoOS,
      prioridadOS: prioridadOS ?? this.prioridadOS,
      contactoOS: contactoOS ?? this.contactoOS,
      idUser: idUser ?? this.idUser,
      idPadron: idPadron ?? this.idPadron,
      idTipoProblema: idTipoProblema ?? this.idTipoProblema,
      idMedio: idMedio ?? this.idMedio,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'idOrdenServicio': idOrdenServicio,
      'folioOS': folioOS,
      'fechaOS': fechaOS,
      'materialOS': materialOS,
      'estadoOS': estadoOS,
      'prioridadOS': prioridadOS,
      'contactoOS': contactoOS,
      'idUser': idUser,
      'idPadron': idPadron,
      'idTipoProblema': idTipoProblema,
      'idMedio': idMedio,
    };
  }

  factory OrdenServicio.fromMap(Map<String, dynamic> map) {
    return OrdenServicio(
      idOrdenServicio:
          map['idOrdenServicio'] != null ? map['idOrdenServicio'] as int : null,
      folioOS: map['folioOS'] != null ? map['folioOS'] as String : null,
      fechaOS: map['fechaOS'] != null ? map['fechaOS'] as String : null,
      materialOS:
          map['materialOS'] != null
              ? (map['materialOS'] is bool
                  ? map['materialOS']
                  : (map['materialOS'] as int) == 1)
              : null,
      estadoOS: map['estadoOS'] != null ? map['estadoOS'] as String : null,
      prioridadOS:
          map['prioridadOS'] != null ? map['prioridadOS'] as String : null,
      contactoOS: map['contactoOS'] != null ? map['contactoOS'] as int : null,
      idUser: map['idUser'] != null ? map['idUser'] as int : null,
      idPadron: map['idPadron'] != null ? map['idPadron'] as int : null,
      idTipoProblema:
          map['idTipoProblema'] != null ? map['idTipoProblema'] as int : null,
      idMedio: map['idMedio'] != null ? map['idMedio'] as int : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory OrdenServicio.fromJson(String source) =>
      OrdenServicio.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'OrdenServicio(idOrdenServicio: $idOrdenServicio, folioOS: $folioOS, fechaOS: $fechaOS, materialOS: $materialOS, estadoOS: $estadoOS, prioridadOS: $prioridadOS, contactoOS: $contactoOS, idUser: $idUser, idPadron: $idPadron, idTipoProblema: $idTipoProblema, idMedio: $idMedio)';
  }

  @override
  bool operator ==(covariant OrdenServicio other) {
    if (identical(this, other)) return true;

    return other.idOrdenServicio == idOrdenServicio &&
        other.folioOS == folioOS &&
        other.fechaOS == fechaOS &&
        other.materialOS == materialOS &&
        other.estadoOS == estadoOS &&
        other.prioridadOS == prioridadOS &&
        other.contactoOS == contactoOS &&
        other.idUser == idUser &&
        other.idPadron == idPadron &&
        other.idTipoProblema == idTipoProblema &&
        other.idMedio == idMedio;
  }

  @override
  int get hashCode {
    return idOrdenServicio.hashCode ^
        folioOS.hashCode ^
        fechaOS.hashCode ^
        materialOS.hashCode ^
        estadoOS.hashCode ^
        prioridadOS.hashCode ^
        contactoOS.hashCode ^
        idUser.hashCode ^
        idPadron.hashCode ^
        idTipoProblema.hashCode ^
        idMedio.hashCode;
  }
}
