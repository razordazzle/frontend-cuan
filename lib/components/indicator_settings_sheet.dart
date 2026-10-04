import 'package:flutter/material.dart';

import '../data/model/active_chart_indicator.dart';
import 'sma_settings_modal.dart';

/// Buka modal settings sesuai tipe [indicator].
void showIndicatorSettingsSheet({
  required BuildContext context,
  required ActiveChartIndicator indicator,
  required ValueChanged<ActiveChartIndicator> onSave,
}) {
  if (indicator.type == 'sma') {
    SmaSettingsModal.show(
      context: context,
      indicator: indicator,
      onSave: onSave,
    );
    return;
  }

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _IndicatorSettingsPlaceholder(indicator: indicator),
  );
}

/// Placeholder untuk indikator yang customization-nya belum tersedia.
class _IndicatorSettingsPlaceholder extends StatelessWidget {
  final ActiveChartIndicator indicator;

  const _IndicatorSettingsPlaceholder({required this.indicator});

  String get _title => switch (indicator.type) {
    'rsi' => 'Relative Strength Index (RSI)',
    'vol' => 'Volume',
    _ => indicator.title,
  };

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E222D) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  _title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Customization untuk $_title akan dikonfigurasi di langkah berikutnya.',
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? const Color(0xFFD1D4DC)
                    : const Color(0xFF4A4E5A),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
