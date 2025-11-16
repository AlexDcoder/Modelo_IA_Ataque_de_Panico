class UserProfileUpdateDTO {
  final String username;
  final String email;

  UserProfileUpdateDTO({required this.username, required this.email});

  Map<String, dynamic> toJson() => {'username': username, 'email': email};
}
