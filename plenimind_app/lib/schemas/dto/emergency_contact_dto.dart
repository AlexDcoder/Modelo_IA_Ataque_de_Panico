class EmergencyContactDTO {
  final String name;
  final String phone;

  EmergencyContactDTO({required this.name, required this.phone});

  Map<String, dynamic> toJson() => {'name': name, 'phone': phone};

  factory EmergencyContactDTO.fromJson(Map<String, dynamic> json) {
    return EmergencyContactDTO(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}
