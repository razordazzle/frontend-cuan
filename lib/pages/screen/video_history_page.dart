import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cuan_app/providers/vbl_provider.dart';
import 'package:cuan_app/data/model/vbl_models.dart';
import 'package:cuan_app/data/model/lesson.dart';
import 'package:cuan_app/config/app_routes.dart';

class VideoHistoryPage extends StatefulWidget {
  const VideoHistoryPage({super.key});

  @override
  State<VideoHistoryPage> createState() => _VideoHistoryPageState();
}

class _VideoHistoryPageState extends State<VideoHistoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VblProvider>().fetchHistory(refresh: true);
    });
  }

  Future<void> _onRefresh() async {
    await context.read<VblProvider>().fetchHistory(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final p = context.watch<VblProvider>();

    final loading = p.loadingHistory && p.histories.isEmpty;
    final err = p.errHistory;
    // kalau backend belum sort, kita sort desc by updatedAt di UI
    final items = [...p.histories]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Baru Ditonton'),
        centerTitle: false,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : err != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(err, style: TextStyle(color: cs.error)),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => p.fetchHistory(refresh: true),
                        child: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                )
              : items.isEmpty
                  ? const Center(child: Text('Belum ada riwayat video'))
                  : RefreshIndicator(
                      onRefresh: _onRefresh,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: items.length + 1, // footer "muat lagi"
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          if (i < items.length) {
                            final h = items[i];
                            return _HistoryRow(item: h);
                          }
                          // footer
                          if (p.historyExhausted) return const SizedBox.shrink();
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: p.loadingHistory
                                  ? const CircularProgressIndicator()
                                  : OutlinedButton(
                                      onPressed: () => p.loadMoreHistory(limit: 30),
                                      child: const Text('Muat lebih banyak'),
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final VblHistoryItem item;
  const _HistoryRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;

    // bikin Lesson “dummy” untuk dipakai di UI/route berikutnya (mirip VideoListPage)
    final lesson = Lesson(
      title: item.playlistTitle,
      cover: item.thumbnail ?? 'https://placehold.co/1200x675?text=Playlist',
      tag: 'Recorded',        // opsional (tak dipakai di halaman list)
      level: 'Semua',
      category: 'Semua',
    );

    final progress = (item.progressPct.clamp(0, 100)) / 100.0;
    final sequence = item.sequence; // “Part n”
    final duration = _fmtDuration(item.duration);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.lessons,
          arguments: {
            'lesson': lesson,
            'part': sequence,
            'playlistId': item.playlistId,
            'videoId': item.videoId,
            // kalau punya position, bisa kirim di sini
            // 'position': Duration(seconds: (progress * item.duration).round()),
            // 'duration': Duration(seconds: item.duration),
          },
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // thumbnail + overlay + badge + progress tipis (merah) di bawah
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 120,
              height: 72,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(lesson.cover, fit: BoxFit.cover),
                  Container(color: Colors.black.withOpacity(.25)),
                  const Center(
                    child: Icon(Icons.play_arrow_rounded, size: 36, color: Colors.white),
                  ),
                  // badge “Sudah Ditonton”
                  if (item.isCompleted)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest.withOpacity(.85),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Sudah Ditonton',
                          style: t.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                    ),
                  // progress bar tipis di bawah (pakai warna error/merah biar mirip prototipe)
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: FractionallySizedBox(
                      widthFactor: progress <= 0 ? 0.02 : progress, // tetap nampak dikit
                      child: Container(height: 4, color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Title: "Part n | Judul Video"
          Expanded(
            child: RichText(
              text: TextSpan(
                style: t.textTheme.titleSmall?.copyWith(
                  color: cs.onSurface,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                ),
                children: [
                  TextSpan(
                    text: 'Part $sequence ',
                    style: TextStyle(
                      color: cs.primary,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const TextSpan(text: '| '),
                  TextSpan(text: item.videoTitle),
                ],
              ),
            ),
          ),

          // durasi kecil di kanan
          const SizedBox(width: 8),
          Text(
            duration,
            style: t.textTheme.labelMedium?.copyWith(
              color: cs.onSurface.withOpacity(.7),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

String _fmtDuration(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  if (h > 0) return '${h}h${m.toString().padLeft(2, '0')}m';
  return '${m}m${s.toString().padLeft(2, '0')}s';
}
