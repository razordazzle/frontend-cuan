import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// pages
import 'package:cuan_app/pages/payments/payment_detail_page.dart';
import 'package:cuan_app/pages/payments/payment_method_page.dart';
import 'package:cuan_app/pages/screen/research_page.dart' show ResearchItem;

// payments
import 'package:cuan_app/data/model/payment_method.dart';

// provider & models
import 'package:cuan_app/providers/journals_provider.dart';

class ResearchContentPage extends StatefulWidget {
  const ResearchContentPage({
    super.key,
    required this.item,
    required this.index, // 1-based
    required this.total,
    this.content, // boleh diisi kalau sudah ada dari caller
    this.isSubscriber = false, // fallback hint; final akses tetap dari API
    this.previewRatio = 0.35, // 35% terlihat
  });

  final ResearchItem item;
  final int index;
  final int total;
  final String? content;
  final bool isSubscriber;
  final double previewRatio;

  @override
  State<ResearchContentPage> createState() => _ResearchContentPageState();
}

class _ResearchContentPageState extends State<ResearchContentPage> {
  int? _selectedPlan;

  bool _loading = true;
  String? _err;
  String? _content; // isi markdown
  bool?
  _locked; // null = belum diketahui; true=premium terkunci, false=akses penuh

  // dummy plans
  late final List<_Plan> _plans = [
    _Plan(title: 'New', amount: 15000, tag: 'New'),
    _Plan(title: 'Good Deals', amount: 29000, tag: 'Good Deals'),
    _Plan(title: 'Good Deals', amount: 59000, tag: 'Good Deals'),
    _Plan(title: 'Recommended', amount: 99000, tag: 'Recommended'),
    _Plan(
      title: 'Best Value',
      amount: 149000,
      tag: 'Best Value',
      highlight: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // kalau caller sudah kirim content siap pakai, gunakan itu
    if (widget.content != null && widget.content!.trim().isNotEmpty) {
      _content = widget.content;
      _locked = widget.item.isPremium && !widget.isSubscriber; // hint
      _loading = false;
    } else {
      // fetch dari API
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadContent());
    }
  }

  Future<void> _loadContent() async {
    setState(() {
      _loading = true;
      _err = null;
    });

    final jp = context.read<JournalsProvider>();
    try {
      // 1) coba ambil konten penuh
      final d = await jp.fetchDetailOnce(widget.item.id);
      if (!mounted) return;
      setState(() {
        _content = d.contentMd;
        _locked = false;
        _loading = false;
      });
    } catch (e) {
      // 2) kalau gagal (mis. 402), fallback preview
      try {
        final p = await jp.fetchPreview(widget.item.id);
        if (!mounted) return;
        setState(() {
          _content = p.previewMd;
          _locked = true; // tampil mode locked
          _loading = false;
        });
      } catch (e2) {
        if (!mounted) return;
        setState(() {
          _err = e2.toString();
          _loading = false;
        });
      }
    }
  }

