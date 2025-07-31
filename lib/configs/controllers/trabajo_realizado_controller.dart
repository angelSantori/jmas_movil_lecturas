// ignore_for_file: public_member_api_docs, sort_constructors_first
// Librerías
import 'dart:convert';
import 'dart:io';

import 'package:http/io_client.dart';

import 'package:jmas_movil_lecturas/configs/controllers/orden_servicio_controller.dart';
import 'package:jmas_movil_lecturas/configs/service/auth_service.dart';
import 'package:jmas_movil_lecturas/configs/service/database_helper.dart';

class TrabajoRealizadoController {
  final AuthService _authService = AuthService();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  IOClient _createHttpClient() {
    final ioClient = HttpClient();
    ioClient.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    return IOClient(ioClient);
  }

  //  GET
  Future<List<TrabajoRealizado>> getTRXUserID(int userID) async {
    try {
      final IOClient client = _createHttpClient();
      final response = await client
          .get(
            Uri.parse(
              '${_authService.apiURL}/TrabajoRealizadoes/ByUser/$userID',
            ),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData
            .map((listTRXUser) => TrabajoRealizado.fromMap(listTRXUser))
            .toList();
      } else {
        print(
          'Error getTRXUserID | Ife | Controller: ${response.statusCode} - ${response.body}',
        );
        throw Exception('Error al obtener trabajos: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getTRXUserID | Try | Controller: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  //  Trabajo vacío por Usuario
  Future<List<TrabajoRealizado>> getTRXUserEmptyID(int userID) async {
    try {
      final IOClient client = _createHttpClient();
      final response = await client
          .get(
            Uri.parse(
              '${_authService.apiURL}/TrabajoRealizadoes/ByUserEmpty/$userID',
            ),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData
            .map((listTRXUser) => TrabajoRealizado.fromMap(listTRXUser))
            .toList();
      } else {
        print(
          'Error getTRXUserID | Ife | Controller: ${response.statusCode} - ${response.body}',
        );
        throw Exception('Error al obtener trabajos: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getTRXUserID | Try | Controller: $e');
      throw Exception('Error de conexión: $e');
    }
  }

  //Post
  //Add
  Future<bool> addTrabajoRealizado(TrabajoRealizado trabajoRealizado) async {
    try {
      // Primero intentar subir al servidor
      final IOClient client = _createHttpClient();
      final response = await client.post(
        Uri.parse('${_authService.apiURL}/TrabajoRealizadoes'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: trabajoRealizado.toJson(),
      );

      if (response.statusCode == 201) {
        // Si se subió correctamente, marcarlo como sincronizado
        trabajoRealizado = TrabajoRealizado.fromJson(response.body);
        await _dbHelper.insertTrabajo(trabajoRealizado);
        return true;
      }
    } catch (e) {
      print('Error al subir trabajo: $e');
    }

    // Si falla, guardar localmente
    await _dbHelper.insertTrabajo(trabajoRealizado);
    return false;
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
        // Si la edición fue exitosa, actualizar estado de la orden
        if (trabajoRealizado.idOrdenServicio != null) {
          final ordenServicioController = OrdenServicioController();
          final orden = await ordenServicioController.getOrdenServicioXId(
            trabajoRealizado.idOrdenServicio!,
          );
          if (orden != null) {
            final ordenActualizada = orden.copyWith(
              estadoOS: 'Revisión',
              materialOS: trabajoRealizado.fotoRequiereMaterial64TR != null,
            );
            await ordenServicioController.editOrdenServicio(ordenActualizada);
          }
        }
        return true;
      } else {
        // Si falla, guardar localmente como nuevo registro
        await _dbHelper.insertTrabajo(trabajoRealizado);
        return false;
      }
    } catch (e) {
      // Si hay error de conexión, guardar localmente como nuevo registro
      await _dbHelper.insertTrabajo(trabajoRealizado);
      return false;
    }
  }

  Future<List<TrabajoRealizado>> getLocalTrabajos() async {
    return await _dbHelper.getTrabajosNoSincronizados();
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
  String? fotoRequiereMaterial64TR;
  int? encuenstaTR;
  int? idUserTR;
  int? idOrdenServicio;
  String? folioOS;
  String? padronNombre;
  String? padronDireccion;
  String? problemaNombre;
  String? folioSalida;
  TrabajoRealizado({
    this.idTrabajoRealizado,
    this.folioTR,
    this.fechaTR,
    this.ubicacionTR,
    this.comentarioTR,
    this.fotoAntes64TR,
    this.fotoDespues64TR,
    this.fotoRequiereMaterial64TR,
    this.encuenstaTR,
    this.idUserTR,
    this.idOrdenServicio,
    this.folioOS,
    this.padronNombre,
    this.padronDireccion,
    this.problemaNombre,
    this.folioSalida,
  });

  TrabajoRealizado copyWith({
    int? idTrabajoRealizado,
    String? folioTR,
    String? fechaTR,
    String? ubicacionTR,
    String? comentarioTR,
    String? fotoAntes64TR,
    String? fotoDespues64TR,
    String? fotoRequiereMaterial64TR,
    int? encuenstaTR,
    int? idUserTR,
    int? idOrdenServicio,
    String? folioOS,
    String? padronNombre,
    String? padronDireccion,
    String? problemaNombre,
    String? folioSalida,
  }) {
    return TrabajoRealizado(
      idTrabajoRealizado: idTrabajoRealizado ?? this.idTrabajoRealizado,
      folioTR: folioTR ?? this.folioTR,
      fechaTR: fechaTR ?? this.fechaTR,
      ubicacionTR: ubicacionTR ?? this.ubicacionTR,
      comentarioTR: comentarioTR ?? this.comentarioTR,
      fotoAntes64TR: fotoAntes64TR ?? this.fotoAntes64TR,
      fotoDespues64TR: fotoDespues64TR ?? this.fotoDespues64TR,
      fotoRequiereMaterial64TR:
          fotoRequiereMaterial64TR ?? this.fotoRequiereMaterial64TR,
      encuenstaTR: encuenstaTR ?? this.encuenstaTR,
      idUserTR: idUserTR ?? this.idUserTR,
      idOrdenServicio: idOrdenServicio ?? this.idOrdenServicio,
      folioOS: folioOS ?? this.folioOS,
      padronNombre: padronNombre ?? this.padronNombre,
      padronDireccion: padronDireccion ?? this.padronDireccion,
      problemaNombre: problemaNombre ?? this.problemaNombre,
      folioSalida: folioSalida ?? this.folioSalida,
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
      'fotoRequiereMaterial64TR': fotoRequiereMaterial64TR,
      'encuenstaTR': encuenstaTR,
      'idUserTR': idUserTR,
      'idOrdenServicio': idOrdenServicio,
      'folioOS': folioOS,
      'padronNombre': padronNombre,
      'padronDireccion': padronDireccion,
      'problemaNombre': problemaNombre,
      'folioSalida': folioSalida,
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
      fotoRequiereMaterial64TR:
          map['fotoRequiereMaterial64TR'] != null
              ? map['fotoRequiereMaterial64TR'] as String
              : null,
      encuenstaTR:
          map['encuenstaTR'] != null ? map['encuenstaTR'] as int : null,
      idUserTR: map['idUserTR'] != null ? map['idUserTR'] as int : null,
      idOrdenServicio:
          map['idOrdenServicio'] != null ? map['idOrdenServicio'] as int : null,
      folioOS: map['folioOS'] != null ? map['folioOS'] as String : null,
      padronNombre:
          map['padronNombre'] != null ? map['padronNombre'] as String : null,
      padronDireccion:
          map['padronDireccion'] != null
              ? map['padronDireccion'] as String
              : null,
      problemaNombre:
          map['problemaNombre'] != null
              ? map['problemaNombre'] as String
              : null,
      folioSalida:
          map['folioSalida'] != null ? map['folioSalida'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory TrabajoRealizado.fromJson(String source) =>
      TrabajoRealizado.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'TrabajoRealizado(idTrabajoRealizado: $idTrabajoRealizado, folioTR: $folioTR, fechaTR: $fechaTR, ubicacionTR: $ubicacionTR, comentarioTR: $comentarioTR, fotoAntes64TR: $fotoAntes64TR, fotoDespues64TR: $fotoDespues64TR, fotoRequiereMaterial64TR: $fotoRequiereMaterial64TR, encuenstaTR: $encuenstaTR, idUserTR: $idUserTR, idOrdenServicio: $idOrdenServicio, folioOS: $folioOS, padronNombre: $padronNombre, padronDireccion: $padronDireccion, problemaNombre: $problemaNombre, folioSalida: $folioSalida)';
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
        other.fotoRequiereMaterial64TR == fotoRequiereMaterial64TR &&
        other.encuenstaTR == encuenstaTR &&
        other.idUserTR == idUserTR &&
        other.idOrdenServicio == idOrdenServicio &&
        other.folioOS == folioOS &&
        other.padronNombre == padronNombre &&
        other.padronDireccion == padronDireccion &&
        other.problemaNombre == problemaNombre &&
        other.folioSalida == folioSalida;
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
        fotoRequiereMaterial64TR.hashCode ^
        encuenstaTR.hashCode ^
        idUserTR.hashCode ^
        idOrdenServicio.hashCode ^
        folioOS.hashCode ^
        padronNombre.hashCode ^
        padronDireccion.hashCode ^
        problemaNombre.hashCode ^
        folioSalida.hashCode;
  }
}
