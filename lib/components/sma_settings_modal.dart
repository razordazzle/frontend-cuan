import 'package:flutter/material.dart';
import '../data/model/active_chart_indicator.dart';

class SmaSettingsModal extends StatefulWidget {
  final ActiveChartIndicator indicator;
  final ValueChanged<ActiveChartIndicator> onSave;

  const SmaSettingsModal({
    super.key,
    required this.indicator,
    required this.onSave,
  });

  static void show({
    required BuildContext context,
    required ActiveChartIndicator indicator,
    required ValueChanged<ActiveChartIndicator> onSave,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (BuildContext ctx) {
        return SmaSettingsModal(
          indicator: indicator,
          onSave: onSave,
        );
      },
    );
  }

  @override
  State<SmaSettingsModal> createState() => _SmaSettingsModalState();
}

class _SmaSettingsModalState extends State<SmaSettingsModal> {
  int _activeTabIndex = 0; // 0: Inputs, 1: Style

  // Inputs state
  late TextEditingController _lengthController;
  late TextEditingController _offsetController;
  late TextEditingController _smoothingLengthController;
  late String _source;
  late String _smoothingType;
  late String _timeframe;
  late bool _waitForClose;

  // Style state
  late bool _isMaVisible;
  late Color _color;
  late double _opacity;
  late int _lineWidth;
  late int _lineStyle; // 0: solid, 1: dashed, 2: dotted
  late String _plotType;
  late bool _priceLine;
  late String _precision;
  late bool _labelsOnPriceScale;
  late bool _valuesInStatusLine;
  late bool _inputsInStatusLine;
  bool _isColorPickerOpen = false;
  final GlobalKey _swatchKey = GlobalKey();

  final List<Color> _recentColors = <Color>[
    const Color(0xFF2A2E39),
    const Color(0xFFAB47BC),
    const Color(0xFF2A2E39),
  ];

  // Color tokens harmonized with _DrawingsBottomSheetWidget (#121212 & #1E1E1E)
  static const Color _sheetBg = Color(0xFF121212);
  static const Color _cardBg = Color(0xFF1E1E1E);
  static const Color _cardBorder = Color(0xFF2C2C2E);
  static const Color _closeBtnBg = Color(0xFF242426);
  static const Color _subtitleColor = Color(0xFF8E8E93);
  static const Color _textColor = Colors.white;

  // Authentic 10-column TradingView palette matrix (8 rows) matching TV_PALETTE_COLORS in tv_chart.html
  static const List<List<Color>> _tradingViewColorMatrix = <List<Color>>[
    // Row 0: Grayscale (10)
    <Color>[
      Color(0xFFFFFFFF), Color(0xFFD1D4DC), Color(0xFFB2B5BE), Color(0xFF9598A1), Color(0xFF787B86),
      Color(0xFF60626B), Color(0xFF434651), Color(0xFF2A2E39), Color(0xFF1E222D), Color(0xFF000000),
    ],
    // Row 1: Very light pastel tints
    <Color>[
      Color(0xFFFFCDD2), Color(0xFFFFE0B2), Color(0xFFFFF9C4), Color(0xFFF0F4C3), Color(0xFFDCEDC8),
      Color(0xFFC8E6C9), Color(0xFFB2EBF2), Color(0xFFBBDEFB), Color(0xFFD1C4E9), Color(0xFFF8BBD0),
    ],
    // Row 2: Soft pastels
    <Color>[
      Color(0xFFEF9A9A), Color(0xFFFFCC80), Color(0xFFFFF59D), Color(0xFFE6EE9C), Color(0xFFC5E1A5),
      Color(0xFFA5D6A7), Color(0xFF80DEEA), Color(0xFF90CAF9), Color(0xFFB39DDB), Color(0xFFF48FB1),
    ],
    // Row 3: Medium vibrant
    <Color>[
      Color(0xFFE57373), Color(0xFFFFB74D), Color(0xFFFFF176), Color(0xFFDCE775), Color(0xFFAED581),
      Color(0xFF81C784), Color(0xFF4DD0E1), Color(0xFF64B5F6), Color(0xFF9575CD), Color(0xFFF06292),
    ],
    // Row 4: Primary / Vivid (TradingView signature core row)
    <Color>[
      Color(0xFFF44336), Color(0xFFFF9800), Color(0xFFFFEB3B), Color(0xFFCDDC39), Color(0xFF8BC34A),
      Color(0xFF4CAF50), Color(0xFF00BCD4), Color(0xFF2196F3), Color(0xFF7C4DFF), Color(0xFFE91E63),
    ],
    // Row 5: Deep vibrant
    <Color>[
      Color(0xFFE53935), Color(0xFFFB8C00), Color(0xFFFDD835), Color(0xFFC0CA33), Color(0xFF7CB342),
      Color(0xFF43A047), Color(0xFF00ACC1), Color(0xFF1E88E5), Color(0xFF651FFF), Color(0xFFD81B60),
    ],
    // Row 6: Dark shades
    <Color>[
      Color(0xFFD32F2F), Color(0xFFF57C00), Color(0xFFFBC02D), Color(0xFFAFB42B), Color(0xFF689F38),
      Color(0xFF388E3C), Color(0xFF0097A7), Color(0xFF1976D2), Color(0xFF512DA8), Color(0xFFC2185B),
    ],
    // Row 7: Deepest / Shadow shades
    <Color>[
      Color(0xFFB71C1C), Color(0xFFE65100), Color(0xFFF57F17), Color(0xFF827717), Color(0xFF33691E),
      Color(0xFF1B5E20), Color(0xFF006064), Color(0xFF0D47A1), Color(0xFF311B92), Color(0xFF880E4F),
    ],
  ];

