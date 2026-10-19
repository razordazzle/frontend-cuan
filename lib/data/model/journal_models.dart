import 'package:cuan_app/utils/wib_time.dart';

class JournalListItem {
  final String journalId;
  final String title;
  final String type; // "research" | "knowledge"
  final bool isPaid;
  final DateTime publishedAt;
  final String? thumbnailUrl;
  final String? author;
  final int? priceIdr; // harga unlock journal premium; null = free / belum diatur admin
  final bool hasAccess; // sudah kebuka buat user ini (free / member / sudah beli)

  JournalListItem({
    required this.journalId,
    required this.title,
    required this.type,
    required this.isPaid,
    required this.publishedAt,
    this.thumbnailUrl,
    this.author,
    this.priceIdr,
    this.hasAccess = true,
  });

  factory JournalListItem.fromJson(Map<String, dynamic> j) => JournalListItem(
        journalId: j['journal_id'] as String,
        title: j['title'] as String,
        type: j['type'] as String,
        isPaid: j['is_paid'] as bool,
        publishedAt: parseServerTime(j['published_at'] as String),
        thumbnailUrl: j['thumbnail_url'] as String?,
        author: j['author'] as String?,
        priceIdr: (j['price_idr'] as num?)?.toInt(),
        // backend lama belum kirim has_access: anggap kebuka kalau bukan premium
        hasAccess: j['has_access'] as bool? ?? !(j['is_paid'] as bool),
      );
}

class JournalListResponse {
  final List<JournalListItem> items;
  final String? nextCursor;
  JournalListResponse({required this.items, this.nextCursor});

  factory JournalListResponse.fromJson(Map<String, dynamic> j) =>
      JournalListResponse(
        items: (j['items'] as List)
            .map((e) => JournalListItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        nextCursor: j['next_cursor'] as String?,
      );
}

class JournalDetailResponse {
  final String journalId;
  final String title;
  final String? author;
  final DateTime publishedAt;
  final String contentMd;
  final bool isPaid;

  JournalDetailResponse({
    required this.journalId,
    required this.title,
    this.author,
    required this.publishedAt,
    required this.contentMd,
    required this.isPaid,
  });

  factory JournalDetailResponse.fromJson(Map<String, dynamic> j) =>
      JournalDetailResponse(
        journalId: j['journal_id'] as String,
        title: j['title'] as String,
        author: j['author'] as String?,
        publishedAt: parseServerTime(j['published_at'] as String),
        contentMd: j['content_md'] as String,
        isPaid: j['is_paid'] as bool,
      );
}

class JournalPreviewResponse {
  final String journalId;
  final String title;
  final String previewMd;
  JournalPreviewResponse({
    required this.journalId,
    required this.title,
    required this.previewMd,
  });

  factory JournalPreviewResponse.fromJson(Map<String, dynamic> j) =>
      JournalPreviewResponse(
        journalId: j['journal_id'] as String,
        title: j['title'] as String,
        previewMd: j['preview_md'] as String,
      );
}

class JournalAccessResponse {
  final bool hasAccess;
  final bool isMember;
  final int? priceIdr;
  JournalAccessResponse({
    required this.hasAccess,
    this.isMember = false,
    this.priceIdr,
  });

  factory JournalAccessResponse.fromJson(Map<String, dynamic> j) =>
      JournalAccessResponse(
        hasAccess: j['has_access'] as bool,
        isMember: j['is_member'] as bool? ?? false,
        priceIdr: (j['price_idr'] as num?)?.toInt(),
      );
}
