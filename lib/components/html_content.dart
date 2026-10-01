import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

/// Merender isi journal (HTML dari RichTextEditor di admin panel) dengan gaya
/// mengikuti tema app. Backend sudah menyaring HTML-nya (allowlist), dan
/// flutter_html tidak mengeksekusi script, jadi aman ditampilkan apa adanya.
class HtmlContent extends StatelessWidget {
  const HtmlContent({super.key, required this.html});

  final String html;

  static const Set<String> _launchableSchemes = {'http', 'https', 'mailto'};
  static final RegExp _tagPattern = RegExp(r'</?[a-zA-Z][^>]*>');

  /// Journal lama / fallback preview dari server berupa teks polos (tanpa tag):
  /// baris baru harus jadi `<br>` karena HTML menganggapnya spasi biasa.
  /// Teks dari server sudah di-escape, jadi sengaja tidak di-escape lagi.
  static String toHtml(String content) =>
      _tagPattern.hasMatch(content) ? content : content.replaceAll('\n', '<br>');

  /// Teks tanpa tag, untuk mengukur panjang isi sebenarnya.
  static String plainText(String content) =>
      content.replaceAll(_tagPattern, ' ').trim();

  /// Hanya http(s) dan mailto yang boleh dibuka dari link di dalam artikel.
  static bool isLaunchable(String? url) {
    final uri = url == null ? null : Uri.tryParse(url);
    return uri != null && _launchableSchemes.contains(uri.scheme);
  }

  Future<void> _openLink(String? url) async {
    if (!isLaunchable(url)) return;
    await launchUrl(Uri.parse(url!), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final base = theme.textTheme.bodyMedium ?? const TextStyle();

    return Html(
      data: toHtml(html),
      onLinkTap: (url, _, _) => _openLink(url),
      style: {
        'body': Style.fromTextStyle(base).copyWith(
          color: cs.onSurface,
          lineHeight: const LineHeight(1.35),
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
        ),
        'a': Style(color: cs.primary),
        'blockquote': Style(
          margin: Margins.symmetric(vertical: 8),
          padding: HtmlPaddings.only(left: 12),
          border: Border(left: BorderSide(color: cs.outlineVariant, width: 3)),
        ),
        'pre': Style(
          padding: HtmlPaddings.all(8),
          backgroundColor: cs.surfaceContainerHighest,
        ),
      },
    );
  }
}

/// Teaser konten premium: isi tampil jelas di bagian atas lalu memudar ke bawah.
/// HTML tidak bisa dipotong per karakter seperti teks polos, jadi efek
/// "terkunci" dibuat lewat mask gradien.
class HtmlTeaser extends StatelessWidget {
  const HtmlTeaser({super.key, required this.html, required this.clearRatio});

  final String html;
  final double clearRatio; // porsi tinggi yang tetap jelas (0..1)

  static const int _minCharsToFade = 120; // isi sependek ini tampil utuh

  @override
  Widget build(BuildContext context) {
    final content = HtmlContent(html: html);
    if (HtmlContent.plainText(html).length < _minCharsToFade) return content;

    final clear = clearRatio.clamp(0.0, 1.0).toDouble();
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Colors.white, Colors.white, Colors.transparent],
        stops: [0, clear, 1],
      ).createShader(bounds),
      child: content,
    );
  }
}
