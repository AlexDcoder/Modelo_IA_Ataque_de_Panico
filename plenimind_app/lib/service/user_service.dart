import 'dart:convert';
import 'package:plenimind_app/service/api_client.dart';
import 'package:plenimind_app/schemas/request/vital_data.dart';
import 'package:plenimind_app/schemas/dto/user_create_dto.dart';
import 'package:plenimind_app/schemas/response/user_vital_data.dart';
import 'package:plenimind_app/schemas/response/feedback_response.dart';
import 'package:plenimind_app/schemas/response/user_personal_request.dart';

class UserService {
  final ApiClient _apiClient = ApiClient();

  // Cria um usuário usando DTO
  Future<UserPersonalDataResponse?> createUser(UserCreateDTO user) async {
    final response = await _apiClient.post('users', user.toJson());

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body);
      return UserPersonalDataResponse.fromJson(json);
    } else {
      print('Erro ao criar usuário: ${response.statusCode} ${response.body}');
      return null;
    }
  }

  // Cria dados vitais e retorna o response completo
  Future<UserVitalDataResponse?> createVitalData(
    String uid,
    UserVitalData vitals,
  ) async {
    final response = await _apiClient.post('vital-data/$uid', vitals.toJson());

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body);
      return UserVitalDataResponse.fromJson(json);
    } else {
      print(
        'Erro ao enviar dados vitais: ${response.statusCode} ${response.body}',
      );
      return null;
    }
  }

  Future<Map<String, dynamic>?> getAiPrediction(String uid) async {
    final response = await _apiClient.get('users/$uid/ai-response');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('Erro ao obter predição: ${response.statusCode} ${response.body}');
      return null;
    }
  }

  // Buscar usuário por UID e retornar o response completo
  Future<UserPersonalDataResponse?> getUserById(String uid) async {
    final response = await _apiClient.get('users/$uid');

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return UserPersonalDataResponse.fromJson(json);
    } else {
      print('Erro ao buscar usuário: ${response.statusCode} ${response.body}');
      return null;
    }
  }

  Future<FeedbackInput> sendFeedback(String uid, FeedbackInput feedback) async {
    final response = await _apiClient.post(
      'users/$uid/feedback',
      feedback.toJson(),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body);
      return FeedbackInput.fromJson(json);
    } else {
      print('Erro ao enviar feedback: ${response.statusCode} ${response.body}');
      throw Exception('Erro ao enviar feedback');
    }
  }
}
