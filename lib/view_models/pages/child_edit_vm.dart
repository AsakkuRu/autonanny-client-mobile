import 'package:flutter/material.dart';
import 'package:nanny_components/dialogs/loading.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/models/from_api/child.dart';
import 'package:nanny_core/models/from_api/child_medical_info.dart';
import 'package:nanny_core/models/from_api/emergency_contact.dart';
import 'package:nanny_core/nanny_core.dart';
import 'package:image_picker/image_picker.dart';

class ChildEditVM extends ViewModelBase {
  final Child? child;

  ChildEditVM({
    required super.context,
    required super.update,
    this.child,
  }) {
    if (child != null) {
      _initializeFromChild();
      _loadMedicalInfo();
      _loadEmergencyContacts();
    }
  }

  final TextEditingController surnameController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController patronymicController = TextEditingController();
  final TextEditingController birthdayController = TextEditingController();
  final TextEditingController schoolClassController = TextEditingController();
  final TextEditingController characterNotesController = TextEditingController();
  
  // FE-MVP-013: Контроллеры для медицинской информации
  final TextEditingController allergiesController = TextEditingController();
  final TextEditingController chronicDiseasesController = TextEditingController();
  final TextEditingController medicationsController = TextEditingController();
  String? bloodType;
  final TextEditingController policyNumberController = TextEditingController();

  String? gender;
  DateTime? birthday;
  String? photoPath;
  
  // FE-MVP-014: Список экстренных контактов
  List<EmergencyContact> emergencyContacts = [];

