import 'package:flutter/material.dart';
import 'package:nanny_client/ui_sdk/client_ui_sdk.dart';
import 'package:nanny_client/view_models/pages/graph_create_vm.dart';
import 'package:nanny_components/widgets/schedule_viewer.dart';
import 'package:nanny_components/widgets/weeks_selector.dart';
import 'package:nanny_core/models/from_api/child.dart';
import 'package:nanny_core/models/from_api/drive_and_map/drive_tariff.dart';
import 'package:nanny_core/models/from_api/drive_and_map/schedule.dart';
import 'package:nanny_core/models/from_api/other_parametr.dart';
import 'package:nanny_core/nanny_core.dart';

class GraphCreate extends StatefulWidget {
  const GraphCreate({super.key, this.schedule});

  final Schedule? schedule;

  @override
  State<GraphCreate> createState() => _GraphCreateState();
}

class _GraphCreateState extends State<GraphCreate> {
  late final GraphCreateVM vm;

  @override
  void initState() {
    super.initState();
    vm = GraphCreateVM(
      context: context,
      update: setState,
      schedule: widget.schedule,
    );
  }

  bool get _isEditMode => widget.schedule != null;

  @override
  Widget build(BuildContext context) {
    return AutonannyAppScaffold(
      appBar: AutonannyAppBar(
        title: _isEditMode ? 'Редактирование графика' : 'Новый график поездок',
        leading: AutonannyIconButton(
          icon: const AutonannyIcon(AutonannyIcons.arrowLeft),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
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
            label: _isEditMode ? 'Обновить график' : 'Создать график',
            onPressed: vm.confirm,
            leading: const AutonannyIcon(
              AutonannyIcons.checkCircle,
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<bool>(
          future: vm.loadRequest,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const AutonannyLoadingState(
                label: 'Подготавливаем график поездок.',
              );
            }

            if (snapshot.hasError || snapshot.data != true) {
              return AutonannyErrorState(
                title: 'Не удалось загрузить данные',
                description: snapshot.error?.toString() ??
                    'Попробуйте открыть создание графика ещё раз.',
                actionLabel: 'Повторить',
                onAction: vm.reloadPage,
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AutonannySpacing.xl,
                AutonannySpacing.md,
                AutonannySpacing.xl,
                120,
              ),
              children: [
                _GraphCreateHero(isEditMode: _isEditMode),
                const SizedBox(height: AutonannySpacing.xl),
                AutonannySectionContainer(
                  title: 'Основные параметры',
                  subtitle:
                      'Название графика, тип программы и дни, в которые нужен водитель.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutonannyTextField(
                        controller: vm.nameController,
                        labelText: 'Название графика',
                        hintText: 'Например, школа и секции',
                        onChanged: vm.changeTitle,
                      ),
                      const SizedBox(height: AutonannySpacing.lg),
                      _SelectionField<GraphType>(
                        title: 'Тип загруженности графика',
                        value: vm.editor.type,
                        items: GraphType.values
                            .map(
                              (type) => _SelectionFieldItem<GraphType>(
                                value: type,
                                label: type.name,
                              ),
                            )
                            .toList(growable: false),
                        onChanged: vm.graphTypeChanged,
                      ),
                      const SizedBox(height: AutonannySpacing.lg),
                      Text(
                        'Дни поездок',
                        style: AutonannyTypography.labelL(
                          color: context.autonannyColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AutonannySpacing.sm),
                      WeeksSelector(
                        selectedWeekday: vm.selectedWeekday,
                        onChanged: vm.weekdaySelected,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AutonannySpacing.lg),
                _ChildrenSection(vm: vm),
                const SizedBox(height: AutonannySpacing.lg),
                AutonannySectionContainer(
                  title: 'Расписание маршрутов',
                  subtitle:
                      'Добавьте хотя бы один маршрут для каждого выбранного дня графика.',
                  trailing: AutonannyButton(
                    label: 'Добавить',
                    size: AutonannyButtonSize.medium,
                    expand: false,
                    leading: const AutonannyIcon(
                      AutonannyIcons.add,
                      color: Colors.white,
                    ),
                    onPressed: vm.addOrEditRoute,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (vm.editor.roads.isEmpty)
                        const AutonannyEmptyState(
                          title: 'Маршруты ещё не добавлены',
                          description:
                              'Создайте первый маршрут, чтобы график можно было сохранить.',
                          icon: AutonannyIcon(AutonannyIcons.route, size: 36),
                        )
                      else ...[
                        ScheduleViewer(
                          schedule:
                              vm.editor.createSchedule(vm.selectedWeekday),
                          selectedWeedkays: vm.selectedWeekday,
                          onDeleteRoad: vm.deleteRoute,
                          onEditRoad: (road) =>
                              vm.addOrEditRoute(updatingRoad: road),
                        ),
                        const SizedBox(height: AutonannySpacing.lg),
                        _TripsCounterBanner(roadsCount: vm.editor.roads.length),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AutonannySpacing.lg),
                AutonannySectionContainer(
                  title: 'Тариф и доп. услуги',
                  subtitle:
                      'Выберите категорию графика и дополнительные требования к поездкам.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TariffSection(vm: vm),
                      const SizedBox(height: AutonannySpacing.lg),
                      _AdditionalServicesSection(vm: vm),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GraphCreateHero extends StatelessWidget {
  const _GraphCreateHero({required this.isEditMode});

  final bool isEditMode;

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
                  isEditMode ? 'Обновление контракта' : 'Создание контракта',
                  style: AutonannyTypography.h2(color: colors.textInverse),
                ),
                const SizedBox(height: AutonannySpacing.xs),
                Text(
                  isEditMode
                      ? 'Настройте расписание и параметры регулярных поездок.'
                      : 'Соберите недельный или долгосрочный график поездок для ребёнка.',
                  style: AutonannyTypography.bodyS(
                    color: colors.textInverse.withValues(alpha: 0.84),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AutonannySpacing.lg),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colors.textInverse.withValues(alpha: 0.16),
              borderRadius: AutonannyRadii.brLg,
            ),
            alignment: Alignment.center,
            child: const AutonannyIcon(
              AutonannyIcons.calendar,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChildrenSection extends StatelessWidget {
  const _ChildrenSection({required this.vm});

  final GraphCreateVM vm;

  @override
  Widget build(BuildContext context) {
    return AutonannySectionContainer(
      title: 'Дети',
      subtitle:
          'Выберите детей, которые будут участвовать в этом графике. Максимум 4 ребёнка.',
      child: vm.children.isEmpty
          ? const AutonannyInlineBanner(
              title: 'Нет профилей детей',
              message:
                  'Сначала добавьте профили детей в соответствующем разделе приложения.',
              tone: AutonannyBannerTone.warning,
              leading: AutonannyIcon(AutonannyIcons.warning),
            )
          : Column(
              children: vm.children
                  .map(
                    (child) => Padding(
                      padding:
                          const EdgeInsets.only(bottom: AutonannySpacing.sm),
                      child: _ChildSelectionTile(
                        child: child,
                        isSelected: child.id != null &&
                            vm.selectedChildrenIds.contains(child.id),
                        onTap: child.id == null
                            ? null
                            : () => vm.toggleChildSelection(child.id!),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }
}

class _ChildSelectionTile extends StatelessWidget {
  const _ChildSelectionTile({
    required this.child,
    required this.isSelected,
    required this.onTap,
  });

  final Child child;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;
    final imageUrl = NannyConsts.buildFileUrl(child.photoPath);
    final ageLabel = child.birthday == null
        ? null
        : 'Возраст: ${DateTime.now().year - child.birthday!.year} лет';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AutonannyRadii.brLg,
        child: AnimatedContainer(
          duration: AutonannyMotion.fast,
          padding: const EdgeInsets.all(AutonannySpacing.md),
          decoration: BoxDecoration(
            color: colors.surfaceElevated,
            borderRadius: AutonannyRadii.brLg,
            border: Border.all(
              color: isSelected ? colors.actionPrimary : colors.borderSubtle,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              AutonannyAvatar(
                image: imageUrl == null ? null : NetworkImage(imageUrl),
                initials: _initials('${child.name} ${child.surname}'),
                size: 48,
              ),
              const SizedBox(width: AutonannySpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${child.surname} ${child.name}'.trim(),
                      style: AutonannyTypography.labelL(
                        color: colors.textPrimary,
                      ),
                    ),
                    if (ageLabel != null) ...[
                      const SizedBox(height: AutonannySpacing.xs),
                      Text(
                        ageLabel,
                        style: AutonannyTypography.bodyS(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Checkbox(
                value: isSelected,
                onChanged: onTap == null ? null : (_) => onTap!(),
                activeColor: colors.actionPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String value) {
    final parts = value
        .split(' ')
        .where((element) => element.trim().isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) {
      return 'A';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1);
    }
    return '${parts[0][0]}${parts[1][0]}';
  }
}

class _TariffSection extends StatelessWidget {
  const _TariffSection({required this.vm});

  final GraphCreateVM vm;

  @override
  Widget build(BuildContext context) {
    if (vm.tariffs.isEmpty) {
      return const AutonannyInlineBanner(
        title: 'Тарифы недоступны',
        message: 'Повторите попытку позже.',
        tone: AutonannyBannerTone.warning,
        leading: AutonannyIcon(AutonannyIcons.warning),
      );
    }

    if (vm.tariffs.length == 1) {
      final tariff = vm.tariffs.first;
      return AutonannyCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Категория',
              style: AutonannyTypography.caption(
                color: context.autonannyColors.textTertiary,
              ),
            ),
            const SizedBox(height: AutonannySpacing.sm),
            Text(
              tariff.title ?? 'Заказ маршрута',
              style: AutonannyTypography.h3(
                color: context.autonannyColors.textPrimary,
              ),
            ),
            const SizedBox(height: AutonannySpacing.xs),
            Text(
              'Акцент на квалификации и опыте автоняни.',
              style: AutonannyTypography.bodyS(
                color: context.autonannyColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return _SelectionField<DriveTariff>(
      title: 'Тариф',
      value: vm.editor.tariff,
      items: vm.tariffs
          .map(
            (tariff) => _SelectionFieldItem<DriveTariff>(
              value: tariff,
              label: tariff.title ?? 'Неизвестный тариф',
            ),
          )
          .toList(growable: false),
      onChanged: vm.tariffSelected,
    );
  }
}

class _AdditionalServicesSection extends StatefulWidget {
  const _AdditionalServicesSection({required this.vm});

  final GraphCreateVM vm;

  @override
  State<_AdditionalServicesSection> createState() =>
      _AdditionalServicesSectionState();
}

class _AdditionalServicesSectionState
    extends State<_AdditionalServicesSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return AutonannyCard(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          initiallyExpanded: _expanded,
          onExpansionChanged: (value) => setState(() => _expanded = value),
          title: Text(
            'Дополнительные услуги',
            style: AutonannyTypography.labelL(
              color: context.autonannyColors.textPrimary,
            ),
          ),
          subtitle: Text(
            'Выберите требования, которые будут учитывать при подборе водителя.',
            style: AutonannyTypography.bodyS(
              color: context.autonannyColors.textSecondary,
            ),
          ),
          trailing: RotatedBox(
            quarterTurns: _expanded ? 3 : 1,
            child: AutonannyIcon(
              AutonannyIcons.chevronRight,
              color: context.autonannyColors.textSecondary,
            ),
          ),
          children: [
            const SizedBox(height: AutonannySpacing.md),
            if (widget.vm.params.isEmpty)
              const Align(
                alignment: Alignment.centerLeft,
                child: AutonannyInlineBanner(
                  title: 'Дополнительные услуги пока недоступны',
                  tone: AutonannyBannerTone.info,
                  leading: AutonannyIcon(AutonannyIcons.info),
                ),
              )
            else
              Column(
                children: widget.vm.params
                    .map(
                      (param) => _ServiceCheckboxTile(
                        param: param,
                        selected: widget.vm.editor.params.contains(param),
                        onChanged: (value) {
                          if (value) {
                            widget.vm.addParam(param);
                          } else {
                            widget.vm.removeParam(param);
                          }
                        },
                      ),
                    )
                    .toList(growable: false),
              ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCheckboxTile extends StatelessWidget {
  const _ServiceCheckboxTile({
    required this.param,
    required this.selected,
    required this.onChanged,
  });

  final OtherParametr param;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AutonannySpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(!selected),
          borderRadius: AutonannyRadii.brMd,
          child: Row(
            children: [
              Checkbox(
                value: selected,
                onChanged: (value) => onChanged(value ?? false),
                activeColor: context.autonannyColors.actionPrimary,
              ),
              Expanded(
                child: Text(
                  param.title ?? 'Неизвестная услуга',
                  style: AutonannyTypography.bodyM(
                    color: context.autonannyColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripsCounterBanner extends StatelessWidget {
  const _TripsCounterBanner({required this.roadsCount});

  final int roadsCount;

  @override
  Widget build(BuildContext context) {
    final tripsPerMonth = roadsCount * 4;
    final isValid = tripsPerMonth >= 4;

    return AutonannyInlineBanner(
      title: 'Поездок в месяц: $tripsPerMonth',
      message: isValid
          ? 'Минимальное требование по частоте поездок выполнено.'
          : 'Для контракта требуется минимум 4 поездки в месяц.',
      tone: isValid ? AutonannyBannerTone.success : AutonannyBannerTone.danger,
      leading: AutonannyIcon(
        isValid ? AutonannyIcons.checkCircle : AutonannyIcons.error,
      ),
    );
  }
}

class _SelectionField<T> extends StatelessWidget {
  const _SelectionField({
    required this.title,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String title;
  final T value;
  final List<_SelectionFieldItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AutonannyTypography.labelL(color: colors.textPrimary),
        ),
        const SizedBox(height: AutonannySpacing.sm),
        DropdownButtonFormField<T>(
          key: ValueKey<T>(value),
          initialValue: value,
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item.value,
                  child: Text(
                    item.label,
                    overflow: TextOverflow.ellipsis,
                    style: AutonannyTypography.bodyM(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: colors.surfaceElevated,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AutonannySpacing.lg,
              vertical: AutonannySpacing.md,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AutonannyRadii.brLg,
              borderSide: BorderSide(color: colors.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AutonannyRadii.brLg,
              borderSide: BorderSide(color: colors.actionPrimary, width: 1.4),
            ),
          ),
          icon: RotatedBox(
            quarterTurns: 1,
            child: AutonannyIcon(
              AutonannyIcons.chevronRight,
              color: colors.textSecondary,
            ),
          ),
          borderRadius: AutonannyRadii.brLg,
        ),
      ],
    );
  }
}

class _SelectionFieldItem<T> {
  const _SelectionFieldItem({
    required this.value,
    required this.label,
  });

  final T value;
  final String label;
}
