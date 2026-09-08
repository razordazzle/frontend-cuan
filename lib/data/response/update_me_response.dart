class UpdateMeResponse {
  final bool updated;
  UpdateMeResponse({required this.updated});
  factory UpdateMeResponse.fromJson(Map<String, dynamic> j) =>
      UpdateMeResponse(updated: j['updated'] == true);
}
