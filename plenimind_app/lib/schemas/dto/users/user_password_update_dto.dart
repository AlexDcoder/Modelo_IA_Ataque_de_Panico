class UserPasswordUpdateDTO {
  final String password;

  UserPasswordUpdateDTO({required this.password});

  Map<String, dynamic> toJson() => {'password': password};
}
