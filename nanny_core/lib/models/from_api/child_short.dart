/// Краткая модель ребёнка для блока «Кто едет» на главном экране.
/// Содержит только поля, необходимые для отображения чипа.
class ChildShort {
  final int id;
  final String name;
  final String surname;
  final String? photoPath;

  const ChildShort({
    required this.id,
    required this.name,
    required this.surname,
    this.photoPath,
  });

  String get displayName => name;

  String get fullName {
    if (surname.isNotEmpty) return '$surname $name';
    return name;
  }

  factory ChildShort.fromJson(Map<String, dynamic> json) {
    return ChildShort(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      surname: json['surname'] as String? ?? '',
      photoPath: json['photo_path'] as String?,
    );
  }
}
