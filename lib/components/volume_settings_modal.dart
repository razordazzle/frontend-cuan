import 'package:flutter/material.dart';

import '../data/model/active_chart_indicator.dart';
import '../data/model/indicator_line_style.dart';
import 'indicator_settings_form.dart';

/// Settings Volume ala TradingView.
class VolumeSettingsModal extends StatefulWidget {
  final ActiveChartIndicator indicator;
  final ValueChanged<ActiveChartIndicator> onSave;

  const VolumeSettingsModal({
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
    builder: (_) => VolumeSettingsModal(indicator: indicator, onSave: onSave),
  );

  @override
  State<VolumeSettingsModal> createState() => _VolumeSettingsModalState();
}

class _VolumeSettingsModalState extends State<VolumeSettingsModal> {
  /// Indent baris Growing/Falling agar sejajar label "Volume" (checkbox 19 + jarak 10).
  static const EdgeInsets _subRowPadding = EdgeInsets.only(left: 29);

  // Inputs
  late final TextEditingController _maLengthController;
  late bool _colorByPreviousClose;

  // Style
  late bool _isVolumeVisible;
  late Color _growingColor;
  late Color _fallingColor;
  late IndicatorLineStyle _maStyle;
  late IndicatorOutputSettings _output;

  @override
  void initState() {
    super.initState();
    final ActiveChartIndicator ind = widget.indicator;
    _maLengthController = TextEditingController(text: '${ind.period}');
    _colorByPreviousClose = ind.colorByPreviousClose;
    _isVolumeVisible = ind.isLineVisible;
    _growingColor = ind.volumeGrowingColor;
    _fallingColor = ind.volumeFallingColor;
    _maStyle = ind.smoothingStyle;
    _output = IndicatorOutputSettings.of(ind);
  }

  @override
  void dispose() {
    _maLengthController.dispose();
    super.dispose();
  }

  void _save() {
    final ActiveChartIndicator ind = widget.indicator;
    final ActiveChartIndicator updated = _output.applyTo(
      ind.copyWith(
        period: parsePositiveInt(_maLengthController.text, ind.period),
        colorByPreviousClose: _colorByPreviousClose,
        isLineVisible: _isVolumeVisible,
        volumeGrowingColor: _growingColor,
        volumeFallingColor: _fallingColor,
        smoothingStyle: _maStyle,
      ),
    );
    widget.onSave(updated.copyWith(title: updated.inputsTitle));
  }

  Widget _buildColorRow({
    required String label,
    required Color color,
    required ValueChanged<Color> onChanged,
  }) {
    return Padding(
      padding: _subRowPadding,
      child: SettingsRow(
        label: label,
        control: FillColorSwatch(
          color: color,
          onChanged: (Color value) => setState(() => onChanged(value)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IndicatorSettingsSheet(
      title: 'Volume',
      onSave: _save,
      inputs: <Widget>[
        SettingsRow(
          label: 'MA Length',
          control: SettingsNumberField(controller: _maLengthController),
        ),
        const SizedBox(height: 16),
        SettingsCheckboxRow(
          label: 'Color based on previous close',
          value: _colorByPreviousClose,
          onChanged: (bool value) =>
              setState(() => _colorByPreviousClose = value),
        ),
        const SizedBox(height: 20),
      ],
      style: <Widget>[
        ToggleStyleRow(
          label: 'Volume',
          isVisible: _isVolumeVisible,
          onVisibilityChanged: (bool visible) =>
              setState(() => _isVolumeVisible = visible),
          controls: const <Widget>[],
        ),
        const SizedBox(height: 12),
        _buildColorRow(
          label: 'Growing',
          color: _growingColor,
          onChanged: (Color color) => _growingColor = color,
        ),
        const SizedBox(height: 12),
        _buildColorRow(
          label: 'Falling',
          color: _fallingColor,
          onChanged: (Color color) => _fallingColor = color,
        ),
        const SizedBox(height: 16),
        PlotStyleRow(
          label: 'Volume MA',
          value: _maStyle,
          onChanged: (IndicatorLineStyle value) =>
              setState(() => _maStyle = value),
        ),
        const SizedBox(height: 26),
        OutputSettingsSection(
          value: _output,
          onChanged: (IndicatorOutputSettings value) =>
              setState(() => _output = value),
          showPrecision: false,
        ),
      ],
    );
  }
}
