import 'package:cuan_app/utils/phone_format.dart';
import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  final String fullname;
  final String username;
  final String birthPlace;
  final String birthDate; // "YYYY-MM-DD"
  final String domicile;
  final String phone;

  const EditProfilePage({
    super.key,
    this.fullname = '',
    this.username = '',
    this.birthPlace = '',
    this.birthDate = '',
    this.domicile = '',
    this.phone = '',
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final _nameCtrl = TextEditingController(text: widget.fullname);
  late final _userCtrl = TextEditingController(text: widget.username);
  late final _placeCtrl = TextEditingController(text: widget.birthPlace);
  late final _dateCtrl = TextEditingController(text: widget.birthDate);
  late final _domCtrl = TextEditingController(text: widget.domicile);
  late final _phoneCtrl = TextEditingController(text: widget.phone);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _nameCtrl.text = (args['name'] as String?) ?? _nameCtrl.text;
      _userCtrl.text = (args['username'] as String?) ?? _userCtrl.text;
      _placeCtrl.text = (args['birthPlace'] as String?) ?? _placeCtrl.text;
      _dateCtrl.text = (args['birthDate'] as String?) ?? _dateCtrl.text;
      _domCtrl.text = (args['domicile'] as String?) ?? _domCtrl.text;
      _phoneCtrl.text = (args['phone'] as String?) ?? _phoneCtrl.text;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _userCtrl.dispose();
    _placeCtrl.dispose();
    _dateCtrl.dispose();
    _domCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;

    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          // Header kecil (avatar + title)
          Row(
            children: const [
              CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(
                  'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=600&auto=format&fit=crop',
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Edit Profil',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _UnderlineField(label: 'Nama Lengkap', controller: _nameCtrl),
          _UnderlineField(label: 'Username', controller: _userCtrl),
          _UnderlineField(label: 'Tempat Lahir', controller: _placeCtrl),
          _UnderlineField(
            label: 'Tanggal Lahir (YYYY-MM-DD)',
            controller: _dateCtrl,
          ),
          _UnderlineField(label: 'Domisili', controller: _domCtrl),
          _UnderlineField(
            label: 'Nomor Telepon',
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                side: BorderSide(color: cs.primary, width: 1.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              onPressed: () {
                final changes = <String, String>{};
                void put(String k, String v) {
                  if (v.trim().isNotEmpty) changes[k] = v.trim();
                }

                put('name', _nameCtrl.text);
                put('username', _userCtrl.text);
                put('birthPlace', _placeCtrl.text);
                put('birthDate', _dateCtrl.text);
                put('domicile', _domCtrl.text);
                put('phone', toE164ID(_phoneCtrl.text));

                Navigator.pop(context, changes);
              },
              child: const Text('Simpan Perubahan'),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnderlineField extends StatelessWidget {
  const _UnderlineField({
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // label kiri + input kanan
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: t.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              // input kanan (tanpa box, underline)
              Flexible(
                // width: MediaQuery.of(context).size.width * .45,
                child: TextField(
                  controller: controller,
                  textAlign: TextAlign.right,
                  keyboardType: keyboardType,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Input',
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: cs.outlineVariant.withOpacity(.35),
                      ),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: cs.primary, width: 1.4),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: cs.outlineVariant.withOpacity(.35),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // garis pemisah keseluruhan baris (opsional)
          Divider(color: cs.outlineVariant.withOpacity(.35), height: 1),
        ],
      ),
    );
  }
}
