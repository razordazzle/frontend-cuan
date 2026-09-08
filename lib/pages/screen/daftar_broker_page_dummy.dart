import 'package:flutter/material.dart';

class DaftarBrokerPage extends StatefulWidget {
  const DaftarBrokerPage({super.key});
  @override
  State<DaftarBrokerPage> createState() => _DaftarBrokerPageState();
}

class _DaftarBrokerPageState extends State<DaftarBrokerPage> {
  // 0=Semua, 1=Local, 2=Foreign, 3=BUMN
  int _filter = 1;

  // warna brand sesuai prototype
  static const localColor   = Color(0xFFFFC107); // kuning
  static const bumnColor    = Color(0xFF00BCD4); // biru
  static const foreignColor = Color(0xFFD32F2F); // merah 600-ish
  
  Future<List<Map<String, dynamic>>>? _futureBrokers;
  
  @override 
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t  = Theme.of(context).textTheme;

    // ----- dummy list + tipe -----
    final all = List.generate(20, (i) {
      final types = ['local', 'foreign', 'bumn'];
      return {
        'code': 'XX',
        'name': 'XXXXXXXXXXXXXXXXXX',
        'type': types[i % types.length],
      };
    });

    // terapkan filter
    final rows = all.where((r) {
      switch (_filter) {
        case 1: return r['type'] == 'local';
        case 2: return r['type'] == 'foreign';
        case 3: return r['type'] == 'bumn';
        default: return true;
      }
    }).toList();

    Color typeColor(String type) {
      switch (type) {
        case 'local':   return localColor;
        case 'foreign': return foreignColor;
        case 'bumn':    return bumnColor;
        default:        return cs.onSurface;
      }
    }

    // ----- Chip helper dengan style ala prototype -----
    Widget pill(String text, int v, {bool enabled = true}) {
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
        onSelected: enabled ? (_) => setState(() => _filter = v) : null,
        // gaya “pil” dengan border
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

    Widget legend(Color c, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12, height: 12,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: t.bodySmall?.copyWith(color: cs.onSurface)),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Daftar Broker'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: [
          // Filter chips
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              pill('Semuanya', 0),
              pill('Local Broker', 1),
              // contoh: foreign belum tersedia -> disabled style abu-abu
              pill('Foreign Broker', 2, enabled: true),
              pill('BUMN', 3),
            ],
          ),
          const SizedBox(height: 10),

          // Legend warna
          Wrap(
            spacing: 16,
            children: [
              legend(localColor,   'Local Broker'),
              legend(foreignColor, 'Foreign Broker'),
              legend(bumnColor,    'BUMN'),
            ],
          ),
          const SizedBox(height: 12),

          // Header kolom
          Row(
            children: [
              Expanded(
                child: Text(
                  'Kode',
                  style: t.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Text(
                  'Nama',
                  style: t.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: cs.outline.withOpacity(.12)),
          const SizedBox(height: 4),

          // List
          ...rows.map((r) {
            final clr = typeColor(r['type'] as String);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      r['code'] as String,
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
                      r['name'] as String,
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
      ),
    );
  }
}
