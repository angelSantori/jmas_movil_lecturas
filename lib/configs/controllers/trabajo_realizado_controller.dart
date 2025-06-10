// ignore_for_file: public_member_api_docs, sort_constructors_first
// Librerías
import 'dart:convert';
import 'dart:io';

import 'package:http/io_client.dart';

import 'package:jmas_movil_lecturas/configs/service/auth_service.dart';

class TrabajoRealizadoController {
  final AuthService _authService = AuthService();

  IOClient _createHttpClient() {
    final ioClient = HttpClient();
    ioClient.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    return IOClient(ioClient);
  }

  //GET
  Future<List<TrabajoRealizado>> getTRXUserID(int userID) async {
    try {
      final IOClient client = _createHttpClient();
      final response = await client.get(
        Uri.parse('${_authService.apiURL}/TrabajoRealizadoes/ByUser/$userID'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData
            .map((listTRXUser) => TrabajoRealizado.fromMap(listTRXUser))
            .toList();
      } else {
        print(
          'Error getTRXUserID | Ife | Controller: ${response.statusCode} - ${response.body}',
        );
        return [];
      }
    } catch (e) {
      print('Error getTRXUserID | Try | Controller: $e');
      return [];
    }
  }

  //Post
  //Add
  Future<bool> addTrabajoRealizado(TrabajoRealizado trabajoRealizado) async {
    try {
      final IOClient client = _createHttpClient();
      final response = await client.post(
        Uri.parse('${_authService.apiURL}/TrabajoRealizadoes'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: trabajoRealizado.toJson(),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        print(
          'Error addTrabajoRealizado | Ife | Controller: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Error addTrabajoRealizado | Try | Controller: $e');
      return false;
    }
  }

  //PUT
  //edit
  Future<bool> editTrabajoRealizado(TrabajoRealizado trabajoRealizado) async {
    try {
      final IOClient client = _createHttpClient();
      final response = await client.put(
        Uri.parse(
          '${_authService.apiURL}/TrabajoRealizadoes/${trabajoRealizado.idTrabajoRealizado}',
        ),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: trabajoRealizado.toJson(),
      );

      if (response.statusCode == 204) {
        return true;
      } else {
        print(
          'Error editTrabajoRealizado | Ife | Controller: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('Error editTrabajoRealizado | Try | Controller: $e');
      return false;
    }
  }
}

class TrabajoRealizado {
  int? idTrabajoRealizado;
  String? folioTR;
  String? fechaTR;
  String? ubicacionTR;
  String? comentarioTR;
  String? fotoAntes64TR;
  String? fotoDespues64TR;
  int? idUserTR;
  int? idOrdenTrabajo;
  int? idSalida;
  TrabajoRealizado({
    this.idTrabajoRealizado,
    this.folioTR,
    this.fechaTR,
    this.ubicacionTR,
    this.comentarioTR,
    this.fotoAntes64TR,
    this.fotoDespues64TR,
    this.idUserTR,
    this.idOrdenTrabajo,
    this.idSalida,
  });

  TrabajoRealizado copyWith({
    int? idTrabajoRealizado,
    String? folioTR,
    String? fechaTR,
    String? ubicacionTR,
    String? comentarioTR,
    String? fotoAntes64TR,
    String? fotoDespues64TR,
    int? idUserTR,
    int? idOrdenTrabajo,
    int? idSalida,
  }) {
    return TrabajoRealizado(
      idTrabajoRealizado: idTrabajoRealizado ?? this.idTrabajoRealizado,
      folioTR: folioTR ?? this.folioTR,
      fechaTR: fechaTR ?? this.fechaTR,
      ubicacionTR: ubicacionTR ?? this.ubicacionTR,
      comentarioTR: comentarioTR ?? this.comentarioTR,
      fotoAntes64TR: fotoAntes64TR ?? this.fotoAntes64TR,
      fotoDespues64TR: fotoDespues64TR ?? this.fotoDespues64TR,
      idUserTR: idUserTR ?? this.idUserTR,
      idOrdenTrabajo: idOrdenTrabajo ?? this.idOrdenTrabajo,
      idSalida: idSalida ?? this.idSalida,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'idTrabajoRealizado': idTrabajoRealizado,
      'folioTR': folioTR,
      'fechaTR': fechaTR,
      'ubicacionTR': ubicacionTR,
      'comentarioTR': comentarioTR,
      'fotoAntes64TR': fotoAntes64TR,
      'fotoDespues64TR': fotoDespues64TR,
      'idUserTR': idUserTR,
      'idOrdenTrabajo': idOrdenTrabajo,
      'idSalida': idSalida,
    };
  }

  factory TrabajoRealizado.fromMap(Map<String, dynamic> map) {
    return TrabajoRealizado(
      idTrabajoRealizado:
          map['idTrabajoRealizado'] != null
              ? map['idTrabajoRealizado'] as int
              : null,
      folioTR: map['folioTR'] != null ? map['folioTR'] as String : null,
      fechaTR: map['fechaTR'] != null ? map['fechaTR'] as String : null,
      ubicacionTR:
          map['ubicacionTR'] != null ? map['ubicacionTR'] as String : null,
      comentarioTR:
          map['comentarioTR'] != null ? map['comentarioTR'] as String : null,
      fotoAntes64TR:
          map['fotoAntes64TR'] != null ? map['fotoAntes64TR'] as String : null,
      fotoDespues64TR:
          map['fotoDespues64TR'] != null
              ? map['fotoDespues64TR'] as String
              : null,
      idUserTR: map['idUserTR'] != null ? map['idUserTR'] as int : null,
      idOrdenTrabajo:
          map['idOrdenTrabajo'] != null ? map['idOrdenTrabajo'] as int : null,
      idSalida: map['idSalida'] != null ? map['idSalida'] as int : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory TrabajoRealizado.fromJson(String source) =>
      TrabajoRealizado.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'TrabajoRealizado(idTrabajoRealizado: $idTrabajoRealizado, folioTR: $folioTR, fechaTR: $fechaTR, ubicacionTR: $ubicacionTR, comentarioTR: $comentarioTR, fotoAntes64TR: $fotoAntes64TR, fotoDespues64TR: $fotoDespues64TR, idUserTR: $idUserTR, idOrdenTrabajo: $idOrdenTrabajo, idSalida: $idSalida)';
  }

  @override
  bool operator ==(covariant TrabajoRealizado other) {
    if (identical(this, other)) return true;

    return other.idTrabajoRealizado == idTrabajoRealizado &&
        other.folioTR == folioTR &&
        other.fechaTR == fechaTR &&
        other.ubicacionTR == ubicacionTR &&
        other.comentarioTR == comentarioTR &&
        other.fotoAntes64TR == fotoAntes64TR &&
        other.fotoDespues64TR == fotoDespues64TR &&
        other.idUserTR == idUserTR &&
        other.idOrdenTrabajo == idOrdenTrabajo &&
        other.idSalida == idSalida;
  }

  @override
  int get hashCode {
    return idTrabajoRealizado.hashCode ^
        folioTR.hashCode ^
        fechaTR.hashCode ^
        ubicacionTR.hashCode ^
        comentarioTR.hashCode ^
        fotoAntes64TR.hashCode ^
        fotoDespues64TR.hashCode ^
        idUserTR.hashCode ^
        idOrdenTrabajo.hashCode ^
        idSalida.hashCode;
  }
}
