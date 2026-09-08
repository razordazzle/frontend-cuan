import 'package:cuan_app/data/services/stocks_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DaftarBrokerPage extends StatefulWidget {
  const DaftarBrokerPage({super.key});
  @override
  State<DaftarBrokerPage> createState() => _DaftarBrokerPageState();
}

class _DaftarBrokerPageState extends State<DaftarBrokerPage> {
  // 0=Semua, 1=Local, 2=Foreign, 3=BUMN
  int _filter = 1;

  // warna brand sesuai prototype
  static const localColor = Color(0xFFFFC107); // kuning
  static const bumnColor = Color(0xFF00BCD4); // biru
  static const foreignColor = Color(0xFFD32F2F); // merah 600-ish

  Future<List<Map<String, dynamic>>>? _futureBrokers;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // panggil pertama kali setelah widget mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reload();
    });
  }

  /// mapping filter -> category param backend
  String? get _category {
    switch (_filter) {
      case 1:
        return 'local';
      case 2:
        return 'foreign';
      case 3:
        return 'bumn';
      default:
        return null; // 0 = semua
    }
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final svc = context.read<StocksService>();
    return svc.listBrokers(
      category: _category, // boleh null untuk semua
      limit: 500,
    );
  }

  void _reload() {
    setState(() {
      _futureBrokers = _load();
    });
  }

  Color typeColor(String? rawType, ColorScheme cs) {
    final type = (rawType ?? '').toLowerCase();
    switch (type) {
      case 'local':
        return localColor;
      case 'foreign':
        return foreignColor;
      case 'bumn':
        return bumnColor;
      default:
        return cs.onSurface;
    }
  }

  // ----- Chip helper dengan style ala prototype -----
  Widget pill(BuildContext context, String text, int v, {bool enabled = true}) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final on = _filter == v;
    final base = cs.onSurface.withOpacity(enabled ? .85 : .35);

    return ChoiceChip(
      label: Text(
        text,
        style: t.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: on ? cs.onSurface : base,
        ),
      ),
      selected: on,
      onSelected: enabled
          ? (_) {
              setState(() {
                _filter = v;
              });
              _reload(); // reload dari backend dengan kategori baru
            }
          : null,
      shape: StadiumBorder(
        side: BorderSide(
          color: on
              ? cs.outline.withOpacity(.6)
              : cs.outline.withOpacity(enabled ? .35 : .25),
        ),
      ),
      backgroundColor: Colors.transparent,
      selectedColor: cs.surfaceVariant.withOpacity(.25),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
    );
  }

  Widget legend(Color c, String label, TextTheme t, ColorScheme cs) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      ),
      const SizedBox(width: 8),
      Text(label, style: t.bodySmall?.copyWith(color: cs.onSurface)),
    ],
  );
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Daftar Broker'),
        centerTitle: false,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureBrokers,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 40),
                  const SizedBox(height: 8),
                  Text('Gagal memuat broker', style: t.titleMedium),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba lagi'),
                  ),
                ],
              ),
            );
          }

          final rows = snap.data ?? const <Map<String, dynamic>>[];

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            children: [
              // Filter chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  pill(context, 'Semuanya', 0),
                  pill(context, 'Local Broker', 1),
                  pill(context, 'Foreign Broker', 2),
                  pill(context, 'BUMN', 3),
                ],
              ),
              const SizedBox(height: 10),

              // Legend warna
              Wrap(
                spacing: 16,
                children: [
                  legend(localColor, 'Local Broker', t, cs),
                  legend(foreignColor, 'Foreign Broker', t, cs),
                  legend(bumnColor, 'BUMN', t, cs),
                ],
              ),
              const SizedBox(height: 12),

              // Header kolom
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Kode',
                      style: t.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Nama',
                      style: t.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Divider(height: 1, color: cs.outline.withOpacity(.12)),
              const SizedBox(height: 4),

              // List
              ...rows.map((r) {
                final code = r['code'] as String? ?? '';
                final name = r['name'] as String? ?? '';
                final cat = r['category'] as String? ?? '';
                final clr = typeColor(cat, cs);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          code,
                          style: t.titleMedium?.copyWith(
                            color: clr,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: Text(
                          name,
                          style: t.bodyMedium?.copyWith(
                            color: cs.onSurface.withOpacity(.75),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
