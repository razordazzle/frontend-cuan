import 'dart:async';

import 'package:cuan_app/config/app_routes.dart';
import 'package:cuan_app/data/model/lesson.dart';
import 'package:cuan_app/data/model/vbl_models.dart';
import 'package:cuan_app/pages/screen/readme_page.dart';
import 'package:cuan_app/pages/screen/video_history_page.dart';
import 'package:cuan_app/providers/vbl_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ModulPage extends StatefulWidget {
  const ModulPage({super.key});
  @override
  State<ModulPage> createState() => _ModulPageState();
}

String _coverOrPlaceholder(String url, String placeholder) {
  final u = url.trim();
  return (u.startsWith('http://') || u.startsWith('https://'))
      ? u
      : placeholder;
}

class _ModulPageState extends State<ModulPage> {
  static const _prefKeyReadme = 'modul_readme_v1';

  String _kategori = 'Semua';
  String _tingkat = 'Semua';
  // search
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowReadme();
      context.read<VblProvider>().fetchPlaylists();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _maybeShowReadme() async {
    final sp = await SharedPreferences.getInstance();
    if (sp.getBool(_prefKeyReadme) ?? false) return;
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const ReadmePage(
          prefKey: _prefKeyReadme,
          popInsteadOfReplace: true,
        ),
      ),
    );
  }

  Future<void> _resetReadmeFlag() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove('modul_readme_v1');
  }

  void _openReadme() {
    Navigator.pushNamed(
      context,
      AppRoutes.readme,
      arguments: {'prefKey': 'modul_readme_v1', 'popInsteadOfReplace': true},
    );
  }

  void _openHistory() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const VideoHistoryPage()));
  }

  void _toggleSearch() {
    setState(() {
      if (_isSearching) {
        _isSearching = false;
        _searchController.clear();
        context.read<VblProvider>().clearSearch();
      } else {
        _isSearching = true;
      }
    });
  }

  void _onSearchChanged(String query) {
    setState(() {}); // rebuild segera biar body switch ke mode search/normal
    _searchDebounce?.cancel();
    final q = query.trim();
    if (q.isEmpty) {
      context.read<VblProvider>().clearSearch();
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      context.read<VblProvider>().searchPlaylists(q);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;

    final vbl = context.watch<VblProvider>();
    final isSearchMode =
        _isSearching && _searchController.text.trim().isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 16,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Cari playlist...',
                  border: InputBorder.none,
                ),
                style: t.textTheme.titleMedium,
                onChanged: _onSearchChanged,
              )
            : Text(
                'Video Edukasi Saham',
                style: t.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'show_readme') {
                _openReadme();
              } else if (v == 'reset_readme') {
                await _resetReadmeFlag();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Flag Readme di-reset. Buka tab ini lagi untuk melihat Readme.',
                    ),
                  ),
                );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'show_readme',
                child: Text('Tampilkan Readme sekarang'),
              ),
              PopupMenuItem(
                value: 'reset_readme',
                child: Text('Reset Readme (debug)'),
              ),
            ],
          ),
          const SizedBox(width: 6),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(8),
          child: Divider(
            height: 1,
            thickness: 1,
            color: cs.outline.withValues(alpha: .12),
          ),
        ),
      ),
      body: isSearchMode
          ? _buildSearchBody(vbl, cs, t)
          : _buildMainBody(vbl, cs, t),
    );
  }

  // ======================= MODE: SEARCH =======================
  Widget _buildSearchBody(VblProvider vbl, ColorScheme cs, ThemeData t) {
    final results = vbl.searchResults ?? const <VblPlaylistItem>[];
    final loading = vbl.loadingSearch && results.isEmpty;
    final error = vbl.errSearch;

    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null && results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error, style: TextStyle(color: cs.error)),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () =>
                  vbl.searchPlaylists(_searchController.text.trim()),
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }
    if (results.isEmpty) {
      return const Center(child: Text('Tidak ada playlist yang cocok'));
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.62,
      ),
      itemCount: results.length + (vbl.searchNextCursor != null ? 1 : 0),
      itemBuilder: (context, i) {
        if (i >= results.length) {
          if (!vbl.loadingMoreSearch) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<VblProvider>().loadMoreSearchResults(
                _searchController.text.trim(),
              );
            });
          }
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(),
            ),
          );
        }
        return _VblCard(item: results[i]);
      },
    );
  }

  // ======================= MODE: NORMAL (Hero + sections) =======================
  Widget _buildMainBody(VblProvider vbl, ColorScheme cs, ThemeData t) {
    final items = vbl.playlists ?? const <VblPlaylistItem>[];

    if (vbl.loadingList && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vbl.errList != null && items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(vbl.errList!, style: TextStyle(color: cs.error)),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => context.read<VblProvider>().fetchPlaylists(),
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }

    final filtered = items.where((e) {
      final okKat = _kategori == 'Semua' || e.category == _kategori;
      final okLvl = _tingkat == 'Semua' || e.level == _tingkat;
      return okKat && okLvl;
    }).toList();

    final rest = filtered.skip(1).toList();
    final fundamental = items
        .where((e) => e.category == 'Fundamental')
        .toList();

    final double cardHeight = 280;
    final double cardWidth = cardHeight * 9 / 16;
    final double contentWidth = MediaQuery.sizeOf(context).width - 32;
    final double heroHeight = contentWidth * 9 / 16;

    return CustomScrollView(
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _PinnedControlsDelegate(
            height: 64,
            child: Row(
              children: [
                _TinyAction(
                  icon: Icons.info_outline,
                  tooltip: 'Readme',
                  onTap: _openReadme,
                ),
                const SizedBox(width: 8),
                _TinyAction(
                  icon: Icons.history,
                  tooltip: 'Riwayat',
                  onTap: _openHistory,
                ),
                const Spacer(),
                _FilterMenu(
                  label: 'Kategori',
                  value: _kategori,
                  items: const ['Dasar', 'Teknikal', 'Fundamental', 'Makro'],
                  onSelected: (v) => setState(() => _kategori = v),
                ),
                const SizedBox(width: 10),
                _FilterMenu(
                  label: 'Tingkat',
                  value: _tingkat,
                  items: const ['Beginner', 'Intermediate', 'Advanced'],
                  onSelected: (v) => setState(() => _tingkat = v),
                ),
              ],
            ),
          ),
        ),

        if (filtered.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Belum ada playlist yang cocok'),
                  if (vbl.nextCursor != null) ...[
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => vbl.loadMorePlaylists(),
                      child: vbl.loadingMoreList
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Coba muat lebih banyak'),
                    ),
                  ],
                ],
              ),
            ),
          )
        else ...[
          const SliverToBoxAdapter(child: SizedBox(height: 14)),

          // HERO — TIDAK pinned lagi, ikut scroll natural
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: SizedBox(
                height: heroHeight,
                child: _HeroVbl(item: filtered.first),
              ),
            ),
          ),

          if (rest.isNotEmpty) ...[
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'All Classes',
                  style: t.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 10)),
            SliverToBoxAdapter(
              child: SizedBox(
                height: cardHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  primary: false,
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: rest.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => SizedBox(
                    width: cardWidth,
                    child: _VblCard(item: rest[i]),
                  ),
                ),
              ),
            ),
          ],

          if (fundamental.isNotEmpty) ...[
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Fundamental',
                  style: t.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 10)),
            SliverToBoxAdapter(
              child: SizedBox(
                height: cardHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  primary: false,
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: fundamental.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => SizedBox(
                    width: cardWidth,
                    child: _VblCard(item: fundamental[i]),
                  ),
                ),
              ),
            ),
          ],

          // FOOTER LOAD MORE — nambah lebih banyak playlist dari server
          if (vbl.nextCursor != null) ...[
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(
              child: Center(
                child: vbl.loadingMoreList
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(),
                      )
                    : OutlinedButton(
                        onPressed: () => vbl.loadMorePlaylists(),
                        child: const Text('Muat lebih banyak playlist'),
                      ),
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 90)),
        ],
      ],
    );
  }
}
/* ======================= COMPONENTS ======================= */

