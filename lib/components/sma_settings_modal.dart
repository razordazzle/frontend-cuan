import 'package:flutter/material.dart';
import '../data/model/active_chart_indicator.dart';
import '../data/model/indicator_line_style.dart';
import 'line_style_picker.dart';

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

  // Style state
  late IndicatorLineStyle _maStyle;
  late IndicatorLineStyle _smoothingStyle;
  final GlobalKey _maSwatchKey = GlobalKey();
  final GlobalKey _smoothingSwatchKey = GlobalKey();

  /// Swatch yang color picker-nya sedang terbuka (untuk highlight).
  GlobalKey? _openPickerKey;
  late String _precision;
  late bool _labelsOnPriceScale;
  late bool _valuesInStatusLine;
  late bool _inputsInStatusLine;

  // Color tokens harmonized with _DrawingsBottomSheetWidget (#121212 & #1E1E1E)
  static const Color _sheetBg = Color(0xFF121212);
  static const Color _cardBg = Color(0xFF1E1E1E);
  static const Color _cardBorder = Color(0xFF2C2C2E);
  static const Color _closeBtnBg = Color(0xFF242426);
  static const Color _subtitleColor = Color(0xFF8E8E93);
  static const Color _textColor = Colors.white;

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

    _maStyle = IndicatorLineStyle(
      color: ind.color ?? const Color(0xFF2962FF),
      lineWidth: ind.lineWidth,
      lineStyle: ind.lineStyle,
      isVisible: ind.isVisible,
    );
    _smoothingStyle = ind.smoothingStyle;
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

    final int period = newPeriod > 0 ? newPeriod : 20;
    final int smoothingLength = newSmoothingLength > 0 ? newSmoothingLength : 14;
    final bool hasSmoothing = _smoothingType != 'None';

    // Format title (e.g. "SMA 20 close" / "SMA 20 close EMA 14")
    final String newTitle = <String>[
      'SMA $period ${_source.toLowerCase()}',
      if (hasSmoothing) '$_smoothingType $smoothingLength',
    ].join(' ');

    final ActiveChartIndicator updated = widget.indicator.copyWith(
      period: period,
      offset: newOffset,
      source: _source,
      smoothingType: _smoothingType,
      smoothingLength: smoothingLength,
      smoothingStyle: _smoothingStyle,
      isVisible: _maStyle.isVisible,
      color: _maStyle.color,
      lineWidth: _maStyle.lineWidth,
      lineStyle: _maStyle.lineStyle,
      precision: _precision,
      labelsOnPriceScale: _labelsOnPriceScale,
      valuesInStatusLine: _valuesInStatusLine,
      inputsInStatusLine: _inputsInStatusLine,
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
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStyleTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      children: <Widget>[
        _buildPlotStyleRow(
          label: 'MA',
          style: _maStyle,
          swatchKey: _maSwatchKey,
          onChanged: (IndicatorLineStyle style) => _maStyle = style,
        ),
        if (_smoothingType != 'None') ...<Widget>[
          const SizedBox(height: 16),
          _buildPlotStyleRow(
            label: 'Smoothing MA',
            style: _smoothingStyle,
            swatchKey: _smoothingSwatchKey,
            onChanged: (IndicatorLineStyle style) => _smoothingStyle = style,
          ),
        ],
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

  /// Baris style satu plot: [checkbox visible] label ........ [swatch warna + preview garis]
  ///
  /// [onChanged] hanya meng-assign state; setState dilakukan oleh pemanggilnya.
  Widget _buildPlotStyleRow({
    required String label,
    required IndicatorLineStyle style,
    required GlobalKey swatchKey,
    required ValueChanged<IndicatorLineStyle> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        GestureDetector(
          onTap: () => setState(
            () => onChanged(style.copyWith(isVisible: !style.isVisible)),
          ),
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildCustomCheckbox(style.isVisible),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
        LineStyleSwatchButton(
          key: swatchKey,
          value: style,
          isActive: _openPickerKey == swatchKey,
          onTap: () => _openLineStylePicker(swatchKey, style, onChanged),
        ),
      ],
    );
  }

  Future<void> _openLineStylePicker(
    GlobalKey swatchKey,
    IndicatorLineStyle style,
    ValueChanged<IndicatorLineStyle> onChanged,
  ) async {
    setState(() => _openPickerKey = swatchKey);
    await showLineStylePicker(
      context: context,
      anchorKey: swatchKey,
      initialValue: style,
      onChanged: (IndicatorLineStyle value) => setState(() => onChanged(value)),
    );
    if (mounted) setState(() => _openPickerKey = null);
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
