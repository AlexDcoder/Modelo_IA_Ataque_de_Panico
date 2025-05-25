import 'dart:convert';
import 'package:http/http.dart' as http;
import 'sensor_data.dart';

class SensorObserver {
  final String baseUrl;
  final String uid;

  SensorObserver({required this.baseUrl, required this.uid});

  Future<bool> sendData(SensorData data) async {
    // Tenta criar usuário (POST)
    final postUrl = Uri.parse('$baseUrl/server/users');
    final postResponse = await http.post(
      postUrl,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'uid': uid, ...data.toJson()}),
    );

    if (postResponse.statusCode == 200 || postResponse.statusCode == 201) {
      // Criado com sucesso
      return true;
    } else if (postResponse.statusCode == 307 ||
        postResponse.statusCode == 409) {
      // Usuário já existe - tenta atualizar via PUT
      final putUrl = Uri.parse('$baseUrl/server/users/$uid');
      final putResponse = await http.put(
        putUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'uid': uid, ...data.toJson()}),
      );

      return putResponse.statusCode == 200;
    } else {
      // Outro erro
      return false;
    }
  }
}
