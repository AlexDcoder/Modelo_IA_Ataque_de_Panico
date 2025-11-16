import 'package:plenimind_app/schemas/dto/emergency_contact_dto.dart';

class UserEmergencyContactsUpdateDTO {
  final List<EmergencyContactDTO> emergencyContacts;

  UserEmergencyContactsUpdateDTO({required this.emergencyContacts});

  Map<String, dynamic> toJson() => {
    'emergency_contact': emergencyContacts.map((e) => e.toJson()).toList(),
  };
}
