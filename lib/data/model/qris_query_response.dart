class QrisQueryResponse {
  final bool ok;
  final String partnerRefNo;
  final String? latestStatus;
  final bool isPaid;


  QrisQueryResponse({
    required this.ok,
    required this.partnerRefNo,
    required this.latestStatus,
    required this.isPaid,
  });
   String get statusText {
    if (isPaid) return 'Pembayaran berhasil';
    if (latestStatus == null || latestStatus!.isEmpty) return 'Menunggu pembayaran...';
    return 'Status: $latestStatus';
  }

  factory QrisQueryResponse.fromJson(Map<String, dynamic> j) {
    return QrisQueryResponse(
      ok: j['ok'] == true,
      partnerRefNo: j['partner_ref_no']?.toString() ?? '',
      latestStatus: j['latest_status']?.toString(),
      isPaid: j['is_paid'] == true,
    );
  }
}
