import 'dart:async';

import 'package:cuan_app/config/app_routes.dart';
import 'package:cuan_app/data/model/lesson.dart';
import 'package:cuan_app/data/model/vbl_models.dart';
import 'package:cuan_app/providers/vbl_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

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
  YoutubePlayerController? _ytController;
  bool _reportedComplete =
      false; //Hindari saveProgress berkali-kali pas video abis
  Timer? _autoSaveTimer;
  double _lastSavedPct = -1;
  bool _hasRealProgress = false;
  bool _hasSeeked = false;
  double? _resumePct;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final p = context.read<VblProvider>();
      await p.fetchVideo(widget.videoId); // GET /vbl/videos/{video_id}

      final prog = await p.fetchProgressForVideo(widget.videoId);
      if (prog != null && !prog.isCompleted) {
        // kalau video udah pernah completed, mulai dari 0 lagi (rewatch), bukan resume
        _resumePct = prog.progressPct;
        setState(() => _progressPct = prog.progressPct);
      }
      final videoUrl = p.video?.videoUrl;
      if (videoUrl != null && videoUrl.isNotEmpty) {
        final ytId = YoutubePlayer.convertUrlToId(videoUrl);
        if (ytId != null) {
          _ytController = YoutubePlayerController(
            initialVideoId: ytId,
            flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
          )..addListener(_onPlayerStateChange);
          setState(() {});
        }
      }
    });
  }

  //Dipanggil tiap ada perubahan state player (posisi, play/pause, dll)
  void _onPlayerStateChange() {
    final controller = _ytController;
    if (controller == null || !controller.value.isReady) return;
    //seek ke posisi resume, HANYA SEKALI, begitu player pertama kali ready
    if (!_hasSeeked) {
      final total = widget.duration.inSeconds > 0
          ? widget.duration
          : controller.metadata.duration;
      if (total.inSeconds > 0) {
        _hasSeeked =
            true; // BARU di-set true SETELAH total valid, bukan di awal
        if (_resumePct != null && _resumePct! > 0) {
          final seekTo = Duration(
            seconds: (total.inSeconds * (_resumePct! / 100)).round(),
          );
          controller.seekTo(seekTo);
        }
      }
      // kalau total masih 0, _hasSeeked TETAP false, jadi listener berikutnya bakal nyoba lagi
    }

    final position = controller.value.position;
    final total = widget.duration.inSeconds > 0
        ? widget.duration
        : controller.metadata.duration;

    if (total.inSeconds > 0) {
      final pct = (position.inSeconds / total.inSeconds * 100)
          .clamp(0, 100)
          .toDouble();
      if ((pct - _progressPct).abs() >= 1) {
        setState(() => _progressPct = pct);
      }
      _hasRealProgress = true;
    }
    final state = controller.value.playerState;
    if (state == PlayerState.playing) {
      _startAutoSaveTimer();
    } else {
      _autoSaveTimer?.cancel();
      if (state == PlayerState.paused) {
        if (!_reportedComplete)
          _persistProgress(); // simpan langsung pas user pause
      }
    }

    if (state == PlayerState.ended && !_reportedComplete) {
      _reportedComplete = true;
      _autoSaveTimer?.cancel();
      _persistProgress(isCompleted: true, forcePct: 100);
    }
  }

  //jalanin timer yang nembak save tiap 10 detik selama video playing
  void _startAutoSaveTimer() {
    if (_autoSaveTimer != null && _autoSaveTimer!.isActive) return;
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_reportedComplete) {
        _autoSaveTimer?.cancel();
        return;
      }
      _persistProgress();
    });
  }

  //fungsi terpusat buat kirim progress ke backend, dengan guard biar nggak spam
  Future<void> _persistProgress({
    bool isCompleted = false,
    double? forcePct,
    bool force = false,
  }) async {
    if (!_hasRealProgress && !isCompleted) return;
    final pct = forcePct ?? _progressPct;
    if (!isCompleted && (pct - _lastSavedPct).abs() < 1)
      return; // progress belum berubah, skip
    _lastSavedPct = pct;
    if (isCompleted) {
      _reportedComplete = true; //cegah timer nimpa balik ke false
      _autoSaveTimer?.cancel();
    }
    await context.read<VblProvider>().saveProgress(
      playlistId: widget.playlistId,
      videoId: widget.videoId,
      progressPct: pct,
      isCompleted: isCompleted,
    );
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _ytController?.removeListener(_onPlayerStateChange);
    _ytController?.dispose();
    super.dispose();
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
    final VblVideoDetailResponse? vd = p.video; // {videoUrl, description}
    final loading = p.loadingVideo;
    final error = p.errVideo;

    final duration = widget.duration;
    final position = Duration(
      milliseconds: (duration.inMilliseconds * (_progressPct / 100)).round(),
    );
    final double progress = duration.inMilliseconds == 0
        ? 0
        : position.inMilliseconds / duration.inMilliseconds;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lessons'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
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
                    onPressed: () =>
                        context.read<VblProvider>().fetchVideo(widget.videoId),
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                // ======= Header 16:9 (cover) + progress UI =======
                if (_ytController != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: YoutubePlayer(
                      controller: _ytController!,
                      showVideoProgressIndicator: true,
                      progressIndicatorColor: cs.primary,
                      bottomActions: [
                        CurrentPosition(),
                        const SizedBox(width: 8),
                        ProgressBar(isExpanded: true),
                        const SizedBox(width: 8),
                        RemainingDuration(),
                        FullScreenButton(),
                      ],
                    ),
                  )
                else
                  // fallback loading state sementara nunggu video_url & controller siap
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        color: Colors.black12,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // ======= Judul (Part n | Title) =======
                RichText(
                  text: TextSpan(
                    style: t.textTheme.titleMedium?.copyWith(
                      color: cs.onSurface,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                    ),
                    children: [
                      TextSpan(
                        text: 'Part ${widget.part} ',
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const TextSpan(text: '| '),
                      TextSpan(text: widget.lesson.title),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ======= Description (dari API video detail) =======
                Text(
                  'Description',
                  style: t.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  vd?.description?.isNotEmpty == true ? vd!.description! : '—',
                  style: t.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withOpacity(.9),
                    height: 1.35,
                  ),
                ),

                const SizedBox(height: 16),

                // ======= Slider progress (demo) =======
                Text('Progress: ${_progressPct.toStringAsFixed(1)}%'),
                Slider(
                  value: _progressPct,
                  min: 0,
                  max: 100,
                  onChanged: (v) => setState(() => _progressPct = v),
                  onChangeEnd: (v) async {
                    final isDone = v >= 100 - 1e-6;
                    await _persistProgress(
                      isCompleted: isDone,
                      forcePct: v,
                      force: true,
                    ); // GANTI
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Progress tersimpan')),
                      );
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
                          await _persistProgress(
                            isCompleted: true,
                            forcePct: 100,
                            force: true,
                          ); // GANTI
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Ditandai Complete'),
                              ),
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
