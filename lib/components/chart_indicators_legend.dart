import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Painter untuk menggambar icon baut/mur segi-enam (Nut Icon)
/// persis seperti icon setting indikator TradingView mobile
class NutIconPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  const NutIconPainter({
    required this.color,
    this.strokeWidth = 1.4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round;

    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = (size.width / 2) * 0.88;

    // Gambar segi enam reguler
    final Path hexPath = Path();
    for (int i = 0; i < 6; i++) {
      final double angle = (math.pi / 180) * (60 * i + 30);
      final double x = cx + r * math.cos(angle);
      final double y = cy + r * math.sin(angle);
      if (i == 0) {
        hexPath.moveTo(x, y);
      } else {
        hexPath.lineTo(x, y);
      }
    }
    hexPath.close();
    canvas.drawPath(hexPath, paint);

    // Gambar lubang lingkaran di tengah
    canvas.drawCircle(Offset(cx, cy), r * 0.42, paint);
  }

  @override
  bool shouldRepaint(covariant NutIconPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

/// Widget Legend Indikator Aktif di Pojok Kiri Atas Chart
/// Menampilkan indikator yang sedang aktif ala TradingView mobile
class ChartIndicatorsLegend extends StatefulWidget {
  final bool showSma;
  final bool showRsi;
  final bool showVolume;
  final String? selectedId;
  final ValueChanged<String?>? onSelectionChanged;
  final ValueChanged<bool> onToggleSma;
  final ValueChanged<bool> onToggleRsi;
  final ValueChanged<bool> onToggleVolume;
  final ValueChanged<String>? onOpenSettings;

  const ChartIndicatorsLegend({
    super.key,
    required this.showSma,
    required this.showRsi,
    required this.showVolume,
    this.selectedId,
    this.onSelectionChanged,
    required this.onToggleSma,
    required this.onToggleRsi,
    required this.onToggleVolume,
    this.onOpenSettings,
  });

  @override
  State<ChartIndicatorsLegend> createState() => _ChartIndicatorsLegendState();
}

class _ChartIndicatorsLegendState extends State<ChartIndicatorsLegend> {
  String? _internalSelectedId; // 'sma', 'rsi', 'vol'
  String? get _effectiveSelectedId => widget.selectedId ?? _internalSelectedId;

  void _setSelectedId(String? id) {
    setState(() {
      _internalSelectedId = id;
    });
    widget.onSelectionChanged?.call(id);
  }

  bool _isCollapsed = false;

  // Track state hide sementara (via eye icon)
  bool _smaHidden = false;
  bool _rsiHidden = false;
  bool _volumeHidden = false;

  @override
  Widget build(BuildContext context) {
    // Kumpulkan indikator yang sedang aktif
    final List<Map<String, dynamic>> activeItems = <Map<String, dynamic>>[];

    if (widget.showSma) {
      activeItems.add(<String, dynamic>{
        'id': 'sma',
        'title': 'SMA 20 close',
        'isHidden': _smaHidden,
        'onToggleEye': () {
          setState(() {
            _smaHidden = !_smaHidden;
            widget.onToggleSma(!_smaHidden);
          });
        },
        'onDelete': () {
          _setSelectedId(null);
          setState(() {
            _smaHidden = false;
            widget.onToggleSma(false);
          });
        },
        'onSettings': () => widget.onOpenSettings?.call('sma'),
      });
    }

    if (widget.showRsi) {
      activeItems.add(<String, dynamic>{
        'id': 'rsi',
        'title': 'RSI 14 close',
        'isHidden': _rsiHidden,
        'onToggleEye': () {
          setState(() {
            _rsiHidden = !_rsiHidden;
            widget.onToggleRsi(!_rsiHidden);
          });
        },
        'onDelete': () {
          _setSelectedId(null);
          setState(() {
            _rsiHidden = false;
            widget.onToggleRsi(false);
          });
        },
        'onSettings': () => widget.onOpenSettings?.call('rsi'),
      });
    }

    if (widget.showVolume) {
      activeItems.add(<String, dynamic>{
        'id': 'vol',
        'title': 'Vol',
        'isHidden': _volumeHidden,
        'onToggleEye': () {
          setState(() {
            _volumeHidden = !_volumeHidden;
            widget.onToggleVolume(!_volumeHidden);
          });
        },
        'onDelete': () {
          _setSelectedId(null);
          setState(() {
            _volumeHidden = false;
            widget.onToggleVolume(false);
          });
        },
        'onSettings': () => widget.onOpenSettings?.call('vol'),
      });
    }

    // Jika tidak ada indikator yang aktif sama sekali
    if (activeItems.isEmpty) {
      return const SizedBox.shrink();
    }

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : const Color(0xFF131722);
    final Color mutedTextColor = isDark ? const Color(0xFF787B86) : const Color(0xFF8E8E93);

    return TapRegion(
      onTapOutside: (PointerDownEvent _) {
        if (_effectiveSelectedId != null) {
          _setSelectedId(null);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Daftar Indikator (jika tidak di-collapse)
          if (!_isCollapsed)
            ...activeItems.map((Map<String, dynamic> item) {
              final String id = item['id'] as String;
              final String title = item['title'] as String;
              final bool isHidden = item['isHidden'] as bool;
              final VoidCallback onToggleEye = item['onToggleEye'] as VoidCallback;
              final VoidCallback onDelete = item['onDelete'] as VoidCallback;
              final VoidCallback onSettings = item['onSettings'] as VoidCallback;
              final bool isSelected = _effectiveSelectedId == id;

              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: isSelected
                    ? _buildSelectedRow(
                        id: id,
                        title: title,
                        isHidden: isHidden,
                        textColor: textColor,
                        mutedColor: mutedTextColor,
                        onToggleEye: onToggleEye,
                        onDelete: onDelete,
                        onSettings: onSettings,
                      )
                    : _buildNormalRow(
                        id: id,
                        title: title,
                        isHidden: isHidden,
                        textColor: textColor,
                        mutedColor: mutedTextColor,
                      ),
              );
            }),

          // Tombol Collapse / Expand [⌃] ala TradingView
          GestureDetector(
            onTap: () {
              setState(() {
                _isCollapsed = !_isCollapsed;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(top: 2),
              width: 24,
              height: 18,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131722).withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isDark ? const Color(0xFF2A2E39) : const Color(0xFFE0E3EB),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                _isCollapsed ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
                size: 15,
                color: isDark ? const Color(0xFFD1D4DC) : const Color(0xFF131722),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Baris Normal (Gambar 1)
  Widget _buildNormalRow({
    required String id,
    required String title,
    required bool isHidden,
    required Color textColor,
    required Color mutedColor,
  }) {
    return GestureDetector(
      onTap: () {
        _setSelectedId(id);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              title,
              style: TextStyle(
                color: isHidden ? mutedColor : textColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                decoration: isHidden ? TextDecoration.lineThrough : TextDecoration.none,
              ),
            ),
            const SizedBox(width: 6),
            // Purple sync/refresh icon badge ala TradingView (Gambar 1)
            Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Color(0xFF332042),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.sync_rounded,
                size: 11,
                color: Color(0xFFB07FE8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Baris Terpilih dengan Action Bar (Gambar 2)
  Widget _buildSelectedRow({
    required String id,
    required String title,
    required bool isHidden,
    required Color textColor,
    required Color mutedColor,
    required VoidCallback onToggleEye,
    required VoidCallback onDelete,
    required VoidCallback onSettings,
  }) {
    return GestureDetector(
      onTap: () {
        // Klik ulang untuk deselect
        _setSelectedId(null);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF131722).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: const Color(0xFF2962FF),
            width: 1.5,
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Colors.black45,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Nama Indikator
            Text(
              title,
              style: TextStyle(
                color: isHidden ? mutedColor : textColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                decoration: isHidden ? TextDecoration.lineThrough : TextDecoration.none,
              ),
            ),
            const SizedBox(width: 14),

            // 1. Eye Button (Visibility)
            GestureDetector(
              onTap: onToggleEye,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  isHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 18,
                  color: isHidden ? mutedColor : textColor,
                ),
              ),
            ),
            const SizedBox(width: 10),

            // 2. Nut Icon (Settings / Customization)
            GestureDetector(
              onTap: onSettings,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: CustomPaint(
                  size: const Size(18, 18),
                  painter: NutIconPainter(color: textColor),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // 3. Trash Can Button (Delete)
            GestureDetector(
              onTap: onDelete,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(width: 10),

            // 4. More Options Button (Three dots)
            GestureDetector(
              onTap: () {
                _showMoreOptions(context, title, onSettings, onDelete);
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.more_horiz_rounded,
                  size: 18,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext ctx, String title, VoidCallback onSettings, VoidCallback onDelete) {
    showModalBottomSheet<void>(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetCtx) {
        final bool isDark = Theme.of(sheetCtx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E222D) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.tune_rounded),
                  title: const Text('Settings...'),
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    onSettings();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  title: const Text('Remove', style: TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    onDelete();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