  void _initializeFromChild() {
    surnameController.text = child!.surname;
    nameController.text = child!.name;
    patronymicController.text = child!.patronymic ?? '';
    schoolClassController.text = child!.schoolClass ?? '';
    characterNotesController.text = child!.characterNotes ?? '';
    gender = child!.gender;
    birthday = child!.birthday;
    photoPath = child!.photoPath;
    
    if (birthday != null) {
      birthdayController.text = _formatDate(birthday!);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  void setGender(String? value) {
    update(() {
      gender = value;
    });
  }

  Future<void> pickBirthday() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: birthday ?? DateTime.now().subtract(const Duration(days: 365 * 5)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('ru'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: NannyTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      update(() {
        birthday = picked;
        birthdayController.text = _formatDate(picked);
      });
    }
  }

  Future<void> pickPhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (image != null) {
      if (!context.mounted) return;
      LoadScreen.showLoad(context, true);

      try {
        Logger().i('Uploading photo: ${image.path}');
        final uploadResult = await NannyFilesApi.uploadFiles([XFile(image.path)]);
        Logger().i('Upload result: success=${uploadResult.success}, statusCode=${uploadResult.statusCode}, error=${uploadResult.errorMessage}');

        if (!context.mounted) return;
        LoadScreen.showLoad(context, false);

        if (uploadResult.success && uploadResult.response != null && uploadResult.response!.paths.isNotEmpty) {
          Logger().i('Photo uploaded, path: ${uploadResult.response!.paths.first}');
          update(() {
            photoPath = uploadResult.response!.paths.first;
          });
        } else {
          await NannyDialogs.showMessageBox(context, 'Ошибка', uploadResult.errorMessage);
        }
      } catch (e) {
        Logger().e('Photo upload error: $e');
        if (!context.mounted) return;
        LoadScreen.showLoad(context, false);
        await NannyDialogs.showMessageBox(context, 'Ошибка', 'Не удалось загрузить фото: $e');
      }
    }
  }

  Future<void> save() async {
    // Валидация
    if (surnameController.text.trim().isEmpty) {
      NannyDialogs.showMessageBox(context, "Ошибка", "Введите фамилию");
      return;
    }

    if (nameController.text.trim().isEmpty) {
      NannyDialogs.showMessageBox(context, "Ошибка", "Введите имя");
      return;
    }

    if (birthday == null) {
      NannyDialogs.showMessageBox(context, "Ошибка", "Выберите дату рождения");
      return;
    }

    // NEW-008 / ТЗ: у ребёнка должен быть хотя бы один экстренный контакт (при создании и при редактировании)
    if (emergencyContacts.isEmpty) {
      NannyDialogs.showMessageBox(
        context,
        "Ошибка",
        "Добавьте хотя бы один экстренный контакт перед сохранением ребёнка",
      );
      return;
    }

    if (!context.mounted) return;
    LoadScreen.showLoad(context, true);

    // Вычисляем возраст
    final now = DateTime.now();
    final age = now.year - birthday!.year;

    // Создаем объект ребенка
    final childData = Child(
      id: child?.id,
      surname: surnameController.text.trim(),
      name: nameController.text.trim(),
      patronymic: patronymicController.text.trim().isEmpty 
          ? null 
          : patronymicController.text.trim(),
      birthday: birthday,
      age: age,
      gender: gender,
      schoolClass: schoolClassController.text.trim().isEmpty 
          ? null 
          : schoolClassController.text.trim(),
      characterNotes: characterNotesController.text.trim().isEmpty 
          ? null 
          : characterNotesController.text.trim(),
      photoPath: photoPath,
      idUser: NannyUser.userInfo?.id ?? 0,
    );

    // Сохраняем
    int? savedChildId;
    if (child == null) {
      final createResult = await NannyChildrenApi.createChild(childData);
      if (!context.mounted) return;
      if (!createResult.success) {
        LoadScreen.showLoad(context, false);
        NannyDialogs.showMessageBox(context, "Ошибка", createResult.errorMessage);
        return;
      }
      savedChildId = createResult.response;
    } else {
      final updateResult = await NannyChildrenApi.updateChild(child!.id!, childData);
      if (!context.mounted) return;
      if (!updateResult.success) {
        LoadScreen.showLoad(context, false);
        NannyDialogs.showMessageBox(context, "Ошибка", updateResult.errorMessage);
        return;
      }
      savedChildId = child!.id;
    }

    // FE-MVP-013: Сохраняем медицинскую информацию
    if (savedChildId != null) {
      await _saveMedicalInfo(savedChildId);

      // FE-MVP-014: Сохраняем экстренные контакты для нового ребёнка
      if (child == null) {
        for (final contact in emergencyContacts) {
          final c = EmergencyContact(
            idChild: savedChildId,
            name: contact.name,
            relationship: contact.relationship,
            phone: contact.phone,
          );
          await NannyChildrenApi.createEmergencyContact(c);
        }
      }
    }

    if (!context.mounted) return;
    LoadScreen.showLoad(context, false);

    await NannyDialogs.showMessageBox(
      context,
      "Успех",
      child == null ? "Ребенок добавлен" : "Данные сохранены",
    );

    if (!context.mounted) return;
    // Возвращаемся назад с результатом
    Navigator.of(context).pop(true);
  }

  // FE-MVP-013: Загрузка медицинской информации
  Future<void> _loadMedicalInfo() async {
    if (child?.id == null) return;
    
    final result = await NannyChildrenApi.getMedicalInfo(child!.id!);
    if (result.success && result.response != null) {
      final info = result.response!;
      allergiesController.text = info.allergies ?? '';
      chronicDiseasesController.text = info.chronicDiseases ?? '';
      medicationsController.text = info.medications ?? '';
      bloodType = info.bloodType;
      policyNumberController.text = info.medicalPolicyNumber ?? '';
    }
  }

  // FE-MVP-013: Сохранение медицинской информации
  Future<void> _saveMedicalInfo(int childId) async {
    // Проверяем, есть ли хоть одно заполненное поле
    if (allergiesController.text.trim().isEmpty &&
        chronicDiseasesController.text.trim().isEmpty &&
        medicationsController.text.trim().isEmpty &&
        bloodType == null &&
        policyNumberController.text.trim().isEmpty) {
      return; // Нет данных для сохранения
    }

    final medicalInfo = ChildMedicalInfo(
      idChild: childId,
      allergies: allergiesController.text.trim().isEmpty ? null : allergiesController.text.trim(),
      chronicDiseases: chronicDiseasesController.text.trim().isEmpty ? null : chronicDiseasesController.text.trim(),
      medications: medicationsController.text.trim().isEmpty ? null : medicationsController.text.trim(),
      bloodType: bloodType,
      medicalPolicyNumber: policyNumberController.text.trim().isEmpty ? null : policyNumberController.text.trim(),
    );

    // Пытаемся обновить или создать
    if (child?.id != null) {
      // Сначала пробуем обновить
      var updateResult = await NannyChildrenApi.updateMedicalInfo(childId, medicalInfo);
      if (!updateResult.success) {
        // Если не получилось обновить, создаём
        var createResult = await NannyChildrenApi.createMedicalInfo(medicalInfo);
        if (!createResult.success) {
          Logger().e('Failed to save medical info: ${createResult.errorMessage}');
        }
      }
    } else {
      // Новый ребёнок - создаём медицинскую информацию
      var createResult = await NannyChildrenApi.createMedicalInfo(medicalInfo);
      if (!createResult.success) {
        Logger().e('Failed to create medical info: ${createResult.errorMessage}');
      }
    }
  }

  // FE-MVP-014: Загрузка экстренных контактов
  Future<void> _loadEmergencyContacts() async {
    if (child?.id == null) return;
    
    final result = await NannyChildrenApi.getEmergencyContacts(child!.id!);
    if (result.success && result.response != null) {
      emergencyContacts = result.response!;
      update(() {});
    }
  }

  // FE-MVP-014: Добавление экстренного контакта
  Future<void> addEmergencyContact() async {
    final result = await _showContactDialog();
    if (result == null) return;

    if (child?.id == null) {
      // Для нового ребенка просто добавляем в список
      emergencyContacts.add(result);
      update(() {});
      return;
    }

    // Для существующего ребенка сохраняем на сервере
    LoadScreen.showLoad(context, true);
    try {
      final apiResult = await NannyChildrenApi.createEmergencyContact(result);
      
      if (!context.mounted) return;
      LoadScreen.showLoad(context, false);

      if (apiResult.success) {
        await _loadEmergencyContacts();
        if (!context.mounted) return;
        await NannyDialogs.showMessageBox(context, 'Успех', 'Контакт добавлен');
      } else {
        await NannyDialogs.showMessageBox(context, 'Ошибка', apiResult.errorMessage);
      }
    } catch (e) {
      if (!context.mounted) return;
      LoadScreen.showLoad(context, false);
      Logger().e('Add emergency contact error: $e');
      await NannyDialogs.showMessageBox(context, 'Ошибка', 'Не удалось добавить контакт');
    }
  }

  // FE-MVP-014: Редактирование экстренного контакта
  Future<void> editEmergencyContact(EmergencyContact contact) async {
    final result = await _showContactDialog(contact: contact);
    if (result == null) return;

    if (contact.id == null) {
      // Локальный контакт - просто обновляем
      final index = emergencyContacts.indexOf(contact);
      if (index != -1) {
        emergencyContacts[index] = result;
        update(() {});
      }
      return;
    }

    // Контакт на сервере - обновляем через API
    LoadScreen.showLoad(context, true);
    final apiResult = await NannyChildrenApi.updateEmergencyContact(contact.id!, result);
    
    if (!context.mounted) return;
    LoadScreen.showLoad(context, false);

    if (apiResult.success) {
      await _loadEmergencyContacts();
    } else {
      NannyDialogs.showMessageBox(context, "Ошибка", apiResult.errorMessage);
    }
  }

  // FE-MVP-014: Удаление экстренного контакта
  Future<void> deleteEmergencyContact(EmergencyContact contact) async {
    final confirmed = await NannyDialogs.confirmAction(
      context,
      "Удалить контакт ${contact.name}?",
      confirmText: 'Удалить',
      cancelText: 'Отмена',
    );

    if (!confirmed) return;

    if (contact.id == null) {
      // Локальный контакт - просто удаляем из списка
      emergencyContacts.remove(contact);
      update(() {});
      return;
    }

    // Контакт на сервере - удаляем через API
    LoadScreen.showLoad(context, true);
    final result = await NannyChildrenApi.deleteEmergencyContact(contact.id!);
    
    if (!context.mounted) return;
    LoadScreen.showLoad(context, false);

    if (result.success) {
      emergencyContacts.removeWhere((c) => c.id == contact.id);
      update(() {});
      NannyDialogs.showMessageBox(context, "Успех", "Контакт удален");
    } else {
      NannyDialogs.showMessageBox(context, "Ошибка", result.errorMessage);
    }
  }

  // FE-MVP-014: Диалог для добавления/редактирования контакта
  Future<EmergencyContact?> _showContactDialog({EmergencyContact? contact}) async {
    final nameController = TextEditingController(text: contact?.name ?? '');
    final relationshipController = TextEditingController(text: contact?.relationship ?? '');
    final phoneController = TextEditingController(text: contact?.phone ?? '');
    final phoneMask = MaskTextInputFormatter(
      mask: '+7 (###) ### ## ##',
      filter: {'#': RegExp(r'[0-9]')},
    );
    if (contact?.phone != null && contact!.phone.isNotEmpty) {
      phoneController.text = contact!.phone;
      phoneMask.formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(text: contact.phone),
      );
    }

    return showDialog<EmergencyContact>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(contact == null ? 'Добавить контакт' : 'Редактировать контакт'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Имя',
                hintText: 'Иван Иванов',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: relationshipController,
              decoration: const InputDecoration(
                labelText: 'Степень родства',
                hintText: 'Бабушка, дедушка, тётя...',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Телефон',
                hintText: '+7 900 123 45 67',
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [phoneMask],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty ||
                  relationshipController.text.trim().isEmpty ||
                  phoneController.text.trim().isEmpty) {
                NannyDialogs.showMessageBox(
                  context,
                  "Ошибка",
                  "Заполните все поля",
                );
                return;
              }

              final maskedPhone = phoneMask.getMaskedText();
              final formattedPhone = maskedPhone.isNotEmpty
                  ? maskedPhone
                  : phoneController.text.trim();

              final newContact = EmergencyContact(
                id: contact?.id,
                idChild: child?.id ?? 0,
                name: nameController.text.trim(),
                relationship: relationshipController.text.trim(),
                phone: formattedPhone,
              );

              Navigator.pop(context, newContact);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    surnameController.dispose();
    nameController.dispose();
    patronymicController.dispose();
    birthdayController.dispose();
    schoolClassController.dispose();
    characterNotesController.dispose();
    allergiesController.dispose();
    chronicDiseasesController.dispose();
    medicationsController.dispose();
    policyNumberController.dispose();
  }
}
