class AboutResponse {
  final String company;
  final String version;
  final String description;
  final String logoUrl;
  final String email;

  AboutResponse({
    required this.company,
    required this.version,
    required this.description,
    required this.logoUrl,
    required this.email,
  });

  factory AboutResponse.fromJson(Map<String, dynamic> json) => AboutResponse(
    company: json['company'] ?? '',
    version: json['version'] ?? '',
    description: json['description'] ?? '',
    logoUrl: json['logo_url'] ?? '',
    email: json['email'] ?? '',
  );
}
