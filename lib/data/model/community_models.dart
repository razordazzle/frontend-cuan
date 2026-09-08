class CommunityLinkResponse {
  final String platform;
  final String link;

  CommunityLinkResponse({required this.platform, required this.link});

  factory CommunityLinkResponse.fromJson(Map<String, dynamic> json) {
    return CommunityLinkResponse(
      platform: json['platform'] as String? ?? 'Community',
      link: json['link'] as String? ?? '',
    );
  }
}