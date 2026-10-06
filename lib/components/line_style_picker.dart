import 'package:flutter/material.dart';

import '../data/model/indicator_line_style.dart';

/// Tombol pill "kotak warna + preview garis" untuk membuka [showLineStylePicker].
class LineStyleSwatchButton extends StatelessWidget {
  final IndicatorLineStyle value;

  /// Highlight biru saat picker milik tombol ini sedang terbuka.
  final bool isActive;

  /// False untuk swatch warna saja (mis. isian background), tanpa preview garis.
  final bool showLinePreview;
  final VoidCallback onTap;

  const LineStyleSwatchButton({
    super.key,
    required this.value,
    required this.onTap,
    this.isActive = false,
    this.showLinePreview = true,
  });

  static const double _colorBoxSize = 22;
  static const double _borderWidth = 1.5;
  static const double _padding = 5.5;

  /// Tinggi & lebar mode warna saja. Border ikut dihitung karena Container
  /// memperlakukan lebar border sebagai padding tambahan.
  static const double _compactSize =
      _colorBoxSize + 2 * (_padding + _borderWidth);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: showLinePreview ? 82 : _compactSize,
        height: _compactSize,
        padding: EdgeInsets.symmetric(
          horizontal: showLinePreview ? 8 : _padding,
          vertical: _padding,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? const Color(0xFF2962FF) : const Color(0xFF3A3A3C),
            width: _borderWidth,
          ),
          boxShadow: isActive
              ? const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x662962FF),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: <Widget>[
            _ColorBox(color: value.color, size: _colorBoxSize),
            if (showLinePreview) ...<Widget>[
              const SizedBox(width: 6),
              Expanded(
                child: Center(
                  child: LineStylePreview(
                    color: value.color,
                    width: value.lineWidth.toDouble().clamp(1.0, 4.0),
                    lineStyle: value.lineStyle,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Kotak warna; warna transparan ditampilkan di atas pola kotak-kotak (ala TradingView).
class _ColorBox extends StatelessWidget {
  final Color color;
  final double size;

  const _ColorBox({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: color.a < 1 ? const _CheckerboardPainter() : null,
          child: ColoredBox(color: color),
        ),
      ),
    );
  }
}

class _CheckerboardPainter extends CustomPainter {
  static const double _cellSize = 5.5;
  static const Color _darkCell = Color(0xFF1E222D);
  static const Color _lightCell = Color(0xFF2A2E39);

  const _CheckerboardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _darkCell);
    final Paint light = Paint()..color = _lightCell;
    for (double y = 0; y < size.height; y += _cellSize) {
      final bool oddRow = (y / _cellSize).round().isOdd;
      for (
        double x = oddRow ? _cellSize : 0;
        x < size.width;
        x += _cellSize * 2
      ) {
        canvas.drawRect(Rect.fromLTWH(x, y, _cellSize, _cellSize), light);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CheckerboardPainter oldDelegate) => false;
}

/// Preview garis solid / dashed / dotted.
class LineStylePreview extends StatelessWidget {
  final Color color;
  final double width;
  final int lineStyle; // 0: solid, 1: dashed, 2: dotted

  const LineStylePreview({
    super.key,
    required this.color,
    required this.width,
    required this.lineStyle,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(34, 12),
      painter: _LinePreviewPainter(
        color: color,
        width: width,
        lineStyle: lineStyle,
      ),
    );
  }
}

/// Buka popover color picker ala TradingView (palet 10x8, recent colors, opacity,
/// ketebalan, jenis garis) tepat di bawah widget [anchorKey].
///
/// [onChanged] dipanggil setiap kali user mengubah nilai (live preview).
/// [showLineOptions] false = hanya warna & opacity (mis. untuk isian background).
/// Future selesai saat popover ditutup.
Future<void> showLineStylePicker({
  required BuildContext context,
  required GlobalKey anchorKey,
  required IndicatorLineStyle initialValue,
  required ValueChanged<IndicatorLineStyle> onChanged,
  bool showLineOptions = true,
}) {
  final RenderBox? anchor =
      anchorKey.currentContext?.findRenderObject() as RenderBox?;
  final MediaQueryData mediaQuery = MediaQuery.of(context);
  final Size screen = mediaQuery.size;
  const double verticalGap = 6.0;

  // Lebar persis tv-trendline-style-popover di tv_chart.html (310px).
  final double popoverWidth = 310.0.clamp(280.0, screen.width - 24.0);
  final Offset anchorOrigin = anchor?.localToGlobal(Offset.zero) ?? Offset.zero;

  // Tepat di bawah swatch + 6px, rata kanan dengan swatch.
  double top = anchor != null
      ? anchorOrigin.dy + anchor.size.height + verticalGap
      : 180.0;
  final double anchorRightInset = anchor != null
      ? screen.width - (anchorOrigin.dx + anchor.size.width)
      : 16.0;
  final double right = anchorRightInset.clamp(
    12.0,
    screen.width - popoverWidth - 12.0,
  );

  // Kalau ruang di bawah sempit, tampilkan di atas swatch.
  double maxHeight = screen.height - top - (mediaQuery.padding.bottom + 16.0);
  if (maxHeight < 280 && anchor != null && anchorOrigin.dy > maxHeight) {
    top = (anchorOrigin.dy - verticalGap - 480).clamp(
      mediaQuery.padding.top + 16.0,
      anchorOrigin.dy - verticalGap,
    );
    maxHeight = anchorOrigin.dy - verticalGap - top;
  }

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'DismissColorPicker',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 140),
    transitionBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
    pageBuilder:
        (
          BuildContext dialogContext,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
        ) => Stack(
          children: <Widget>[
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => Navigator.of(dialogContext).pop(),
              ),
            ),
            Positioned(
              top: top,
              right: right,
              width: popoverWidth,
              child: _LineStylePickerPopover(
                initialValue: initialValue,
                onChanged: onChanged,
                showLineOptions: showLineOptions,
                maxHeight: maxHeight.clamp(200.0, 520.0),
              ),
            ),
          ],
        ),
  );
}

