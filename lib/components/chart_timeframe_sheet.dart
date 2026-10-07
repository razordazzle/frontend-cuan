import 'package:flutter/material.dart';

import '../data/model/chart_timeframe.dart';

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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color sheetBg = isDark ? const Color(0xFF121212) : Colors.white;
    final Color borderColor = isDark
        ? const Color(0xFF2C2C2E)
        : const Color(0xFFE0E3EB);
    final Color textColor = isDark ? Colors.white : const Color(0xFF131722);
    final Color subtitleColor = isDark
        ? const Color(0xFF8E8E93)
        : const Color(0xFF9598A1);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: borderColor)),
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
                  color: isDark
                      ? const Color(0xFF3E3E42)
                      : const Color(0xFFD1D4DC),
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
                  color: textColor,
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
                          color: subtitleColor,
                        ),
                      ),
                    ),
                    for (final ChartTimeframe timeframe
                        in ChartTimeframe.values)
                      if (timeframe.group == group)
                        _TimeframeTile(
                          timeframe: timeframe,
                          isSelected: timeframe == selected,
                          textColor: textColor,
                          backgroundColor: sheetBg,
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
  final Color textColor;
  final Color backgroundColor;

  const _TimeframeTile({
    required this.timeframe,
    required this.isSelected,
    required this.textColor,
    required this.backgroundColor,
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
            color: isSelected ? textColor : Colors.transparent,
            borderRadius: radius,
          ),
          child: Text(
            timeframe.title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? backgroundColor : textColor,
            ),
          ),
        ),
      ),
    );
  }
}
