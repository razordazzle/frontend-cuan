import 'package:cuan_app/pages/screen/research_content_page.dart';
import 'package:cuan_app/providers/journals_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ====== MODEL dari API (pastikan path ini sesuai punyamu) ======
import 'package:cuan_app/data/model/journal_models.dart';

class ResearchPage extends StatefulWidget {
  const ResearchPage({super.key});

  @override
  State<ResearchPage> createState() => _ResearchPageState();
}

enum _TabCat { all, research, knowledges }

class _ResearchPageState extends State<ResearchPage> {
  final _searchCtrl = TextEditingController();
  _TabCat _tab = _TabCat.all;

  // ganti ini sesuai status user sebenarnya (atau ambil dari provider kalau ada)
  final bool _isSubscriber = false;

  // simple bookmark storage by journalId
  final Map<String, bool> _bookmarks = {};

  static String _mon(int m) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m - 1];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JournalsProvider>().fetchList(); // default: all, latest
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Map data API (JournalListItem) -> UI card (ResearchItem) + apply filter
  List<ResearchItem> _filteredItems(
    List<JournalListItem> src, {
    bool? premium, // true=premium only, false=free only, null=all
  }) {
    final q = _searchCtrl.text.trim().toLowerCase();

    final mapped = src.map((j) {
      final cat = j.type == 'research' ? 'Research' : 'Knowledges';
      return ResearchItem(
        id: j.journalId,
        title: j.title,
        cover:
            j.thumbnailUrl ??
            'https://images.unsplash.com/photo-1559526324-593bc073d938?q=80&w=1600&auto=format&fit=crop',
        category: cat,
        publishedAt: j.publishedAt,
        duration: const Duration(minutes: 30), // API tdk ada durasi → dummy
        isPremium: j.isPaid,
        isBookmarked: _bookmarks[j.journalId] ?? false,
      );
    }).toList();

    return mapped.where((e) {
      final okTab = switch (_tab) {
        _TabCat.all => true,
        _TabCat.research => e.category == 'Research',
        _TabCat.knowledges => e.category == 'Knowledges',
      };
      final okPrem = premium == null ? true : (e.isPremium == premium);
      final okQ =
          q.isEmpty ||
          e.title.toLowerCase().contains(q) ||
          e.category.toLowerCase().contains(q);
      return okTab && okPrem && okQ;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;

    final jp = context.watch<JournalsProvider>();
    final loading = jp.loadingList;
    final err = jp.errList;
    final list = jp.items ?? const <JournalListItem>[];

    if (loading && list.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Research & Reading Corner')),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (err != null && list.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Research & Reading Corner')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(err, style: TextStyle(color: cs.error)),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => context.read<JournalsProvider>().fetchList(),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final all = _filteredItems(list);
    final free = _filteredItems(list, premium: false);
    final premium = _filteredItems(list, premium: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Research & Reading Corner'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // Search
          TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search Here',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: cs.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(32),
                borderSide: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: .5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(32),
                borderSide: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: .5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(32),
                borderSide: BorderSide(color: cs.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 16),

          // Tabs
          Row(
            children: [
              _TabChip(
                label: 'All',
                selected: _tab == _TabCat.all,
                onTap: () => setState(() => _tab = _TabCat.all),
              ),
              const SizedBox(width: 18),
              _TabChip(
                label: 'Research',
                selected: _tab == _TabCat.research,
                onTap: () => setState(() => _tab = _TabCat.research),
              ),
              const SizedBox(width: 18),
              _TabChip(
                label: 'Knowledges',
                selected: _tab == _TabCat.knowledges,
                onTap: () => setState(() => _tab = _TabCat.knowledges),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // All Classes
          const _SectionTitle('All Classes'),
          const SizedBox(height: 8),
          _HList(
            items: all,
            isSubscriber: _isSubscriber,
            onToggleBookmark: (item) => setState(() {
              final now = !(_bookmarks[item.id] ?? false);
              _bookmarks[item.id] = now;
            }),
            onOpen: (item) async {
              // === HOOK DETAIL/PREVIEW DARI PROVIDER ===
              // Kalau sudah implement JournalsProvider.detail/preview:
              // try {
              //   final detail = await context.read<JournalsProvider>().fetchDetail(item.id);
              //   if (!context.mounted) return;
              //   Navigator.of(context).push(MaterialPageRoute(
              //     builder: (_) => ResearchContentPage(
              //       item: item,
              //       index: 1,
              //       total: 1,
              //       isSubscriber: true,
              //       content: detail.contentMd,
              //     ),
              //   ));
              // } on JournalPaywalled catch (e) {
              //   if (!context.mounted) return;
              //   Navigator.of(context).push(MaterialPageRoute(
              //     builder: (_) => ResearchContentPage(
              //       item: item,
              //       index: 1, total: 1,
              //       isSubscriber: false,
              //       content: e.preview,
              //     ),
              //   ));
              // }
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ResearchContentPage(
                    item: item,
                    index: 1,
                    total: all.length,
                    isSubscriber: _isSubscriber && !item.isPremium,
                    // content: ... // isi dari provider kalau mau
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 18),

          // Free
          const _SectionTitle('Free'),
          const SizedBox(height: 8),
          _HList(
            items: free,
            isSubscriber: _isSubscriber,
            onToggleBookmark: (item) => setState(() {
              final now = !(_bookmarks[item.id] ?? false);
              _bookmarks[item.id] = now;
            }),
            onOpen: (item) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ResearchContentPage(
                    item: item,
                    index: 1,
                    total: free.length,
                    isSubscriber: true, // free selalu terbuka
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 18),

          // Premium
          const _SectionTitle('Premium'),
          const SizedBox(height: 8),
          _HList(
            items: premium,
            isSubscriber: _isSubscriber,
            onToggleBookmark: (item) => setState(() {
              final now = !(_bookmarks[item.id] ?? false);
              _bookmarks[item.id] = now;
            }),
            onOpen: (item) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ResearchContentPage(
                    item: item,
                    index: 1,
                    total: premium.length,
                    isSubscriber:
                        _isSubscriber, // kalau bukan subscriber → terkunci
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 90),
        ],
      ),
    );
  }
}

/* ======================= GRID & CARD ======================= */

const double kResearchCardHeight = 280; // sama seperti Modul
const double kResearchCardAspect = 9 / 16; // portrait
const double kResearchCardWidth = kResearchCardHeight * kResearchCardAspect;

class _HList extends StatelessWidget {
  const _HList({
    required this.items,
    required this.onToggleBookmark,
    required this.isSubscriber,
    required this.onOpen,
  });

  final List<ResearchItem> items;
  final ValueChanged<ResearchItem> onToggleBookmark;
  final bool isSubscriber;
  final ValueChanged<ResearchItem> onOpen;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'No result',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return SizedBox(
      height: kResearchCardHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) => SizedBox(
          width: kResearchCardWidth,
          child: _ResearchCard(
            item: items[i],
            caption: items[i].category,
            onBookmark: () => onToggleBookmark(items[i]),
            onTap: () => onOpen(items[i]),
          ),
        ),
      ),
    );
  }
}

class _ResearchCard extends StatelessWidget {
  const _ResearchCard({
    required this.item,
    required this.onBookmark,
    required this.onTap,
    required this.caption,
  });

  final ResearchItem item;
  final VoidCallback onBookmark;
  final VoidCallback onTap;
  final String caption;

  String _meta(DateTime dt, Duration dur) {
    final mon = _ResearchPageState._mon(dt.month);
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final durMin = dur.inMinutes.remainder(60).toString().padLeft(2, '0');
    final durSec = (dur.inSeconds % 60).toString().padLeft(2, '0');
    return '$mon $d, $hh:$mm | 00:$durMin:$durSec';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: .6)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                const AspectRatio(
                  aspectRatio: kResearchCardAspect,
                  child: SizedBox.expand(),
                ),
                Positioned.fill(
                  child: Image.network(item.cover, fit: BoxFit.cover),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: .08),
                          Colors.black.withValues(alpha: .55),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Row(
                    children: [
                      if (item.isPremium)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: .35),
                            shape: BoxShape.circle,
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(
                              Icons.workspace_premium_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      const SizedBox(width: 6),
                      Material(
                        color: Colors.black.withValues(alpha: .35),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onBookmark,
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              item.isBookmarked
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .95),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          height: 1.2,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _meta(item.publishedAt, item.duration),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .85),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                        ),
                      ),
                    ],
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

/* ======================= TABS & SECTION ======================= */

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: selected ? cs.primary : cs.onSurface.withValues(alpha: .8),
            ),
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: selected ? 24 : 0,
            height: 3,
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    return Text(
      text,
      style: t.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: cs.onSurface,
        height: 1.1,
      ),
    );
  }
}

/* ======================= MODEL (UI) ======================= */

class ResearchItem {
  ResearchItem({
    required this.id,
    required this.title,
    required this.cover,
    required this.category,
    required this.publishedAt,
    required this.duration,
    required this.isPremium,
    this.isBookmarked = false,
  });

  String id;
  String title;
  String cover;
  String category; // 'Research' | 'Knowledges'
  DateTime publishedAt;
  Duration duration;
  bool isPremium;
  bool isBookmarked;
}
