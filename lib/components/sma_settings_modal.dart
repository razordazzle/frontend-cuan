import 'package:flutter/material.dart';

import '../data/model/active_chart_indicator.dart';
import '../data/model/indicator_line_style.dart';
import 'indicator_settings_form.dart';

/// Settings Moving Average (SMA) ala TradingView.
class SmaSettingsModal extends StatefulWidget {
  final ActiveChartIndicator indicator;
  final ValueChanged<ActiveChartIndicator> onSave;

  const SmaSettingsModal({
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
    builder: (_) => SmaSettingsModal(indicator: indicator, onSave: onSave),
  );

  @override
  State<SmaSettingsModal> createState() => _SmaSettingsModalState();
}

class _SmaSettingsModalState extends State<SmaSettingsModal> {
  // Inputs
  late final TextEditingController _lengthController;
  late final TextEditingController _offsetController;
  late final TextEditingController _smoothingLengthController;
  late String _source;
  late String _smoothingType;

  // Style
  late IndicatorLineStyle _maStyle;
  late IndicatorLineStyle _smoothingStyle;
  late IndicatorOutputSettings _output;

  bool get _hasSmoothing => _smoothingType != 'None';

  @override
  void initState() {
    super.initState();
    final ActiveChartIndicator ind = widget.indicator;
    _lengthController = TextEditingController(text: '${ind.period}');
    _offsetController = TextEditingController(text: '${ind.offset}');
    _smoothingLengthController = TextEditingController(
      text: '${ind.smoothingLength}',
    );
    _source = ind.source;
    _smoothingType = ind.smoothingType;
    _maStyle = IndicatorLineStyle(
      color: ind.color ?? const Color(0xFF2962FF),
      lineWidth: ind.lineWidth,
      lineStyle: ind.lineStyle,
      isVisible: ind.isVisible,
    );
    _smoothingStyle = ind.smoothingStyle;
    _output = IndicatorOutputSettings.of(ind);
  }

  @override
  void dispose() {
    _lengthController.dispose();
    _offsetController.dispose();
    _smoothingLengthController.dispose();
    super.dispose();
  }

  void _save() {
    final ActiveChartIndicator ind = widget.indicator;
    final ActiveChartIndicator updated = _output.applyTo(
      ind.copyWith(
        period: parsePositiveInt(_lengthController.text, ind.period),
        offset: int.tryParse(_offsetController.text.trim()) ?? 0,
        source: _source,
        smoothingType: _smoothingType,
        smoothingLength: parsePositiveInt(
          _smoothingLengthController.text,
          ind.smoothingLength,
        ),
        smoothingStyle: _smoothingStyle,
        isVisible: _maStyle.isVisible,
        color: _maStyle.color,
        lineWidth: _maStyle.lineWidth,
        lineStyle: _maStyle.lineStyle,
      ),
    );
    widget.onSave(updated.copyWith(title: updated.inputsTitle));
  }

  @override
  Widget build(BuildContext context) {
    return IndicatorSettingsSheet(
      title: 'SMA',
      onSave: _save,
      inputs: <Widget>[
        SettingsRow(
          label: 'Length',
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
        const SizedBox(height: 16),
        SettingsRow(
          label: 'Offset',
          control: SettingsNumberField(
            controller: _offsetController,
            allowNegative: true,
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
            items: SettingsOptions.movingAverages,
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
        const SizedBox(height: 20),
      ],
      style: <Widget>[
        PlotStyleRow(
          label: 'MA',
          value: _maStyle,
          onChanged: (IndicatorLineStyle value) =>
              setState(() => _maStyle = value),
        ),
        if (_hasSmoothing) ...<Widget>[
          const SizedBox(height: 16),
          PlotStyleRow(
            label: 'Smoothing MA',
            value: _smoothingStyle,
            onChanged: (IndicatorLineStyle value) =>
                setState(() => _smoothingStyle = value),
          ),
        ],
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
