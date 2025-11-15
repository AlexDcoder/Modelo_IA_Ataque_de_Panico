import '../dto/emergency_contact_dto.dart';

class UserPersonalDataResponse {
  final String uid;
  final String username;
  final String email;
  final String detectionTime;
  final List<EmergencyContactDTO> emergencyContacts;

  UserPersonalDataResponse({
    required this.uid,
    required this.username,
    required this.email,
    required this.detectionTime,
    required this.emergencyContacts,
  });

  factory UserPersonalDataResponse.fromJson(Map<String, dynamic> json) {
    return UserPersonalDataResponse(
      uid: json['uid'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      detectionTime: json['detection_time'] ?? '',
      emergencyContacts:
          (json['emergency_contact'] as List? ?? [])
              .map((e) => EmergencyContactDTO.fromJson(e))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'username': username,
    'email': email,
    'detection_time': detectionTime,
    'emergency_contact': emergencyContacts.map((e) => e.toJson()).toList(),
  };
}
