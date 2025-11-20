import '../dto/emergency_contact_dto.dart';

class UserPersonalData {
  final String username;
  final String email;
  final String password;
  final String detectionTime;
  final List<EmergencyContactDTO> emergencyContacts;

  UserPersonalData({
    required this.username,
    required this.email,
    required this.password,
    required this.detectionTime,
    required this.emergencyContacts,
  });

  Map<String, dynamic> toJson() => {
    'username': username,
    'email': email,
    'password': password,
    'detection_time': detectionTime,
    'emergency_contact': emergencyContacts.map((e) => e.toJson()).toList(),
  };
}
