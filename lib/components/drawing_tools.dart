import 'package:flutter/material.dart';

import '../controllers/chart_drawings_controller.dart';

enum _DrawingCategory {
  trend('TREND TOOLS'),
  gannFibonacci('GANN AND FIBONACCI'),
  shapes('GEOMETRIC SHAPES');

  const _DrawingCategory(this.label);
  final String label;
}

enum _DrawingFilter {
  favorites('Favorites'),
  all('Tools'),
  trend('Trend tools', _DrawingCategory.trend),
  gannFibonacci('Gann and...', _DrawingCategory.gannFibonacci),
  shapes('Shapes', _DrawingCategory.shapes);

  const _DrawingFilter(this.label, [this.category]);
  final String label;
  final _DrawingCategory? category;

  bool matches(ChartDrawingTool tool, Set<ChartDrawingTool> favorites) =>
      switch (this) {
        _DrawingFilter.favorites => favorites.contains(tool),
        _DrawingFilter.all => true,
        _ => tool._category == category,
      };
}

extension _ChartDrawingToolUi on ChartDrawingTool {
  String get _title => switch (this) {
    ChartDrawingTool.trendline => 'Trendline',
    ChartDrawingTool.horizontalLine => 'Horizontal line',
    ChartDrawingTool.fibonacci => 'Fib retracement',
    ChartDrawingTool.rectangle => 'Rectangle',
  };

  _DrawingCategory get _category => switch (this) {
    ChartDrawingTool.trendline ||
    ChartDrawingTool.horizontalLine => _DrawingCategory.trend,
    ChartDrawingTool.fibonacci => _DrawingCategory.gannFibonacci,
    ChartDrawingTool.rectangle => _DrawingCategory.shapes,
  };

  Widget _icon(Color color) => switch (this) {
    ChartDrawingTool.trendline => _TrendlineVectorIcon(color: color),
    ChartDrawingTool.horizontalLine => _HLineVectorIcon(color: color),
    ChartDrawingTool.fibonacci => _FibVectorIcon(color: color),
    ChartDrawingTool.rectangle => _RectVectorIcon(color: color),
  };
}

/// Bottom sheet katalog drawing tools (pilih tool, favorit, toggle toolbar di chart).
class DrawingToolsSheet extends StatefulWidget {
  final ChartDrawingsController controller;

  const DrawingToolsSheet({super.key, required this.controller});

  static void show({
    required BuildContext context,
    required ChartDrawingsController controller,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DrawingToolsSheet(controller: controller),
    );
  }

  @override
  State<DrawingToolsSheet> createState() => _DrawingToolsSheetState();
}

class _DrawingToolsSheetState extends State<DrawingToolsSheet> {
  /// Urutan tool di katalog; grouping kategori juga mengikuti urutan ini.
  static const List<ChartDrawingTool> _catalog = <ChartDrawingTool>[
    ChartDrawingTool.trendline,
    ChartDrawingTool.horizontalLine,
    ChartDrawingTool.fibonacci,
    ChartDrawingTool.rectangle,
  ];
  static const Color _starColor = Color(0xFFF7A600); // TradingView Amber Star
  static const Color _selectedColor = Color(0xFF2962FF);

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _searchQuery = '';
  _DrawingFilter _selectedFilter = _DrawingFilter.favorites;
  bool _isSearching = false;

