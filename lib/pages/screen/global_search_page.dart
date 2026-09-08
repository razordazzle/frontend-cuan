// lib/pages/screen/global_search_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cuan_app/providers/search_provider.dart';
import 'package:cuan_app/data/model/search_models.dart';
import 'package:cuan_app/config/app_routes.dart';
import 'package:cuan_app/data/model/lesson.dart'; // utk navigasi playlist (UI reuse)

class GlobalSearchPage extends StatelessWidget {
  const GlobalSearchPage({super.key, this.defaultTypes});
  final String? defaultTypes; // mis: 'stock|journal|playlist'

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SearchProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              autofocus: true,
              onChanged: (v) => context
                  .read<SearchProvider>()
                  .search(v, type: defaultTypes, limit: 15),
              decoration: InputDecoration(
                hintText: 'Cari saham, jurnal, playlist…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(32),
                  borderSide: BorderSide(color: cs.outlineVariant),
                ),
              ),
            ),
          ),
          if (p.loading) const LinearProgressIndicator(),
          if (p.error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(p.error!, style: TextStyle(color: cs.error)),
            ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: p.results.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final r = p.results[i];
                final icon = switch (r.type) {
                  SearchKind.stock => Icons.trending_up,
                  SearchKind.journal => Icons.menu_book_rounded,
                  SearchKind.playlist => Icons.playlist_play,
                };
                final subtitle = switch (r.type) {
                  SearchKind.stock => r.ticker ?? '',
                  SearchKind.journal => 'Journal',
                  SearchKind.playlist => 'Playlist',
                };
                return ListTile(
                  leading: Icon(icon, color: cs.primary),
                  title: Text(r.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(subtitle),
                  onTap: () {
                    switch (r.type) {
                      case SearchKind.stock:
                        // contoh navigasi ke KeyStatistics / Stock Detail
                        Navigator.pushNamed(context, AppRoutes.keyStats,
                            arguments: {'ticker': r.ticker ?? ''});
                        break;
                      case SearchKind.journal:
                        // buka detail journal: gunakan ResearchContentPage
                        // biasanya kamu fetch detail di provider dulu;
                        // di sini langsung navigasi ke page yang akan fetch sendiri
                        Navigator.of(context).pushNamed(
                          '/journal_detail', // jika ada rute khususmu
                          arguments: {'journalId': r.id},
                        );
                        break;
                      case SearchKind.playlist:
                        // buka VideoDetail/List dari playlist
                        // kita buat Lesson dummy hanya untuk tampilan cover/judul
                        final lesson = Lesson(
                          title: r.title,
                          cover: 'https://placehold.co/1200x675?text=Playlist',
                          tag: 'Playlist',
                          level: 'Semua',
                          category: 'Semua',
                        );
                        Navigator.pushNamed(
                          context,
                          AppRoutes.videoDetail,
                          arguments: {
                            'lesson': lesson,
                            'playlistId': r.id!,
                          },
                        );
                        break;
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