  static const double _controlWidth = 125;

  static const List<String> _sourceItems = <String>[
    'Open',
    'High',
    'Low',
    'Close',
    '(H + L)/2',
    '(H + L + C)/3',
    '(O + H + L + C)/4',
  ];

  static const List<String> _smoothingItems = <String>[
    'None',
    'SMA',
    'EMA',
    'SMMA (RMA)',
    'WMA',
    'VWMA',
  ];

  static const List<String> _timeframeItems = <String>[
    'Chart',
    '1 minute',
    '5 minutes',
    '15 minutes',
    '30 minutes',
    '1 hour',
    '4 hours',
    '1 day',
    '1 week',
    '1 month',
  ];

  static const List<String> _precisionItems = <String>[
    'Default',
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
  ];

  @override
  void initState() {
    super.initState();
    final ActiveChartIndicator ind = widget.indicator;
    _lengthController = TextEditingController(text: ind.period.toString());
    _offsetController = TextEditingController(text: ind.offset.toString());
    _smoothingLengthController = TextEditingController(text: ind.smoothingLength.toString());
    _source = ind.source.isNotEmpty ? ind.source : 'Close';
    _smoothingType = ind.smoothingType.isNotEmpty ? ind.smoothingType : 'None';
    _timeframe = ind.timeframe.isNotEmpty ? ind.timeframe : 'Chart';
    _waitForClose = ind.waitForClose;

    _isMaVisible = ind.isVisible;
    final Color c = ind.color ?? const Color(0xFF2962FF);
    _opacity = c.a > 0 ? c.a : 1.0;
    _color = c.withValues(alpha: 1.0);
    _lineWidth = ind.lineWidth;
    _lineStyle = ind.lineStyle;
    _plotType = ind.plotType;
    _priceLine = ind.priceLine;
    _precision = ind.precision.isNotEmpty ? ind.precision : 'Default';
    _labelsOnPriceScale = ind.labelsOnPriceScale;
    _valuesInStatusLine = ind.valuesInStatusLine;
    _inputsInStatusLine = ind.inputsInStatusLine;
  }

