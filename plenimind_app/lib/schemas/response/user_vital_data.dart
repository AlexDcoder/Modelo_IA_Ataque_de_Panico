class UserVitalDataResponse {
  final String uid;
  final double heartRate;
  final double respirationRate;
  final double accelStd;
  final double spo2;
  final double stressLevel;

  UserVitalDataResponse({
    required this.uid,
    required this.heartRate,
    required this.respirationRate,
    required this.accelStd,
    required this.spo2,
    required this.stressLevel,
  });

  factory UserVitalDataResponse.fromJson(Map<String, dynamic> json) {
    return UserVitalDataResponse(
      uid: json['uid'] ?? '',
      heartRate: (json['heart_rate'] as num?)?.toDouble() ?? 0.0,
      respirationRate: (json['respiration_rate'] as num?)?.toDouble() ?? 0.0,
      accelStd: (json['accel_std'] as num?)?.toDouble() ?? 0.0,
      spo2: (json['spo2'] as num?)?.toDouble() ?? 0.0,
      stressLevel: (json['stress_level'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'heart_rate': heartRate,
    'respiration_rate': respirationRate,
    'accel_std': accelStd,
    'spo2': spo2,
    'stress_level': stressLevel,
  };
}
