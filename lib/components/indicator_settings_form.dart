import 'package:flutter/material.dart';

import '../data/model/active_chart_indicator.dart';
import '../data/model/indicator_line_style.dart';
import 'line_style_picker.dart';

/// Token warna modal settings indikator (selaras dengan sheet drawing: #121212 & #1E1E1E).
abstract final class SettingsColors {
  static const Color sheetBg = Color(0xFF121212);
  static const Color cardBg = Color(0xFF1E1E1E);
  static const Color cardBorder = Color(0xFF2C2C2E);
  static const Color closeButtonBg = Color(0xFF242426);
  static const Color subtitle = Color(0xFF8E8E93);
  static const Color label = Color(0xFFD1D4DC);
  static const Color disabledLabel = Color(0xFF787B86);
  static const Color disabledText = Color(0xFF50535E);
}

/// Pilihan dropdown yang dipakai bersama oleh modal settings indikator.
abstract final class SettingsOptions {
  static const List<String> sources = <String>[
    'Open',
    'High',
    'Low',
    'Close',
    '(H + L)/2',
    '(H + L + C)/3',
    '(O + H + L + C)/4',
  ];

  static const List<String> movingAverages = <String>[
    'None',
    'SMA',
    'EMA',
    'SMMA (RMA)',
    'WMA',
    'VWMA',
  ];

  static const List<String> precisions = <String>[
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
}

const double kSettingsControlWidth = 125;

/// Angka bulat > 0 dari input teks, atau [fallback] kalau tidak valid.
int parsePositiveInt(String text, int fallback) {
  final int? value = int.tryParse(text.trim());
  return value != null && value > 0 ? value : fallback;
}

/// Angka (boleh desimal) dari input teks, atau [fallback] kalau tidak valid.
double parseNumber(String text, double fallback) =>
    double.tryParse(text.trim().replaceAll(',', '.')) ?? fallback;

/// Kerangka modal settings indikator ala TradingView: header, tab Inputs/Style, tombol Cancel/Ok.
class IndicatorSettingsSheet extends StatefulWidget {
  final String title;
  final List<Widget> inputs;
  final List<Widget> style;

  /// Dipanggil saat Ok ditekan; sheet ditutup otomatis setelahnya.
  final VoidCallback onSave;

  const IndicatorSettingsSheet({
    super.key,
    required this.title,
    required this.inputs,
    required this.style,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    required WidgetBuilder builder,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: builder,
    );
  }

  @override
  State<IndicatorSettingsSheet> createState() => _IndicatorSettingsSheetState();
}

class _IndicatorSettingsSheetState extends State<IndicatorSettingsSheet> {
  static const List<String> _tabs = <String>['Inputs', 'Style'];

  int _activeTabIndex = 0;

  void _save() {
    widget.onSave();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: SettingsColors.sheetBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: SettingsColors.cardBorder, width: 1),
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
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                children: _activeTabIndex == 0 ? widget.inputs : widget.style,
              ),
            ),
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
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
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
                color: SettingsColors.closeButtonBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 18, color: Colors.white),
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
              for (final (int index, String title)
                  in _tabs.indexed) ...<Widget>[
                if (index > 0) const SizedBox(width: 24),
                _buildTabItem(title: title, index: index),
              ],
            ],
          ),
        ),
        Container(height: 1, color: SettingsColors.cardBorder),
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
                    color: isSelected ? Colors.white : SettingsColors.subtitle,
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

  Widget _buildBottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: SettingsColors.sheetBg,
        border: Border(
          top: BorderSide(color: SettingsColors.cardBorder, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: SettingsColors.cardBorder),
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
          GestureDetector(
            onTap: _save,
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

class SettingsSectionHeader extends StatelessWidget {
  final String title;

  const SettingsSectionHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: SettingsColors.subtitle,
        fontSize: 11.5,
        letterSpacing: 0.8,
        fontWeight: FontWeight.w600,
        decoration: TextDecoration.none,
      ),
    );
  }
}

/// Baris "label ........ kontrol".
class SettingsRow extends StatelessWidget {
  final String label;
  final Widget control;
  final bool enabled;

  const SettingsRow({
    super.key,
    required this.label,
    required this.control,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            color: enabled
                ? SettingsColors.label
                : SettingsColors.disabledLabel,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            decoration: TextDecoration.none,
          ),
        ),
        control,
      ],
    );
  }
}

