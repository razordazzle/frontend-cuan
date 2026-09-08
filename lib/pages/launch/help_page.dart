// lib/pages/menu/help_page.dart (contoh ringkas)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cuan_app/providers/info_provider.dart';

class HelpPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final p = context.watch<InfoProvider>();
    // Gunakan Future.microtask agar tidak memicu error "setState() or markNeedsBuild() called during build"
    if (p.faq == null && !p.loadingFaq && p.faqError == null) {
      Future.microtask(() => p.fetchFaq());
    }

    Widget body() {
      if (p.loadingFaq && p.faq == null) {
        return const Center(child: CircularProgressIndicator());
      }
      
      if (p.faqError != null) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(p.faqError!, style: TextStyle(color: cs.error)),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => p.fetchFaq(force: true),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        );
      }

      final items = p.faq!.faqs;

      // 1. Kelompokkan FAQ berdasarkan kategori
      final Map<String, List<dynamic>> groupedFaqs = {};
      for (var item in items) {
        // Fallback ke 'Umum' jika category null
        final cat = item.category ?? 'Umum'; 
        if (!groupedFaqs.containsKey(cat)) {
          groupedFaqs[cat] = [];
        }
        groupedFaqs[cat]!.add(item);
      }

      // 2. Render List Kategori
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: groupedFaqs.keys.length,
        itemBuilder: (context, index) {
          final categoryName = groupedFaqs.keys.elementAt(index);
          final categoryItems = groupedFaqs[categoryName]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header Kategori ---
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4),
                child: Text(
                  categoryName,
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.primary,
                  ),
                ),
              ),
              
              // --- List FAQ dalam Kategori ---
              Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
                ),
                clipBehavior: Clip.antiAlias, // Agar ujung Card melengkung rapi
                child: Column(
                  children: categoryItems.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    final isLast = i == categoryItems.length - 1;

                    return Column(
                      children: [
                        ExpansionTile(
                          title: Text(
                            item.q,
                            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          expandedCrossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.a,
                              style: tt.bodyMedium?.copyWith(
                                height: 1.5, 
                                color: cs.onSurfaceVariant
                              ),
                            ),
                          ],
                        ),
                        // Garis pembatas antar item (tidak ditampilkan di item terakhir)
                        if (!isLast)
                          Divider(height: 1, color: cs.outlineVariant.withOpacity(0.5)),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
            ],
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Bantuan / FAQ')),
      body: RefreshIndicator(
        onRefresh: () => p.fetchFaq(force: true),
        child: body(),
      ),
    );
  }
}
