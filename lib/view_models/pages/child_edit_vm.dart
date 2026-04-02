import 'package:flutter/material.dart';
import 'package:autonanny_ui_core/autonanny_ui_core.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:nanny_client/ui_sdk/support/ui_sdk_dialogs.dart';
import 'package:nanny_client/ui_sdk/support/ui_sdk_loading_overlay.dart';
import 'package:nanny_client/ui_sdk/support/ui_sdk_view_model_base.dart';
import 'package:nanny_core/models/from_api/child.dart';
import 'package:nanny_core/models/from_api/child_medical_info.dart';
import 'package:nanny_core/models/from_api/emergency_contact.dart';
import 'package:nanny_core/nanny_core.dart';

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
  final TextEditingController characterNotesController =
      TextEditingController();

  // FE-MVP-013: Контроллеры для медицинской информации
  final TextEditingController allergiesController = TextEditingController();
  final TextEditingController chronicDiseasesController =
      TextEditingController();
  final TextEditingController medicationsController = TextEditingController();
  String? bloodType;
  final TextEditingController policyNumberController = TextEditingController();

  /// Тогглы «есть данные»; при выкл + сохранение на сервер уходит пустая строка.
  bool hasAllergiesDetails = false;
  bool hasChronicDiseasesDetails = false;
  bool hasMedicationsDetails = false;
  bool _hadMedicalRecord = false;

  String? gender;
  DateTime? birthday;
  String? photoPath;

  // FE-MVP-014: Список экстренных контактов
  List<EmergencyContact> emergencyContacts = [];
  bool isSaving = false;

  /// Upload возвращает полный URL с хостом запроса; в API сохраняем имя файла — картинка
  /// открывается через [NannyConsts.buildFileUrl] под текущий домен (эмулятор / устройство / prod).
  static String? normalizeChildPhotoPathForStorage(String? value) {
    if (value == null || value.isEmpty) return null;
    final v = value.trim();
    if (!v.startsWith('http://') && !v.startsWith('https://')) {
      return v.replaceFirst(RegExp(r'^/+'), '');
    }
    final idx = v.indexOf('/files/');
    if (idx < 0) return v;
    final rest = v.substring(idx + '/files/'.length);
    return rest.isEmpty ? v : rest;
  }

  void _initializeFromChild() {
    surnameController.text = child!.surname;
    nameController.text = child!.name;
    patronymicController.text = child!.patronymic ?? '';
    schoolClassController.text = child!.schoolClass ?? '';
    characterNotesController.text = child!.characterNotes ?? '';
    gender = child!.gender;
    birthday = child!.birthday;
    photoPath = normalizeChildPhotoPathForStorage(child!.photoPath) ??
        child!.photoPath;

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

  void setAllergiesDetailsEnabled(bool value) {
    update(() {
      hasAllergiesDetails = value;
      if (!value) allergiesController.clear();
    });
  }

  void setChronicDiseasesDetailsEnabled(bool value) {
    update(() {
      hasChronicDiseasesDetails = value;
      if (!value) chronicDiseasesController.clear();
    });
  }

  void setMedicationsDetailsEnabled(bool value) {
    update(() {
      hasMedicationsDetails = value;
      if (!value) medicationsController.clear();
    });
  }

  Future<void> pickBirthday() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          birthday ?? DateTime.now().subtract(const Duration(days: 365 * 5)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('ru'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AutonannyPalette.primary,
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
        final uploadResult =
            await NannyFilesApi.uploadFiles([XFile(image.path)]);
        Logger().i(
            'Upload result: success=${uploadResult.success}, statusCode=${uploadResult.statusCode}, error=${uploadResult.errorMessage}');

        if (!context.mounted) return;
        LoadScreen.showLoad(context, false);

        if (uploadResult.success &&
            uploadResult.response != null &&
            uploadResult.response!.paths.isNotEmpty) {
          final stored = normalizeChildPhotoPathForStorage(
              uploadResult.response!.paths.first);
          Logger().i('Photo uploaded, stored path: $stored');
          update(() {
            photoPath = stored;
          });
        } else {
          await NannyDialogs.showMessageBox(
              context, 'Ошибка', uploadResult.errorMessage);
        }
      } catch (e) {
        Logger().e('Photo upload error: $e');
        if (!context.mounted) return;
        LoadScreen.showLoad(context, false);
        await NannyDialogs.showMessageBox(
            context, 'Ошибка', 'Не удалось загрузить фото: $e');
      }
    }
  }

  /// [pageContext] — контекст экрана из `build` (не из initState), чтобы после async корректно закрыть маршрут.
  Future<void> save(BuildContext pageContext) async {
    if (isSaving) {
      return;
    }

    // Валидация
    if (surnameController.text.trim().isEmpty) {
      NannyDialogs.showMessageBox(pageContext, "Ошибка", "Введите фамилию");
      return;
    }

    if (nameController.text.trim().isEmpty) {
      NannyDialogs.showMessageBox(pageContext, "Ошибка", "Введите имя");
      return;
    }

    if (birthday == null) {
      NannyDialogs.showMessageBox(
          pageContext, "Ошибка", "Выберите дату рождения");
      return;
    }

    // NEW-008 / ТЗ: у ребёнка должен быть хотя бы один экстренный контакт (при создании и при редактировании)
    if (emergencyContacts.isEmpty) {
      NannyDialogs.showMessageBox(
        pageContext,
        "Ошибка",
        "Добавьте хотя бы один экстренный контакт перед сохранением ребёнка",
      );
      return;
    }

    if (!pageContext.mounted) return;
    update(() {
      isSaving = true;
    });
    LoadScreen.showLoad(pageContext, true);

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
      photoPath: normalizeChildPhotoPathForStorage(photoPath) ?? photoPath,
      idUser: NannyUser.userInfo?.id ?? 0,
    );

    // Сохраняем
    int? savedChildId;
    if (child == null) {
      final createResult = await NannyChildrenApi.createChild(childData);
      if (!pageContext.mounted) return;
      if (!createResult.success) {
        LoadScreen.showLoad(pageContext, false);
        update(() {
          isSaving = false;
        });
        NannyDialogs.showMessageBox(
            pageContext, "Ошибка", createResult.errorMessage);
        return;
      }
      savedChildId = createResult.response;
    } else {
      final updateResult =
          await NannyChildrenApi.updateChild(child!.id!, childData);
      if (!pageContext.mounted) return;
      if (!updateResult.success) {
        LoadScreen.showLoad(pageContext, false);
        update(() {
          isSaving = false;
        });
        NannyDialogs.showMessageBox(
            pageContext, "Ошибка", updateResult.errorMessage);
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

    if (!pageContext.mounted) return;
    await LoadScreen.showLoad(pageContext, false);
    if (!pageContext.mounted) return;
    update(() {
      isSaving = false;
    });

    if (!pageContext.mounted) return;
    // После закрытия диалога загрузки — на следующем кадре, чтобы стек навигатора был стабилен.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (pageContext.mounted) {
        Navigator.of(pageContext).maybePop(true);
      }
    });
  }

  // FE-MVP-013: Загрузка медицинской информации
  Future<void> _loadMedicalInfo() async {
    if (child?.id == null) return;

    final result = await NannyChildrenApi.getMedicalInfo(child!.id!);
    if (result.success && result.response != null) {
      final info = result.response!;
      _hadMedicalRecord = true;
      hasAllergiesDetails = isSubstantiveMedicalDetail(info.allergies);
      allergiesController.text =
          hasAllergiesDetails ? (info.allergies ?? '').trim() : '';
      hasChronicDiseasesDetails =
          isSubstantiveMedicalDetail(info.chronicDiseases);
      chronicDiseasesController.text = hasChronicDiseasesDetails
          ? (info.chronicDiseases ?? '').trim()
          : '';
      hasMedicationsDetails = isSubstantiveMedicalDetail(info.medications);
      medicationsController.text =
          hasMedicationsDetails ? (info.medications ?? '').trim() : '';
      bloodType = info.bloodType;
      policyNumberController.text = info.medicalPolicyNumber ?? '';
      update(() {});
    }
  }

  // FE-MVP-013: Сохранение медицинской информации
  Future<void> _saveMedicalInfo(int childId) async {
    final policyTrim = policyNumberController.text.trim();

    final aUpdate = hasAllergiesDetails ? allergiesController.text.trim() : '';
    final chUpdate =
        hasChronicDiseasesDetails ? chronicDiseasesController.text.trim() : '';
    final mUpdate =
        hasMedicationsDetails ? medicationsController.text.trim() : '';

    final aCreate =
        hasAllergiesDetails && aUpdate.isNotEmpty ? aUpdate : null;
    final chCreate =
        hasChronicDiseasesDetails && chUpdate.isNotEmpty ? chUpdate : null;
    final mCreate =
        hasMedicationsDetails && mUpdate.isNotEmpty ? mUpdate : null;

    final createPayloadNeeded = aCreate != null ||
        chCreate != null ||
        mCreate != null ||
        bloodType != null ||
        policyTrim.isNotEmpty;

    if (!_hadMedicalRecord && !createPayloadNeeded) {
      return;
    }

    final medicalForUpdate = ChildMedicalInfo(
      idChild: childId,
      allergies: hasAllergiesDetails ? aUpdate : '',
      chronicDiseases: hasChronicDiseasesDetails ? chUpdate : '',
      medications: hasMedicationsDetails ? mUpdate : '',
      bloodType: bloodType,
      medicalPolicyNumber: policyTrim.isEmpty ? '' : policyTrim,
    );

    final medicalForCreate = ChildMedicalInfo(
      idChild: childId,
      allergies: aCreate,
      chronicDiseases: chCreate,
      medications: mCreate,
      bloodType: bloodType,
      medicalPolicyNumber: policyTrim.isEmpty ? null : policyTrim,
    );

    if (child?.id != null) {
      if (_hadMedicalRecord) {
        var updateResult = await NannyChildrenApi.updateMedicalInfo(
            childId, medicalForUpdate);
        if (!updateResult.success) {
          var createResult =
              await NannyChildrenApi.createMedicalInfo(medicalForCreate);
          if (!createResult.success) {
            Logger()
                .e('Failed to save medical info: ${createResult.errorMessage}');
          }
        }
      } else if (createPayloadNeeded) {
        var createResult =
            await NannyChildrenApi.createMedicalInfo(medicalForCreate);
        if (!createResult.success) {
          Logger()
              .e('Failed to create medical info: ${createResult.errorMessage}');
        }
      }
    } else {
      if (createPayloadNeeded) {
        var createResult =
            await NannyChildrenApi.createMedicalInfo(medicalForCreate);
        if (!createResult.success) {
          Logger()
              .e('Failed to create medical info: ${createResult.errorMessage}');
        }
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
        await NannyDialogs.showMessageBox(
            context, 'Ошибка', apiResult.errorMessage);
      }
    } catch (e) {
      if (!context.mounted) return;
      LoadScreen.showLoad(context, false);
      Logger().e('Add emergency contact error: $e');
      await NannyDialogs.showMessageBox(
          context, 'Ошибка', 'Не удалось добавить контакт');
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
    final apiResult =
        await NannyChildrenApi.updateEmergencyContact(contact.id!, result);

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
  Future<EmergencyContact?> _showContactDialog(
      {EmergencyContact? contact}) async {
    final nameController = TextEditingController(text: contact?.name ?? '');
    final relationshipController =
        TextEditingController(text: contact?.relationship ?? '');
    final phoneController = TextEditingController(text: contact?.phone ?? '');
    final phoneMask = MaskTextInputFormatter(
      mask: '+7 (###) ### ## ##',
      filter: {'#': RegExp(r'[0-9]')},
    );
    if (contact != null && contact.phone.isNotEmpty) {
      phoneController.text = contact.phone;
      phoneMask.formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(text: contact.phone),
      );
    }

    return showDialog<EmergencyContact>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            contact == null ? 'Добавить контакт' : 'Редактировать контакт'),
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
