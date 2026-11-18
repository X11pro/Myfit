String formatDisplayDate(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day/$month/${local.year}';
}

String formatDisplayDateTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${formatDisplayDate(local)} $hour:$minute';
}

String formatDisplayDateKey(String value) {
  final date = DateTime.tryParse(value);
  return date == null ? value : formatDisplayDate(date);
}
