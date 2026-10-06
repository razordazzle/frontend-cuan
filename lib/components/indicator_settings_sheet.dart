import 'package:flutter/material.dart';

import '../data/model/active_chart_indicator.dart';
import 'rsi_settings_modal.dart';
import 'sma_settings_modal.dart';
import 'volume_settings_modal.dart';

/// Buka modal settings sesuai tipe [indicator]. Tipe yang belum punya settings diabaikan.
void showIndicatorSettingsSheet({
  required BuildContext context,
  required ActiveChartIndicator indicator,
  required ValueChanged<ActiveChartIndicator> onSave,
}) {
  switch (indicator.type) {
    case 'sma':
      SmaSettingsModal.show(
        context: context,
        indicator: indicator,
        onSave: onSave,
      );
    case 'rsi':
      RsiSettingsModal.show(
        context: context,
        indicator: indicator,
        onSave: onSave,
      );
    case 'vol':
      VolumeSettingsModal.show(
        context: context,
        indicator: indicator,
        onSave: onSave,
      );
  }
}
