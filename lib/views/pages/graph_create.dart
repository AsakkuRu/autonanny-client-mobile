import 'package:flutter/material.dart';
import 'package:nanny_client/ui_sdk/client_ui_sdk.dart';
import 'package:nanny_client/ui_sdk/support/ui_sdk_dialogs.dart';
import 'package:nanny_client/view_models/pages/graph_create_vm.dart';
import 'package:nanny_components/widgets/weeks_selector.dart';
import 'package:nanny_core/models/from_api/child.dart';
import 'package:nanny_core/models/from_api/drive_and_map/drive_tariff.dart';
import 'package:nanny_core/models/from_api/drive_and_map/schedule.dart';
import 'package:nanny_core/nanny_core.dart';

class GraphCreate extends StatefulWidget {
  const GraphCreate({super.key, this.schedule});

  final Schedule? schedule;

  @override
  State<GraphCreate> createState() => _GraphCreateState();
}

class _GraphCreateState extends State<GraphCreate> {
  static const List<String> _stepTitles = [
    'Параметры',
    'Дети',
    'Маршруты',
    'Услуги',
    'Проверка',
  ];

  static const List<String> _stepDescriptions = [
    'Название контракта и период регулярных поездок.',
    'Кто относится к этому контракту.',
    'Дни поездок, маршруты и дети внутри каждого маршрута.',
    'Тариф и дополнительные услуги.',
    'Финальная проверка перед сохранением.',
  ];

  late final GraphCreateVM vm;
  int _currentStepIndex = 0;

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
  bool get _isLastStep => _currentStepIndex == _stepTitles.length - 1;

  Future<void> _showRouteFlow(
    NannyWeekday weekday, {
    Road? updatingRoad,
  }) async {
    if (vm.selectedChildrenIds.isEmpty) {
      return;
    }

    final result = await NannyDialogs.showRouteCreateOrEditSheet(
      context,
      weekday,
      road: updatingRoad,
      tariffId: vm.editor.tariff.id,
      allSelectedWeekdays: [weekday],
      applyToAllDaysDefault: false,
      availableChildren: vm.selectedContractChildren,
      initialSelectedChildIds: vm.initialRouteChildrenIds(road: updatingRoad),
    );
    if (result == null || !mounted) {
      return;
    }

    vm.saveRoute(
      route: result.road,
      weekday: weekday,
      childIds:
          result.childIds ?? vm.initialRouteChildrenIds(road: updatingRoad),
      updatingRoad: updatingRoad,
    );
  }

  List<String> _stepIssuesFor(int stepIndex) {
    switch (stepIndex) {
      case 0:
        return vm.hasContractTitle
            ? const <String>[]
            : const <String>['Введите название контракта.'];
      case 1:
        return vm.selectedChildrenIds.isNotEmpty
            ? const <String>[]
            : const <String>['Выберите хотя бы одного ребёнка.'];
      case 2:
        final issues = <String>[];
        if (vm.selectedWeekday.isEmpty) {
          issues.add('Выберите дни поездок.');
        }
        if (vm.editor.roads.isEmpty) {
          issues.add('Добавьте хотя бы один маршрут.');
        }
        if (vm.weekdaysWithoutRoutes.isNotEmpty) {
          final dayLabels = vm.weekdaysWithoutRoutes
              .map((weekday) => weekday.shortName)
              .join(', ');
          issues.add('Для дней $dayLabels пока нет маршрутов.');
        }
        if (vm.routesWithoutChildren.isNotEmpty) {
          final dayLabels = vm.routesWithoutChildren
              .map((road) => road.weekDay.shortName)
              .toSet()
              .join(', ');
          issues.add('У маршрутов не выбраны дети: $dayLabels.');
        }
        if (vm.contractChildrenWithoutRoutes.isNotEmpty) {
          final childLabels = vm.contractChildrenWithoutRoutes
              .map((child) => child.fullName.trim())
              .where((label) => label.isNotEmpty)
              .join(', ');
          issues.add(
            childLabels.isEmpty
                ? 'Не все выбранные дети распределены по маршрутам.'
                : 'Добавьте в маршруты всех выбранных детей: $childLabels.',
          );
        }
        if (vm.tripsPerMonth > 0 && vm.tripsPerMonth < 4) {
          issues.add('Для контракта нужно минимум 4 поездки в месяц.');
        }
        return issues;
      case 3:
        return const <String>[];
      case 4:
        return vm.readinessIssues;
      default:
        return const <String>[];
    }
  }