/// Input angka; saat [enabled] false tampil redup dan tidak bisa diedit.
class SettingsNumberField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final bool allowNegative;
  final bool allowDecimal;
  final double width;

  const SettingsNumberField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.allowNegative = false,
    this.allowDecimal = false,
    this.width = kSettingsControlWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 38,
      decoration: BoxDecoration(
        color: enabled
            ? SettingsColors.cardBg
            : SettingsColors.cardBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: enabled
              ? SettingsColors.cardBorder
              : SettingsColors.cardBorder.withValues(alpha: 0.6),
        ),
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: TextInputType.numberWithOptions(
          signed: allowNegative,
          decimal: allowDecimal,
        ),
        style: TextStyle(
          color: enabled ? Colors.white : SettingsColors.disabledText,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: const InputDecoration(
          filled: false,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

/// Dropdown yang membuka bottom sheet daftar pilihan.
class SettingsSelect extends StatelessWidget {
  final String title;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  final double width;

  const SettingsSelect({
    super.key,
    required this.title,
    required this.value,
    required this.items,
    required this.onChanged,
    this.width = kSettingsControlWidth,
  });

  void _openSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (BuildContext sheetContext) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.68,
        ),
        decoration: const BoxDecoration(
          color: SettingsColors.sheetBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(color: SettingsColors.cardBorder, width: 1),
          ),
        ),
        child: SafeArea(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (BuildContext context, int index) {
              final String item = items[index];
              final bool isSelected = item == value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: InkWell(
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    onChanged(item);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item,
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontSize: 15,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openSheet(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: width,
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: SettingsColors.cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: SettingsColors.cardBorder),
        ),
        child: Row(
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
}

class SettingsCheckbox extends StatelessWidget {
  final bool isChecked;

  const SettingsCheckbox({super.key, required this.isChecked});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 19,
      height: 19,
      decoration: BoxDecoration(
        color: isChecked ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isChecked ? Colors.white : SettingsColors.disabledText,
          width: 1.6,
        ),
      ),
      alignment: Alignment.center,
      child: isChecked
          ? const Icon(Icons.check_rounded, size: 14, color: Colors.black)
          : null,
    );
  }
}

class SettingsCheckboxRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsCheckboxRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: <Widget>[
          SettingsCheckbox(isChecked: value),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: SettingsColors.label,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}

/// Swatch yang membuka [showLineStylePicker] di bawahnya.
/// [showLineOptions] false = hanya warna & opacity (untuk isian/fill).
class StyleSwatch extends StatefulWidget {
  final IndicatorLineStyle value;
  final ValueChanged<IndicatorLineStyle> onChanged;
  final bool showLineOptions;

  const StyleSwatch({
    super.key,
    required this.value,
    required this.onChanged,
    this.showLineOptions = true,
  });

  @override
  State<StyleSwatch> createState() => _StyleSwatchState();
}

class _StyleSwatchState extends State<StyleSwatch> {
  final GlobalKey _anchorKey = GlobalKey();
  bool _isPickerOpen = false;

  Future<void> _openPicker() async {
    setState(() => _isPickerOpen = true);
    await showLineStylePicker(
      context: context,
      anchorKey: _anchorKey,
      initialValue: widget.value,
      onChanged: widget.onChanged,
      showLineOptions: widget.showLineOptions,
    );
    if (mounted) setState(() => _isPickerOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    return LineStyleSwatchButton(
      key: _anchorKey,
      value: widget.value,
      isActive: _isPickerOpen,
      showLinePreview: widget.showLineOptions,
      onTap: _openPicker,
    );
  }
}

/// Swatch warna saja (tanpa ketebalan & jenis garis), mis. untuk warna isian.
class FillColorSwatch extends StatelessWidget {
  final Color color;
  final ValueChanged<Color> onChanged;

  const FillColorSwatch({
    super.key,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return StyleSwatch(
      value: IndicatorLineStyle(color: color),
      showLineOptions: false,
      onChanged: (IndicatorLineStyle value) => onChanged(value.color),
    );
  }
}

/// Baris style: [checkbox] label ...... [controls...]
class ToggleStyleRow extends StatelessWidget {
  static const double _controlGap = 8;

  final String label;
  final bool isVisible;
  final ValueChanged<bool> onVisibilityChanged;
  final List<Widget> controls;

