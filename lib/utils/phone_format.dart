String toE164ID(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (raw.trim().startsWith('+')) return '+$digits';
  if (digits.startsWith('62'))     return '+$digits';
  if (digits.startsWith('0'))      return '+62${digits.substring(1)}';
  return '+62$digits';
}