  Future<void> _continueFlow() async {
    final issues = _stepIssuesFor(_currentStepIndex);
    if (issues.isNotEmpty) {
      await NannyDialogs.showMessageBox(
        context,
        'Шаг еще не завершён',
        issues.join('\n'),
      );
      return;
    }
    setState(() {
      _currentStepIndex += 1;
    });
  }

  void _goBack() {
    if (_currentStepIndex == 0) {
      return;
    }
    setState(() {
      _currentStepIndex -= 1;
    });
  }

  List<Widget> _buildCurrentStepSections(BuildContext context) {
    switch (_currentStepIndex) {
      case 0:
        return [
          AutonannySectionContainer(
            title: 'Основные параметры',
            subtitle:
                'Базовые параметры контракта: название и формат регулярных поездок.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutonannyTextField(
                  controller: vm.nameController,
                  labelText: 'Название контракта',
                  hintText: 'Например, школа, секции и дом',
                  onChanged: vm.changeTitle,
                ),
                const SizedBox(height: AutonannySpacing.lg),
                _SelectionField<GraphType>(
                  title: 'Период контракта',
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
              ],
            ),
          ),
        ];
      case 1:
        return [
          _ChildrenSection(vm: vm),
        ];
      case 2:
        return [
          AutonannySectionContainer(
            title: 'Дни поездок и маршруты',
            subtitle:
                'Сначала выберите дни контракта, затем добавьте маршруты для выбранных дней.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: AutonannySpacing.lg),
                if (vm.selectedChildrenIds.isEmpty)
                  const AutonannyInlineBanner(
                    title: 'Сначала выберите детей контракта',
                    message:
                        'Маршруты создаются только после выбора детей, которые относятся к контракту.',
                    tone: AutonannyBannerTone.warning,
                    leading: AutonannyIcon(AutonannyIcons.warning),
                  )
                else
                  AutonannyInlineBanner(
                    title: 'Выбрано детей: ${vm.selectedChildrenIds.length}',
                    message:
                        'Новые маршруты будут привязаны только к выбранным детям контракта.',
                    tone: AutonannyBannerTone.info,
                    leading: const AutonannyIcon(AutonannyIcons.child),
                  ),
                if (vm.contractChildrenWithoutRoutes.isNotEmpty) ...[
                  const SizedBox(height: AutonannySpacing.md),
                  AutonannyInlineBanner(
                    title: 'Не все дети распределены по маршрутам',
                    message: vm.contractChildrenWithoutRoutes
                        .map((child) => child.fullName.trim())
                        .where((label) => label.isNotEmpty)
                        .join(', '),
                    tone: AutonannyBannerTone.warning,
                    leading: const AutonannyIcon(AutonannyIcons.warning),
                  ),
                ],
                const SizedBox(height: AutonannySpacing.lg),
                if (vm.selectedWeekday.isEmpty)
                  const AutonannyInlineBanner(
                    title: 'Выберите дни контракта',
                    message:
                        'После выбора дней появятся отдельные панели, внутри которых можно добавлять маршруты.',
                    tone: AutonannyBannerTone.info,
                    leading: AutonannyIcon(AutonannyIcons.calendar),
                  )
                else ...[
                  ...vm.sortedSelectedWeekdays.map(
                    (weekday) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: AutonannySpacing.md,
                      ),
                      child: _DayRoutesPanel(
                        day: weekday,
                        roads: vm.routesForDay(weekday),
                        onAddRoute: vm.selectedChildrenIds.isEmpty
                            ? null
                            : () => _showRouteFlow(weekday),
                        onEditRoute: (road) => _showRouteFlow(
                          weekday,
                          updatingRoad: road,
                        ),
                        onDeleteRoute: vm.deleteRoute,
                        routeChildrenBuilder: vm.routeChildrenForRoad,
                      ),
                    ),
                  ),
                  _TripsCounterBanner(roadsCount: vm.editor.roads.length),
                ],
              ],
            ),
          ),
        ];
      case 3:
        return [
          AutonannySectionContainer(
            title: 'Тариф и доп. услуги',
            subtitle:
                'Выберите период контракта и дополнительные требования к поездкам.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TariffSection(vm: vm),
                const SizedBox(height: AutonannySpacing.lg),
                _AdditionalServicesSection(vm: vm),
              ],
            ),
          ),
        ];
      case 4:
      default:
        return [
          _ContractDraftSummarySection(vm: vm),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return AutonannyAppScaffold(
      appBar: AutonannyAppBar(
        title: _isEditMode ? 'Редактирование контракта' : 'Новый контракт',
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
          child: Row(
            children: [
              if (_currentStepIndex > 0)
                Expanded(
                  child: AutonannyButton(
                    label: 'Назад',
                    variant: AutonannyButtonVariant.secondary,
                    leading: AutonannyIcon(
                      AutonannyIcons.arrowLeft,
                      color: context.autonannyColors.actionPrimary,
                    ),
                    onPressed: _goBack,
                  ),
                ),
              if (_currentStepIndex > 0)
                const SizedBox(width: AutonannySpacing.md),
              Expanded(
                child: AutonannyButton(
                  label: _isLastStep
                      ? (_isEditMode ? 'Обновить контракт' : 'Создать контракт')
                      : 'Далее',
                  onPressed: _isLastStep
                      ? (vm.canSubmit ? vm.confirm : null)
                      : _continueFlow,
                  leading: AutonannyIcon(
                    _isLastStep
                        ? AutonannyIcons.checkCircle
                        : AutonannyIcons.arrowRight,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<bool>(
          future: vm.loadRequest,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const AutonannyLoadingState(
                label: 'Подготавливаем контракт.',
              );
            }

            if (snapshot.hasError || snapshot.data != true) {
              return AutonannyErrorState(
                title: 'Не удалось загрузить данные',
                description: snapshot.error?.toString() ??
                    'Попробуйте открыть создание контракта ещё раз.',
                actionLabel: 'Повторить',
                onAction: vm.reloadPage,
              );
            }

            final stepIssues = _stepIssuesFor(_currentStepIndex);
            final stepSections = _buildCurrentStepSections(context);

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
                _CreateFlowHeader(
                  currentStepIndex: _currentStepIndex,
                  titles: _stepTitles,
                  descriptions: _stepDescriptions,
                ),
                if (stepIssues.isNotEmpty && !_isLastStep) ...[
                  const SizedBox(height: AutonannySpacing.lg),
                  AutonannyInlineBanner(
                    title: 'Чтобы перейти дальше, завершите шаг',
                    message: stepIssues.join('\n'),
                    tone: AutonannyBannerTone.warning,
                    leading: const AutonannyIcon(AutonannyIcons.warning),
                  ),
                ],
                for (var i = 0; i < stepSections.length; i++) ...[
                  const SizedBox(height: AutonannySpacing.lg),
                  stepSections[i],
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DayRoutesPanel extends StatelessWidget {
  const _DayRoutesPanel({
    required this.day,
    required this.roads,
    required this.onAddRoute,
    required this.onEditRoute,
    required this.onDeleteRoute,
    required this.routeChildrenBuilder,
  });

  final NannyWeekday day;
  final List<Road> roads;
  final VoidCallback? onAddRoute;
  final ValueChanged<Road> onEditRoute;
  final ValueChanged<Road> onDeleteRoute;
  final List<Child> Function(Road road) routeChildrenBuilder;

  @override
  Widget build(BuildContext context) {
    return AutonannyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      day.fullName,
                      style: AutonannyTypography.labelL(
                        color: context.autonannyColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AutonannySpacing.xs),
                    Text(
                      'Добавляйте маршруты и сразу выбирайте детей для каждой поездки.',
                      style: AutonannyTypography.bodyS(
                        color: context.autonannyColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AutonannySpacing.md),
              AutonannyButton(
                label: 'Маршрут',
                size: AutonannyButtonSize.medium,
                variant: AutonannyButtonVariant.secondary,
                expand: false,
                leading: const AutonannyIcon(AutonannyIcons.add),
                onPressed: onAddRoute,
              ),
            ],
          ),
          const SizedBox(height: AutonannySpacing.lg),
          if (roads.isEmpty)
            const AutonannyInlineBanner(
              title: 'День выбран, но маршрутов пока нет',
              message:
                  'Добавьте хотя бы один маршрут для этого дня, иначе контракт нельзя будет сохранить.',
              tone: AutonannyBannerTone.warning,
              leading: AutonannyIcon(AutonannyIcons.route),
            )
          else
            Column(
              children: roads
                  .map(
                    (road) => Padding(
                      padding:
                          const EdgeInsets.only(bottom: AutonannySpacing.md),
                      child: _RouteDraftCard(
                        road: road,
                        assignedChildren: routeChildrenBuilder(road),
                        onEdit: () => onEditRoute(road),
                        onDelete: () => onDeleteRoute(road),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
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
                      ? 'Настройте расписание и параметры регулярных поездок по контракту.'
                      : 'Соберите недельный или долгосрочный контракт с регулярными поездками для ребёнка.',
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

class _CreateFlowHeader extends StatelessWidget {
  const _CreateFlowHeader({
    required this.currentStepIndex,
    required this.titles,
    required this.descriptions,
  });

  final int currentStepIndex;
  final List<String> titles;
  final List<String> descriptions;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;

    return AutonannySectionContainer(
      title: 'Шаг ${currentStepIndex + 1} из ${titles.length}',
      subtitle: descriptions[currentStepIndex],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AutonannySpacing.sm,
            runSpacing: AutonannySpacing.sm,
            children: List.generate(
              titles.length,
              (index) {
                final isActive = index == currentStepIndex;
                final isCompleted = index < currentStepIndex;
                final backgroundColor = isActive
                    ? colors.actionPrimary
                    : isCompleted
                        ? colors.statusSuccessSurface
                        : colors.surfaceSecondary;
                final textColor = isActive
                    ? colors.textInverse
                    : isCompleted
                        ? colors.statusSuccess
                        : colors.textSecondary;
                final label = '${index + 1}. ${titles[index]}';

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AutonannySpacing.md,
                    vertical: AutonannySpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: AutonannyRadii.brLg,
                    border: Border.all(
                      color:
                          isActive ? colors.actionPrimary : colors.borderSubtle,
                    ),
                  ),
                  child: Text(
                    label,
                    style: AutonannyTypography.labelM(
                      color: textColor,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AutonannySpacing.md),
          Text(
            titles[currentStepIndex],
            style: AutonannyTypography.h3(
              color: colors.textPrimary,
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
      title: 'Дети контракта',
      subtitle:
          'Сначала выберите детей, которые относятся к этому контракту. Максимум 4 ребёнка.',
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

class _RouteDraftCard extends StatelessWidget {
  const _RouteDraftCard({
    required this.road,
    required this.assignedChildren,
    required this.onEdit,
    required this.onDelete,
  });

  final Road road;
  final List<Child> assignedChildren;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;
    final fromAddress = road.addresses.isEmpty
        ? 'Точка отправления не указана'
        : road.addresses.first.fromAddress.address;
    final toAddress = road.addresses.isEmpty
        ? 'Точка прибытия не указана'
        : road.addresses.last.toAddress.address;
    final tripTypeLabel = road.typeDrive.contains(DriveType.roundTrip)
        ? 'Туда и обратно'
        : 'В одну сторону';

    return Container(
      padding: const EdgeInsets.all(AutonannySpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: AutonannyRadii.brLg,
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      road.title.isEmpty ? 'Маршрут без названия' : road.title,
                      style: AutonannyTypography.labelL(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AutonannySpacing.xs),
                    Text(
                      '${road.startTime.formatTime()} - ${road.endTime.formatTime()}',
                      style: AutonannyTypography.bodyS(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AutonannySpacing.md),
              Text(
                tripTypeLabel,
                style: AutonannyTypography.caption(
                  color: colors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AutonannySpacing.md),
          Text(
            fromAddress,
            style: AutonannyTypography.bodyM(color: colors.textPrimary),
          ),
          const SizedBox(height: AutonannySpacing.xs),
          Text(
            toAddress,
            style: AutonannyTypography.bodyS(color: colors.textSecondary),
          ),
          const SizedBox(height: AutonannySpacing.md),
          Text(
            'Дети маршрута',
            style: AutonannyTypography.caption(color: colors.textTertiary),
          ),
          const SizedBox(height: AutonannySpacing.xs),
          if (assignedChildren.isEmpty)
            const AutonannyInlineBanner(
              title: 'Дети не выбраны',
              message:
                  'Откройте редактирование маршрута и укажите, кто едет по этой поездке.',
              tone: AutonannyBannerTone.danger,
              leading: AutonannyIcon(AutonannyIcons.warning),
            )
          else
            Wrap(
              spacing: AutonannySpacing.sm,
              runSpacing: AutonannySpacing.sm,
              children: assignedChildren
                  .map(
                    (child) => _ChildToken(
                      label: '${child.name} ${child.surname}'.trim(),
                    ),
                  )
                  .toList(growable: false),
            ),
          if (road.amount != null) ...[
            const SizedBox(height: AutonannySpacing.md),
            Text(
              'Предварительная стоимость маршрута: ${road.amount!.toStringAsFixed(0)} ₽',
              style: AutonannyTypography.bodyS(
                color: colors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AutonannySpacing.md),
          Row(
            children: [
              Expanded(
                child: AutonannyButton(
                  label: 'Изменить',
                  variant: AutonannyButtonVariant.secondary,
                  onPressed: onEdit,
                ),
              ),
              const SizedBox(width: AutonannySpacing.sm),
              Expanded(
                child: OutlinedButton(
                  onPressed: onDelete,
                  child: const Text('Удалить'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChildToken extends StatelessWidget {
  const _ChildToken({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AutonannySpacing.md,
        vertical: AutonannySpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: AutonannyRadii.brLg,
      ),
      child: Text(
        label,
        style: AutonannyTypography.caption(color: colors.textPrimary),
      ),
    );
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
  @override
  Widget build(BuildContext context) {
    return AdditionalServicesSelector(
      subtitle:
          'Выберите требования, которые будут учитывать при подборе водителя.',
      options: widget.vm.params
          .map(
            (param) => AdditionalServiceOptionData(
              id: '${param.id ?? param.title}',
              title: param.title ?? 'Неизвестная услуга',
              isSelected: widget.vm.isParamSelected(param),
              priceLabel: (param.amount != null && param.amount! > 0)
                  ? '${param.amount!.round()} ₽'
                  : null,
              caption:
                  param.count == null ? null : 'Количество: ${param.count}',
            ),
          )
          .toList(growable: false),
      onToggle: (optionId) {
        final match = widget.vm.params.firstWhere(
          (param) => '${param.id ?? param.title}' == optionId,
        );
        final isSelected = widget.vm.isParamSelected(match);
        if (isSelected) {
          widget.vm.removeParam(match);
        } else {
          widget.vm.addParam(match);
        }
        setState(() {});
      },
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

class _ContractDraftSummarySection extends StatelessWidget {
  const _ContractDraftSummarySection({
    required this.vm,
  });

  final GraphCreateVM vm;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;

    return AutonannySectionContainer(
      title: 'Сводка по контракту',
      subtitle:
          'Проверьте конфигурацию контракта перед сохранением. Стоимость считается по маршрутам, где уже есть расчет.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (vm.readinessIssues.isNotEmpty) ...[
            AutonannyInlineBanner(
              title: 'Контракт еще не готов к сохранению',
              message: vm.readinessIssues.join('\n'),
              tone: AutonannyBannerTone.warning,
              leading: const AutonannyIcon(AutonannyIcons.warning),
            ),
            const SizedBox(height: AutonannySpacing.md),
          ],
          Row(
            children: [
              Expanded(
                child: _SummaryMetricCard(
                  label: 'Детей',
                  value: '${vm.selectedChildrenIds.length}',
                ),
              ),
              const SizedBox(width: AutonannySpacing.sm),
              Expanded(
                child: _SummaryMetricCard(
                  label: 'Дней',
                  value: '${vm.selectedDaysCount}',
                ),
              ),
              const SizedBox(width: AutonannySpacing.sm),
              Expanded(
                child: _SummaryMetricCard(
                  label: 'Маршрутов',
                  value: '${vm.routesCount}',
                ),
              ),
            ],
          ),
          const SizedBox(height: AutonannySpacing.md),
          Row(
            children: [
              Expanded(
                child: _SummaryMetricCard(
                  label: 'В неделю',
                  value: _formatAmount(vm.estimatedWeeklyAmount),
                  caption: 'с учетом услуг',
                ),
              ),
              const SizedBox(width: AutonannySpacing.sm),
              Expanded(
                child: _SummaryMetricCard(
                  label: 'В месяц',
                  value: _formatAmount(vm.estimatedMonthlyAmount),
                  caption: '${vm.tripsPerMonth} поездок',
                ),
              ),
            ],
          ),
          const SizedBox(height: AutonannySpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AutonannySpacing.md),
            decoration: BoxDecoration(
              color: colors.surfaceSecondary,
              borderRadius: AutonannyRadii.brLg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Категория: ${vm.editor.tariff.title ?? 'Заказ маршрута'}',
                  style: AutonannyTypography.bodyM(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: AutonannySpacing.xs),
                Text(
                  'Доп. услуги: ${vm.selectedServicesLabel}',
                  style: AutonannyTypography.bodyS(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AutonannySpacing.xs),
                Text(
                  'Маршруты: ${_formatAmount(vm.estimatedRoutesWeeklyAmount)} в неделю',
                  style: AutonannyTypography.bodyS(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AutonannySpacing.xs),
                Text(
                  'Услуги: ${_formatAmount(vm.selectedAdditionalServicesTotal)} в неделю',
                  style: AutonannyTypography.bodyS(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (vm.estimatedMonthlyAmount == null && vm.routesCount > 0) ...[
            const SizedBox(height: AutonannySpacing.md),
            const AutonannyInlineBanner(
              title: 'Стоимость пока неполная',
              message:
                  'Для части маршрутов еще нет расчета. Откройте маршрут и дождитесь предварительной стоимости.',
              tone: AutonannyBannerTone.info,
              leading: AutonannyIcon(AutonannyIcons.info),
            ),
          ],
        ],
      ),
    );
  }

  String _formatAmount(double? value) {
    if (value == null || value <= 0) {
      return '—';
    }
    return '~ ${value.round()} ₽';
  }
}

class _SummaryMetricCard extends StatelessWidget {
  const _SummaryMetricCard({
    required this.label,
    required this.value,
    this.caption,
  });

  final String label;
  final String value;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;

    return Container(
      padding: const EdgeInsets.all(AutonannySpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: AutonannyRadii.brLg,
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AutonannyTypography.caption(
              color: colors.textTertiary,
            ),
          ),
          const SizedBox(height: AutonannySpacing.xs),
          Text(
            value,
            style: AutonannyTypography.h3(
              color: colors.textPrimary,
            ),
          ),
          if (caption case final captionText?) ...[
            const SizedBox(height: AutonannySpacing.xs),
            Text(
              captionText,
              style: AutonannyTypography.caption(
                color: colors.textSecondary,
              ),
            ),
          ],
        ],
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
