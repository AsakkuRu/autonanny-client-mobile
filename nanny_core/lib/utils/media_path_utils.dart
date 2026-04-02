/// Отсекает пустые значения и типичные заглушки OpenAPI/макетов для пути к видео водителя.
bool isRealDriverVideoPath(String? path) {
  final p = path?.trim() ?? '';
  if (p.isEmpty) return false;
  final lower = p.toLowerCase();
  if (lower.contains('example.com')) return false;
  if (lower == 'string') return false;
  return true;
}
