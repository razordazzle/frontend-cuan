class QrisGenerateResponse {
  final bool ok;
  final bool reused;
  final String paymentId;
  final String invoiceId;
  final String partnerRefNo;
  final String amount;
  final String qrContent;

  QrisGenerateResponse({
    required this.ok,
    required this.reused,
    required this.paymentId,
    required this.invoiceId,
    required this.partnerRefNo,
    required this.amount,
    required this.qrContent,
  });

  factory QrisGenerateResponse.fromJson(Map<String, dynamic> json) {
    return QrisGenerateResponse(
      ok: json['ok'] == true,
      reused: json['reused'] == true,
      paymentId: (json['payment_id'] ?? '').toString(),
      invoiceId: (json['invoice_id'] ?? '').toString(),
      partnerRefNo: (json['partner_ref_no'] ?? '').toString(),
      amount: (json['amount'] ?? '').toString(),
      qrContent: (json['qr_content'] ?? '').toString(),
    );
  }
}
