import 'package:cuan_app/data/model/termsclause.dart';
import 'package:flutter/material.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;

    Widget brandInTitle(String full) {
      final i = full.lastIndexOf(' ');
      if (i <= 0) {
        return Text(
          full,
          style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        );
      }
      final left = full.substring(0, i);
      final brand = full.substring(i + 1);

      return Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$left ',
              style: t.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            TextSpan(
              text: brand,
              style: t.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: cs.primary,
              ),
            ),
          ],
        ),
      );
    }

    final clauses = <TermsClause>[
      const TermsClause(
        title: 'Pasal 1  Definisi',
        body: 'Menjelaskan istilah-istilah ...',
      ),
      const TermsClause(
        title: 'Pasal 2  Ruang Lingkup',
        body: 'Menjelaskan cakupan layanan ...',
      ),
      const TermsClause(
        title: 'Pasal 3  Kelayakan Pengguna',
        body: 'Syarat usia minimum ...',
      ),
      const TermsClause(
        title: 'Pasal 4  Hak Kekayaan Intelektual',
        body: 'Hak cipta, merek dagang ...',
      ),
      const TermsClause(
        title: 'Pasal 5  Penafian dan Batas Tanggung Jawab',
        body: 'Informasi bersifat edukasi ...',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: brandInTitle('Syarat & Ketentuan CuanApp'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Text(
            'PT Cuan Digital Nusantara — Aplikasi “Cuan”',
            style: t.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Efektif per 5 Juli 2025',
            style: t.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Dokumen ini mengikat secara hukum antara PT Cuan Digital Nusantara (“Kami”) dan Anda sebagai '
            'pengguna (“Anda”) atas akses dan/atau penggunaan Aplikasi, situs web, API, serta seluruh layanan '
            'turunannya (“Layanan”). Dengan menekan tombol “Saya Setuju” atau melanjutkan penggunaan, Anda '
            'menyatakan telah membaca, memahami, dan menyetujui dokumen ini berikut Kebijakan Privasi yang melekat.',
            style: t.textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 18),

          // judul bagian
          Text(
            'SYARAT & KETENTUAN (TERMS OF SERVICE)',
            style: t.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: .5,
            ),
          ),
          const SizedBox(height: 10),

          // panel daftar pasal
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: .4),
              ),
            ),
            child: _ClauseList(clauses: clauses),
          ),

          const SizedBox(height: 16),
          Text(
            'Dengan tetap menggunakan aplikasi ini, Anda menyetujui syarat & ketentuan di atas. '
            'Untuk pertanyaan, hubungi support@cuan.app',
            style: t.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClauseList extends StatefulWidget {
  const _ClauseList({required this.clauses});
  final List<TermsClause> clauses;

  @override
  State<_ClauseList> createState() => _ClauseListState();
}

class _ClauseListState extends State<_ClauseList> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.clauses.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: .35)),
      itemBuilder: (context, i) {
        final c = widget.clauses[i];
        return Theme(
          // kecilkan densitas ExpansionTile
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 12),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            title: Text(
              c.title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            trailing: const Icon(Icons.expand_more),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(c.body, style: const TextStyle(height: 1.4))],
          ),
        );
      },
    );
  }
}
