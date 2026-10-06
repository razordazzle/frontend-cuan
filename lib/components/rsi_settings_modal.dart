import 'package:flutter/material.dart';

import '../data/model/active_chart_indicator.dart';
import '../data/model/indicator_level.dart';
import '../data/model/indicator_line_style.dart';
import 'indicator_settings_form.dart';

/// Settings Relative Strength Index (RSI) ala TradingView.
class RsiSettingsModal extends StatefulWidget {
  final ActiveChartIndicator indicator;
  final ValueChanged<ActiveChartIndicator> onSave;

  const RsiSettingsModal({
    super.key,
    required this.indicator,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    required ActiveChartIndicator indicator,
    required ValueChanged<ActiveChartIndicator> onSave,
  }) => IndicatorSettingsSheet.show(
    context: context,
    builder: (_) => RsiSettingsModal(indicator: indicator, onSave: onSave),
  );

  @override
  State<RsiSettingsModal> createState() => _RsiSettingsModalState();
}

/// Satu garis level (atas/tengah/bawah) yang sedang diedit di modal.
class _LevelDraft {
  final String label;
  final TextEditingController controller;
  IndicatorLineStyle style;

  _LevelDraft(this.label, IndicatorLevel level)
    : controller = TextEditingController(text: _formatLevel(level.value)),
      style = level.style;

  static String _formatLevel(double value) =>
      value == value.roundToDouble() ? value.toInt().toString() : '$value';

  IndicatorLevel toLevel(IndicatorLevel fallback) => IndicatorLevel(
    value: parseNumber(controller.text, fallback.value),
    style: style,
  );
}

class _RsiSettingsModalState extends State<RsiSettingsModal> {
  static const List<String> _smoothingItems = <String>[
    'None',
    'SMA',
    ActiveChartIndicator.bollingerSmoothingType,
    'EMA',
    'SMMA (RMA)',
    'WMA',
    'VWMA',
  ];
  static const double _levelFieldWidth = 64;

  // Inputs
  late final TextEditingController _lengthController;
  late final TextEditingController _smoothingLengthController;
  late final TextEditingController _bbStdDevController;
  late String _source;
  late String _smoothingType;

  // Style
  late IndicatorLineStyle _rsiStyle;
  late IndicatorLineStyle _smoothingStyle;
  late IndicatorLineStyle _bollingerStyle;
  late final _LevelDraft _upper;
  late final _LevelDraft _middle;
  late final _LevelDraft _lower;
  late IndicatorFill _bandsFill;
  late IndicatorGradientFill _overboughtFill;
  late IndicatorGradientFill _oversoldFill;
  late IndicatorOutputSettings _output;

  bool get _hasSmoothing => _smoothingType != 'None';
  bool get _hasBollingerBands =>
      _smoothingType == ActiveChartIndicator.bollingerSmoothingType;

  @override
  void initState() {
    super.initState();
    final ActiveChartIndicator ind = widget.indicator;
    _lengthController = TextEditingController(text: '${ind.period}');
    _smoothingLengthController = TextEditingController(
      text: '${ind.smoothingLength}',
    );
    _bbStdDevController = TextEditingController(text: '${ind.bbStdDev}');
    _source = ind.source;
    _smoothingType = ind.smoothingType;
    _rsiStyle = IndicatorLineStyle(
      color: ind.color ?? const Color(0xFFE91E63),
      lineWidth: ind.lineWidth,
      lineStyle: ind.lineStyle,
      isVisible: ind.isLineVisible,
    );
    _smoothingStyle = ind.smoothingStyle;
    _bollingerStyle = ind.bollingerStyle;
    _upper = _LevelDraft('RSI Upper Band', ind.upperLevel);
    _middle = _LevelDraft('RSI Middle Band', ind.middleLevel);
    _lower = _LevelDraft('RSI Lower Band', ind.lowerLevel);
    _bandsFill = ind.bandsFill;
    _overboughtFill = ind.overboughtFill;
    _oversoldFill = ind.oversoldFill;
    _output = IndicatorOutputSettings.of(ind);
  }