class _LineStylePickerPopover extends StatefulWidget {
  final IndicatorLineStyle initialValue;
  final ValueChanged<IndicatorLineStyle> onChanged;
  final bool showLineOptions;
  final double maxHeight;

  const _LineStylePickerPopover({
    required this.initialValue,
    required this.onChanged,
    required this.showLineOptions,
    required this.maxHeight,
  });

  @override
  State<_LineStylePickerPopover> createState() =>
      _LineStylePickerPopoverState();
}

class _LineStylePickerPopoverState extends State<_LineStylePickerPopover> {
  static const Color _popoverBg = Color(0xFF1E1E1E);
  static const Color _divider = Color(0xFF2C2C2E);
  static const Color _segmentBg = Color(0xFF2A2A2A);
  static const Color _segmentBorder = Color(0xFF3A3A3C);
  static const Color _labelColor = Color(0xFF8E8E93);
  static const double _paletteGap = 4;
  static const int _maxRecentColors = 4;
  static const List<int> _lineWidths = <int>[1, 2, 3, 4];
  static const List<int> _lineStyles = <int>[0, 1, 2];

  // Palet 10 kolom x 8 baris ala TradingView (sama dengan TV_PALETTE_COLORS di tv_chart.html).
  // dart format off
  static const List<List<Color>> _palette = <List<Color>>[
    // Grayscale
    <Color>[
      Color(0xFFFFFFFF), Color(0xFFD1D4DC), Color(0xFFB2B5BE), Color(0xFF9598A1), Color(0xFF787B86),
      Color(0xFF60626B), Color(0xFF434651), Color(0xFF2A2E39), Color(0xFF1E222D), Color(0xFF000000),
    ],
    // Very light pastel tints
    <Color>[
      Color(0xFFFFCDD2), Color(0xFFFFE0B2), Color(0xFFFFF9C4), Color(0xFFF0F4C3), Color(0xFFDCEDC8),
      Color(0xFFC8E6C9), Color(0xFFB2EBF2), Color(0xFFBBDEFB), Color(0xFFD1C4E9), Color(0xFFF8BBD0),
    ],
    // Soft pastels
    <Color>[
      Color(0xFFEF9A9A), Color(0xFFFFCC80), Color(0xFFFFF59D), Color(0xFFE6EE9C), Color(0xFFC5E1A5),
      Color(0xFFA5D6A7), Color(0xFF80DEEA), Color(0xFF90CAF9), Color(0xFFB39DDB), Color(0xFFF48FB1),
    ],
    // Medium vibrant
    <Color>[
      Color(0xFFE57373), Color(0xFFFFB74D), Color(0xFFFFF176), Color(0xFFDCE775), Color(0xFFAED581),
      Color(0xFF81C784), Color(0xFF4DD0E1), Color(0xFF64B5F6), Color(0xFF9575CD), Color(0xFFF06292),
    ],
    // Primary / vivid
    <Color>[
      Color(0xFFF44336), Color(0xFFFF9800), Color(0xFFFFEB3B), Color(0xFFCDDC39), Color(0xFF8BC34A),
      Color(0xFF4CAF50), Color(0xFF00BCD4), Color(0xFF2196F3), Color(0xFF7C4DFF), Color(0xFFE91E63),
    ],
    // Deep vibrant
    <Color>[
      Color(0xFFE53935), Color(0xFFFB8C00), Color(0xFFFDD835), Color(0xFFC0CA33), Color(0xFF7CB342),
      Color(0xFF43A047), Color(0xFF00ACC1), Color(0xFF1E88E5), Color(0xFF651FFF), Color(0xFFD81B60),
    ],
    // Dark shades
    <Color>[
      Color(0xFFD32F2F), Color(0xFFF57C00), Color(0xFFFBC02D), Color(0xFFAFB42B), Color(0xFF689F38),
      Color(0xFF388E3C), Color(0xFF0097A7), Color(0xFF1976D2), Color(0xFF512DA8), Color(0xFFC2185B),
    ],
    // Deepest shades
    <Color>[
      Color(0xFFB71C1C), Color(0xFFE65100), Color(0xFFF57F17), Color(0xFF827717), Color(0xFF33691E),
      Color(0xFF1B5E20), Color(0xFF006064), Color(0xFF0D47A1), Color(0xFF311B92), Color(0xFF880E4F),
    ],
  ];
  // dart format on

