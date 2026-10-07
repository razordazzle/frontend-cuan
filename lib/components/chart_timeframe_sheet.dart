import 'package:flutter/material.dart';

import '../data/model/chart_timeframe.dart';
import 'settings_colors.dart';

/// Sheet pemilih timeframe ala TradingView: daftar per kelompok (MINUTES/HOURS/DAYS),
/// timeframe aktif disorot seperti combobox di settings indikator.
class ChartTimeframeSheet extends StatelessWidget {
  final ChartTimeframe selected;

  const ChartTimeframeSheet({super.key, required this.selected});

  /// Return timeframe yang dipilih, atau null kalau sheet ditutup tanpa memilih.
  static Future<ChartTimeframe?> show({
    required BuildContext context,
    required ChartTimeframe selected,
  }) => showModalBottomSheet<ChartTimeframe>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChartTimeframeSheet(selected: selected),
  );

  @override
  Widget build(BuildContext context) {
    // Palet sama dengan combobox settings indikator.
    final SettingsColors colors = SettingsColors.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      decoration: BoxDecoration(
        color: colors.sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: colors.cardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                decoration: BoxDecoration(
                  color: colors.handle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 4),
              child: Text(
                'Timeframe',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colors.foreground,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 12),
                children: <Widget>[
                  for (final ChartTimeframeGroup group
                      in ChartTimeframeGroup.values) ...<Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
                      child: Text(
                        group.title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                          color: colors.subtitle,
                        ),
                      ),
                    ),
                    for (final ChartTimeframe timeframe
                        in ChartTimeframe.values)
                      if (timeframe.group == group)
                        _TimeframeTile(
                          timeframe: timeframe,
                          isSelected: timeframe == selected,
                          foreground: colors.foreground,
                          onForeground: colors.onForeground,
                        ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Item timeframe; yang aktif = pill terang dengan teks gelap (warna dibalik).
class _TimeframeTile extends StatelessWidget {
  final ChartTimeframe timeframe;
  final bool isSelected;
  final Color foreground;
  final Color onForeground;

  const _TimeframeTile({
    required this.timeframe,
    required this.isSelected,
    required this.foreground,
    required this.onForeground,
  });

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(8);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      child: InkWell(
        onTap: () => Navigator.of(context).pop(timeframe),
        borderRadius: radius,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? foreground : Colors.transparent,
            borderRadius: radius,
          ),
          child: Text(
            timeframe.title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? onForeground : foreground,
            ),
          ),
        ),
      ),
    );
  }
}
