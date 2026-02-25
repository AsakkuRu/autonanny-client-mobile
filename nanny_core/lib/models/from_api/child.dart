class Child {
  Child({
    this.id,
    required this.surname,
    required this.name,
    this.patronymic,
    this.childPhone,
    this.age,
    this.birthday,
    this.photoPath,
    this.schoolClass,
    this.characterNotes,
    this.gender,
    required this.idUser,
    this.isActive = true,
    this.datetimeCreate,
  });

  final int? id;
  final String surname;
  final String name;
  final String? patronymic;
  final String? childPhone;
  final int? age;
  final DateTime? birthday;
  final String? photoPath;
  final String? schoolClass;  // BE-MVP-016: Класс/Школа
  final String? characterNotes;  // BE-MVP-016: Особенности характера
  final String? gender;  // M/F
  final int idUser;
  final bool isActive;
  final DateTime? datetimeCreate;

  String get fullName {
    if (patronymic != null && patronymic!.isNotEmpty) {
      return '$surname $name $patronymic';
    }
    return '$surname $name';
  }

  String get ageDisplay {
    if (age != null) {
      return '$age ${_getAgeWord(age!)}';
    }
    if (birthday != null) {
      final now = DateTime.now();
      final calculatedAge = now.year - birthday!.year;
      return '$calculatedAge ${_getAgeWord(calculatedAge)}';
    }
    return 'Возраст не указан';
  }

  String _getAgeWord(int age) {
    if (age % 10 == 1 && age % 100 != 11) {
      return 'год';
    } else if ([2, 3, 4].contains(age % 10) && ![12, 13, 14].contains(age % 100)) {
      return 'года';
    } else {
      return 'лет';
    }
  }

  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(
      id: json['id'],
      surname: json['surname'] ?? '',
      name: json['name'] ?? '',
      patronymic: json['patronymic'],
      childPhone: json['child_phone'],
      age: json['age'],
      birthday: json['birthday'] != null ? DateTime.parse(json['birthday']) : null,
      photoPath: json['photo_path'],
      schoolClass: json['school_class'],
      characterNotes: json['character_notes'],
      gender: json['gender'],
      idUser: json['id_user'],
      isActive: json['isActive'] ?? true,
      datetimeCreate: json['datetime_create'] != null 
          ? DateTime.parse(json['datetime_create']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'surname': surname,
      'name': name,
      'patronymic': patronymic ?? '',
      'child_phone': childPhone ?? '',
      'age': age ?? 0,
      'birthday': birthday?.toIso8601String().split('T')[0],
      'photo_path': photoPath ?? '',
      'school_class': schoolClass ?? '',
      'character_notes': characterNotes ?? '',
      'gender': gender ?? '',
      'id_user': idUser,
      'isActive': isActive,
    };
  }

  Child copyWith({
    int? id,
    String? surname,
    String? name,
    String? patronymic,
    String? childPhone,
    int? age,
    DateTime? birthday,
    String? photoPath,
    String? schoolClass,
    String? characterNotes,
    String? gender,
    int? idUser,
    bool? isActive,
    DateTime? datetimeCreate,
  }) {
    return Child(
      id: id ?? this.id,
      surname: surname ?? this.surname,
      name: name ?? this.name,
      patronymic: patronymic ?? this.patronymic,
      childPhone: childPhone ?? this.childPhone,
      age: age ?? this.age,
      birthday: birthday ?? this.birthday,
      photoPath: photoPath ?? this.photoPath,
      schoolClass: schoolClass ?? this.schoolClass,
      characterNotes: characterNotes ?? this.characterNotes,
      gender: gender ?? this.gender,
      idUser: idUser ?? this.idUser,
      isActive: isActive ?? this.isActive,
      datetimeCreate: datetimeCreate ?? this.datetimeCreate,
    );
  }
}