class _TinyAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _TinyAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 18, color: cs.onSurface),
        ),
      ),
    );
  }
}

class _FilterMenu extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onSelected;
  const _FilterMenu({
    required this.label,
    required this.value,
    required this.items,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final active = value != 'Semua';
    return PopupMenuButton<String>(
      onSelected: onSelected,
      itemBuilder: (_) => [
        'Semua',
        ...items,
      ].map((e) => PopupMenuItem(value: e, child: Text(e))).toList(),
      offset: const Offset(0, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: active
              ? cs.primary.withValues(alpha: .12)
              : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? cs.primary
                : cs.outlineVariant.withValues(alpha: .5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              active ? value : label,
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.keyboard_arrow_down, color: cs.onSurface),
          ],
        ),
      ),
    );
  }
}

class _HeroVbl extends StatelessWidget {
  final VblPlaylistItem item;
  const _HeroVbl({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // bikin “Lesson-like” hanya untuk UI (judul/cover/tag)
    final lesson = Lesson(
      title: item.title,
      cover: _coverOrPlaceholder(
        item.thumbnail,
        'https://placehold.co/1200x675?text=Playlist',
      ),
      tag: item.category, // pakai kategori sebagai tag
      level: item.level, // opsional
      category: item.category, // opsional
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.videoDetail,
            arguments: {
              'lesson': lesson, // untuk UI
              'playlistId': item.playlistId, // 👉 penting untuk API selanjutnya
            },
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              const AspectRatio(aspectRatio: 16 / 9, child: SizedBox.expand()),
              Positioned.fill(
                child: Image.network(lesson.cover, fit: BoxFit.cover),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(.15),
                        Colors.black.withOpacity(.55),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(.88),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.level,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VblCard extends StatelessWidget {
  final VblPlaylistItem item;
  const _VblCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lesson = Lesson(
      title: item.title,
      cover: _coverOrPlaceholder(
        item.thumbnail,
        'https://placehold.co/450x800?text=Playlist',
      ),
      tag: item.category,
      level: item.level,
      category: item.category,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.videoDetail,
            arguments: {'lesson': lesson, 'playlistId': item.playlistId},
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant.withOpacity(.6)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                const AspectRatio(
                  aspectRatio: 9 / 16,
                  child: SizedBox.expand(),
                ),
                Positioned.fill(
                  child: Image.network(lesson.cover, fit: BoxFit.cover),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(.10),
                          Colors.black.withOpacity(.55),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 10,
                  child: Text(
                    item.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      height: 1.2,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PinnedControlsDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;
  _PinnedControlsDelegate({required this.height, required this.child});

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface, // background biar nutup konten di bawahnya
      elevation: overlapsContent ? 2 : 0, // kasih bayangan saat nempel konten
      child: SafeArea(
        top: false, // AppBar sudah handle top inset
        bottom: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: child, // Row kontrol
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedControlsDelegate oldDelegate) =>
      height != oldDelegate.height || child != oldDelegate.child;
}