  @override
  void dispose() {
    _lengthController.dispose();
    _offsetController.dispose();
    _smoothingLengthController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final int newPeriod = int.tryParse(_lengthController.text.trim()) ?? widget.indicator.period;
    final int newOffset = int.tryParse(_offsetController.text.trim()) ?? 0;
    final int newSmoothingLength =
        int.tryParse(_smoothingLengthController.text.trim()) ?? widget.indicator.smoothingLength;

    // Format title (e.g. SMA 20 close)
    final String srcFormatted = _source.toLowerCase();
    final String newTitle = 'SMA $newPeriod $srcFormatted';

    final ActiveChartIndicator updated = widget.indicator.copyWith(
      period: newPeriod > 0 ? newPeriod : 20,
      offset: newOffset,
      source: _source,
      smoothingType: _smoothingType,
      smoothingLength: newSmoothingLength > 0 ? newSmoothingLength : 14,
      timeframe: _timeframe,
      waitForClose: _waitForClose,
      isVisible: _isMaVisible,
      color: _color.withValues(alpha: _opacity),
      lineWidth: _lineWidth,
      lineStyle: _lineStyle,
      precision: _precision,
      labelsOnPriceScale: _labelsOnPriceScale,
      valuesInStatusLine: _valuesInStatusLine,
      inputsInStatusLine: _inputsInStatusLine,
      plotType: _plotType,
      priceLine: _priceLine,
      title: newTitle,
    );

    widget.onSave(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: _sheetBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: _cardBorder, width: 1),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black54,
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            // Top Drag Handle
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3E3E42),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            // Header Bar
            _buildHeader(),

            // Tabs (Inputs, Style)
            _buildTabBar(),

            // Scrollable Tab Content
            Expanded(
              child: _activeTabIndex == 0 ? _buildInputsTab() : _buildStyleTab(),
            ),

