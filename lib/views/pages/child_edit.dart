import 'package:flutter/material.dart';
import 'package:nanny_client/ui_sdk/client_ui_sdk.dart';
import 'package:nanny_client/view_models/pages/child_edit_vm.dart';
import 'package:nanny_components/styles/nanny_theme.dart';
import 'package:nanny_components/widgets/nanny_text_forms.dart';
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
    final colors = context.autonannyColors;

    return AutonannyAppScaffold(
      appBar: AutonannyAppBar(
        title: widget.child == null ? "Добавить ребенка" : "Редактировать",
        leading: AutonannyIconButton(
          icon: const AutonannyIcon(AutonannyIcons.arrowLeft),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
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
                    AutonannyAvatar(
                      imageUrl: vm.photoPath,
                      initials: _childInitials(),
                      size: 100,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.actionPrimary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: NannyTheme.shadow.withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const AutonannyIcon(
                          AutonannyIcons.edit,
                          color: Colors.white,
                          size: 18,
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
              validator: (text) {
                if (text == null || text.trim().isEmpty) {
                  return "Введите фамилию";
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Имя
            NannyTextForm(
              controller: vm.nameController,
              hintText: "Имя",
              validator: (text) {
                if (text == null || text.trim().isEmpty) {
                  return "Введите имя";
                }
                return null;
              },
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
                  validator: (text) {
                    if (text == null || text.trim().isEmpty) {
                      return "Выберите дату рождения";
                    }
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Пол
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: NannyTheme.shadow.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.wc, color: NannyTheme.neutral500),
                  const SizedBox(width: 12),
                  Text(
                    'Пол',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: NannyTheme.neutral700,
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
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: NannyTheme.shadow.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: vm.characterNotesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText:
                      "Особенности характера, интересы, важная информация...",
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
            Text(
              'Медицинская информация',
              style: Theme.of(context).textTheme.titleMedium,
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
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
                          DropdownMenuItem(
                              value: 'B+', child: Text('III (B+)')),
                          DropdownMenuItem(
                              value: 'B-', child: Text('III (B-)')),
                          DropdownMenuItem(
                              value: 'AB+', child: Text('IV (AB+)')),
                          DropdownMenuItem(
                              value: 'AB-', child: Text('IV (AB-)')),
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
                Text(
                  'Экстренные контакты',
                  style: Theme.of(context).textTheme.titleMedium,
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
                  color: NannyTheme.neutral50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: NannyTheme.neutral500, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Добавьте контакты близких на случай экстренной ситуации',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: NannyTheme.neutral600),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...vm.emergencyContacts.map(
                (contact) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: NannyTheme.shadow.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.contact_emergency,
                            color: NannyTheme.neutral500),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                contact.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${contact.relationship} • ${contact.phone}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: NannyTheme.neutral600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => vm.editEmergencyContact(contact),
                          icon: const Icon(Icons.edit, size: 20),
                          color: NannyTheme.neutral500,
                        ),
                        if (vm.emergencyContacts.length > 1)
                          IconButton(
                            onPressed: () => vm.deleteEmergencyContact(contact),
                            icon: const Icon(Icons.delete, size: 20),
                            color: NannyTheme.danger,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Кнопка сохранения. NEW-008 / ТЗ: недоступна без минимум одного экстренного контакта (создание и редактирование)
            SizedBox(
              width: double.infinity,
              child: AutonannyButton(
                onPressed: vm.emergencyContacts.isEmpty ? null : vm.save,
                label: widget.child == null ? 'Добавить' : 'Сохранить',
                leading: const AutonannyIcon(
                  AutonannyIcons.checkCircle,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _childInitials() {
    String firstChar(String? value) {
      if (value == null || value.trim().isEmpty) {
        return '';
      }
      return value.trim().characters.first;
    }

    final first = vm.nameController.text.trim().isNotEmpty
        ? firstChar(vm.nameController.text)
        : firstChar(widget.child?.name);
    final second = vm.surnameController.text.trim().isNotEmpty
        ? firstChar(vm.surnameController.text)
        : firstChar(widget.child?.surname);
    final initials = '$first$second'.trim().toUpperCase();
    return initials.isEmpty ? 'A' : initials;
  }
}
