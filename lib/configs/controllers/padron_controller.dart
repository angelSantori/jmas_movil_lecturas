import 'dart:convert';
import 'dart:io';
import 'package:http/io_client.dart';
import 'package:jmas_movil_lecturas/configs/service/auth_service.dart';

class PadronController {
  final AuthService _authService = AuthService();

  IOClient _createHttpClient() {
    final ioClient = HttpClient();
    ioClient.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    return IOClient(ioClient);
  }

  //List padron
  //  Padron x Id
  Future<Padron?> getPadronXId(int idPadron) async {
    try {
      final IOClient client = _createHttpClient();
      final response = await client.get(
        Uri.parse('${_authService.apiURL}/Padrons/$idPadron'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData =
            json.decode(response.body) as Map<String, dynamic>;
        return Padron.fromMap(jsonData);
      } else {
        print(
          'Error getPadronXId | Try | Controller: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Error getPadronXId | Try | Controller: $e');
      return null;
    }
  }

  Future<List<Padron>> listPadron() async {
    try {
      final IOClient client = _createHttpClient();
      final response = await client.get(
        Uri.parse('${_authService.apiURL}/Padrons'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData
            .map((padronList) => Padron.fromMap(padronList))
            .toList();
      } else {
        print(
          'Error lista Padron | Ife | Controlles: ${response.statusCode} - ${response.body}',
        );
        return [];
      }
    } catch (e) {
      print('Error lista Padron | TryCatch | Controller: $e');
      return [];
    }
  }
}

class Padron {
  int? idPadron;
  String? padronNombre;
  String? padronDireccion;
  Padron({this.idPadron, this.padronNombre, this.padronDireccion});

  Padron copyWith({
    int? idPadron,
    String? padronNombre,
    String? padronDireccion,
  }) {
    return Padron(
      idPadron: idPadron ?? this.idPadron,
      padronNombre: padronNombre ?? this.padronNombre,
      padronDireccion: padronDireccion ?? this.padronDireccion,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'idPadron': idPadron,
      'padronNombre': padronNombre,
      'padronDireccion': padronDireccion,
    };
  }

  factory Padron.fromMap(Map<String, dynamic> map) {
    return Padron(
      idPadron: map['idPadron'] != null ? map['idPadron'] as int : null,
      padronNombre:
          map['padronNombre'] != null ? map['padronNombre'] as String : null,
      padronDireccion:
          map['padronDireccion'] != null
              ? map['padronDireccion'] as String
              : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Padron.fromJson(String source) =>
      Padron.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'Padron(idPadron: $idPadron, padronNombre: $padronNombre, padronDireccion: $padronDireccion)';

  @override
  bool operator ==(covariant Padron other) {
    if (identical(this, other)) return true;

    return other.idPadron == idPadron &&
        other.padronNombre == padronNombre &&
        other.padronDireccion == padronDireccion;
  }

  @override
  int get hashCode =>
      idPadron.hashCode ^ padronNombre.hashCode ^ padronDireccion.hashCode;
}
