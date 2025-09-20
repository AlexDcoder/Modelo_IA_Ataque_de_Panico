class UserVitalData {
  final double heartRate;
  final double respirationRate;
  final double accelStd;
  final double spo2;
  final double stressLevel;

  UserVitalData({
    required this.heartRate,
    required this.respirationRate,
    required this.accelStd,
    required this.spo2,
    required this.stressLevel,
  });

  Map<String, dynamic> toJson() => {
    'heart_rate': heartRate,
    'respiration_rate': respirationRate,
    'accel_std': accelStd,
    'spo2': spo2,
    'stress_level': stressLevel,
  };
}
