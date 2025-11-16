class UserSettingsUpdateDTO {
  final String detectionTime;

  UserSettingsUpdateDTO({required this.detectionTime});

  Map<String, dynamic> toJson() => {'detection_time': detectionTime};
}
