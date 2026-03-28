import 'package:flutter/material.dart';
import 'package:nanny_client/ui_sdk/client_ui_sdk.dart';
import 'package:nanny_client/view_models/pages/child_edit_vm.dart';
import 'package:nanny_core/models/from_api/child.dart';
import 'package:nanny_core/models/from_api/emergency_contact.dart';

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
    final isEdit = widget.child != null;

    return AutonannyListScreenShell(
      appBar: AutonannyAppBar(
        title: isEdit ? 'Профиль ребёнка' : 'Добавить ребёнка',
        leading: AutonannyIconButton(
          icon: const AutonannyIcon(AutonannyIcons.arrowLeft),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      header: _ChildEditHeader(isEdit: isEdit),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AutonannySpacing.xl,
            0,
            AutonannySpacing.xl,
            AutonannySpacing.lg,
          ),
          child: AutonannyButton(
            onPressed: vm.emergencyContacts.isEmpty ? null : vm.save,
            label: isEdit ? 'Сохранить изменения' : 'Добавить ребёнка',
            leading: const AutonannyIcon(
              AutonannyIcons.checkCircle,
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: ListView(
        children: [
          _ChildPhotoSection(
            imageUrl: vm.photoPath,
            initials: _childInitials(),
            onTap: vm.pickPhoto,
          ),
          const SizedBox(height: AutonannySpacing.lg),
          const AutonannyInlineBanner(
            title: 'Экстренный контакт обязателен',
            message:
                'Перед сохранением добавьте минимум один контакт близкого взрослого на случай экстренной ситуации.',
            tone: AutonannyBannerTone.info,
            leading: AutonannyIcon(AutonannyIcons.info),
          ),
          const SizedBox(height: AutonannySpacing.lg),
          AutonannySectionContainer(
            title: 'Основные данные',
            subtitle: 'Имя, дата рождения и школьная информация ребёнка.',
            child: Column(
              children: [
                AutonannyTextField(
                  controller: vm.surnameController,
                  labelText: 'Фамилия*',
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: AutonannySpacing.md),
                AutonannyTextField(
                  controller: vm.nameController,
                  labelText: 'Имя*',
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: AutonannySpacing.md),
                AutonannyTextField(
                  controller: vm.patronymicController,
                  labelText: 'Отчество',
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: AutonannySpacing.md),
                AutonannyTextField(
                  controller: vm.birthdayController,
                  labelText: 'Дата рождения*',
                  readOnly: true,
                  onTap: vm.pickBirthday,
                  suffix: Padding(
                    padding: const EdgeInsets.only(
                      right: AutonannySpacing.md,
                    ),
                    child: AutonannyIcon(
                      AutonannyIcons.calendar,
                      color: context.autonannyColors.textTertiary,
                    ),
                  ),
                ),
                const SizedBox(height: AutonannySpacing.md),
                AutonannyTextField(
                  controller: vm.schoolClassController,
                  labelText: 'Класс / школа',
                  hintText: 'Например: 3 класс, школа №5',
                ),
              ],
            ),
          ),
          const SizedBox(height: AutonannySpacing.lg),
          AutonannySectionContainer(
            title: 'О ребёнке',
            subtitle: 'Пол, характер и важные особенности для водителя.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Пол',
                  style: AutonannyTypography.caption(
                    color: context.autonannyColors.textTertiary,
                  ),
                ),
                const SizedBox(height: AutonannySpacing.sm),
                AutonannySegmentedControl<String>(
                  value: vm.gender ?? '',
                  onChanged: vm.setGender,
                  options: const [
                    AutonannySegmentedOption(value: 'M', label: 'Мальчик'),
                    AutonannySegmentedOption(value: 'F', label: 'Девочка'),
                  ],
                ),
                const SizedBox(height: AutonannySpacing.md),
                AutonannyTextField(
                  controller: vm.characterNotesController,
                  labelText: 'Особенности характера',
                  hintText:
                      'Интересы, привычки, важная информация для сопровождения...',
                  maxLines: 4,
                ),
              ],
            ),
          ),
          const SizedBox(height: AutonannySpacing.lg),
          AutonannySectionContainer(
            title: 'Медицинская информация',
            subtitle:
                'Заполните данные, которые важны в дороге и при сопровождении.',
            child: Column(
              children: [
                AutonannyTextField(
                  controller: vm.allergiesController,
                  labelText: 'Аллергии',
                  maxLines: 2,
                ),
                const SizedBox(height: AutonannySpacing.md),
                AutonannyTextField(
                  controller: vm.chronicDiseasesController,
                  labelText: 'Хронические заболевания',
                  maxLines: 2,
                ),
                const SizedBox(height: AutonannySpacing.md),
                AutonannyTextField(
                  controller: vm.medicationsController,
                  labelText: 'Постоянные медикаменты',
                  maxLines: 2,
                ),
                const SizedBox(height: AutonannySpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _BloodTypeField(
                        value: vm.bloodType,
                        onChanged: (value) =>
                            setState(() => vm.bloodType = value),
                      ),
                    ),
                    const SizedBox(width: AutonannySpacing.md),
                    Expanded(
                      child: AutonannyTextField(
                        controller: vm.policyNumberController,
                        labelText: 'Полис ОМС',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AutonannySpacing.lg),
          AutonannySectionContainer(
            title: 'Экстренные контакты',
            subtitle:
                'Их увидит водитель во время поездки, если понадобится срочная связь.',
            trailing: AutonannyButton(
              label: 'Добавить',
              variant: AutonannyButtonVariant.secondary,
              leading: const AutonannyIcon(AutonannyIcons.add),
              onPressed: vm.addEmergencyContact,
            ),
            child: vm.emergencyContacts.isEmpty
                ? const AutonannyEmptyState(
                    title: 'Контакты пока не добавлены',
                    description:
                        'Добавьте хотя бы один контакт родственника или доверенного взрослого.',
                    icon: AutonannyIcon(AutonannyIcons.phone, size: 36),
                  )
                : Column(
                    children: vm.emergencyContacts
                        .map(
                          (contact) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AutonannySpacing.md,
                            ),
                            child: _EmergencyContactCard(
                              contact: contact,
                              canDelete: vm.emergencyContacts.length > 1,
                              onEdit: () => vm.editEmergencyContact(contact),
                              onDelete: () =>
                                  vm.deleteEmergencyContact(contact),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
        ],
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

class _ChildEditHeader extends StatelessWidget {
  const _ChildEditHeader({required this.isEdit});

  final bool isEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;

    return Container(
      padding: const EdgeInsets.all(AutonannySpacing.xl),
      decoration: const BoxDecoration(
        gradient: AutonannyGradients.hero,
        borderRadius: AutonannyRadii.brLg,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Профиль ребёнка' : 'Новый профиль ребёнка',
                  style: AutonannyTypography.h2(color: colors.textInverse),
                ),
                const SizedBox(height: AutonannySpacing.xs),
                Text(
                  'Соберите данные для безопасных поездок: контакты, особенности и медицинскую информацию.',
                  style: AutonannyTypography.bodyS(
                    color: colors.textInverse.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AutonannySpacing.lg),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colors.textInverse.withValues(alpha: 0.16),
              borderRadius: AutonannyRadii.brMd,
            ),
            alignment: Alignment.center,
            child: const AutonannyIcon(
              AutonannyIcons.child,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChildPhotoSection extends StatelessWidget {
  const _ChildPhotoSection({
    required this.imageUrl,
    required this.initials,
    required this.onTap,
  });

  final String? imageUrl;
  final String initials;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;

    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Stack(
              children: [
                AutonannyAvatar(
                  imageUrl: imageUrl,
                  initials: initials,
                  size: 104,
                  borderRadius: BorderRadius.circular(28),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      gradient: AutonannyGradients.primaryAction,
                      shape: BoxShape.circle,
                      boxShadow: AutonannyShadows.cta,
                    ),
                    child: const Center(
                      child: AutonannyIcon(
                        AutonannyIcons.edit,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AutonannySpacing.md),
          Text(
            'Фото профиля',
            style: AutonannyTypography.labelL(color: colors.textPrimary),
          ),
          const SizedBox(height: AutonannySpacing.xs),
          Text(
            'Помогает водителю быстрее узнать ребёнка при встрече.',
            textAlign: TextAlign.center,
            style: AutonannyTypography.bodyS(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _BloodTypeField extends StatelessWidget {
  const _BloodTypeField({
    required this.value,
    required this.onChanged,
  });

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AutonannySpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: AutonannyRadii.brLg,
        border: Border.all(color: colors.borderSubtle),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(
            'Группа крови',
            style: AutonannyTypography.bodyM(color: colors.textTertiary),
          ),
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
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _EmergencyContactCard extends StatelessWidget {
  const _EmergencyContactCard({
    required this.contact,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
  });

  final EmergencyContact contact;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;

    return AutonannyCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.statusInfoSurface,
              borderRadius: AutonannyRadii.brMd,
            ),
            child: Center(
              child: AutonannyIcon(
                AutonannyIcons.phone,
                color: colors.actionPrimary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: AutonannySpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: AutonannyTypography.labelL(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: AutonannySpacing.xxs),
                Text(
                  contact.relationship,
                  style: AutonannyTypography.bodyS(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AutonannySpacing.xxs),
                Text(
                  contact.phone,
                  style: AutonannyTypography.bodyM(
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AutonannySpacing.sm),
          Column(
            children: [
              AutonannyIconButton(
                icon: const AutonannyIcon(AutonannyIcons.edit),
                tooltip: 'Редактировать контакт',
                size: 40,
                onPressed: onEdit,
              ),
              if (canDelete) ...[
                const SizedBox(height: AutonannySpacing.sm),
                AutonannyIconButton(
                  icon: const AutonannyIcon(AutonannyIcons.close),
                  tooltip: 'Удалить контакт',
                  size: 40,
                  variant: AutonannyIconButtonVariant.ghost,
                  onPressed: onDelete,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
