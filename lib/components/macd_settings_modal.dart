import 'package:flutter/material.dart';

import '../data/model/active_chart_indicator.dart';
import '../data/model/indicator_level.dart';
import '../data/model/indicator_line_style.dart';
import '../data/model/indicator_macd.dart';
import 'indicator_settings_form.dart';

/// Settings Moving Average Convergence Divergence (MACD) ala TradingView.
class MacdSettingsModal extends StatefulWidget {
  final ActiveChartIndicator indicator;
  final ValueChanged<ActiveChartIndicator> onSave;

  const MacdSettingsModal({
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
    builder: (_) => MacdSettingsModal(indicator: indicator, onSave: onSave),
  );

  @override
  State<MacdSettingsModal> createState() => _MacdSettingsModalState();
}

class _MacdSettingsModalState extends State<MacdSettingsModal> {
  static const double _levelFieldWidth = 64;
  static const Map<MacdTrend, String> _histogramLabels = <MacdTrend, String>{
    MacdTrend.growAbove: 'Grow above zero',
    MacdTrend.fallAbove: 'Fall above zero',
    MacdTrend.growBelow: 'Grow below zero',
    MacdTrend.fallBelow: 'Fall below zero',
  };

  // Inputs
  late final TextEditingController _fastLengthController;
  late final TextEditingController _slowLengthController;
  late final TextEditingController _signalLengthController;
  late String _source;
  late String _oscillatorMaType;
  late String _signalMaType;

  // Style
  late MacdHistogramStyle _histogram;
  late IndicatorLineStyle _macdStyle;
  late IndicatorLineStyle _signalStyle;
  late IndicatorLineStyle _zeroLineStyle;
  late final TextEditingController _zeroLineController;
  late IndicatorOutputSettings _output;

  @override
  void initState() {
    super.initState();
    final ActiveChartIndicator ind = widget.indicator;
    final MacdSettings macd = ind.macd;
    _fastLengthController = TextEditingController(text: '${macd.fastLength}');
    _slowLengthController = TextEditingController(text: '${macd.slowLength}');
    _signalLengthController = TextEditingController(
      text: '${macd.signalLength}',
    );
    _source = ind.source;
    _oscillatorMaType = macd.oscillatorMaType;
    _signalMaType = macd.signalMaType;
    _histogram = macd.histogram;
    _macdStyle = IndicatorLineStyle(
      color: ind.color ?? const Color(0xFF2962FF),
      lineWidth: ind.lineWidth,
      lineStyle: ind.lineStyle,
      isVisible: ind.isLineVisible,
    );
    _signalStyle = macd.signalStyle;
    _zeroLineStyle = macd.zeroLine.style;
    _zeroLineController = TextEditingController(
      text: formatNumber(macd.zeroLine.value),
    );
    _output = IndicatorOutputSettings.of(ind);
  }

  @override
  void dispose() {
    _fastLengthController.dispose();
    _slowLengthController.dispose();
    _signalLengthController.dispose();
    _zeroLineController.dispose();
    super.dispose();
  }

  void _save() {
    final ActiveChartIndicator ind = widget.indicator;
    final MacdSettings macd = ind.macd;
    final ActiveChartIndicator updated = _output.applyTo(
      ind.copyWith(
        source: _source,
        isLineVisible: _macdStyle.isVisible,
        color: _macdStyle.color,
        lineWidth: _macdStyle.lineWidth,
        lineStyle: _macdStyle.lineStyle,
        macd: macd.copyWith(
          fastLength: parsePositiveInt(
            _fastLengthController.text,
            macd.fastLength,
          ),
          slowLength: parsePositiveInt(
            _slowLengthController.text,
            macd.slowLength,
          ),
          signalLength: parsePositiveInt(
            _signalLengthController.text,
            macd.signalLength,
          ),
          oscillatorMaType: _oscillatorMaType,
          signalMaType: _signalMaType,
          histogram: _histogram,
          signalStyle: _signalStyle,
          zeroLine: IndicatorLevel(
            value: parseNumber(_zeroLineController.text, macd.zeroLine.value),
            style: _zeroLineStyle,
          ),
        ),
      ),
    );
    widget.onSave(updated.copyWith(title: updated.inputsTitle));
  }

  Widget _buildMaTypeRow({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return SettingsRow(
      label: label,
      control: SettingsSelect(
        title: label,
        value: value,
        items: MacdSettings.maTypes,
        onChanged: (String type) => setState(() => onChanged(type)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IndicatorSettingsSheet(
      title: 'MACD',
      onSave: _save,
      inputs: <Widget>[
        SettingsRow(
          label: 'Fast Length',
          control: SettingsNumberField(controller: _fastLengthController),
        ),
        const SizedBox(height: 16),
        SettingsRow(
          label: 'Slow Length',
          control: SettingsNumberField(controller: _slowLengthController),
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
        const SizedBox(height: 16),
        SettingsRow(
          label: 'Signal Smoothing',
          control: SettingsNumberField(controller: _signalLengthController),
        ),
        const SizedBox(height: 16),
        _buildMaTypeRow(
          label: 'Oscillator MA Type',
          value: _oscillatorMaType,
          onChanged: (String value) => _oscillatorMaType = value,
        ),
        const SizedBox(height: 16),
        _buildMaTypeRow(
          label: 'Signal Line MA Type',
          value: _signalMaType,
          onChanged: (String value) => _signalMaType = value,
        ),
        const SizedBox(height: 20),
      ],
      style: <Widget>[
        ToggleStyleRow(
          label: 'Histogram',
          isVisible: _histogram.isVisible,
          onVisibilityChanged: (bool visible) => setState(
            () => _histogram = _histogram.copyWith(isVisible: visible),
          ),
          controls: const <Widget>[],
        ),
        for (final MapEntry<MacdTrend, String>(key: MacdTrend trend, :value)
            in _histogramLabels.entries) ...<Widget>[
          const SizedBox(height: 12),
          SettingsColorSubRow(
            label: value,
            color: _histogram.colorOf(trend),
            onChanged: (Color color) =>
                setState(() => _histogram = _histogram.withColor(trend, color)),
          ),
        ],
        const SizedBox(height: 16),
        PlotStyleRow(
          label: 'MACD',
          value: _macdStyle,
          onChanged: (IndicatorLineStyle value) =>
              setState(() => _macdStyle = value),
        ),
        const SizedBox(height: 16),
        PlotStyleRow(
          label: 'Signal Line',
          value: _signalStyle,
          onChanged: (IndicatorLineStyle value) =>
              setState(() => _signalStyle = value),
        ),
        const SizedBox(height: 16),
        PlotStyleRow(
          label: 'Zero Line',
          value: _zeroLineStyle,
          onChanged: (IndicatorLineStyle value) =>
              setState(() => _zeroLineStyle = value),
          trailing: SettingsNumberField(
            controller: _zeroLineController,
            allowNegative: true,
            allowDecimal: true,
            width: _levelFieldWidth,
          ),
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
