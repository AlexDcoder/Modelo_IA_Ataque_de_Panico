import 'dart:convert';

import 'package:smartwatch_app/models/request/user_personal_data.dart';
import 'package:smartwatch_app/models/request/user_vital_data.dart';
import 'package:smartwatch_app/models/response/user_feedback.dart';
import 'package:smartwatch_app/services/api_client.dart';

class UserResponse {
  final String uid;

  UserResponse({required this.uid});

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(uid: json['uid']);
  }
}

class UserService {
  final ApiClient _apiClient = ApiClient();

  Future<UserResponse?> createUser(UserPersonalData user) async {
    final response = await _apiClient.post('users', user.toJson());

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body);
      return UserResponse.fromJson(json);
    } else {
      print('Erro ao criar usuário: ${response.statusCode} ${response.body}');
      return null;
    }
  }

  Future<bool> createVitalData(String uid, UserVitalData vitals) async {
    final response = await _apiClient.post('vital-data/$uid', vitals.toJson());

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      print(
        'Erro ao enviar dados vitais: ${response.statusCode} ${response.body}',
      );
      return false;
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

  // Novo método para buscar usuário por UID (GET)
  Future<UserResponse?> getUserById(String uid) async {
    final response = await _apiClient.get('users/$uid');

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return UserResponse.fromJson(json);
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
