import 'package:plenimind_app/schemas/dto/emergency_contact_dto.dart';

class EmergencyContact {
  final String id;
  final String name;
  final String phone;
  final String imageUrl;
  final int priority;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.imageUrl,
    required this.priority,
  });

  // Converter para DTO para envio à API
  EmergencyContactDTO toDTO() {
    return EmergencyContactDTO(name: name, phone: phone);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'imageUrl': imageUrl,
    'priority': priority,
  };

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      imageUrl: json['imageUrl'],
      priority: json['priority'],
    );
  }
}
