import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    // --- Data FAQ ---
    final tentangAplikasi = <_FaqItem>[
      _FaqItem('Apa itu aplikasi Cuan Mobile?',
          'Cuan Mobile adalah aplikasi untuk membantu Anda mengelola keuangan, investasi, dan mencapai tujuan finansial Anda dengan lebih mudah.'),
      _FaqItem('Siapa yang dapat menggunakan aplikasi ini?',
          'Siapa saja yang ingin punya kontrol lebih baik atas keuangan pribadi.'),
      _FaqItem('Apakah aplikasi ini berbayar?',
          'Gratis untuk digunakan dengan beberapa fitur premium opsional.'),
      _FaqItem('Apakah data saya aman digunakan di aplikasi ini?',
          'Kami menggunakan enkripsi end-to-end dan praktik keamanan industri.'),
      _FaqItem('Aplikasi ini tersedia di platform apa saja?',
          'Saat ini tersedia untuk Android dan iOS.'),
    ];

    final akunKeamanan = <_FaqItem>[
      _FaqItem('Bagaimana cara membuat akun?',
          'Daftar dari halaman utama menggunakan email atau nomor HP yang valid.'),
      _FaqItem('Saya lupa password, bagaimana cara meresetnya?',
          'Gunakan fitur “Lupa Password” di halaman login. Kami kirim tautan reset ke email Anda.'),
      _FaqItem('Apakah bisa login menggunakan akun Google?',
          'Ya, tersedia opsi login cepat via Google.'),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.onBackground),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Bantuan',
            style: tt.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onBackground,
            )),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          _SectionPanel(
            title: 'A. Tentang Aplikasi',
            items: tentangAplikasi,
          ),
          const SizedBox(height: 20),
          _SectionPanel(
            title: 'B. Akun & Keamanan',
            items: akunKeamanan,
          ),
        ],
      ),
    );
  }
}

/* ===================== Widgets ===================== */

class _SectionPanel extends StatelessWidget {
  final String title;
  final List<_FaqItem> items;
  const _SectionPanel({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // panel lembut seperti mockup (abu terang di light, gelap di dark)
    final panelColor = isDark
        ? cs.surface.withOpacity(.6)
        : cs.surfaceVariant.withOpacity(.6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: tt.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: cs.onBackground,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: panelColor,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Theme(
            // hilangkan garis divider default ExpansionTile
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  _FaqTile(item: items[i]),
                  if (i != items.length - 1)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: cs.outline.withOpacity(.15),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FaqTile extends StatefulWidget {
  final _FaqItem item;
  const _FaqTile({required this.item});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      backgroundColor: Colors.transparent,
      collapsedBackgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      collapsedShape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      onExpansionChanged: (v) => setState(() => _expanded = v),
      trailing: AnimatedRotation(
        turns: _expanded ? .5 : 0, // rotasi chevron saat terbuka
        duration: const Duration(milliseconds: 180),
        child: Icon(Icons.expand_more, color: cs.onSurface.withOpacity(.8)),
      ),
      iconColor: cs.onSurface,
      collapsedIconColor: cs.onSurface,
      title: Text(
        widget.item.q,
        style: tt.bodyLarge?.copyWith(
          color: cs.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      children: [
        Text(
          widget.item.a,
          style: tt.bodyMedium?.copyWith(
            color: cs.onSurface.withOpacity(.8),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

/* ===================== Model ===================== */

class _FaqItem {
  final String q;
  final String a;
  const _FaqItem(this.q, this.a);
}