  const ToggleStyleRow({
    super.key,
    required this.label,
    required this.isVisible,
    required this.onVisibilityChanged,
    required this.controls,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: GestureDetector(
            onTap: () => onVisibilityChanged(!isVisible),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: <Widget>[
                SettingsCheckbox(isChecked: isVisible),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        for (final (int index, Widget control) in controls.indexed) ...<Widget>[
          if (index > 0) const SizedBox(width: _controlGap),
          control,
        ],
      ],
    );
  }
}

/// Baris style satu garis plot: [checkbox visible] label ...... [swatch garis] [trailing?]
class PlotStyleRow extends StatelessWidget {
  final String label;
  final IndicatorLineStyle value;
  final ValueChanged<IndicatorLineStyle> onChanged;

  /// Kontrol tambahan di kanan swatch (mis. input nilai level).
  final Widget? trailing;

  const PlotStyleRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final Widget? trailing = this.trailing;
    return ToggleStyleRow(
      label: label,
      isVisible: value.isVisible,
      onVisibilityChanged: (bool visible) =>
          onChanged(value.copyWith(isVisible: visible)),
      controls: <Widget>[
        StyleSwatch(value: value, onChanged: onChanged),
        ?trailing,
      ],
    );
  }
}

/// Setting tampilan nilai indikator yang sama untuk semua indikator.
@immutable
class IndicatorOutputSettings {
  final String precision;
  final bool labelsOnPriceScale;
  final bool valuesInStatusLine;
  final bool inputsInStatusLine;

  const IndicatorOutputSettings({
    required this.precision,
    required this.labelsOnPriceScale,
    required this.valuesInStatusLine,
    required this.inputsInStatusLine,
  });

  factory IndicatorOutputSettings.of(ActiveChartIndicator indicator) =>
      IndicatorOutputSettings(
        precision: indicator.precision,
        labelsOnPriceScale: indicator.labelsOnPriceScale,
        valuesInStatusLine: indicator.valuesInStatusLine,
        inputsInStatusLine: indicator.inputsInStatusLine,
      );

  IndicatorOutputSettings copyWith({
    String? precision,
    bool? labelsOnPriceScale,
    bool? valuesInStatusLine,
    bool? inputsInStatusLine,
  }) => IndicatorOutputSettings(
    precision: precision ?? this.precision,
    labelsOnPriceScale: labelsOnPriceScale ?? this.labelsOnPriceScale,
    valuesInStatusLine: valuesInStatusLine ?? this.valuesInStatusLine,
    inputsInStatusLine: inputsInStatusLine ?? this.inputsInStatusLine,
  );

  /// Terapkan ke [indicator] (dipakai saat Save).
  ActiveChartIndicator applyTo(ActiveChartIndicator indicator) =>
      indicator.copyWith(
        precision: precision,
        labelsOnPriceScale: labelsOnPriceScale,
        valuesInStatusLine: valuesInStatusLine,
        inputsInStatusLine: inputsInStatusLine,
      );
}

/// Bagian OUTPUT VALUES & INPUT VALUES di tab Style.
class OutputSettingsSection extends StatelessWidget {
  final IndicatorOutputSettings value;
  final ValueChanged<IndicatorOutputSettings> onChanged;

  const OutputSettingsSection({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SettingsSectionHeader('OUTPUT VALUES'),
        const SizedBox(height: 16),
        SettingsRow(
          label: 'Precision',
          control: SettingsSelect(
            title: 'Precision',
            value: value.precision,
            items: SettingsOptions.precisions,
            onChanged: (String precision) =>
                onChanged(value.copyWith(precision: precision)),
          ),
        ),
        const SizedBox(height: 16),
        SettingsCheckboxRow(
          label: 'Labels on price scale',
          value: value.labelsOnPriceScale,
          onChanged: (bool checked) =>
              onChanged(value.copyWith(labelsOnPriceScale: checked)),
        ),
        const SizedBox(height: 16),
        SettingsCheckboxRow(
          label: 'Values in status line',
          value: value.valuesInStatusLine,
          onChanged: (bool checked) =>
              onChanged(value.copyWith(valuesInStatusLine: checked)),
        ),
        const SizedBox(height: 26),
        const SettingsSectionHeader('INPUT VALUES'),
        const SizedBox(height: 16),
        SettingsCheckboxRow(
          label: 'Inputs in status line',
          value: value.inputsInStatusLine,
          onChanged: (bool checked) =>
              onChanged(value.copyWith(inputsInStatusLine: checked)),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
