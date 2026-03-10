import 'package:flutter/material.dart';
import 'package:nanny_client/view_models/pages/child_edit_vm.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/models/from_api/child.dart';

class ChildEditView extends StatefulWidget {
  final Child? child;

  const ChildEditView({super.key, this.child});

  @override
  State<ChildEditView> createState() => _ChildEditViewState();
}

class _ChildEditViewState extends State<ChildEditView> {
  late ChildEditVM vm;

  @override
  void initState() {
    super.initState();
    vm = ChildEditVM(
      context: context,
      update: setState,
      child: widget.child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: NannyAppBar(
        color: const Color(0xFFF7F7F7),
        hasBackButton: true,
        title: widget.child == null ? "Добавить ребенка" : "Редактировать",
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Фото ребенка
            Center(
              child: GestureDetector(
                onTap: vm.pickPhoto,
                child: Stack(
                  children: [
                    ProfileImage(
                      url: vm.photoPath ?? '',
                      radius: 100,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: NannyTheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Фамилия
            NannyTextForm(
              controller: vm.surnameController,
              hintText: "Фамилия",
            ),
            const SizedBox(height: 12),

            // Имя
            NannyTextForm(
              controller: vm.nameController,
              hintText: "Имя",
            ),
            const SizedBox(height: 12),

            // Отчество
            NannyTextForm(
              controller: vm.patronymicController,
              hintText: "Отчество (необязательно)",
            ),
            const SizedBox(height: 12),

            // Дата рождения
            GestureDetector(
              onTap: vm.pickBirthday,
              child: AbsorbPointer(
                child: NannyTextForm(
                  controller: vm.birthdayController,
                  hintText: "Дата рождения",
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Пол
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.wc, color: Color(0xFF757575)),
                  const SizedBox(width: 12),
                  const Text(
                    'Пол:',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF757575),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Мальчик'),
                            value: 'M',
                            groupValue: vm.gender,
                            onChanged: (value) => vm.setGender(value),
                            activeColor: NannyTheme.primary,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Девочка'),
                            value: 'F',
                            groupValue: vm.gender,
                            onChanged: (value) => vm.setGender(value),
                            activeColor: NannyTheme.primary,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Класс/Школа
            NannyTextForm(
              controller: vm.schoolClassController,
              hintText: "Класс/Школа (например: 3 класс, школа №5)",
            ),
            const SizedBox(height: 12),

            // Особенности характера
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: vm.characterNotesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: "Особенности характера, интересы, важная информация...",
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: Color(0xFFBDBDBD),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // FE-MVP-013: Медицинская информация
            const Text(
              'Медицинская информация',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2B2B2B),
              ),
            ),
            const SizedBox(height: 16),

            // Аллергии
            NannyTextForm(
              controller: vm.allergiesController,
              hintText: "Аллергии (если есть)",
              maxLines: 2,
            ),
            const SizedBox(height: 12),

            // Хронические заболевания
            NannyTextForm(
              controller: vm.chronicDiseasesController,
              hintText: "Хронические заболевания (если есть)",
              maxLines: 2,
            ),
            const SizedBox(height: 12),

            // Медикаменты
            NannyTextForm(
              controller: vm.medicationsController,
              hintText: "Постоянные медикаменты (если есть)",
              maxLines: 2,
            ),
            const SizedBox(height: 12),

            // Группа крови и полис ОМС
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: vm.bloodType,
                        hint: const Text('Группа крови'),
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'O+', child: Text('I (O+)')),
                          DropdownMenuItem(value: 'O-', child: Text('I (O-)')),
                          DropdownMenuItem(value: 'A+', child: Text('II (A+)')),
                          DropdownMenuItem(value: 'A-', child: Text('II (A-)')),
                          DropdownMenuItem(value: 'B+', child: Text('III (B+)')),
                          DropdownMenuItem(value: 'B-', child: Text('III (B-)')),
                          DropdownMenuItem(value: 'AB+', child: Text('IV (AB+)')),
                          DropdownMenuItem(value: 'AB-', child: Text('IV (AB-)')),
                        ],
                        onChanged: (value) {
                          vm.bloodType = value;
                          vm.update(() {});
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NannyTextForm(
                    controller: vm.policyNumberController,
                    hintText: "Полис ОМС",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // FE-MVP-014: Экстренные контакты
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Экстренные контакты',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2B2B2B),
                  ),
                ),
                IconButton(
                  onPressed: vm.addEmergencyContact,
                  icon: const Icon(Icons.add_circle, color: NannyTheme.primary),
                  tooltip: 'Добавить контакт',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Список экстренных контактов
            if (vm.emergencyContacts.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF757575), size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Добавьте контакты близких на случай экстренной ситуации',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF757575),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...vm.emergencyContacts.map((contact) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.contact_emergency, color: Color(0xFF757575)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              contact.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2B2B2B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${contact.relationship} • ${contact.phone}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF757575),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => vm.editEmergencyContact(contact),
                        icon: const Icon(Icons.edit, size: 20),
                        color: const Color(0xFF757575),
                      ),
                      // NEW-009: не показывать «Удалить» у единственного контакта
                      if (vm.emergencyContacts.length > 1)
                        IconButton(
                          onPressed: () => vm.deleteEmergencyContact(contact),
                          icon: const Icon(Icons.delete, size: 20),
                          color: Colors.red,
                        ),
                    ],
                  ),
                ),
              )),
            const SizedBox(height: 24),

            // Кнопка сохранения. NEW-008: при создании ребёнка недоступна без экстренного контакта
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (widget.child == null && vm.emergencyContacts.isEmpty)
                    ? null
                    : vm.save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: NannyTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  widget.child == null ? 'Добавить' : 'Сохранить',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
