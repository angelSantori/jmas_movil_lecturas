// Librerías
import 'dart:convert';
import 'dart:io';
import 'package:http/io_client.dart';
import 'package:jmas_movil_lecturas/configs/service/auth_service.dart';

class TipoProblemaController {
  final AuthService _authService = AuthService();

  IOClient _createHttpClient() {
    final ioClient = HttpClient();
    ioClient.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    return IOClient(ioClient);
  }

  //  GET
  //  List
  Future<List<TipoProblema>> listTipoProblema() async {
    try {
      final IOClient client = _createHttpClient();
      final response = await client.get(
        Uri.parse('${_authService.apiURL}/TipoProblemas'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((listTP) => TipoProblema.fromMap(listTP)).toList();
      } else {
        print(
          'Error listTipoProblema | Ife | Controller: ${response.statusCode} - ${response.body}',
        );
        return [];
      }
    } catch (e) {
      print('Error listTipoProblema | Try | Controller: $e');
      return [];
    }
  }

  //  TipoProblema x Id
  Future<TipoProblema?> tipoProblemaXId(int idTP) async {
    try {
      final IOClient client = _createHttpClient();
      final response = await client.get(
        Uri.parse('${_authService.apiURL}/TipoProblemas/$idTP'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData =
            json.decode(response.body) as Map<String, dynamic>;
        return TipoProblema.fromMap(jsonData);
      } else {
        print(
          'Error tipoProblemaXId | Ife | Controller: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Error tipoProblemaXId | Try | Controller: $e');
      return null;
    }
  }
}

class TipoProblema {
  int? idTipoProblema;
  String? nombreTP;
  TipoProblema({this.idTipoProblema, this.nombreTP});

  TipoProblema copyWith({int? idTipoProblema, String? nombreTP}) {
    return TipoProblema(
      idTipoProblema: idTipoProblema ?? this.idTipoProblema,
      nombreTP: nombreTP ?? this.nombreTP,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'idTipoProblema': idTipoProblema,
      'nombreTP': nombreTP,
    };
  }

  factory TipoProblema.fromMap(Map<String, dynamic> map) {
    return TipoProblema(
      idTipoProblema:
          map['idTipoProblema'] != null ? map['idTipoProblema'] as int : null,
      nombreTP: map['nombreTP'] != null ? map['nombreTP'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory TipoProblema.fromJson(String source) =>
      TipoProblema.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'TipoProblema(idTipoProblema: $idTipoProblema, nombreTP: $nombreTP)';

  @override
  bool operator ==(covariant TipoProblema other) {
    if (identical(this, other)) return true;

    return other.idTipoProblema == idTipoProblema && other.nombreTP == nombreTP;
  }

  @override
  int get hashCode => idTipoProblema.hashCode ^ nombreTP.hashCode;
}
