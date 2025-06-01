import 'package:smartwatch_app/models/request/user_vital_data.dart';

class UserVitalDataResponse extends UserVitalData {
  final String uid;

  UserVitalDataResponse({
    required double heartRate,
    required double respirationRate,
    required double accelStd,
    required double spo2,
    required double stressLevel,
    required this.uid,
  }) : super(
         heartRate: heartRate,
         respirationRate: respirationRate,
         accelStd: accelStd,
         spo2: spo2,
         stressLevel: stressLevel,
       );

  factory UserVitalDataResponse.fromJson(Map<String, dynamic> json) {
    return UserVitalDataResponse(
      heartRate: (json['heart_rate'] as num).toDouble(),
      respirationRate: (json['respiration_rate'] as num).toDouble(),
      accelStd: (json['accel_std'] as num).toDouble(),
      spo2: (json['spo2'] as num).toDouble(),
      stressLevel: (json['stress_level'] as num).toDouble(),
      uid: json['uid'],
    );
  }

  @override
  Map<String, dynamic> toJson() => {...super.toJson(), 'uid': uid};
}