  String _rupiah(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idxFromEnd = s.length - i;
      buf.write(s[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write('.');
    }
    return 'Rp ${buf.toString()}';
  }

  String _fmtDate(DateTime dt) {
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final yyyy = dt.year.toString();
    return '$dd/$mm/$yyyy';
  }

  static const String _lorem =
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla eu sodales mi, '
      'placerat venenatis felis. Integer sollicitudin massa in tristique sagittis. '
      'Aenean pretium erat vitae felis viverra, quis pretium lacus vestibulum. '
      'Vivamus et velit nulla. Donec nunc orci, tempus sit amet iaculis id, luctus '
      'faucibus dolor. Fusce non viverra metus. Aliquam aliquam mollis ipsum et '
      'varius. Duis porttitor commodo egestas. Aliquam sit amet mi consectetur, '
      'porttitor est sed, eleifend ante. Nunc mattis, ipsum eget iaculis consequat, '
      'leo ante pretium nisl, in mattis libero lectus faucibus orci. Mauris eget '
      'fermentum nunc, ut sodales neque.';

  Future<void> _startCheckout() async {
    if (_selectedPlan == null) return;
    final plan = _plans[_selectedPlan!];

    // 1) pilih metode pembayaran
    final method = await Navigator.push<PaymentMethod>(
      context,
      MaterialPageRoute(builder: (_) => const PaymentMethodPage()),
    );
    if (!mounted || method == null) return;

    // 2) VA/bank perlu nomor
    final isBankOrVA =
        method.group == PaymentGroup.bankTransfer ||
        method.group == PaymentGroup.virtualAccount;

    // 3) ke detail pembayaran
    // await Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (_) => PaymentDetailPage(
    //       method: method,
    //       amount: plan.amount,
    //       accountNumber: isBankOrVA ? '17986543212' : null, // TODO: dari server
    //     ),
    //   ),
    // );

    // 4) TODO: setelah kembali, cek status invoice/payment & refresh akses
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;

    // fallback locked jika belum tahu (pakai hint dari list)
    final locked = _locked ?? (widget.item.isPremium && !widget.isSubscriber);
    final fullText = (_content ?? _lorem);

    Widget _partialBody() {
      if (fullText.length < 120) {
        return Text(
          fullText,
          style: t.textTheme.bodyMedium?.copyWith(height: 1.35),
        );
      }
      final desired = (fullText.length * widget.previewRatio).floor();
      int cut = desired.clamp(20, fullText.length - 1);
      final candidates = <int>[
        fullText.lastIndexOf(' ', cut),
        fullText.lastIndexOf('\n', cut),
        fullText.lastIndexOf('.', cut),
        fullText.lastIndexOf(',', cut),
      ].where((i) => i >= 30).toList();
      if (candidates.isNotEmpty) {
        candidates.sort();
        cut = candidates.last;
      }
      final visible = fullText.substring(0, cut).trimRight();
      final hidden = fullText.substring(cut).trimLeft();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(visible, style: t.textTheme.bodyMedium?.copyWith(height: 1.35)),
          const SizedBox(height: 6),
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 5.5, sigmaY: 5.5),
            child: Text(
              hidden,
              style: t.textTheme.bodyMedium?.copyWith(height: 1.35),
            ),
          ),
        ],
      );
    }

    // LOADING
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: Text('${widget.index} of ${widget.total}'),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // ERROR
    if (_err != null) {
      return Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: Text('${widget.index} of ${widget.total}'),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _err!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cs.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _loadContent,
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // NORMAL
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text('${widget.index} of ${widget.total}'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search),
            tooltip: 'Search',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // ===== COVER =====
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: locked ? Border.all(color: cs.primary, width: 1.6) : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(
                        sigmaX: locked ? 3 : 0,
                        sigmaY: locked ? 3 : 0,
                      ),
                      child: Image.network(
                        widget.item.cover,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (locked)
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: cs.surface.withValues(alpha: .9),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.diamond, size: 16, color: cs.primary),
                            const SizedBox(width: 6),
                            Text(
                              'Premium',
                              style: TextStyle(
                                color: cs.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ===== TITLE =====
          Text(
            widget.item.title.toUpperCase(),
            style: t.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: .2,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),

          // ===== DATE =====
          Text(
            _fmtDate(widget.item.publishedAt),
            style: t.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),

          // ===== CONTENT =====
          if (locked)
            _partialBody()
          else
            Text(
              fullText,
              style: t.textTheme.bodyMedium?.copyWith(height: 1.35),
            ),

          // ===== PREMIUM OFFER =====
          if (locked) ...[
            const SizedBox(height: 20),
            _JoinPremiumCallout(),
            const SizedBox(height: 16),
            ...List.generate(_plans.length, (i) {
              final p = _plans[i];
              final selected = _selectedPlan == i;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _PlanTile(
                  plan: p,
                  selected: selected,
                  onTap: () => setState(() => _selectedPlan = i),
                ),
              );
            }),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selectedPlan == null ? null : _startCheckout,
                child: const Text('Berlangganan Sekarang'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/* ==================== WIDGETS ==================== */

class _JoinPremiumCallout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Bergabung premium untuk\nbaca selengkapnya',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _Plan {
  _Plan({
    required this.title,
    required this.amount, // dalam IDR
    this.period = '1 hari',
    this.tag,
    this.highlight = false,
  });

  final String title;
  final int amount;
  final String period;
  final String? tag;
  final bool highlight;
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.plan,
    required this.selected,
    required this.onTap,
  });
  final _Plan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    String rupiah(int n) {
      final s = n.toString();
      final buf = StringBuffer();
      for (int i = 0; i < s.length; i++) {
        final idxFromEnd = s.length - i;
        buf.write(s[i]);
        if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write('.');
      }
      return 'Rp ${buf.toString()}';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? cs.primary
                  : cs.outlineVariant.withValues(alpha: .6),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // radio
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? cs.primary : cs.onSurfaceVariant,
                      width: 2,
                    ),
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: selected ? 10 : 0,
                    height: selected ? 10 : 0,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // texts
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (plan.tag != null)
                        Text(
                          plan.tag!,
                          style: t.labelSmall?.copyWith(
                            color: plan.highlight
                                ? cs.primary
                                : cs.onSurfaceVariant,
                            fontWeight: plan.highlight
                                ? FontWeight.w800
                                : FontWeight.w700,
                          ),
                        ),
                      Text(
                        '${rupiah(plan.amount)}/${plan.period}',
                        style: t.bodySmall?.copyWith(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                if (plan.highlight)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Best',
                      style: TextStyle(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