            // Bottom Action Bar ([...], Cancel, Ok)
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          const Text(
            'SMA',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _textColor,
              letterSpacing: -0.3,
              decoration: TextDecoration.none,
            ),
          ),
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: _closeBtnBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 18,
                color: _textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: <Widget>[
              _buildTabItem(title: 'Inputs', index: 0),
              const SizedBox(width: 24),
              _buildTabItem(title: 'Style', index: 1),
            ],
          ),
        ),
        Container(
          height: 1,
          color: _cardBorder,
        ),
      ],
    );
  }

  Widget _buildTabItem({required String title, required int index}) {
    final bool isSelected = _activeTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTabIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 10),
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : _subtitleColor,
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 2.5,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputsTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      children: <Widget>[
        // Length
        _buildRow(
          label: 'Length',
          control: _buildNumberInput(controller: _lengthController, width: _controlWidth),
        ),
        const SizedBox(height: 16),

        // Source
        _buildRow(
          label: 'Source',
          control: _buildPickerTrigger(
            value: _source,
            width: _controlWidth,
            onTap: () {
              _openPickerSheet(
                title: 'Source',
                items: _sourceItems,
                currentValue: _source,
                onSelected: (String val) => setState(() => _source = val),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Offset
        _buildRow(
          label: 'Offset',
          control: _buildNumberInput(controller: _offsetController, width: _controlWidth, allowNegative: true),
        ),
        const SizedBox(height: 26),

        // Section: SMOOTHING
        _buildSectionHeader('SMOOTHING'),
        const SizedBox(height: 16),

        // Type
        _buildRow(
          label: 'Type',
          control: _buildPickerTrigger(
            value: _smoothingType,
            width: _controlWidth,
            onTap: () {
              _openPickerSheet(
                title: 'Type',
                items: _smoothingItems,
                currentValue: _smoothingType,
                onSelected: (String val) => setState(() => _smoothingType = val),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Smoothing Length (Disabled when None, Enabled otherwise)
        Builder(
          builder: (BuildContext context) {
            final bool isSmoothingEnabled = _smoothingType != 'None';
            return _buildRow(
              labelWidget: Text(
                'Length',
                style: TextStyle(
                  color: isSmoothingEnabled ? const Color(0xFFD1D4DC) : const Color(0xFF787B86),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  decoration: TextDecoration.none,
                ),
              ),
              control: isSmoothingEnabled
                  ? _buildNumberInput(controller: _smoothingLengthController, width: _controlWidth)
                  : _buildDisabledInput(
                      text: _smoothingLengthController.text.isNotEmpty
                          ? _smoothingLengthController.text
                          : '14',
                      width: _controlWidth,
                    ),
            );
          },
        ),
        const SizedBox(height: 26),

        // Section: CALCULATION
        _buildSectionHeader('CALCULATION'),
        const SizedBox(height: 16),

        // Timeframe
        _buildRow(
          labelWidget: const Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Timeframe',
                style: TextStyle(
                  color: Color(0xFFD1D4DC),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  decoration: TextDecoration.none,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.help_outline_rounded, color: Color(0xFF787B86), size: 16),
            ],
          ),
          control: _buildPickerTrigger(
            value: _timeframe,
            width: _controlWidth,
            onTap: () {
              _openPickerSheet(
                title: 'Timeframe',
                items: _timeframeItems,
                currentValue: _timeframe,
                onSelected: (String val) => setState(() => _timeframe = val),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Checkbox: Wait for timeframe closes (default ON)
        _buildCheckboxRow(
          label: 'Wait for timeframe closes',
          value: _waitForClose,
          onChanged: (bool val) => setState(() => _waitForClose = val),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStyleTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      children: <Widget>[
        // MA Checkbox & Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            // Left: [x] MA
            GestureDetector(
              onTap: () => setState(() => _isMaVisible = !_isMaVisible),
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _buildCustomCheckbox(_isMaVisible),
                  const SizedBox(width: 10),
                  const Text(
                    'MA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),

            // Right: Trendline-style combined pill button
            GestureDetector(
              onTap: _openColorPickerModal,
              child: Container(
                key: _swatchKey,
                width: 82,
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isColorPickerOpen ? const Color(0xFF2962FF) : const Color(0xFF3A3A3C),
                    width: 1.5,
                  ),
                  boxShadow: _isColorPickerOpen
                      ? const <BoxShadow>[
                          BoxShadow(color: Color(0x662962FF), blurRadius: 4, spreadRadius: 1),
                        ]
                      : null,
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: _color.withValues(alpha: _opacity),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Center(
                        child: CustomPaint(
                          size: const Size(34, 12),
                          painter: _LinePreviewPainter(
                            color: _color.withValues(alpha: _opacity),
                            width: _lineWidth.toDouble().clamp(1.0, 4.0),
                            lineStyle: _lineStyle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),

        // Section: OUTPUT VALUES
        _buildSectionHeader('OUTPUT VALUES'),
        const SizedBox(height: 16),

        // Precision
        _buildRow(
          label: 'Precision',
          control: _buildPickerTrigger(
            value: _precision,
            width: _controlWidth,
            onTap: () {
              _openPickerSheet(
                title: 'Precision',
                items: _precisionItems,
                currentValue: _precision,
                onSelected: (String val) => setState(() => _precision = val),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Labels on price scale
        _buildCheckboxRow(
          label: 'Labels on price scale',
          value: _labelsOnPriceScale,
          onChanged: (bool val) => setState(() => _labelsOnPriceScale = val),
        ),
        const SizedBox(height: 16),

        // Values in status line
        _buildCheckboxRow(
          label: 'Values in status line',
          value: _valuesInStatusLine,
          onChanged: (bool val) => setState(() => _valuesInStatusLine = val),
        ),
        const SizedBox(height: 26),

        // Section: INPUT VALUES
        _buildSectionHeader('INPUT VALUES'),
        const SizedBox(height: 16),

        // Inputs in status line
        _buildCheckboxRow(
          label: 'Inputs in status line',
          value: _inputsInStatusLine,
          onChanged: (bool val) => setState(() => _inputsInStatusLine = val),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: _subtitleColor,
        fontSize: 11.5,
        letterSpacing: 0.8,
        fontWeight: FontWeight.w600,
        decoration: TextDecoration.none,
      ),
    );
  }

  Widget _buildRow({
    String? label,
    Widget? labelWidget,
    required Widget control,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        labelWidget ??
            Text(
              label ?? '',
              style: const TextStyle(
                color: Color(0xFFD1D4DC),
                fontSize: 14,
                fontWeight: FontWeight.w400,
                decoration: TextDecoration.none,
              ),
            ),
        control,
      ],
    );
  }

  Widget _buildNumberInput({
    required TextEditingController controller,
    double width = _controlWidth,
    bool allowNegative = false,
  }) {
    return Container(
      width: width,
      height: 38,
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _cardBorder),
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(signed: allowNegative),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: const InputDecoration(
          filled: false,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildDisabledInput({required String text, double width = _controlWidth}) {
    return Container(
      width: width,
      height: 38,
      decoration: BoxDecoration(
        color: _cardBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _cardBorder.withValues(alpha: 0.6)),
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF50535E),
          fontSize: 14,
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  Widget _buildPickerTrigger({
    required String value,
    required VoidCallback onTap,
    double width = _controlWidth,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: width,
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _cardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF868993),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  void _openPickerSheet({
    required String title,
    required List<String> items,
    required String currentValue,
    required ValueChanged<String> onSelected,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (BuildContext pickerCtx) {
        final double maxHeight = MediaQuery.of(context).size.height * 0.68;
        return Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: const BoxDecoration(
            color: _sheetBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(color: _cardBorder, width: 1),
            ),
          ),
          child: SafeArea(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (BuildContext context, int index) {
                final String item = items[index];
                final bool isSelected = item == currentValue;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(pickerCtx).pop();
                      onSelected(item);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildCheckboxRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: <Widget>[
          _buildCustomCheckbox(value),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFD1D4DC),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomCheckbox(bool isChecked) {
    return Container(
      width: 19,
      height: 19,
      decoration: BoxDecoration(
        color: isChecked ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isChecked ? Colors.white : const Color(0xFF50535E),
          width: 1.6,
        ),
      ),
      alignment: Alignment.center,
      child: isChecked
          ? const Icon(
              Icons.check_rounded,
              size: 14,
              color: Colors.black,
            )
          : null,
    );
  }

  void _openColorPickerModal() {
    final RenderBox? renderBox = _swatchKey.currentContext?.findRenderObject() as RenderBox?;
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final double screenWidth = mediaQuery.size.width;
    final double screenHeight = mediaQuery.size.height;
    const double verticalGap = 6.0;

    // Exact width from tv-trendline-style-popover in tv_chart.html (310px)
    final double popoverWidth = 310.0.clamp(280.0, screenWidth - 24.0);

    // Position top: right below the swatch button + 6px (matching topOffset in tv_chart.html)
    double top = renderBox != null
        ? renderBox.localToGlobal(Offset.zero).dy + renderBox.size.height + verticalGap
        : 180.0;

    // Position right: aligned with the right edge of the swatch pill (matching rightOffset in tv_chart.html)
    final double swatchRightEdge = renderBox != null
        ? screenWidth - (renderBox.localToGlobal(Offset.zero).dx + renderBox.size.width)
        : 16.0;
    final double right = swatchRightEdge.clamp(12.0, screenWidth - popoverWidth - 12.0);

    final double bottomMargin = mediaQuery.padding.bottom + 16.0;
    double maxAvailableHeight = screenHeight - top - bottomMargin;
    if (maxAvailableHeight < 280 && renderBox != null) {
      final double boxTop = renderBox.localToGlobal(Offset.zero).dy;
      if (boxTop > maxAvailableHeight) {
        top = (boxTop - verticalGap - 480).clamp(mediaQuery.padding.top + 16.0, boxTop - verticalGap);
        maxAvailableHeight = boxTop - verticalGap - top;
      }
    }

    setState(() => _isColorPickerOpen = true);

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'DismissColorPicker',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 140),
      transitionBuilder: (BuildContext ctx, Animation<double> anim, Animation<double> secAnim, Widget child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        );
      },
      pageBuilder: (BuildContext dialogCtx, Animation<double> anim, Animation<double> secAnim) {
        return StatefulBuilder(
          builder: (BuildContext ctx, void Function(void Function()) dialogSetState) {
            return Stack(
              children: <Widget>[
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => Navigator.of(dialogCtx).pop(),
                  ),
                ),
                Positioned(
                  top: top,
                  right: right,
                  width: popoverWidth,
                  child: Material(
                    type: MaterialType.transparency,
                    child: Container(
                      width: popoverWidth,
                      constraints: BoxConstraints(
                        maxHeight: maxAvailableHeight.clamp(200.0, 520.0),
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2C2C2E), width: 1),
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
                            // 1. Color palette grid (10x8)
                            Column(
                              children: _tradingViewColorMatrix.asMap().entries.map((MapEntry<int, List<Color>> rowEntry) {
                                final int rIdx = rowEntry.key;
                                final List<Color> row = rowEntry.value;
                                return Padding(
                                  padding: EdgeInsets.only(bottom: rIdx < _tradingViewColorMatrix.length - 1 ? 4.0 : 0.0),
                                  child: Row(
                                    children: row.asMap().entries.map((MapEntry<int, Color> colEntry) {
                                      final int cIdx = colEntry.key;
                                      final Color c = colEntry.value;
                                      final bool isSelected =
                                          (_color.toARGB32() & 0xFFFFFF) == (c.toARGB32() & 0xFFFFFF);
                                      return Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.only(right: cIdx < row.length - 1 ? 4.0 : 0.0),
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _color = c;
                                                if (!_recentColors.any((Color rc) =>
                                                    (rc.toARGB32() & 0xFFFFFF) == (c.toARGB32() & 0xFFFFFF))) {
                                                  _recentColors.insert(0, c);
                                                  if (_recentColors.length > 4) _recentColors.removeLast();
                                                }
                                              });
                                              dialogSetState(() {});
                                            },
                                            child: AspectRatio(
                                              aspectRatio: 1.0,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: c,
                                                  borderRadius: BorderRadius.circular(3.5),
                                                  border: isSelected
                                                      ? Border.all(color: Colors.white, width: 2.0)
                                                      : null,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                );
                              }).toList(),
                            ),

                    // 2. Recent colors + Add button
                    Container(
                      height: 1,
                      color: const Color(0xFF2C2C2E),
                      margin: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    Row(
                      children: <Widget>[
                        ..._recentColors.map((Color c) {
                          final bool isSelected =
                              (_color.toARGB32() & 0xFFFFFF) == (c.toARGB32() & 0xFFFFFF);
                          return GestureDetector(
                            onTap: () {
                              setState(() => _color = c);
                              dialogSetState(() {});
                            },
                            child: Container(
                              width: 24,
                              height: 24,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: c,
                                borderRadius: BorderRadius.circular(5),
                                border: isSelected
                                    ? Border.all(color: Colors.white, width: 2)
                                    : null,
                              ),
                            ),
                          );
                        }),
                        GestureDetector(
                          onTap: () {
                            if (!_recentColors.any((Color rc) =>
                                (rc.toARGB32() & 0xFFFFFF) == (_color.toARGB32() & 0xFFFFFF))) {
                              setState(() {
                                _recentColors.insert(0, _color);
                                if (_recentColors.length > 4) _recentColors.removeLast();
                              });
                              dialogSetState(() {});
                            }
                          },
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: const Color(0xFF434651)),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.add, color: Color(0xFF8E8E93), size: 16),
                          ),
                        ),
                      ],
                    ),

                    // 3. Opacity section
                    const SizedBox(height: 6),
                    const Text(
                      'Opacity',
                      style: TextStyle(
                        color: _subtitleColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 12,
                              trackShape: _OpacitySliderTrackShape(_color),
                              thumbShape: _OpacitySliderThumbShape(),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                            ),
                            child: Slider(
                              value: _opacity.clamp(0.0, 1.0),
                              min: 0.0,
                              max: 1.0,
                              onChanged: (double val) {
                                setState(() => _opacity = val);
                                dialogSetState(() {});
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 48,
                          height: 26,
                          decoration: BoxDecoration(
                            color: _cardBg,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFF434651)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${(_opacity * 100).round()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // 4. Thickness section
                    const SizedBox(height: 12),
                    const Text(
                      'Thickness',
                      style: TextStyle(
                        color: _subtitleColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF3A3A3C)),
                      ),
                      child: Row(
                        children: <int>[1, 2, 3, 4].map((int w) {
                          final bool isSelected = _lineWidth == w;
                          final bool isLast = w == 4;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _lineWidth = w);
                                dialogSetState(() {});
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : Colors.transparent,
                                  border: isLast
                                      ? null
                                      : const Border(
                                          right: BorderSide(color: Color(0xFF3A3A3C)),
                                        ),
                                ),
                                alignment: Alignment.center,
                                child: Container(
                                  width: 26,
                                  height: w.toDouble(),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.black : Colors.white,
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // 5. Line style section
                    const SizedBox(height: 12),
                    const Text(
                      'Line style',
                      style: TextStyle(
                        color: _subtitleColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF3A3A3C)),
                      ),
                      child: Row(
                        children: <int>[0, 1, 2].map((int style) {
                          final bool isSelected = _lineStyle == style;
                          final bool isLast = style == 2;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _lineStyle = style);
                                dialogSetState(() {});
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : Colors.transparent,
                                  border: isLast
                                      ? null
                                      : const Border(
                                          right: BorderSide(color: Color(0xFF3A3A3C)),
                                        ),
                                ),
                                alignment: Alignment.center,
                                child: CustomPaint(
                                  size: const Size(34, 12),
                                  painter: _LinePreviewPainter(
                                    color: isSelected ? Colors.black : Colors.white,
                                    width: 2.0,
                                    lineStyle: style,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
          },
        );
      },
    ).whenComplete(() {
      if (mounted) {
        setState(() => _isColorPickerOpen = false);
      }
    });
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: _sheetBg,
        border: Border(
          top: BorderSide(color: _cardBorder, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          // Cancel
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _cardBorder),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Ok
          GestureDetector(
            onTap: _handleSave,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Ok',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



class _OpacitySliderTrackShape extends SliderTrackShape with BaseSliderTrackShape {
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

    final RRect rrect = RRect.fromRectAndRadius(trackRect, const Radius.circular(4));
    final Canvas canvas = context.canvas;

    canvas.save();
    canvas.clipRRect(rrect);

    // Dark background
    final Paint bgPaint = Paint()..color = const Color(0xFF1E222D);
    canvas.drawRRect(rrect, bgPaint);

    // Subtle checkered pattern underneath
    final Paint checkPaint = Paint()..color = const Color(0xFF2A2E39);
    const double checkSize = 4.0;
    for (double x = trackRect.left; x < trackRect.right; x += checkSize * 2) {
      for (double y = trackRect.top; y < trackRect.bottom; y += checkSize * 2) {
        canvas.drawRect(Rect.fromLTWH(x, y, checkSize, checkSize), checkPaint);
        canvas.drawRect(Rect.fromLTWH(x + checkSize, y + checkSize, checkSize, checkSize), checkPaint);
      }
    }

    // Gradient overlay from transparent to baseColor
    final Paint gradPaint = Paint()
      ..shader = LinearGradient(
        colors: <Color>[
          baseColor.withValues(alpha: 0.0),
          baseColor.withValues(alpha: 1.0),
        ],
      ).createShader(trackRect);
    canvas.drawRRect(rrect, gradPaint);

    // Border
    final Paint borderPaint = Paint()
      ..color = const Color(0xFF434651)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(rrect, borderPaint);

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
    // Outer black circle
    canvas.drawCircle(center, 9, Paint()..color = Colors.black);
    // Inner white circle
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
      // Solid
      canvas.drawLine(Offset(startX, y), Offset(endX, y), paint);
    } else if (lineStyle == 1) {
      // Dashed (5px dash, 3.5px space)
      const double dashWidth = 5.0;
      const double dashSpace = 3.5;
      double currentX = startX;
      while (currentX < endX) {
        final double nextX = (currentX + dashWidth).clamp(startX, endX);
        canvas.drawLine(Offset(currentX, y), Offset(nextX, y), paint);
        currentX += dashWidth + dashSpace;
      }
    } else {
      // Dotted (dots spaced by 4px)
      const double dotSpace = 4.0;
      final double radius = (width / 2).clamp(1.0, 2.0);
      double currentX = startX;
      while (currentX <= endX) {
        canvas.drawCircle(Offset(currentX, y), radius, Paint()..color = color);
        currentX += dotSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LinePreviewPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.width != width ||
        oldDelegate.lineStyle != lineStyle;
  }
}
