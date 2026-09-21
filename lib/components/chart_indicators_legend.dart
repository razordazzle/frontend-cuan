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

class _ObjectTreeIconPainter extends CustomPainter {
  final Color color;
  const _ObjectTreeIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final double sx = size.width / 20.0;
    final double sy = size.height / 20.0;
    canvas.save();
    canvas.scale(sx, sy);

    final Path p1 = Path()
      ..moveTo(10, 2.5)
      ..lineTo(2.5, 6.5)
      ..lineTo(10, 10.5)
      ..lineTo(17.5, 6.5)
      ..close();
    canvas.drawPath(p1, paint);

    final Path p2 = Path()
      ..moveTo(2.5, 10.5)
      ..lineTo(10, 14.5)
      ..lineTo(17.5, 10.5);
    canvas.drawPath(p2, paint);

    final Path p3 = Path()
      ..moveTo(2.5, 14.5)
      ..lineTo(10, 18.5)
      ..lineTo(17.5, 14.5);
    canvas.drawPath(p3, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ObjectTreeIconPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _CandlestickInfoIconPainter extends CustomPainter {
  final Color color;
  const _CandlestickInfoIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final Paint fillPaint = Paint()
      ..color = const Color(0xFF1E1E1E)
      ..style = PaintingStyle.fill;

    final double sx = size.width / 20.0;
    final double sy = size.height / 20.0;
    canvas.save();
    canvas.scale(sx, sy);

    // Left taller candle
    canvas.drawLine(const Offset(5.5, 2.5), const Offset(5.5, 17.5), linePaint);
    final RRect r1 = RRect.fromRectAndRadius(const Rect.fromLTWH(3.5, 5.5, 4, 9), const Radius.circular(0.5));
    canvas.drawRRect(r1, fillPaint);
    canvas.drawRRect(r1, linePaint);

    // Right shorter candle
    canvas.drawLine(const Offset(14.5, 5.5), const Offset(14.5, 15.5), linePaint);
    final RRect r2 = RRect.fromRectAndRadius(const Rect.fromLTWH(12.5, 8, 4, 5), const Radius.circular(0.5));
    canvas.drawRRect(r2, fillPaint);
    canvas.drawRRect(r2, linePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CandlestickInfoIconPainter oldDelegate) => oldDelegate.color != color;
}

class _SmaIconPainter extends CustomPainter {
  final Color color;
  const _SmaIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final double sx = size.width / 20.0;
    final double sy = size.height / 20.0;
    canvas.save();
    canvas.scale(sx, sy);

    final Path p = Path()
      ..moveTo(3, 14)
      ..cubicTo(7, 6, 12, 16, 17, 6);
    canvas.drawPath(p, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SmaIconPainter oldDelegate) => oldDelegate.color != color;
}

class _RsiIconPainter extends CustomPainter {
  final Color color;
  const _RsiIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final double sx = size.width / 20.0;
    final double sy = size.height / 20.0;
    canvas.save();
    canvas.scale(sx, sy);

    final Path p = Path()
      ..moveTo(2.5, 10)
      ..lineTo(6, 5)
      ..lineTo(10.5, 15)
      ..lineTo(14.5, 7)
      ..lineTo(17.5, 11);
    canvas.drawPath(p, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RsiIconPainter oldDelegate) => oldDelegate.color != color;
}

class _VolumeIconPainter extends CustomPainter {
  final Color color;
  const _VolumeIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final double sx = size.width / 20.0;
    final double sy = size.height / 20.0;
    canvas.save();
    canvas.scale(sx, sy);

    canvas.drawLine(const Offset(4, 16), const Offset(4, 10), paint);
    canvas.drawLine(const Offset(9, 16), const Offset(9, 5), paint);
    canvas.drawLine(const Offset(14, 16), const Offset(14, 8), paint);
    canvas.drawLine(const Offset(17, 16), const Offset(17, 12), paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _VolumeIconPainter oldDelegate) => oldDelegate.color != color;
}

/// Widget Legend Indikator Aktif di Pojok Kiri Atas Chart
/// Menampilkan indikator yang sedang aktif ala TradingView mobile
class ChartIndicatorsLegend extends StatefulWidget {
  final String symbol;
  final String timeframe;
  final bool showSma;
  final bool showRsi;
  final bool showVolume;
  final bool visibleSma;
  final bool visibleRsi;
  final bool visibleVolume;
  final String? selectedId;
  final ValueChanged<String?>? onSelectionChanged;
  final ValueChanged<bool> onToggleVisibilitySma;
  final ValueChanged<bool> onToggleVisibilityRsi;
  final ValueChanged<bool> onToggleVisibilityVolume;
  final VoidCallback onDeleteSma;
  final VoidCallback onDeleteRsi;
  final VoidCallback onDeleteVolume;
  final ValueChanged<String>? onOpenSettings;

  const ChartIndicatorsLegend({
    super.key,
    this.symbol = 'IHSG',
    this.timeframe = '1D',
    required this.showSma,
    required this.showRsi,
    required this.showVolume,
    this.visibleSma = true,
    this.visibleRsi = true,
    this.visibleVolume = true,
    this.selectedId,
    this.onSelectionChanged,
    required this.onToggleVisibilitySma,
    required this.onToggleVisibilityRsi,
    required this.onToggleVisibilityVolume,
    required this.onDeleteSma,
    required this.onDeleteRsi,
    required this.onDeleteVolume,
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

  @override
  Widget build(BuildContext context) {
    // Kumpulkan indikator yang sedang aktif
    final List<Map<String, dynamic>> activeItems = <Map<String, dynamic>>[];

    if (widget.showSma) {
      activeItems.add(<String, dynamic>{
        'id': 'sma',
        'title': 'SMA 20 close',
        'isHidden': !widget.visibleSma,
        'onToggleEye': () => widget.onToggleVisibilitySma(!widget.visibleSma),
        'onDelete': () {
          _setSelectedId(null);
          widget.onDeleteSma();
        },
        'onSettings': () => widget.onOpenSettings?.call('sma'),
      });
    }

    if (widget.showRsi) {
      activeItems.add(<String, dynamic>{
        'id': 'rsi',
        'title': 'RSI 14 close',
        'isHidden': !widget.visibleRsi,
        'onToggleEye': () => widget.onToggleVisibilityRsi(!widget.visibleRsi),
        'onDelete': () {
          _setSelectedId(null);
          widget.onDeleteRsi();
        },
        'onSettings': () => widget.onOpenSettings?.call('rsi'),
      });
    }

    if (widget.showVolume) {
      activeItems.add(<String, dynamic>{
        'id': 'vol',
        'title': 'Vol',
        'isHidden': !widget.visibleVolume,
        'onToggleEye': () => widget.onToggleVisibilityVolume(!widget.visibleVolume),
        'onDelete': () {
          _setSelectedId(null);
          widget.onDeleteVolume();
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
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(width: 6),
            // Purple sync/refresh icon badge ala TradingView (Gambar 1)
            Opacity(
              opacity: isHidden ? 0.35 : 1.0,
              child: Container(
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
                decoration: TextDecoration.none,
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
                _showMoreOptions(
                  context,
                  title: title,
                  isHidden: isHidden,
                  onToggleEye: onToggleEye,
                  onSettings: onSettings,
                  onDelete: onDelete,
                );
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

  void _showMoreOptions(
    BuildContext ctx, {
    required String title,
    required bool isHidden,
    required VoidCallback onToggleEye,
    required VoidCallback onSettings,
    required VoidCallback onDelete,
  }) {
    showModalBottomSheet<void>(
      context: ctx,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (BuildContext sheetCtx) {
        final bool isDark = Theme.of(sheetCtx).brightness == Brightness.dark;
        final Color sheetBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final Color borderColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE0E3EB);
        final Color itemTextColor = isDark ? const Color(0xFFD1D4DC) : const Color(0xFF131722);
        const Color iconColor = Color(0xFF868993);
        final Color separatorColor = isDark ? const Color(0x14FFFFFF) : const Color(0xFFE0E3EB);

        return Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border(
              top: BorderSide(color: borderColor, width: 1),
            ),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Colors.black54,
                blurRadius: 28,
                offset: Offset(0, -8),
              ),
            ],
          ),
          padding: const EdgeInsets.only(top: 8, bottom: 20),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Handle bar (sama dengan tv_chart.html)
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(top: 4, bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF50535E),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // 1. Object tree...
                _buildSheetItem(
                  iconWidget: CustomPaint(
                    size: const Size(20, 20),
                    painter: _ObjectTreeIconPainter(iconColor),
                  ),
                  label: 'Object tree...',
                  textColor: itemTextColor,
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    _showIndicatorsObjectTreeModal(ctx);
                  },
                ),

                // 4. Hide / Show
                _buildSheetItem(
                  iconWidget: Icon(
                    isHidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 20,
                    color: iconColor,
                  ),
                  label: isHidden ? 'Show' : 'Hide',
                  textColor: itemTextColor,
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    onToggleEye();
                  },
                ),

                // 5. Remove
                _buildSheetItem(
                  iconWidget: const Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: iconColor,
                  ),
                  label: 'Remove',
                  textColor: itemTextColor,
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    onDelete();
                  },
                ),

                // Separator line (sama dengan tv_chart.html)
                Container(
                  height: 1,
                  color: separatorColor,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                ),

                // 6. Settings...
                _buildSheetItem(
                  iconWidget: CustomPaint(
                    size: const Size(20, 20),
                    painter: const NutIconPainter(color: iconColor, strokeWidth: 1.6),
                  ),
                  label: 'Settings...',
                  textColor: itemTextColor,
                  onTap: () {
                    Navigator.of(sheetCtx).pop();
                    onSettings();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetItem({
    required Widget iconWidget,
    required String label,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 20,
              height: 20,
              child: Center(child: iconWidget),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w400,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showIndicatorsObjectTreeModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (BuildContext modalCtx) {
        final bool isDark = Theme.of(modalCtx).brightness == Brightness.dark;
        final Color sheetBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final Color borderColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE0E3EB);
        final Color textColor = isDark ? Colors.white : const Color(0xFF131722);
        final Color subtextColor = const Color(0xFF868993);
        final Color itemBorderColor = Colors.white.withValues(alpha: 0.03);

        final Color neutralIconColor = isDark ? const Color(0xFFD1D4DC) : const Color(0xFF131722);

        return StatefulBuilder(
          builder: (BuildContext bCtx, void Function(void Function()) setModalState) {
            final List<Map<String, dynamic>> items = <Map<String, dynamic>>[];

            if (widget.showSma) {
              items.add(<String, dynamic>{
                'id': 'sma',
                'title': 'SMA 20 close',
                'isHidden': !widget.visibleSma,
                'icon': CustomPaint(
                  size: const Size(18, 18),
                  painter: _SmaIconPainter(neutralIconColor),
                ),
                'onToggleEye': () {
                  widget.onToggleVisibilitySma(!widget.visibleSma);
                  setModalState(() {});
                },
                'onDelete': () {
                  widget.onDeleteSma();
                  setModalState(() {});
                },
              });
            }

            if (widget.showRsi) {
              items.add(<String, dynamic>{
                'id': 'rsi',
                'title': 'RSI 14 close',
                'isHidden': !widget.visibleRsi,
                'icon': CustomPaint(
                  size: const Size(18, 18),
                  painter: _RsiIconPainter(neutralIconColor),
                ),
                'onToggleEye': () {
                  widget.onToggleVisibilityRsi(!widget.visibleRsi);
                  setModalState(() {});
                },
                'onDelete': () {
                  widget.onDeleteRsi();
                  setModalState(() {});
                },
              });
            }

            if (widget.showVolume) {
              items.add(<String, dynamic>{
                'id': 'vol',
                'title': 'Vol',
                'isHidden': !widget.visibleVolume,
                'icon': CustomPaint(
                  size: const Size(18, 18),
                  painter: _VolumeIconPainter(neutralIconColor),
                ),
                'onToggleEye': () {
                  widget.onToggleVisibilityVolume(!widget.visibleVolume);
                  setModalState(() {});
                },
                'onDelete': () {
                  widget.onDeleteVolume();
                  setModalState(() {});
                },
              });
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.80,
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(
                  top: BorderSide(color: borderColor, width: 1),
                ),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 32,
                    offset: Offset(0, -8),
                  ),
                ],
              ),
              child: Column(
                children: <Widget>[
                  // Header: Object tree + [✕]
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 18, 14, 14),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: borderColor, width: 1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          'Object tree',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(Icons.close, color: subtextColor, size: 20),
                          onPressed: () => Navigator.of(modalCtx).pop(),
                        ),
                      ],
                    ),
                  ),

                  // Body
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(top: 6, bottom: 20),
                      children: <Widget>[
                        // Row 0: Chart Info Row (Symbol + Timeframe, non-clickable)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: itemBorderColor, width: 1),
                            ),
                          ),
                          child: Row(
                            children: <Widget>[
                              CustomPaint(
                                size: const Size(20, 20),
                                painter: _CandlestickInfoIconPainter(
                                  isDark ? const Color(0xFFD1D4DC) : const Color(0xFF131722),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${widget.symbol}, ${widget.timeframe}',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Empty State if no active indicators
                        if (items.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                            child: Center(
                              child: Text(
                                'No indicators on chart',
                                style: TextStyle(color: subtextColor, fontSize: 14),
                              ),
                            ),
                          )
                        else
                          ...items.map((Map<String, dynamic> item) {
                            final String title = item['title'] as String;
                            final bool isHidden = item['isHidden'] as bool;
                            final Widget iconWidget = item['icon'] as Widget;
                            final VoidCallback onToggleEye = item['onToggleEye'] as VoidCallback;
                            final VoidCallback onDelete = item['onDelete'] as VoidCallback;

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: itemBorderColor, width: 1),
                                ),
                              ),
                              child: Opacity(
                                opacity: isHidden ? 0.6 : 1.0,
                                child: Row(
                                  children: <Widget>[
                                    // Left: Icon + Label
                                    Expanded(
                                      child: Row(
                                        children: <Widget>[
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: Center(child: iconWidget),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              title,
                                              style: TextStyle(
                                                color: isHidden ? subtextColor : textColor,
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w400,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Right: Actions (Eye + Delete)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        // Eye button
                                        GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: onToggleEye,
                                          child: Padding(
                                            padding: const EdgeInsets.all(4),
                                            child: Icon(
                                              isHidden
                                                  ? Icons.visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                              size: 18,
                                              color: isHidden ? const Color(0xFF50535E) : subtextColor,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        // Trash button
                                        GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: onDelete,
                                          child: Padding(
                                            padding: const EdgeInsets.all(4),
                                            child: Icon(
                                              Icons.delete_outline_rounded,
                                              size: 18,
                                              color: subtextColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
