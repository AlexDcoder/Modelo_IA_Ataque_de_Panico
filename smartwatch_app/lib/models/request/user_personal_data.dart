// user_personal_data.dart
class UserPersonalData {
  final String email;
  final String password;
  final int detectionTime;

  UserPersonalData({
    required this.email,
    required this.password,
    required this.detectionTime,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    'detection_time': detectionTime,
  };
}
