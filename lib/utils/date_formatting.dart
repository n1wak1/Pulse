/// Дата в виде `dd.MM.yyyy` (день и месяц с ведущими нулями).
String formatDateDdMmYyyy(DateTime date) {
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  return '$d.$m.${date.year}';
}
