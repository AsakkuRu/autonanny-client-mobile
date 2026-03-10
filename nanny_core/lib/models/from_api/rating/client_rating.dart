/// D-001: Критерий оценки клиента (TASK-D1)
class RatingCriterion {
  final String key;
  final String label;
  final int value;

  const RatingCriterion({
    required this.key,
    required this.label,
    required this.value,
  });

  RatingCriterion copyWith({int? value}) => RatingCriterion(
        key: key,
        label: label,
        value: value ?? this.value,
      );

  factory RatingCriterion.fromJson(Map<String, dynamic> json) {
    return RatingCriterion(
      key: json['key'] ?? '',
      label: json['label'] ?? '',
      value: json['value'] ?? 0,
    );
  }

  static List<RatingCriterion> defaultCriteria() => const [
        RatingCriterion(key: 'punctuality', label: 'Пунктуальность', value: 0),
        RatingCriterion(key: 'adequacy', label: 'Адекватность', value: 0),
        RatingCriterion(key: 'child_behavior', label: 'Поведение ребёнка', value: 0),
      ];
}
