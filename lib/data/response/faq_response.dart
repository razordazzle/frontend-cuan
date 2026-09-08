import 'package:cuan_app/data/model/faq_item.dart';

class FaqResponse {
  final List<FaqItem> faqs;
  FaqResponse(this.faqs);

  factory FaqResponse.fromJson(Map<String, dynamic> j) =>
      FaqResponse(((j['faqs'] as List?) ?? [])
          .map((e) => FaqItem.fromJson(e as Map<String, dynamic>))
          .toList());
}