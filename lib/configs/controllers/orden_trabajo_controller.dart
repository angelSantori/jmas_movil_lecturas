// Librerías
import 'dart:convert';
import 'dart:io';
import 'package:http/io_client.dart';
import 'package:jmas_movil_lecturas/configs/service/auth_service.dart';

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
  Future<List<OrdenTrabajo>> listOrdenTrabajo() async {
    try {
      final IOClient client = _createHttpClient();
      final response = await client.get(
        Uri.parse('${_authService.apiURL}/OrdenTrabajos'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((listOT) => OrdenTrabajo.fromMap(listOT)).toList();
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
  String? descripcionOT;
  String? fechaOT;
  String? medioOT;
  bool? materialOT;
  String? direccionOT;
  String? tipoProblemaOT;
  String? estadoOT;
  String? prioridadOT;
  int? idUser;
  int? idPadron;
  OrdenTrabajo({
    this.idOrdenTrabajo,
    this.folioOT,
    this.descripcionOT,
    this.fechaOT,
    this.medioOT,
    this.materialOT,
    this.direccionOT,
    this.tipoProblemaOT,
    this.estadoOT,
    this.prioridadOT,
    this.idUser,
    this.idPadron,
  });

  OrdenTrabajo copyWith({
    int? idOrdenTrabajo,
    String? folioOT,
    String? descripcionOT,
    String? fechaOT,
    String? medioOT,
    bool? materialOT,
    String? direccionOT,
    String? tipoProblemaOT,
    String? estadoOT,
    String? prioridadOT,
    int? idUser,
    int? idPadron,
  }) {
    return OrdenTrabajo(
      idOrdenTrabajo: idOrdenTrabajo ?? this.idOrdenTrabajo,
      folioOT: folioOT ?? this.folioOT,
      descripcionOT: descripcionOT ?? this.descripcionOT,
      fechaOT: fechaOT ?? this.fechaOT,
      medioOT: medioOT ?? this.medioOT,
      materialOT: materialOT ?? this.materialOT,
      direccionOT: direccionOT ?? this.direccionOT,
      tipoProblemaOT: tipoProblemaOT ?? this.tipoProblemaOT,
      estadoOT: estadoOT ?? this.estadoOT,
      prioridadOT: prioridadOT ?? this.prioridadOT,
      idUser: idUser ?? this.idUser,
      idPadron: idPadron ?? this.idPadron,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'idOrdenTrabajo': idOrdenTrabajo,
      'folioOT': folioOT,
      'descripcionOT': descripcionOT,
      'fechaOT': fechaOT,
      'medioOT': medioOT,
      'materialOT': materialOT,
      'direccionOT': direccionOT,
      'tipoProblemaOT': tipoProblemaOT,
      'estadoOT': estadoOT,
      'prioridadOT': prioridadOT,
      'idUser': idUser,
      'idPadron': idPadron,
    };
  }

  factory OrdenTrabajo.fromMap(Map<String, dynamic> map) {
    return OrdenTrabajo(
      idOrdenTrabajo:
          map['idOrdenTrabajo'] != null ? map['idOrdenTrabajo'] as int : null,
      folioOT: map['folioOT'] != null ? map['folioOT'] as String : null,
      descripcionOT:
          map['descripcionOT'] != null ? map['descripcionOT'] as String : null,
      fechaOT: map['fechaOT'] != null ? map['fechaOT'] as String : null,
      medioOT: map['medioOT'] != null ? map['medioOT'] as String : null,
      materialOT: map['materialOT'] != null ? map['materialOT'] as bool : null,
      direccionOT:
          map['direccionOT'] != null ? map['direccionOT'] as String : null,
      tipoProblemaOT:
          map['tipoProblemaOT'] != null
              ? map['tipoProblemaOT'] as String
              : null,
      estadoOT: map['estadoOT'] != null ? map['estadoOT'] as String : null,
      prioridadOT:
          map['prioridadOT'] != null ? map['prioridadOT'] as String : null,
      idUser: map['idUser'] != null ? map['idUser'] as int : null,
      idPadron: map['idPadron'] != null ? map['idPadron'] as int : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory OrdenTrabajo.fromJson(String source) =>
      OrdenTrabajo.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'OrdenTrabajo(idOrdenTrabajo: $idOrdenTrabajo, folioOT: $folioOT, descripcionOT: $descripcionOT, fechaOT: $fechaOT, medioOT: $medioOT, materialOT: $materialOT, direccionOT: $direccionOT, tipoProblemaOT: $tipoProblemaOT, estadoOT: $estadoOT, prioridadOT: $prioridadOT, idUser: $idUser, idPadron: $idPadron)';
  }

  @override
  bool operator ==(covariant OrdenTrabajo other) {
    if (identical(this, other)) return true;

    return other.idOrdenTrabajo == idOrdenTrabajo &&
        other.folioOT == folioOT &&
        other.descripcionOT == descripcionOT &&
        other.fechaOT == fechaOT &&
        other.medioOT == medioOT &&
        other.materialOT == materialOT &&
        other.direccionOT == direccionOT &&
        other.tipoProblemaOT == tipoProblemaOT &&
        other.estadoOT == estadoOT &&
        other.prioridadOT == prioridadOT &&
        other.idUser == idUser &&
        other.idPadron == idPadron;
  }

  @override
  int get hashCode {
    return idOrdenTrabajo.hashCode ^
        folioOT.hashCode ^
        descripcionOT.hashCode ^
        fechaOT.hashCode ^
        medioOT.hashCode ^
        materialOT.hashCode ^
        direccionOT.hashCode ^
        tipoProblemaOT.hashCode ^
        estadoOT.hashCode ^
        prioridadOT.hashCode ^
        idUser.hashCode ^
        idPadron.hashCode;
  }
}
