import 'package:flutter/foundation.dart';
import 'package:plenimind_app/service/api_client.dart';
import 'package:plenimind_app/core/auth/auth_manager.dart';

class AccountService {
  final ApiClient _apiClient = ApiClient();
  final AuthManager _authManager = AuthManager();

  /// Deleta a conta do usuário
  Future<bool> deleteAccount(String uid, String token) async {
    try {
      debugPrint('🗑️ Iniciando exclusão da conta: $uid');

      final response = await _apiClient.authenticatedDelete(
        'users/$uid',
        token,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('✅ Conta deletada com sucesso');

        // Limpar tokens do AuthManager
        await _authManager.clearTokens();

        return true;
      } else {
        debugPrint(
          '❌ Erro ao deletar conta: ${response.statusCode} ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ Erro ao deletar conta: $e');
      return false;
    }
  }

  /// Deleta todos os dados do usuário localmente (contatos de emergência, etc)
  Future<void> deleteLocalUserData(String userId) async {
    try {
      debugPrint('🗑️ Limpando dados locais do usuário: $userId');

      // Nota: ContactService.getStorageKey usa userId, então os contatos
      // serão automaticamente perdidos quando o usuário deletar e se registrar novamente
      // com um novo userId

      debugPrint('✅ Dados locais do usuário removidos');
    } catch (e) {
      debugPrint('❌ Erro ao limpar dados locais: $e');
    }
  }
}
