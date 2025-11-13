class UserPersonalData {
  final String username;
  final String email;
  final String password;
  final String detectionTime;

  UserPersonalData({
    required this.username,
    required this.email,
    required this.password,
    required this.detectionTime,
  });

  Map<String, dynamic> toJson() => {
    'username': username,
    'email': email,
    'password': password,
    'detection_time': detectionTime,
  };
}
