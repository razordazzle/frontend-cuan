class UpdateMeRequest {
  final String? name;
  final String? username;
  final String? birthPlace; // birth_place
  final String? birthDate;  // "YYYY-MM-DD"
  final String? domicile;
  final String? phone;      // +62...

  UpdateMeRequest({
    this.name,
    this.username,
    this.birthPlace,
    this.birthDate,
    this.domicile,
    this.phone,
  });

  Map<String, dynamic> toJson() => {
    if (name != null) "name": name,
    if (username != null) "username": username,
    if (birthPlace != null) "birth_place": birthPlace,
    if (birthDate != null) "birth_date": birthDate,
    if (domicile != null) "domicile": domicile,
    if (phone != null) "phone": phone,
  };
}