  bool get _isSearchMode => _isSearching || _searchQuery.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && !_isSearching) {
        setState(() => _isSearching = true);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _stopSearching() {
    _searchController.clear();
    _focusNode.unfocus();
    setState(() {
      _searchQuery = '';
      _isSearching = false;
    });
  }

  void _selectTool(ChartDrawingTool tool) {
    Navigator.of(context).pop();
    widget.controller.startDrawing(tool);
  }

  void _clearAllDrawings() {
    Navigator.of(context).pop();
    widget.controller.clearAll();
  }

  Map<_DrawingCategory, List<ChartDrawingTool>> _groupVisibleTools() {
    final Set<ChartDrawingTool> favorites = widget.controller.favoriteTools;
    final Map<_DrawingCategory, List<ChartDrawingTool>> grouped =
        <_DrawingCategory, List<ChartDrawingTool>>{};
    for (final ChartDrawingTool tool in _catalog) {
      final bool isVisible = _searchQuery.isNotEmpty
          ? tool._title.toLowerCase().contains(_searchQuery) ||
                tool._category.label.toLowerCase().contains(_searchQuery)
          : _selectedFilter.matches(tool, favorites);
      if (isVisible) {
        grouped
            .putIfAbsent(tool._category, () => <ChartDrawingTool>[])
            .add(tool);
      }
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (BuildContext context, _) => _buildSheet(context),
    );
  }

  Widget _buildSheet(BuildContext context) {
    final ChartDrawingsController controller = widget.controller;
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    // Theme palette harmonized with chart background (#121212 in dark mode)
    final Color sheetBg = isDark ? const Color(0xFF121212) : Colors.white;
    final Color cardBg = isDark
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFF0F3FA);
    final Color cardBorder = isDark
        ? const Color(0xFF2C2C2E)
        : const Color(0xFFE0E3EB);
    final Color searchBg = isDark
        ? const Color(0xFF1E1E1E)
        : const Color(0xFFF0F3FA);
    final Color textColor = isDark ? Colors.white : const Color(0xFF131722);
    final Color subtitleColor = isDark
        ? const Color(0xFF8E8E93)
        : const Color(0xFF9598A1);
    final Color closeBtnBg = isDark
        ? const Color(0xFF242426)
        : const Color(0xFFF0F3FA);
    final Color iconColor = isDark ? Colors.white : const Color(0xFF131722);

    final Map<_DrawingCategory, List<ChartDrawingTool>> grouped =
        _groupVisibleTools();

    final double screenHeight = MediaQuery.of(context).size.height;
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    // When searching or typing, maintain fullscreen height (94%) so it NEVER shrinks
    final double targetHeight = _isSearchMode
        ? screenHeight * 0.94
        : screenHeight * 0.75;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      height: targetHeight,
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE0E3EB),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.65 : 0.15),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: keyboardHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Drag Pill Handle (only when not in fullscreen search mode)
              if (!_isSearchMode)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 4),
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF3E3E42)
                            : const Color(0xFFD1D4DC),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(height: 12),

              // Title & Close/Back Button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isSearchMode ? 'Search drawings' : 'Drawings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                    InkWell(
                      onTap: _isSearchMode
                          ? _stopSearching
                          : () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: closeBtnBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isSearchMode ? Icons.arrow_back : Icons.close,
                          size: 18,
                          color: iconColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: searchBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _focusNode.hasFocus
                                ? (isDark
                                      ? Colors.white
                                      : const Color(0xFF131722))
                                : cardBorder,
                            width: _focusNode.hasFocus ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, size: 18, color: subtitleColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                focusNode: _focusNode,
                                cursorColor: isDark
                                    ? Colors.white
                                    : const Color(0xFF131722),
                                onTap: () {
                                  if (!_isSearching) {
                                    setState(() => _isSearching = true);
                                  }
                                },
                                onChanged: (String val) {
                                  setState(() {
                                    _searchQuery = val.trim().toLowerCase();
                                    _isSearching = true;
                                  });
                                },
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: textColor,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search',
                                  hintStyle: TextStyle(
                                    fontSize: 13.5,
                                    color: subtitleColor,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  isDense: true,
                                ),
                              ),
                            ),
                            if (_searchQuery.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                                child: Icon(
                                  Icons.clear,
                                  size: 16,
                                  color: subtitleColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (_isSearchMode) ...[
                      const SizedBox(width: 10),
                      TextButton(
                        onPressed: _stopSearching,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Text(
                          'Batal',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF131722),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Category Filter Pills (Horizontal scroll) - visible when not searching text
              if (_searchQuery.isEmpty) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: _DrawingFilter.values.map((
                      _DrawingFilter filter,
                    ) {
                      final bool isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => setState(() => _selectedFilter = filter),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark
                                        ? const Color(0xFF2B2B2B)
                                        : const Color(0xFFE0E3EB))
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              filter.label,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected ? textColor : subtitleColor,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Divider(height: 1, color: cardBorder),
              ],

              // Scrollable Area: Tool Cards grouped by Category
              // Using Expanded guarantees the view fills all vertical space and never shrinks!
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (grouped.isEmpty)
                        _buildEmptyState(subtitleColor)
                      else
                        for (final MapEntry(key: category, value: tools)
                            in grouped.entries)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category.label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: subtitleColor,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    for (final ChartDrawingTool tool in tools)
                                      _buildToolCard(
                                        tool: tool,
                                        isSelected: controller.isDrawing(tool),
                                        isFavorite: controller.isFavorite(tool),
                                        cardBg: cardBg,
                                        cardBorder: cardBorder,
                                        textColor: textColor,
                                        subtitleColor: subtitleColor,
                                        iconColor: iconColor,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                    ],
                  ),
                ),
              ),

              // Bottom Footer: Show favorites on Chart + Hapus Garis (only when not searching)
              if (!_isSearchMode) ...[
                Divider(height: 1, color: cardBorder),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18, color: subtitleColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Show favorites on Chart',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                      ),
                      if (controller.hasDrawings) ...[
                        TextButton.icon(
                          onPressed: _clearAllDrawings,
                          icon: Icon(
                            Icons.delete_sweep_outlined,
                            size: 16,
                            color: Colors.red.shade400,
                          ),
                          label: Text(
                            'Hapus Garis',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade400,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Switch(
                        value: controller.isToolbarVisible,
                        activeThumbColor: _selectedColor,
                        activeTrackColor: _selectedColor.withValues(
                          alpha: 0.35,
                        ),
                        inactiveThumbColor: isDark
                            ? const Color(0xFF8E8E93)
                            : const Color(0xFFD1D4DC),
                        inactiveTrackColor: isDark
                            ? const Color(0xFF2B2B2B)
                            : const Color(0xFFE0E3EB),
                        onChanged: controller.setToolbarVisible,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color subtitleColor) {
    final bool isFavoritesEmpty =
        _searchQuery.isEmpty && _selectedFilter == _DrawingFilter.favorites;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Center(
        child: Column(
          children: [
            Icon(
              isFavoritesEmpty ? Icons.star_outline_rounded : Icons.search_off,
              size: 36,
              color: subtitleColor,
            ),
            const SizedBox(height: 8),
            Text(
              isFavoritesEmpty
                  ? 'Belum ada drawing tool favorit.\nTekan ikon bintang (☆) pada tool untuk menambahkan.'
                  : 'Tidak ada drawing tool yang cocok dengan "$_searchQuery"',
              textAlign: TextAlign.center,
              style: TextStyle(color: subtitleColor, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolCard({
    required ChartDrawingTool tool,
    required bool isSelected,
    required bool isFavorite,
    required Color cardBg,
    required Color cardBorder,
    required Color textColor,
    required Color subtitleColor,
    required Color iconColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectTool(tool),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 104,
          height: 76,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? _selectedColor : cardBorder,
              width: isSelected ? 1.6 : 1.0,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Favorite star toggle on top right
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => widget.controller.toggleFavorite(tool),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12, bottom: 4),
                      child: Icon(
                        isFavorite ? Icons.star : Icons.star_border,
                        size: 13,
                        color: isFavorite ? _starColor : subtitleColor,
                      ),
                    ),
                  ),
                ],
              ),
              // Vector Tool Icon
              tool._icon(isSelected ? _selectedColor : iconColor),
              // Tool Name
              Text(
                tool._title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? _selectedColor : textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Toolbar drawing favorit yang mengambang di atas chart dan bisa digeser lewat drag handle.
///
/// Taruh di dalam `Stack` lewat `Positioned.fill`; area di luar toolbar tetap
/// meneruskan sentuhan ke chart di bawahnya.
class FloatingDrawingToolbar extends StatefulWidget {
  final ChartDrawingsController controller;

  const FloatingDrawingToolbar({super.key, required this.controller});

  @override
  State<FloatingDrawingToolbar> createState() => _FloatingDrawingToolbarState();
}

class _FloatingDrawingToolbarState extends State<FloatingDrawingToolbar> {
  static const double _margin = 16;

  final GlobalKey _toolbarKey = GlobalKey();

  /// Posisi relatif toolbar di area chart. Disimpan sebagai [Alignment] supaya
  /// toolbar tetap di dalam layar walau ukuran chart atau jumlah favorit berubah.
  Alignment _alignment = Alignment.bottomCenter;

  void _onDragUpdate(DragUpdateDetails details) {
    final Size? area = context.size;
    final Size? toolbar = _toolbarKey.currentContext?.size;
    if (area == null || toolbar == null) return;

    setState(() {
      _alignment = Alignment(
        _shift(
          _alignment.x,
          details.delta.dx,
          area.width - _margin * 2 - toolbar.width,
        ),
        _shift(
          _alignment.y,
          details.delta.dy,
          area.height - _margin * 2 - toolbar.height,
        ),
      );
    });
  }

  /// Konversi geseran piksel ke unit [Alignment] (-1..1 mencakup [freeSpace] piksel).
  static double _shift(double current, double delta, double freeSpace) =>
      freeSpace <= 0
      ? current
      : (current + delta * 2 / freeSpace).clamp(-1.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(_margin),
      child: Align(
        alignment: _alignment,
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (BuildContext context, _) => _DrawingToolbar(
            key: _toolbarKey,
            controller: widget.controller,
            onDragUpdate: _onDragUpdate,
          ),
        ),
      ),
    );
  }
}

class _DrawingToolbar extends StatelessWidget {
  final ChartDrawingsController controller;
  final GestureDragUpdateCallback onDragUpdate;

  const _DrawingToolbar({
    super.key,
    required this.controller,
    required this.onDragUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    // Neutral Charcoal/Black background matching chart: #1E1E1E in dark mode, pure white in light mode
    final Color toolbarBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color toolbarBorder = isDark
        ? const Color(0xFF2C2C2E)
        : const Color(0xFFE0E3EB);
    final Color dividerColor = isDark
        ? const Color(0xFF2C2C2E)
        : const Color(0xFFE0E3EB);
    final Color defaultIconColor = isDark
        ? const Color(0xFFD8D8D8)
        : const Color(0xFF50535E);
    const Color activeIconColor = Color(0xFF2962FF);
    final Set<ChartDrawingTool> favorites = controller.favoriteTools;
    final bool hasDrawings = controller.hasDrawings;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: toolbarBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: toolbarBorder, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.65 : 0.18),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle grip (TradingView style 6 dots :::), di luar area scroll
          // supaya geseran horizontal tidak direbut oleh SingleChildScrollView.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: onDragUpdate,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: _DragHandleWidget(
                color: isDark
                    ? const Color(0xFF636670)
                    : const Color(0xFF9598A1),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  for (final (int index, ChartDrawingTool tool)
                      in favorites.indexed) ...[
                    if (index > 0) const SizedBox(width: 2),
                    _FavoriteToolButton(
                      tooltip: tool._title,
                      isSelected: controller.isDrawing(tool),
                      onTap: () => controller.toggleDrawing(tool),
                      icon: tool._icon(
                        controller.isDrawing(tool)
                            ? activeIconColor
                            : defaultIconColor,
                      ),
                    ),
                  ],
                  if (favorites.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(width: 1, height: 20, color: dividerColor),
                    const SizedBox(width: 2),
                  ],

                  // Clear all annotations
                  IconButton(
                    tooltip: 'Hapus Semua Garis',
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 34,
                      minHeight: 34,
                    ),
                    padding: const EdgeInsets.all(4),
                    icon: Icon(
                      Icons.delete_sweep_outlined,
                      size: 19,
                      color: hasDrawings
                          ? Colors.red.shade400
                          : (isDark
                                ? const Color(0xFF636670)
                                : const Color(0xFFBDBDBD)),
                    ),
                    onPressed: hasDrawings ? controller.clearAll : null,
                  ),

                  // Close / Hide toolbar
                  IconButton(
                    tooltip: 'Tutup Toolbar',
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 34,
                      minHeight: 34,
                    ),
                    padding: const EdgeInsets.all(4),
                    icon: Icon(
                      Icons.close,
                      size: 17,
                      color: isDark
                          ? const Color(0xFFB2B5BE)
                          : const Color(0xFF616161),
                    ),
                    onPressed: controller.closeToolbar,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DragHandleWidget extends StatelessWidget {
  final Color color;
  const _DragHandleWidget({this.color = const Color(0xFF787B86)});

  @override
  Widget build(BuildContext context) {
    final Widget dot = Container(
      width: 2.8,
      height: 2.8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List<Widget>.generate(
          3,
          (_) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 1.5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [dot, const SizedBox(width: 2.8), dot],
            ),
          ),
        ),
      ),
    );
  }
}

class _FavoriteToolButton extends StatelessWidget {
  final Widget icon;
  final String tooltip;
  final bool isSelected;
  final VoidCallback onTap;

  const _FavoriteToolButton({
    required this.icon,
    required this.tooltip,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color selectedBg = isDark
        ? const Color(0xFF2A2E39)
        : const Color(0xFFE0E3EB);
    const Color selectedBorder = Color(0xFF2962FF);

    return Tooltip(
      message: tooltip,
      preferBelow: false,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? selectedBg : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: selectedBorder, width: 1.2)
                  : null,
            ),
            child: icon,
          ),
        ),
      ),
    );
  }
}

// Vector Custom Icons inspired by TradingView Mobile
class _TrendlineVectorIcon extends StatelessWidget {
  final Color color;
  const _TrendlineVectorIcon({this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(24, 24),
      painter: _TrendlinePainter(color),
    );
  }
}

class _TrendlinePainter extends CustomPainter {
  final Color color;
  _TrendlinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final Paint ringPaint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    const double r = 2.2;
    const Offset p1 = Offset(4.5, 19.5);
    const Offset p2 = Offset(19.5, 4.5);

    // 45 degree diagonal unit step: r / sqrt(2) ≈ 1.56
    const double delta = 1.56;
    const Offset lineStart = Offset(4.5 + delta, 19.5 - delta);
    const Offset lineEnd = Offset(19.5 - delta, 4.5 + delta);

    canvas.drawLine(lineStart, lineEnd, linePaint);
    canvas.drawCircle(p1, r, ringPaint);
    canvas.drawCircle(p2, r, ringPaint);
  }

  @override
  bool shouldRepaint(covariant _TrendlinePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _HLineVectorIcon extends StatelessWidget {
  final Color color;
  const _HLineVectorIcon({this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(24, 24), painter: _HLinePainter(color));
  }
}

class _HLinePainter extends CustomPainter {
  final Color color;
  _HLinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final Paint ringPaint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    const double r = 2.2;
    const Offset center = Offset(12.0, 12.0);

    // Left line up to ring perimeter
    canvas.drawLine(const Offset(3.0, 12.0), Offset(12.0 - r, 12.0), linePaint);
    // Right line from ring perimeter
    canvas.drawLine(
      Offset(12.0 + r, 12.0),
      const Offset(21.0, 12.0),
      linePaint,
    );
    // Center hollow anchor ring
    canvas.drawCircle(center, r, ringPaint);
  }

  @override
  bool shouldRepaint(covariant _HLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _FibVectorIcon extends StatelessWidget {
  final Color color;
  const _FibVectorIcon({this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(24, 24), painter: _FibPainter(color));
  }
}

class _FibPainter extends CustomPainter {
  final Color color;
  _FibPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint ringPaint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    const double r = 2.2;
    const double xLeft = 3.5;
    const double xRight = 20.5;

    // 4 horizontal parallel levels
    // Line 1: plain top line
    canvas.drawLine(
      const Offset(xLeft, 4.5),
      const Offset(xRight, 4.5),
      linePaint,
    );

    // Line 2: line with hollow anchor ring on the right
    const double circle2CenterX = xRight - r; // 18.3
    canvas.drawLine(
      const Offset(xLeft, 9.5),
      const Offset(circle2CenterX - r, 9.5),
      linePaint,
    );
    canvas.drawCircle(const Offset(circle2CenterX, 9.5), r, ringPaint);

    // Line 3: plain middle line
    canvas.drawLine(
      const Offset(xLeft, 14.5),
      const Offset(xRight, 14.5),
      linePaint,
    );

    // Line 4: line with hollow anchor ring on the left
    const double circle4CenterX = xLeft + r; // 5.7
    canvas.drawCircle(const Offset(circle4CenterX, 19.5), r, ringPaint);
    canvas.drawLine(
      const Offset(circle4CenterX + r, 19.5),
      const Offset(xRight, 19.5),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _FibPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _RectVectorIcon extends StatelessWidget {
  final Color color;
  const _RectVectorIcon({this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(24, 24), painter: _RectPainter(color));
  }
}

class _RectPainter extends CustomPainter {
  final Color color;
  _RectPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint strokePaint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final Paint ringPaint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    const double r = 2.2;
    const double x1 = 5.0;
    const double x2 = 19.0;
    const double y1 = 5.0;
    const double y2 = 19.0;

    // 4 edges connecting the corner rings (without bleeding into ring holes)
    canvas.drawLine(
      const Offset(x1 + r, y1),
      const Offset(x2 - r, y1),
      strokePaint,
    ); // Top
    canvas.drawLine(
      const Offset(x1 + r, y2),
      const Offset(x2 - r, y2),
      strokePaint,
    ); // Bottom
    canvas.drawLine(
      const Offset(x1, y1 + r),
      const Offset(x1, y2 - r),
      strokePaint,
    ); // Left
    canvas.drawLine(
      const Offset(x2, y1 + r),
      const Offset(x2, y2 - r),
      strokePaint,
    ); // Right

    // 4 corner hollow anchor rings
    canvas.drawCircle(const Offset(x1, y1), r, ringPaint); // Top-Left
    canvas.drawCircle(const Offset(x2, y1), r, ringPaint); // Top-Right
    canvas.drawCircle(const Offset(x1, y2), r, ringPaint); // Bottom-Left
    canvas.drawCircle(const Offset(x2, y2), r, ringPaint); // Bottom-Right
  }

  @override
  bool shouldRepaint(covariant _RectPainter oldDelegate) =>
      oldDelegate.color != color;
}
