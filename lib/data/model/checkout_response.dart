class CheckoutResponse {
  final bool ok;
  final bool reusedInvoice;
  final String invoiceId;
  final String invoiceNumber;
  final String amount; // string dari backend
  final int paymentId;
  final String partnerRefNo;
  final String qrContent;

  CheckoutResponse({
    required this.ok,
    required this.reusedInvoice,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.amount,
    required this.paymentId,
    required this.partnerRefNo,
    required this.qrContent,
  });

  factory CheckoutResponse.fromJson(Map<String, dynamic> j) {
    return CheckoutResponse(
      ok: j['ok'] == true,
      reusedInvoice: j['reused_invoice'] == true,
      invoiceId: j['invoice_id']?.toString() ?? '',
      invoiceNumber: j['invoice_number']?.toString() ?? '',
      amount: j['amount']?.toString() ?? '0',
      paymentId: int.tryParse(j['payment_id']?.toString() ?? '') ?? 0,
      partnerRefNo: j['partner_ref_no']?.toString() ?? '',
      qrContent: j['qr_content']?.toString() ?? '',
    );
  }
}
