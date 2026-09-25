import 'package:cuan_app/config/app_routes.dart';
import 'package:cuan_app/data/model/lesson.dart';
import 'package:cuan_app/data/model/vbl_models.dart';
import 'package:cuan_app/providers/vbl_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VideoListPage extends StatefulWidget {
  const VideoListPage({
    super.key,
    required this.lesson,
    required this.playlistId,   // ← pakai ini untuk fetch API
  });

  final Lesson lesson;
  final String playlistId;

  @override
  State<VideoListPage> createState() => _VideoListPageState();
}

class _VideoListPageState extends State<VideoListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VblProvider>().fetchDetail(widget.playlistId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final p = context.watch<VblProvider>();

    final VblPlaylistDetailResponse? d = p.detail;
    final loading = p.loadingDetail;
    final error = p.errDetail;

    return Scaffold(
      appBar: AppBar(title: const Text('List video'), centerTitle: false),
      body: Builder(
        builder: (_) {
          if (loading && d == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error, style: TextStyle(color: cs.error)),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => context
                        .read<VblProvider>()
                        .fetchDetail(widget.playlistId),
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
            );
          }
          final videos = d?.videos ?? const <VblPlaylistVideoItem>[];

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: videos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final v = videos[index];

              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  // Arahkan ke player / lessons dengan playlistId + videoId
                  Navigator.pushNamed(
                    context,
                    AppRoutes.lessons,
                    arguments: {
                      'lesson': widget.lesson,          // masih dipakai UI
                      'part': v.sequence,                // urutan dari API
                      'playlistId': widget.playlistId,   // ← penting
                      'videoId': v.videoId,              // ← penting
                      // opsional: progress kalau kamu punya
                      // 'position': Duration(seconds: ...),
                      'duration': Duration(seconds: v.duration),
                    },
                  );
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // thumbnail (pakai cover playlist; ganti jika punya thumb per video)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 120,
                        height: 72,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(v.thumbnail ?? widget.lesson.cover, fit: BoxFit.cover),
                            Container(color: Colors.black.withOpacity(.25)),
                            const Center(
                              child: Icon(Icons.play_arrow_rounded,
                                  size: 36, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // judul/part
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
                              text: 'Part ${v.sequence} ',
                              style: TextStyle(
                                color: cs.primary,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const TextSpan(text: '| '),
                            TextSpan(text: v.title),
                          ],
                        ),
                      ),
                    ),

                    // durasi kecil di kanan (opsional)
                    const SizedBox(width: 8),
                    Text(_fmtDuration(v.duration),
                        style: t.textTheme.labelMedium?.copyWith(
                          color: cs.onSurface.withOpacity(.7),
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
              );
            },
          );
        },
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
