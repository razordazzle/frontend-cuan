import 'package:cuan_app/components/default_avatar.dart';
import 'package:cuan_app/utils/phone_format.dart';
import 'package:cuan_app/utils/validators.dart';
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
  static String _two(int v) => v.toString().padLeft(2, '0');
  static String _displayDate(DateTime d) =>
      '${_two(d.day)}/${_two(d.month)}/${d.year}';
  static String _apiDate(DateTime d) =>
      '${d.year}-${_two(d.month)}-${_two(d.day)}';

  void _setBirthDate(String? raw) {
    final d = DateTime.tryParse(raw ?? '');
    if (d == null) return;
    _birthDate = DateTime(d.year, d.month, d.day);
    _dateCtrl.text = _displayDate(_birthDate!);
  }

  @override
  void initState() {
    super.initState();
    _setBirthDate(widget.birthDate);
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 20),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Pilih tanggal lahir',
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked == null) return;
    setState(() {
      _birthDate = picked;
      _dateCtrl.text = _displayDate(picked);
    });
  }

  late final _nameCtrl = TextEditingController(text: widget.fullname);
  late final _userCtrl = TextEditingController(text: widget.username);
  late final _placeCtrl = TextEditingController(text: widget.birthPlace);
  late final _dateCtrl = TextEditingController();
  DateTime?
  _birthDate; // dipilih lewat date picker; dikirim ke backend sebagai YYYY-MM-DD
  late final _domCtrl = TextEditingController(text: widget.domicile);
  late final _phoneCtrl = TextEditingController(text: widget.phone);

  bool _filledFromArgs = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // didChangeDependencies bisa terpanggil berkali-kali (mis. tiap keyboard muncul/berubah).
    // Kalau kolom diisi ulang dari arguments tiap kali, ketikan user ketimpa balik ke data lama.
    if (_filledFromArgs) return;
    _filledFromArgs = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _nameCtrl.text = (args['name'] as String?) ?? _nameCtrl.text;
      _userCtrl.text = (args['username'] as String?) ?? _userCtrl.text;
      _placeCtrl.text = (args['birthPlace'] as String?) ?? _placeCtrl.text;
      _setBirthDate(args['birthDate'] as String?);
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
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          28 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          // Header kecil (avatar + title)
          Row(
            children: const [
              DefaultAvatar(radius: 24),
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
          // Tanggal lahir: pilih dari kalender, bukan diketik manual
          _UnderlineField(
            label: 'Tanggal Lahir',
            controller: _dateCtrl,
            readOnly: true,
            onTap: _pickBirthDate,
            hintText: 'Pilih tanggal',
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
                // Nomor HP dicek dulu: dulu apa pun yang diketik langsung dijadikan +62…
                final phone = _phoneCtrl.text.trim();
                if (phone.isNotEmpty && !Validators.isValidPhoneID(phone)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Nomor HP tidak valid. Gunakan format 08xxxxxxxxxx.',
                      ),
                    ),
                  );
                  return;
                }

                final changes = <String, String>{};
                void put(String k, String v) {
                  if (v.trim().isNotEmpty) changes[k] = v.trim();
                }

                put('name', _nameCtrl.text);
                put('username', _userCtrl.text);
                put('birthPlace', _placeCtrl.text);
                if (_birthDate != null) put('birthDate', _apiDate(_birthDate!));
                put('domicile', _domCtrl.text);
                if (phone.isNotEmpty) put('phone', toE164ID(phone));

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
    this.readOnly = false,
    this.onTap,
    this.hintText = 'Input',
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final String hintText;

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
                  readOnly: readOnly,
                  onTap: onTap,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: hintText,
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
