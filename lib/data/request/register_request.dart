class RegisterRequest {
  final String name;
  final String email;
  final String phone;     // format +62...
  final String password;
  final String? username;
  final String? birthPlace;
  final String? birthDate; // "YYYY-MM-DD"
  final String? domicile;

  RegisterRequest({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    this.username,
    this.birthPlace,
    this.birthDate,
    this.domicile,
  });

  Map<String, dynamic> toJson() => {
    "name": name,
    "email": email,
    "phone": phone,
    "password": password,
    if (username  != null) "username"  : username,
    if (birthPlace!= null) "birth_place": birthPlace,
    if (birthDate != null) "birth_date" : birthDate,
    if (domicile  != null) "domicile"   : domicile,
  };
}