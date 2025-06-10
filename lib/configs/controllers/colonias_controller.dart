// Librerías
import 'dart:convert';
import 'dart:io';
import 'package:http/io_client.dart';
import 'package:jmas_movil_lecturas/configs/service/auth_service.dart';

class ColoniasController {
  final AuthService _authService = AuthService();

  IOClient _createHttpClient() {
    final ioClient = HttpClient();
    ioClient.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    return IOClient(ioClient);
  }

  //GET
  //GetXId
  Future<Colonias?> getColoniaXId(int idColonia) async {
    try {
      final IOClient client = _createHttpClient();
      final response = await client.get(
        Uri.parse('${_authService.apiURL}/Colonias/$idColonia'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData =
            json.decode(response.body) as Map<String, dynamic>;
        return Colonias.fromMap(jsonData);
      } else if (response.statusCode == 404) {
        print('Colonia no encontrada con ID: $idColonia | Ife | Controller');
        return null;
      } else {
        print(
          'Error get colonia x id | Ife | Controller: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Error get colonia x id | Try | Controller por ID: $e');
      return null;
    }
  }
}

class Colonias {
  int? idColonia;
  String? nombreColonia;
  Colonias({this.idColonia, this.nombreColonia});

  Colonias copyWith({int? idColonia, String? nombreColonia}) {
    return Colonias(
      idColonia: idColonia ?? this.idColonia,
      nombreColonia: nombreColonia ?? this.nombreColonia,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'idColonia': idColonia,
      'nombreColonia': nombreColonia,
    };
  }

  factory Colonias.fromMap(Map<String, dynamic> map) {
    return Colonias(
      idColonia: map['idColonia'] != null ? map['idColonia'] as int : null,
      nombreColonia:
          map['nombreColonia'] != null ? map['nombreColonia'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Colonias.fromJson(String source) =>
      Colonias.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'Colonias(idColonia: $idColonia, nombreColonia: $nombreColonia)';

  @override
  bool operator ==(covariant Colonias other) {
    if (identical(this, other)) return true;

    return other.idColonia == idColonia && other.nombreColonia == nombreColonia;
  }

  @override
  int get hashCode => idColonia.hashCode ^ nombreColonia.hashCode;
}
