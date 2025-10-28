class AuthManager {
  static final AuthManager _instance = AuthManager._internal();
  factory AuthManager() => _instance;
  AuthManager._internal();

  String? accessToken;
  String? refreshToken;

  void setTokens(String access, String refresh) {
    accessToken = access;
    refreshToken = refresh;
  }

  void clearTokens() {
    accessToken = null;
    refreshToken = null;
  }

  bool get isAuthenticated => accessToken != null;
}
