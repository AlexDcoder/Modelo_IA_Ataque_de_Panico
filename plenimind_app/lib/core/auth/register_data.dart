class RegisterData {
  String? username;
  String? email;
  String? password;
  String? detectionTime;
  List<Map<String, String>> emergencyContacts = [];

  Map<String, dynamic> toJson() {
    return {
      "username": username,
      "email": email,
      "password": password,
      "detection_time": detectionTime,
      "emergency_contact": emergencyContacts,
    };
  }

  bool isComplete() {
    return username != null &&
        username!.isNotEmpty &&
        email != null &&
        email!.isNotEmpty &&
        password != null &&
        password!.isNotEmpty &&
        detectionTime != null &&
        detectionTime!.isNotEmpty &&
        emergencyContacts.isNotEmpty;
  }
}
