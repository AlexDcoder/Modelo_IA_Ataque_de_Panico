import 'package:plenimind_app/schemas/request/vital_data.dart';

class UserVitalDataResponse extends UserVitalData {
  final String uid;

  UserVitalDataResponse({
    required super.heartRate,
    required super.respirationRate,
    required super.accelStd,
    required super.spo2,
    required super.stressLevel,
    required this.uid,
  });

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
