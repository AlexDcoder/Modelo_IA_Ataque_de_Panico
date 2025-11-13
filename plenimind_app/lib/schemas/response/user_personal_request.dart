import 'package:plenimind_app/schemas/request/personal_data.dart';

class UserPersonalDataResponse extends UserPersonalData {
  final String uid;

  UserPersonalDataResponse({
    required super.username,
    required super.email,
    required super.password,
    required super.detectionTime,
    required this.uid,
  });

  factory UserPersonalDataResponse.fromJson(Map<String, dynamic> json) {
    return UserPersonalDataResponse(
      username: json['username'],
      email: json['email'],
      password: json['password'],
      detectionTime: json['detection_time'],
      uid: json['uid'],
    );
  }

  @override
  Map<String, dynamic> toJson() => {...super.toJson(), 'uid': uid};
}
