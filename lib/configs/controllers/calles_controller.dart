//Librerías
import 'dart:convert';
import 'dart:io';
import 'package:http/io_client.dart';
import 'package:jmas_movil_lecturas/configs/service/auth_service.dart';

class CallesController {
  final AuthService _authService = AuthService();

  IOClient _createHttpClient() {
    final ioClient = HttpClient();
    ioClient.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    return IOClient(ioClient);
  }

  //GET
  //GetXId
  Future<Calles?> getCalleXId(int idCalle) async {
    try {
      final IOClient client = _createHttpClient();
      final response = await client.get(
        Uri.parse('${_authService.apiURL}/Calles/$idCalle'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData =
            json.decode(response.body) as Map<String, dynamic>;
        return Calles.fromMap(jsonData);
      } else if (response.statusCode == 404) {
        print('Calle no encontrada con ID: $idCalle | Ife | Controller');
        return null;
      } else {
        print(
          'Error getValleXID | Ife | Controller: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Error getCalleXID | Try | Controller: $e');
      return null;
    }
  }
}

class Calles {
  int? idCalle;
  String? calleNombre;
  Calles({this.idCalle, this.calleNombre});

  Calles copyWith({int? idCalle, String? calleNombre}) {
    return Calles(
      idCalle: idCalle ?? this.idCalle,
      calleNombre: calleNombre ?? this.calleNombre,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{'idCalle': idCalle, 'calleNombre': calleNombre};
  }

  factory Calles.fromMap(Map<String, dynamic> map) {
    return Calles(
      idCalle: map['idCalle'] != null ? map['idCalle'] as int : null,
      calleNombre:
          map['calleNombre'] != null ? map['calleNombre'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Calles.fromJson(String source) =>
      Calles.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'Calles(idCalle: $idCalle, calleNombre: $calleNombre)';

  @override
  bool operator ==(covariant Calles other) {
    if (identical(this, other)) return true;

    return other.idCalle == idCalle && other.calleNombre == calleNombre;
  }

  @override
  int get hashCode => idCalle.hashCode ^ calleNombre.hashCode;
}
