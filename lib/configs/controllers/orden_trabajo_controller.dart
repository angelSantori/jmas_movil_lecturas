// ignore_for_file: public_member_api_docs, sort_constructors_first
// Librerías
import 'dart:convert';
import 'dart:io';

import 'package:http/io_client.dart';
import 'package:jmas_movil_lecturas/configs/controllers/padron_controller.dart';
import 'package:jmas_movil_lecturas/configs/controllers/tipo_problema_controller.dart';

import 'package:jmas_movil_lecturas/configs/service/auth_service.dart';
import 'package:jmas_movil_lecturas/configs/service/database_helper.dart';

class OrdenTrabajoController {
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
  Future<List<OrdenTrabajo>> listOrdenTrabajo() async {
    try {
      final IOClient client = _createHttpClient();
      final response = await client.get(
        Uri.parse('${_authService.apiURL}/OrdenTrabajos'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final ordenes =
            data.map((listOT) => OrdenTrabajo.fromMap(listOT)).toList();

        // Guardar localmente
        final dbHelper = DatabaseHelper();
        for (var orden in ordenes) {
          await dbHelper.insertOrUpdateOrdenTrabajo(orden);

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
          'Error listOrdenTrabajo | Ife | Controller: ${response.statusCode} - ${response.body}',
        );
        return [];
      }
    } catch (e) {
      print('Error listOrdenTrabajo | Try | Controller: $e');
      return [];
    }
  }

  Future<List<OrdenTrabajo>> listOTXFolio(String folio) async {
    try {
      final IOClient client = _createHttpClient();
      final response = await client.get(
        Uri.parse('${_authService.apiURL}/OrdenTrabajos/ByFolio/$folio'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData
            .map((listOtXF) => OrdenTrabajo.fromMap(listOtXF))
            .toList();
      } else {
        print(
          'Error listOTXFolio | Ife | Controller: ${response.statusCode} - ${response.body}',
        );
        return [];
      }
    } catch (e) {
      print('Error listOTXFolio | Try | Controller: $e');
      return [];
    }
  }

  //GetXId
  Future<OrdenTrabajo?> getOrdenTrabajoXId(int idOT) async {
    try {
      final IOClient client = _createHttpClient();
      final response = await client.get(
        Uri.parse('${_authService.apiURL}/OrdenTrabajos/$idOT'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData =
            json.decode(response.body) as Map<String, dynamic>;
        return OrdenTrabajo.fromMap(jsonData);
      } else {
        print(
          'Error getOrdenTrabajoXId | Ife | Controller: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Error getOrdenTrabajoXId | Try | Controller: $e');
      return null;
    }
  }

  //Put
  //Edit
  Future<bool> editOrdenTrabajo(OrdenTrabajo ordenTrabajo) async {
    try {
      final IOClient client = _createHttpClient();
      final response = await client.put(
        Uri.parse(
          '${_authService.apiURL}/OrdenTrabajos/${ordenTrabajo.idOrdenTrabajo}',
        ),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: ordenTrabajo.toJson(),
      );

      if (response.statusCode == 204) {
        return true;
      } else {
        print(
          'Error editOrdenTrabajo | Ife | Controller: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Error editOrdenTrabajo | Try | Controller: $e');
      return false;
    }
  }
}

class OrdenTrabajo {
  int? idOrdenTrabajo;
  String? folioOT;
  String? fechaOT;
  String? medioOT;
  bool? materialOT;
  String? estadoOT;
  String? prioridadOT;
  int? idUser;
  int? idPadron;
  int? idTipoProblema;
  OrdenTrabajo({
    this.idOrdenTrabajo,
    this.folioOT,
    this.fechaOT,
    this.medioOT,
    this.materialOT,
    this.estadoOT,
    this.prioridadOT,
    this.idUser,
    this.idPadron,
    this.idTipoProblema,
  });

  OrdenTrabajo copyWith({
    int? idOrdenTrabajo,
    String? folioOT,
    String? fechaOT,
    String? medioOT,
    bool? materialOT,
    String? estadoOT,
    String? prioridadOT,
    int? idUser,
    int? idPadron,
    int? idTipoProblema,
  }) {
    return OrdenTrabajo(
      idOrdenTrabajo: idOrdenTrabajo ?? this.idOrdenTrabajo,
      folioOT: folioOT ?? this.folioOT,
      fechaOT: fechaOT ?? this.fechaOT,
      medioOT: medioOT ?? this.medioOT,
      materialOT: materialOT ?? this.materialOT,
      estadoOT: estadoOT ?? this.estadoOT,
      prioridadOT: prioridadOT ?? this.prioridadOT,
      idUser: idUser ?? this.idUser,
      idPadron: idPadron ?? this.idPadron,
      idTipoProblema: idTipoProblema ?? this.idTipoProblema,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'idOrdenTrabajo': idOrdenTrabajo,
      'folioOT': folioOT,
      'fechaOT': fechaOT,
      'medioOT': medioOT,
      'materialOT': materialOT == true ? 1 : 0,
      'estadoOT': estadoOT,
      'prioridadOT': prioridadOT,
      'idUser': idUser,
      'idPadron': idPadron,
      'idTipoProblema': idTipoProblema,
    };
  }

  factory OrdenTrabajo.fromMap(Map<String, dynamic> map) {
    return OrdenTrabajo(
      idOrdenTrabajo:
          map['idOrdenTrabajo'] != null ? map['idOrdenTrabajo'] as int : null,
      folioOT: map['folioOT'] != null ? map['folioOT'] as String : null,
      fechaOT: map['fechaOT'] != null ? map['fechaOT'] as String : null,
      medioOT: map['medioOT'] != null ? map['medioOT'] as String : null,
      materialOT:
          map['materialOT'] != null
              ? (map['materialOT'] is bool
                  ? map['materialOT']
                  : (map['materialOT'] as int) == 1)
              : null,
      estadoOT: map['estadoOT'] != null ? map['estadoOT'] as String : null,
      prioridadOT:
          map['prioridadOT'] != null ? map['prioridadOT'] as String : null,
      idUser: map['idUser'] != null ? map['idUser'] as int : null,
      idPadron: map['idPadron'] != null ? map['idPadron'] as int : null,
      idTipoProblema:
          map['idTipoProblema'] != null ? map['idTipoProblema'] as int : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory OrdenTrabajo.fromJson(String source) =>
      OrdenTrabajo.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'OrdenTrabajo(idOrdenTrabajo: $idOrdenTrabajo, folioOT: $folioOT, fechaOT: $fechaOT, medioOT: $medioOT, materialOT: $materialOT, estadoOT: $estadoOT, prioridadOT: $prioridadOT, idUser: $idUser, idPadron: $idPadron, idTipoProblema: $idTipoProblema)';
  }

  @override
  bool operator ==(covariant OrdenTrabajo other) {
    if (identical(this, other)) return true;

    return other.idOrdenTrabajo == idOrdenTrabajo &&
        other.folioOT == folioOT &&
        other.fechaOT == fechaOT &&
        other.medioOT == medioOT &&
        other.materialOT == materialOT &&
        other.estadoOT == estadoOT &&
        other.prioridadOT == prioridadOT &&
        other.idUser == idUser &&
        other.idPadron == idPadron &&
        other.idTipoProblema == idTipoProblema;
  }

  @override
  int get hashCode {
    return idOrdenTrabajo.hashCode ^
        folioOT.hashCode ^
        fechaOT.hashCode ^
        medioOT.hashCode ^
        materialOT.hashCode ^
        estadoOT.hashCode ^
        prioridadOT.hashCode ^
        idUser.hashCode ^
        idPadron.hashCode ^
        idTipoProblema.hashCode;
  }
}
