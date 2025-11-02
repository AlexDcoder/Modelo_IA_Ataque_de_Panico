import 'package:flutter/foundation.dart';
import 'register_data.dart';

class RegisterProvider extends ChangeNotifier {
  final RegisterData _data = RegisterData();

  RegisterData get data => _data;

  void setEmailAndPassword(String email, String password) {
    _data.email = email;
    _data.password = password;
    notifyListeners();
  }

  void setProfileInfo(String username, String detectionTime) {
    _data.username = username;
    _data.detectionTime = detectionTime;
    notifyListeners();
  }

  void setEmergencyContacts(List<Map<String, String>> contacts) {
    _data.emergencyContacts = contacts;
    notifyListeners();
  }

  void clear() {
    _data
      ..email = null
      ..password = null
      ..username = null
      ..detectionTime = null
      ..emergencyContacts = [];
    notifyListeners();
  }
}