  @override
  void dispose() {
    _lengthController.dispose();
    _smoothingLengthController.dispose();
    _bbStdDevController.dispose();
    for (final _LevelDraft level in <_LevelDraft>[_upper, _middle, _lower]) {
      level.controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    final ActiveChartIndicator ind = widget.indicator;
    final double bbStdDev = parseNumber(_bbStdDevController.text, ind.bbStdDev);
    final ActiveChartIndicator updated = _output.applyTo(
      ind.copyWith(
        period: parsePositiveInt(_lengthController.text, ind.period),
        source: _source,
        smoothingType: _smoothingType,
        smoothingLength: parsePositiveInt(
          _smoothingLengthController.text,
          ind.smoothingLength,
        ),
        bbStdDev: bbStdDev > 0 ? bbStdDev : ind.bbStdDev,
        isLineVisible: _rsiStyle.isVisible,
        color: _rsiStyle.color,
        lineWidth: _rsiStyle.lineWidth,
        lineStyle: _rsiStyle.lineStyle,
        smoothingStyle: _smoothingStyle,
        bollingerStyle: _bollingerStyle,
        upperLevel: _upper.toLevel(ind.upperLevel),
        middleLevel: _middle.toLevel(ind.middleLevel),
        lowerLevel: _lower.toLevel(ind.lowerLevel),
        bandsFill: _bandsFill,
        overboughtFill: _overboughtFill,
        oversoldFill: _oversoldFill,
      ),
    );
    widget.onSave(updated.copyWith(title: updated.inputsTitle));
  }

  Widget _buildLevelRow(_LevelDraft level) {
    return PlotStyleRow(
      label: level.label,
      value: level.style,
      onChanged: (IndicatorLineStyle value) =>
          setState(() => level.style = value),
      trailing: SettingsNumberField(
        controller: level.controller,
        allowNegative: true,
        allowDecimal: true,
        width: _levelFieldWidth,
      ),
    );
  }

  /// [onChanged] hanya meng-assign state; setState dilakukan di sini.
  Widget _buildGradientRow({
    required String label,
    required IndicatorGradientFill value,
    required ValueChanged<IndicatorGradientFill> onChanged,
  }) {
    return ToggleStyleRow(
      label: label,
      isVisible: value.isVisible,
      onVisibilityChanged: (bool visible) =>
          setState(() => onChanged(value.copyWith(isVisible: visible))),
      controls: <Widget>[
        FillColorSwatch(
          color: value.topColor,
          onChanged: (Color color) =>
              setState(() => onChanged(value.copyWith(topColor: color))),
        ),
        FillColorSwatch(
          color: value.bottomColor,
          onChanged: (Color color) =>
              setState(() => onChanged(value.copyWith(bottomColor: color))),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return IndicatorSettingsSheet(
      title: 'RSI',
      onSave: _save,
      inputs: <Widget>[
        const SettingsSectionHeader('RSI SETTINGS'),
        const SizedBox(height: 16),
        SettingsRow(
          label: 'RSI Length',
          control: SettingsNumberField(controller: _lengthController),
        ),
        const SizedBox(height: 16),
        SettingsRow(
          label: 'Source',
          control: SettingsSelect(
            title: 'Source',
            value: _source,
            items: SettingsOptions.sources,
            onChanged: (String value) => setState(() => _source = value),
          ),
        ),
        const SizedBox(height: 26),
        const SettingsSectionHeader('SMOOTHING'),
        const SizedBox(height: 16),
        SettingsRow(
          label: 'Type',
          control: SettingsSelect(
            title: 'Type',
            value: _smoothingType,
            items: _smoothingItems,
            onChanged: (String value) => setState(() => _smoothingType = value),
          ),
        ),
        const SizedBox(height: 16),
        SettingsRow(
          label: 'Length',
          enabled: _hasSmoothing,
          control: SettingsNumberField(
            controller: _smoothingLengthController,
            enabled: _hasSmoothing,
          ),
        ),
        const SizedBox(height: 16),
        SettingsRow(
          label: 'BB StdDev',
          enabled: _hasBollingerBands,
          control: SettingsNumberField(
            controller: _bbStdDevController,
            enabled: _hasBollingerBands,
            allowDecimal: true,
          ),
        ),
        const SizedBox(height: 20),
      ],
      style: <Widget>[
        PlotStyleRow(
          label: 'RSI',
          value: _rsiStyle,
          onChanged: (IndicatorLineStyle value) =>
              setState(() => _rsiStyle = value),
        ),
        if (_hasSmoothing) ...<Widget>[
          const SizedBox(height: 16),
          PlotStyleRow(
            label: 'RSI-based MA',
            value: _smoothingStyle,
            onChanged: (IndicatorLineStyle value) =>
                setState(() => _smoothingStyle = value),
          ),
        ],
        if (_hasBollingerBands) ...<Widget>[
          const SizedBox(height: 16),
          PlotStyleRow(
            label: 'Bollinger Bands',
            value: _bollingerStyle,
            onChanged: (IndicatorLineStyle value) =>
                setState(() => _bollingerStyle = value),
          ),
        ],
        const SizedBox(height: 16),
        _buildLevelRow(_upper),
        const SizedBox(height: 16),
        _buildLevelRow(_middle),
        const SizedBox(height: 16),
        _buildLevelRow(_lower),
        const SizedBox(height: 16),
        ToggleStyleRow(
          label: 'RSI Background Fill',
          isVisible: _bandsFill.isVisible,
          onVisibilityChanged: (bool visible) => setState(
            () => _bandsFill = _bandsFill.copyWith(isVisible: visible),
          ),
          controls: <Widget>[
            FillColorSwatch(
              color: _bandsFill.color,
              onChanged: (Color color) => setState(
                () => _bandsFill = _bandsFill.copyWith(color: color),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildGradientRow(
          label: 'Overbought Gradient Fill',
          value: _overboughtFill,
          onChanged: (IndicatorGradientFill value) => _overboughtFill = value,
        ),
        const SizedBox(height: 16),
        _buildGradientRow(
          label: 'Oversold Gradient Fill',
          value: _oversoldFill,
          onChanged: (IndicatorGradientFill value) => _oversoldFill = value,
        ),
        const SizedBox(height: 26),
        OutputSettingsSection(
          value: _output,
          onChanged: (IndicatorOutputSettings value) =>
              setState(() => _output = value),
        ),
      ],
    );
  }
}
