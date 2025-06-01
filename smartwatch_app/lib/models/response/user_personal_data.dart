import 'package:smartwatch_app/models/request/user_personal_data.dart';

class UserPersonalDataResponse extends UserPersonalData {
  final String uid;

  UserPersonalDataResponse({
    required String email,
    required String password,
    required int detectionTime,
    required this.uid,
  }) : super(email: email, password: password, detectionTime: detectionTime);

  factory UserPersonalDataResponse.fromJson(Map<String, dynamic> json) {
    return UserPersonalDataResponse(
      email: json['email'],
      password: json['password'],
      detectionTime: json['detection_time'],
      uid: json['uid'],
    );
  }

  @override
  Map<String, dynamic> toJson() => {...super.toJson(), 'uid': uid};
}
