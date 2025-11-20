/// Utilitário para validação de email com regex
class EmailValidator {
  /// Padrão regex para validação de email (RFC 5322 simplificado)
  static final RegExp _emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#$%&'"
    r'+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
  );

  /// Valida um email usando regex
  /// Retorna true se o email é válido, false caso contrário
  static bool isValid(String email) {
    if (email.isEmpty) return false;
    return _emailRegex.hasMatch(email.trim());
  }

  /// Retorna mensagem de erro descritiva
  static String? getErrorMessage(String email) {
    if (email.isEmpty) {
      return 'Email não pode estar vazio';
    }
    if (!isValid(email)) {
      return 'Email inválido. Verifique o formato.';
    }
    return null;
  }
}
