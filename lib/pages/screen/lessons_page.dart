import 'package:cuan_app/config/app_routes.dart';
import 'package:cuan_app/data/model/lesson.dart';
import 'package:cuan_app/data/model/vbl_models.dart';
import 'package:cuan_app/providers/vbl_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LessonsPage extends StatefulWidget {
  final Lesson lesson;
  final int part;
  final String playlistId;
  final String videoId;
  final Duration position;
  final Duration duration;
  const LessonsPage({
    super.key,
    required this.lesson,
    required this.part,
    required this.playlistId,
    required this.videoId,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  @override
  State<LessonsPage> createState() => _LessonsPageState();
}

class _LessonsPageState extends State<LessonsPage> {
  double _progressPct = 0; // 0..100 UI demo

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final p = context.read<VblProvider>();
      await p.fetchVideo(widget.videoId); // GET /vbl/videos/{video_id}
      await p.fetchLatestProgress(); // GET /vbl/progress/latest (opsional)
      final latest = p.latest;
      if (latest != null && latest.videoId == widget.videoId) {
        setState(() => _progressPct = latest.progressPct);
      }
    });
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;

    final p = context.watch<VblProvider>();
    final VblVideoDetailResponse? vd = p.video;  // {videoUrl, description}
    final loading = p.loadingVideo;
    final error = p.errVideo;

    final duration = widget.duration;
    final position = Duration(milliseconds: (duration.inMilliseconds * (_progressPct / 100)).round());
    final double progress = duration.inMilliseconds == 0 ? 0 : position.inMilliseconds / duration.inMilliseconds;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lessons'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).maybePop()),
        centerTitle: false,
      ),
      body: loading && vd == null
          ? const Center(child: CircularProgressIndicator())
          : error != null && vd == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(error, style: TextStyle(color: cs.error)),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => context.read<VblProvider>().fetchVideo(widget.videoId),
                        child: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    // ======= Header 16:9 (cover) + progress UI =======
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image.network(widget.lesson.cover, fit: BoxFit.cover),
                          ),
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                  colors: [Colors.black.withOpacity(.05), Colors.black.withOpacity(.55)],
                                ),
                              ),
                            ),
                          ),
                          // jika perlu tombol Play yang membuka player eksternal / page player-mu
                          if (vd?.videoUrl != null)
                            Positioned.fill(
                              child: Center(
                                child: FilledButton.icon(
                                  onPressed: () {
                                    // TODO: ganti ke video player-mu
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Play URL: ${vd!.videoUrl}')),
                                    );
                                  },
                                  icon: const Icon(Icons.play_arrow),
                                  label: const Text('Play'),
                                ),
                              ),
                            ),
                          Positioned(
                            left: 12, bottom: 36,
                            child: Text('Part ${widget.part}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                          ),
                          Positioned(
                            right: 12, bottom: 36,
                            child: Text(
                              '${_fmt(position)} / ${_fmt(duration)}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Positioned(
                            left: 12, right: 12, bottom: 12,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 4,
                                backgroundColor: Colors.white.withOpacity(.30),
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ======= Judul (Part n | Title) =======
                    RichText(
                      text: TextSpan(
                        style: t.textTheme.titleMedium?.copyWith(
                          color: cs.onSurface, height: 1.25, fontWeight: FontWeight.w800,
                        ),
                        children: [
                          TextSpan(text: 'Part ${widget.part} ', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w800)),
                          const TextSpan(text: '| '),
                          TextSpan(text: widget.lesson.title),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ======= Description (dari API video detail) =======
                    Text('Description',
                        style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: cs.onSurface)),
                    const SizedBox(height: 8),
                    Text(
                      vd?.description?.isNotEmpty == true
                          ? vd!.description!
                          : '—',
                      style: t.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface.withOpacity(.9), height: 1.35,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ======= Slider progress (demo) =======
                    Text('Progress: ${_progressPct.toStringAsFixed(1)}%'),
                    Slider(
                      value: _progressPct,
                      min: 0, max: 100,
                      onChanged: (v) => setState(() => _progressPct = v),
                      onChangeEnd: (v) async {
                        await context.read<VblProvider>().saveProgress(
                              playlistId: widget.playlistId,
                              videoId: widget.videoId,
                              progressPct: v,
                              isCompleted: v >= 100 - 1e-6,
                            ); // POST /vbl/progress
                        if (mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(content: Text('Progress tersimpan')));
                        }
                      },
                    ),

                    // ======= Tombol aksi =======
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () async {
                              setState(() => _progressPct = 100);
                              await context.read<VblProvider>().saveProgress(
                                    playlistId: widget.playlistId,
                                    videoId: widget.videoId,
                                    progressPct: 100,
                                    isCompleted: true,
                                  );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Ditandai Complete')),
                                );
                              }
                            },
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Complete'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton.filledTonal(
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
                          tooltip: 'All Parts',
                        ),
                      ],
                    ),
                  ],
                ),
    );
  }
}
