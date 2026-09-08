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

class _ModulPageState extends State<ModulPage> {
  final _allCtrl = PageController(viewportFraction: .90);
  final _cryptoCtrl = PageController(viewportFraction: .90);

  static const _prefKeyReadme = 'modul_readme_v1';

  String _kategori = 'Semua';
  String _tingkat = 'Semua';

  final List<Lesson> _all = List.generate(12, (i) {
    return Lesson(
      title: [
        'Trading Made Simple: Understand Crypto in 10 Minutes',
        'Crypto vs. Stock Market: Which One Should You Trade?',
        'The Future of Trading: AI, Crypto, and You',
        'Risk Management 101 for New Traders',
        'Swing Trading Basics for Busy People',
      ][i % 5],
      cover: [
        'https://images.unsplash.com/photo-1640340434856-1f2f4d6e83ea?q=80&w=1600&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1553729784-e91953dec042?q=80&w=1600&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1559526324-593bc073d938?q=80&w=1600&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1551281044-8ed89f2b2ba6?q=80&w=1600&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1518779578993-ec3579fee39f?q=80&w=1600&auto=format&fit=crop',
      ][i % 5],
      tag: i.isEven ? 'Live Class' : 'Recorded',
      level: ['Semua', 'Dasar', 'Menengah', 'Lanjutan'][i % 4],
      category: ['Semua', 'Crypto', 'Saham', 'Teknikal'][i % 4],
    );
  });

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowReadme();
      context.read<VblProvider>().fetchPlaylists();
    });
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

  @override
  void dispose() {
    _allCtrl.dispose();
    _cryptoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final t = Theme.of(context);
    // // final cs = t.colorScheme;

    // final filtered = _all.where((e) {
    //   final okKat = _kategori == 'Semua' || e.category == _kategori;
    //   final okLvl = _tingkat == 'Semua' || e.level == _tingkat;
    //   return okKat && okLvl;
    // }).toList();

    // final hero = filtered.isNotEmpty ? filtered.first : _all.first;
    // final rest = filtered.skip(1).toList();

    // final crypto = _all.where((e) => e.category == 'Crypto').toList();

    // final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context);
    final cs = t.colorScheme;

    final vbl = context.watch<VblProvider>();
    final items = vbl.playlists ?? const <VblPlaylistItem>[];

    // loading & error state
    if (vbl.loadingList && items.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (vbl.errList != null && items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Video Edukasi Saham')),

        body: Center(
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
        ),
      );
    }

    // ----- adaptasi filter lokal (opsional, tergantung kebutuhan UI lama)
    final filtered = items.where((e) {
      final okKat = _kategori == 'Semua' || e.category == _kategori;
      final okLvl = _tingkat == 'Semua' || e.level == _tingkat;
      return okKat && okLvl;
    }).toList();

    if (filtered.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Video Edukasi Saham')),
        body: const Center(child: Text('Belum ada playlist')),
      );
    }

    final hero = filtered.first;
    final rest = filtered.skip(1).toList();
    final crypto = items.where((e) => e.category == 'Crypto').toList();

    final double cardHeight = 280; // tinggi kartu
    final double cardWidth = cardHeight * 9 / 16; // 9:16 portrait

    // tinggi hero 16:9 berdasarkan lebar konten (lebar layar - padding kiri/kanan 16)
    final double contentWidth = MediaQuery.sizeOf(context).width - 32;
    final double heroHeight = contentWidth * 9 / 16;
    
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 16,
        title: Text(
          'Video Edukasi Saham',
          style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.star_border)),

          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'reset_readme') {
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
      body: CustomScrollView(
        slivers: [
          // === Kontrol (Readme, History, Filter) — DIPIN ===
          
          SliverPersistentHeader(
            pinned: true,
            delegate: _PinnedControlsDelegate(
              height: 64, // sesuaikan: 56–64 biasanya pas
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
                    items: const [
                      'Dasar Saham',
                      'Teknikal',
                      'Fundamental',
                      'Makroekonomi',
                    ],
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
          const SliverToBoxAdapter(child: SizedBox(height: 14)),

          // HERO yang DIPIN (sliver sendiri, BUKAN di dalam Row)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverPersistentHeader(
              pinned: true,
              delegate: _PinnedHeroDelegate(
                minExtentHeight: heroHeight,
                maxExtentHeight: heroHeight,
                child: _HeroVbl(item: hero),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // Judul "All Classes"
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

          // List horizontal "All Classes"
          SliverToBoxAdapter(
            child: SizedBox(
              height: cardHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                // penting saat nested scroll:
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

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // Judul "Crypto Trading"
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Crypto Trading',
                style: t.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),

          // List horizontal "Crypto Trading"
          SliverToBoxAdapter(
            child: SizedBox(
              height: cardHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                primary: false,
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: crypto.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => SizedBox(
                  width: cardWidth,
                  child: _VblCard(item: crypto[i]),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 90)),
        ],
      ),
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
    return PopupMenuButton<String>(
      onSelected: onSelected,
      itemBuilder: (_) =>
          items.map((e) => PopupMenuItem(value: e, child: Text(e))).toList(),
      offset: const Offset(0, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: .5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
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

class _HeroLesson extends StatelessWidget {
  final Lesson lesson;
  const _HeroLesson({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.videoDetail,
            arguments: lesson,
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
                        Colors.black.withValues(alpha: .15),
                        Colors.black.withValues(alpha: .55),
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
                        color: cs.primary.withValues(alpha: .88),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        lesson.tag,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      lesson.title,
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

class _LessonCard extends StatelessWidget {
  final Lesson lesson;
  const _LessonCard({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.videoDetail,
            arguments: lesson, // kirim Lesson langsung
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: .6)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // >>> portrait 9:16
                const AspectRatio(
                  aspectRatio: 9 / 16,
                  child: SizedBox.expand(),
                ),
                Positioned.fill(
                  child: Image.network(lesson.cover, fit: BoxFit.cover),
                ),

                // overlay supaya teks kebaca
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: .10),
                          Colors.black.withValues(alpha: .55),
                        ],
                      ),
                    ),
                  ),
                ),

                // tag kiri-atas
                Positioned(
                  left: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: .9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      lesson.tag,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                // title kiri-bawah
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 10,
                  child: Text(
                    lesson.title,
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

class _HeroVbl extends StatelessWidget {
  final VblPlaylistItem item;
  const _HeroVbl({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // bikin “Lesson-like” hanya untuk UI (judul/cover/tag)
    final lesson = Lesson(
      title: item.title,
      cover: item.thumbnail ?? 'https://placehold.co/1200x675?text=Playlist',
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
                        item.level ?? 'Playlist',
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
      cover: item.thumbnail ?? 'https://placehold.co/450x800?text=Playlist',
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
            arguments: {
              'lesson': lesson,
              'playlistId': item.playlistId, // 👉 penting
            },
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

class _PinnedHeroDelegate extends SliverPersistentHeaderDelegate {
  final double minExtentHeight;
  final double maxExtentHeight;
  final Widget child;

  _PinnedHeroDelegate({
    required this.minExtentHeight,
    required this.maxExtentHeight,
    required this.child,
  });

  @override
  double get minExtent => minExtentHeight;

  @override
  double get maxExtent => maxExtentHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      // biar elevation/inkwell tetap oke
      color: Colors.transparent,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedHeroDelegate oldDelegate) {
    return minExtentHeight != oldDelegate.minExtentHeight ||
        maxExtentHeight != oldDelegate.maxExtentHeight ||
        child != oldDelegate.child;
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
