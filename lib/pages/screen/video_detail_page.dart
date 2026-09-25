/* ======================= VIDEO DETAIL PAGE ======================= */

import 'package:cuan_app/config/app_routes.dart';
import 'package:cuan_app/data/model/lesson.dart';
import 'package:cuan_app/data/model/vbl_models.dart';
import 'package:cuan_app/providers/vbl_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VideoDetailPage extends StatefulWidget {
  const VideoDetailPage({required this.lesson, required this.playlistId});

  final Lesson lesson;
  final String playlistId;

  @override
  State<VideoDetailPage> createState() => _VideoDetailPageState();
}

class _VideoDetailPageState extends State<VideoDetailPage> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // fetch detail playlist (judul, deskripsi, daftar video)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vbl = context.read<VblProvider>();
      vbl.fetchDetail(widget.playlistId);
      vbl.fetchPlaylistProgress(widget.playlistId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;

    final vbl = context.watch<VblProvider>();
    final VblPlaylistDetailResponse? d = vbl.detail;
    final loading = vbl.loadingDetail;
    final error = vbl.errDetail;

    // Progress demo – nanti bisa ambil dari /vbl/progress/latest (opsional)

    final playlistProgress = vbl.playlistProgressData;
    double progress = 0.0;
    bool completed = false;

    if (playlistProgress != null &&
        playlistProgress.playlistId == widget.playlistId) {
      progress = (playlistProgress.overallPct / 100.0).clamp(0.0, 1.0);
      completed =
          playlistProgress.totalVideos > 0 &&
          playlistProgress.completedVideos == playlistProgress.totalVideos;
    }
    if (loading && d == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (error != null && d == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error, style: TextStyle(color: cs.error)),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () =>
                    context.read<VblProvider>().fetchDetail(widget.playlistId),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final title = d?.title ?? widget.lesson.title;
    final desc = d?.description ?? '';
    final parts = d?.videos ?? const <VblPlaylistVideoItem>[];

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ================= Header (cover + judul dari API) =================
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(widget.lesson.cover, fit: BoxFit.cover),
                    DecoratedBox(
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
                  ],
                ),
              ),
              Positioned(
                left: 12,
                top: 12 + MediaQuery.of(context).padding.top,
                child: Material(
                  color: Colors.white.withOpacity(.9),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.of(context).maybePop(),
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.arrow_back),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 12,
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          // ================= Progress Row =================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  '${(progress * 100).round()}%',
                  style: t.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    completed ? 'Completed' : 'In Progress',
                    style: t.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: cs.surfaceContainerHighest,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '#${parts.length} Part Video',
                    style: t.textTheme.labelLarge?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: cs.surfaceContainerHighest,
                  shape: const CircleBorder(),
                  child: IconButton.filledTonal(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.listVideo,
                        arguments: {
                          'lesson': widget.lesson,
                          'playlistId': widget.playlistId,
                        },
                      );
                    },
                    icon: const Icon(Icons.list_alt),
                    tooltip: 'List video',
                  ),
                ),
              ],
            ),
          ),

          // ================= Description (dari API) =================
          if (desc.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Description',
                style: t.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                desc,
                style: t.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withOpacity(.9),
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],

          // ================= All Part (dari API) =================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'All Part',
              style: t.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 280,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: parts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _PartCard(
                v: parts[i],
                cover: parts[i].thumbnail ?? widget.lesson.cover,
                tag: widget.lesson.tag,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.lessons,
                    arguments: {
                      'lesson': widget.lesson, // untuk UI player
                      'part': parts[i].sequence, // urutan
                      'playlistId': widget.playlistId, // penting
                      'videoId': parts[i].videoId, // penting
                      // kalau punya durasi/progress, bisa ikutkan:
                      'duration': Duration(seconds: parts[i].duration),
                      // 'position': Duration(seconds: ...from progress...),
                    },
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

class _PartCard extends StatelessWidget {
  const _PartCard({
    required this.v,
    required this.cover,
    required this.tag,
    required this.onTap,
  });

  final VblPlaylistVideoItem v;
  final String cover;
  final String tag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          width: 158,
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
                Positioned.fill(child: Image.network(cover, fit: BoxFit.cover)),
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
                // tag/level (opsional)
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
                      tag,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                // judul
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Part ${v.sequence} | ${v.title}',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          height: 1.2,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _fmtDuration(v.duration),
                        style: TextStyle(
                          color: Colors.white.withOpacity(.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
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

String _fmtDuration(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  if (h > 0) return '${h}h${m.toString().padLeft(2, '0')}m';
  return '${m}m${s.toString().padLeft(2, '0')}s';
}
