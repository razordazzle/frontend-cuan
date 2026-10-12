class QrisQueryResponse {
  final bool ok;
  final String partnerRefNo;
  final String? latestStatus;
  final bool isPaid;
  final String status; // "paid" | "pending" | "expired"
  final String? message;

  QrisQueryResponse({
    required this.ok,
    required this.partnerRefNo,
    required this.latestStatus,
    required this.isPaid,
    required this.status,
    this.message,
  });

  bool get isExpired => status == 'expired';

  String get statusText {
    if (isPaid) return 'Pembayaran berhasil';
    if (message != null && message!.isNotEmpty) return message!;
    if (latestStatus == null || latestStatus!.isEmpty) return 'Menunggu pembayaran...';
    return 'Status: $latestStatus';
  }

  factory QrisQueryResponse.fromJson(Map<String, dynamic> j) {
    return QrisQueryResponse(
      ok: j['ok'] == true,
      partnerRefNo: j['partner_ref_no']?.toString() ?? '',
      latestStatus: j['latest_status']?.toString(),
      isPaid: j['is_paid'] == true,
      status: j['status']?.toString() ?? 'pending',
      message: j['message']?.toString(),
    );
  }
}
