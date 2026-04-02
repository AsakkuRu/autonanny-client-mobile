/// Текст из полей «аллергии / хронические / медикаменты», который пользователь
/// вводит как «нет», не должен показываться как медицинское предупреждение.
bool isSubstantiveMedicalDetail(String? text) {
  final t = text?.trim().toLowerCase() ?? '';
  if (t.isEmpty) return false;
  const negatives = {
    'нет',
    'no',
    'н.',
    'нет.',
    'no.',
    'n/a',
    'na',
    '-',
    '—',
    'none',
    'отсутствует',
    'отсутствуют',
    'не указано',
    'не указаны',
    'пусто',
  };
  return !negatives.contains(t);
}