  /// Recent colors dipakai bersama oleh semua picker selama app berjalan (seperti TradingView).
  static final List<Color> _recentColors = <Color>[
    const Color(0xFF2A2E39),
    const Color(0xFFAB47BC),
  ];

  late IndicatorLineStyle _value = widget.initialValue;

  static bool _isSameRgb(Color a, Color b) =>
      (a.toARGB32() & 0xFFFFFF) == (b.toARGB32() & 0xFFFFFF);

  static void _rememberRecentColor(Color color) {
    final Color opaque = color.withValues(alpha: 1.0);
    if (_recentColors.any((Color c) => _isSameRgb(c, opaque))) return;
    _recentColors.insert(0, opaque);
    if (_recentColors.length > _maxRecentColors) _recentColors.removeLast();
  }

  void _update(IndicatorLineStyle value) {
    setState(() => _value = value);
    widget.onChanged(value);
  }

  /// Ganti warna dasar tapi pertahankan opacity yang sedang dipakai.
  void _selectColor(Color color, {bool remember = false}) {
    if (remember) _rememberRecentColor(color);
    _update(_value.copyWith(color: color.withValues(alpha: _value.color.a)));
  }

  @override
  Widget build(BuildContext context) {
    final Color baseColor = _value.color.withValues(alpha: 1.0);

    return Material(
      type: MaterialType.transparency,
      child: Container(
        constraints: BoxConstraints(maxHeight: widget.maxHeight),
        decoration: BoxDecoration(
          color: _popoverBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _divider, width: 1),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0xBF000000), // rgba(0, 0, 0, 0.75)
              blurRadius: 32,
              offset: Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildPalette(baseColor),
              Container(
                height: 1,
                color: _divider,
                margin: const EdgeInsets.symmetric(vertical: 10),
              ),
              _buildRecentColors(baseColor),
              const SizedBox(height: 6),
              _buildLabel('Opacity', fontSize: 12),
              const SizedBox(height: 6),
              _buildOpacitySlider(baseColor),
              if (widget.showLineOptions) ...<Widget>[
                const SizedBox(height: 12),
                _buildLabel('Thickness'),
                const SizedBox(height: 6),
                _buildSegmentedControl<int>(
                  options: _lineWidths,
                  selected: _value.lineWidth,
                  onSelected: (int width) =>
                      _update(_value.copyWith(lineWidth: width)),
                  builder: (int width, bool isSelected) => Container(
                    width: 26,
                    height: width.toDouble(),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.black : Colors.white,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildLabel('Line style'),
                const SizedBox(height: 6),
                _buildSegmentedControl<int>(
                  options: _lineStyles,
                  selected: _value.lineStyle,
                  onSelected: (int style) =>
                      _update(_value.copyWith(lineStyle: style)),
                  builder: (int style, bool isSelected) => LineStylePreview(
                    color: isSelected ? Colors.black : Colors.white,
                    width: 2.0,
                    lineStyle: style,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Jarak antar kotak ditaruh di luar Expanded supaya semua kotak (termasuk kolom terakhir) sama besar.
  Widget _buildPalette(Color baseColor) {
    return Column(
      children: <Widget>[
        for (final (int rowIndex, List<Color> row)
            in _palette.indexed) ...<Widget>[
          if (rowIndex > 0) const SizedBox(height: _paletteGap),
          Row(
            children: <Widget>[
              for (final (int colIndex, Color swatch)
                  in row.indexed) ...<Widget>[
                if (colIndex > 0) const SizedBox(width: _paletteGap),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectColor(swatch, remember: true),
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: swatch,
                          borderRadius: BorderRadius.circular(3.5),
                          border: _isSameRgb(baseColor, swatch)
                              ? Border.all(color: Colors.white, width: 2.0)
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildRecentColors(Color baseColor) {
    return Row(
      children: <Widget>[
        for (final Color color in _recentColors)
          GestureDetector(
            onTap: () => _selectColor(color),
            child: Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(5),
                border: _isSameRgb(baseColor, color)
                    ? Border.all(color: Colors.white, width: 2)
                    : null,
              ),
            ),
          ),
        GestureDetector(
          onTap: () => setState(() => _rememberRecentColor(baseColor)),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: const Color(0xFF434651)),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.add, color: _labelColor, size: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildOpacitySlider(Color baseColor) {
    final double opacity = _value.color.a;

    return Row(
      children: <Widget>[
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 12,
              trackShape: _OpacitySliderTrackShape(baseColor),
              thumbShape: _OpacitySliderThumbShape(),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: opacity,
              onChanged: (double value) => _update(
                _value.copyWith(color: baseColor.withValues(alpha: value)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 48,
          height: 26,
          decoration: BoxDecoration(
            color: _popoverBg,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF434651)),
          ),
          alignment: Alignment.center,
          child: Text(
            '${(opacity * 100).round()}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text, {double fontSize = 13}) {
    return Text(
      text,
      style: TextStyle(
        color: _labelColor,
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildSegmentedControl<T>({
    required List<T> options,
    required T selected,
    required ValueChanged<T> onSelected,
    required Widget Function(T option, bool isSelected) builder,
  }) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: _segmentBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _segmentBorder),
      ),
      child: Row(
        children: <Widget>[
          for (final (int index, T option) in options.indexed)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelected(option),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  decoration: BoxDecoration(
                    color: option == selected
                        ? Colors.white
                        : Colors.transparent,
                    border: index == options.length - 1
                        ? null
                        : const Border(
                            right: BorderSide(color: _segmentBorder),
                          ),
                  ),
                  alignment: Alignment.center,
                  child: builder(option, option == selected),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OpacitySliderTrackShape extends SliderTrackShape
    with BaseSliderTrackShape {
  final Color baseColor;
  _OpacitySliderTrackShape(this.baseColor);

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 0,
  }) {
    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final RRect rrect = RRect.fromRectAndRadius(
      trackRect,
      const Radius.circular(4),
    );
    final Canvas canvas = context.canvas;

    canvas.save();
    canvas.clipRRect(rrect);

    // Dark background
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFF1E222D));

    // Subtle checkered pattern underneath
    final Paint checkPaint = Paint()..color = const Color(0xFF2A2E39);
    const double checkSize = 4.0;
    for (double x = trackRect.left; x < trackRect.right; x += checkSize * 2) {
      for (double y = trackRect.top; y < trackRect.bottom; y += checkSize * 2) {
        canvas.drawRect(Rect.fromLTWH(x, y, checkSize, checkSize), checkPaint);
        canvas.drawRect(
          Rect.fromLTWH(x + checkSize, y + checkSize, checkSize, checkSize),
          checkPaint,
        );
      }
    }

    // Gradient overlay from transparent to baseColor
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          colors: <Color>[
            baseColor.withValues(alpha: 0.0),
            baseColor.withValues(alpha: 1.0),
          ],
        ).createShader(trackRect),
    );

    // Border
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0xFF434651)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    canvas.restore();
  }
}

class _OpacitySliderThumbShape extends SliderComponentShape {
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(18, 18);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;
    canvas.drawCircle(center, 9, Paint()..color = Colors.black);
    canvas.drawCircle(center, 7.5, Paint()..color = Colors.white);
  }
}

class _LinePreviewPainter extends CustomPainter {
  final Color color;
  final double width;
  final int lineStyle; // 0: solid, 1: dashed, 2: dotted

  const _LinePreviewPainter({
    required this.color,
    required this.width,
    required this.lineStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = lineStyle == 2 ? StrokeCap.round : StrokeCap.butt;

    final double y = size.height / 2;
    const double startX = 2.0;
    final double endX = size.width - 2.0;

    if (lineStyle == 0) {
      canvas.drawLine(Offset(startX, y), Offset(endX, y), paint);
    } else if (lineStyle == 1) {
      // Dashed (5px dash, 3.5px space)
      const double dashWidth = 5.0;
      const double dashSpace = 3.5;
      for (double x = startX; x < endX; x += dashWidth + dashSpace) {
        canvas.drawLine(
          Offset(x, y),
          Offset((x + dashWidth).clamp(startX, endX), y),
          paint,
        );
      }
    } else {
      // Dotted (dots spaced by 4px)
      const double dotSpace = 4.0;
      final double radius = (width / 2).clamp(1.0, 2.0);
      final Paint dotPaint = Paint()..color = color;
      for (double x = startX; x <= endX; x += dotSpace) {
        canvas.drawCircle(Offset(x, y), radius, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LinePreviewPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.width != width ||
      oldDelegate.lineStyle != lineStyle;
}
