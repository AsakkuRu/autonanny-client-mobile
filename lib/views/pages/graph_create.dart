import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nanny_client/ui_sdk/client_ui_sdk.dart';
import 'package:nanny_client/ui_sdk/support/ui_sdk_dialogs.dart';
import 'package:nanny_client/view_models/pages/graph_create_vm.dart';
import 'package:nanny_components/widgets/map/address_pick_choice.dart';
import 'package:nanny_core/api/nanny_orders_api.dart';
import 'package:nanny_core/models/from_api/child.dart';
import 'package:nanny_core/models/from_api/drive_and_map/address_data.dart';
import 'package:nanny_core/models/from_api/drive_and_map/drive_tariff.dart';
import 'package:nanny_core/models/from_api/drive_and_map/geocoding_data.dart';
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
    'Дни и время',
    'Маршруты',
    'Дети',
    'Тариф и услуги',
    'Подтверждение',
  ];

  static const List<String> _stepDescriptions = [
    'Название контракта и период регулярных поездок.',
    'Выберите дни поездок и время через барабан.',
    'Добавьте маршруты для выбранных дней.',
    'Кто относится к этому контракту.',
    'Тариф и услуги.',
    'Проверьте детали перед публикацией.',
  ];

  late final GraphCreateVM vm;
  int _currentStepIndex = 0;
  bool _draftRoundTrip = false;
  final TextEditingController _routeTitleController = TextEditingController();
  final TextEditingController _fromAddressController = TextEditingController();
  final TextEditingController _toAddressController = TextEditingController();
  GeocodeResult? _routeFrom;
  GeocodeResult? _routeTo;

  @override
  void initState() {
    super.initState();
    vm = GraphCreateVM(
      context: context,
      update: setState,
      schedule: widget.schedule,
    );
    final firstRoad = widget.schedule?.roads.firstOrNull;
    if (firstRoad != null) {
      _draftRoundTrip = firstRoad.typeDrive.contains(DriveType.roundTrip);
      _routeTitleController.text = firstRoad.title.trim();
      if (firstRoad.addresses.isNotEmpty) {
        final fromAddress = firstRoad.addresses.first.fromAddress;
        final toAddress = firstRoad.addresses.last.toAddress;
        _fromAddressController.text = fromAddress.address;
        _toAddressController.text = toAddress.address;
        _routeFrom = GeocodeResult(
          addressComponents: const [],
          formattedAddress: fromAddress.address,
          geometry: Geometry(location: fromAddress.location),
          placeId: '',
          plusCode: null,
          types: const [],
        );
        _routeTo = GeocodeResult(
          addressComponents: const [],
          formattedAddress: toAddress.address,
          geometry: Geometry(location: toAddress.location),
          placeId: '',
          plusCode: null,
          types: const [],
        );
      }
    }
  }

  @override
  void dispose() {
    _routeTitleController.dispose();
    _fromAddressController.dispose();
    _toAddressController.dispose();
    super.dispose();
  }

  bool get _isEditMode => widget.schedule != null;
  bool get _isLastStep => _currentStepIndex == _stepTitles.length - 1;

  Future<void> _pickRouteAddress({required bool isFrom}) async {
    final selected = await showAddressPickChoice(context);
    if (selected == null) return;
    setState(() {
      if (isFrom) {
        _routeFrom = selected;
        _fromAddressController.text =
            NannyMapUtils.simplifyAddress(selected.formattedAddress);
      } else {
        _routeTo = selected;
        _toAddressController.text =
            NannyMapUtils.simplifyAddress(selected.formattedAddress);
      }
    });
  }

  Future<double?> _estimateDraftRouteAmount({
    required dynamic fromLocation,
    required dynamic toLocation,
    required String fromAddress,
    required String toAddress,
  }) async {
    final tariffId = vm.editor.tariff.id;
    if (tariffId == null) {
      return null;
    }
    final addresses = <Map<String, dynamic>>[
      DriveAddress(
        fromAddress: AddressData(address: fromAddress, location: fromLocation),
        toAddress: AddressData(address: toAddress, location: toLocation),
      ).toJson(),
      if (_draftRoundTrip)
        DriveAddress(
          fromAddress: AddressData(address: toAddress, location: toLocation),
          toAddress: AddressData(address: fromAddress, location: fromLocation),
        ).toJson(),
    ];
    final estimate = await NannyOrdersApi.estimateScheduleRoadPrice(
      idTariff: tariffId,
      addresses: addresses,
    );
    if (!estimate.success) {
      return null;
    }
    return estimate.response;
  }

  Future<void> _saveDraftRoute() async {
    if (vm.selectedWeekday.isEmpty) return;
    final fromLocation = _routeFrom?.geometry?.location;
    final toLocation = _routeTo?.geometry?.location;
    if (fromLocation == null || toLocation == null) return;

    final fromAddress = NannyMapUtils.simplifyAddress(_routeFrom!.formattedAddress);
    final toAddress = NannyMapUtils.simplifyAddress(_routeTo!.formattedAddress);
    final title = _routeTitleController.text.trim().isEmpty
        ? '$fromAddress -> $toAddress'
        : _routeTitleController.text.trim();
    final firstDay = vm.sortedSelectedWeekdays.first;
    final estimatedAmount = await _estimateDraftRouteAmount(
      fromLocation: fromLocation,
      toLocation: toLocation,
      fromAddress: fromAddress,
      toAddress: toAddress,
    );

    final route = Road(
      weekDay: firstDay,
      startTime: vm.timeForWeekday(firstDay),
      endTime: vm.timeForWeekday(firstDay),
      addresses: [
        DriveAddress(
          fromAddress: AddressData(address: fromAddress, location: fromLocation),
          toAddress: AddressData(address: toAddress, location: toLocation),
        ),
        if (_draftRoundTrip)
          DriveAddress(
            fromAddress: AddressData(address: toAddress, location: toLocation),
            toAddress: AddressData(address: fromAddress, location: fromLocation),
          ),
      ],
      title: title,
      alias: null,
      typeDrive: [_draftRoundTrip ? DriveType.roundTrip : DriveType.oneWay],
      amount: estimatedAmount,
      children: vm.selectedChildrenIds,
    );

    vm.saveRoute(
      route: route,
      weekday: firstDay,
      targetWeekdays: vm.sortedSelectedWeekdays,
      childIds: vm.selectedChildrenIds,
      updatingRoad: vm.editor.roads.firstOrNull,
    );
  }

  List<String> _stepIssuesFor(int stepIndex) {
    switch (stepIndex) {
      case 0:
        return vm.hasContractTitle
            ? const <String>[]
            : const <String>['Введите название контракта.'];
      case 1:
        final issues = <String>[];
        if (vm.selectedWeekday.isEmpty) {
          issues.add('Выберите дни поездок.');
        }
        if (vm.weekdayTripTimes.length < vm.selectedWeekday.length) {
          issues.add('Укажите время поездки для каждого выбранного дня.');
        }
        return issues;
      case 2:
        final issues = <String>[];
        if (vm.editor.roads.isEmpty) {
          issues.add('Добавьте хотя бы один маршрут.');
        }
        if (vm.tripsPerMonth > 0 && vm.tripsPerMonth < 4) {
          issues.add('Для контракта нужно минимум 4 поездки в месяц.');
        }
        return issues;
      case 3:
        final issues = <String>[];
        if (vm.selectedChildrenIds.isEmpty) {
          issues.add('Выберите хотя бы одного ребёнка.');
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
        return issues;
      case 4:
        return const <String>[];
      case 5:
        return vm.readinessIssues;
      default:
        return const <String>[];
    }
  }

  Future<void> _continueFlow() async {
    if (_currentStepIndex == 2) {
      await _saveDraftRoute();
    }
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
                Text(
                  'Тип контракта',
                  style: AutonannyTypography.labelL(
                    color: context.autonannyColors.textTertiary,
                  ),
                ),
                const SizedBox(height: AutonannySpacing.sm),
                _ContractTypeCard(
                  title: 'Недельный',
                  subtitle: 'На 1 неделю',
                  isSelected: vm.editor.type == GraphType.week,
                  icon: Icons.view_week_outlined,
                  onTap: () => vm.graphTypeChanged(GraphType.week),
                ),
                const SizedBox(height: AutonannySpacing.sm),
                _ContractTypeCard(
                  title: 'Месячный',
                  subtitle: 'На 1 месяц, ~4 недели',
                  isSelected: vm.editor.type == GraphType.month,
                  icon: Icons.calendar_month_outlined,
                  onTap: () => vm.graphTypeChanged(GraphType.month),
                ),
                const SizedBox(height: AutonannySpacing.sm),
                _ContractTypeCard(
                  title: 'Полугодовой',
                  subtitle: 'На 6 месяцев',
                  isSelected: vm.editor.type == GraphType.halfYear,
                  icon: Icons.home_outlined,
                  onTap: () => vm.graphTypeChanged(GraphType.halfYear),
                ),
                const SizedBox(height: AutonannySpacing.sm),
                _ContractTypeCard(
                  title: 'Годовой',
                  subtitle: 'На 12 месяцев',
                  isSelected: vm.editor.type == GraphType.year,
                  icon: Icons.access_time_outlined,
                  onTap: () => vm.graphTypeChanged(GraphType.year),
                ),
              ],
            ),
          ),
        ];
      case 1:
        return [
          AutonannySectionContainer(
            title: 'Дни и время',
            subtitle:
                'Сначала задайте режим времени, затем выберите дни поездок.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Одинаковое время для всех дней',
                        style: AutonannyTypography.labelL(
                          color: context.autonannyColors.textPrimary,
                        ),
                      ),
                    ),
                    Switch(
                      value: vm.useSameTimeForAllDays,
                      onChanged: vm.toggleSameTimeForAllDays,
                    ),
                  ],
                ),
                const SizedBox(height: AutonannySpacing.lg),
                if (vm.useSameTimeForAllDays)
                  _TimeFieldCard(
                    label: 'Время для всех дней',
                    value: vm.sharedTripTime.format(context),
                    onTap: () => _pickTime(
                      initial: vm.sharedTripTime,
                      onSelected: vm.setSharedTripTime,
                    ),
                  ),
                if (vm.useSameTimeForAllDays)
                  const SizedBox(height: AutonannySpacing.xl),
                Text(
                  'Дни недели',
                  style: AutonannyTypography.labelL(
                    color: context.autonannyColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AutonannySpacing.sm),
                _WeekdayPillsSelector(
                  selectedWeekday: vm.selectedWeekday,
                  onChanged: vm.weekdaySelected,
                ),
                if (vm.selectedWeekday.isNotEmpty) ...[
                  const SizedBox(height: AutonannySpacing.sm),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AutonannySpacing.md,
                      vertical: AutonannySpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: context.autonannyColors.surfaceSecondary,
                      borderRadius: AutonannyRadii.brLg,
                    ),
                    child: Text(
                      '${vm.selectedWeekday.length} ${_daysWord(vm.selectedWeekday.length)} × 4 нед = ${vm.selectedWeekday.length * 4} поездок/мес',
                      style: AutonannyTypography.bodyS(
                        color: context.autonannyColors.actionPrimary,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AutonannySpacing.lg),
                _WeekdayToggleList(
                  selectedWeekdays: vm.selectedWeekday,
                  showIndividualTimes: !vm.useSameTimeForAllDays,
                  timeLabelBuilder: (weekday) => vm.timeForWeekday(weekday).format(context),
                  onPickTime: (weekday) => _pickTime(
                    initial: vm.timeForWeekday(weekday),
                    onSelected: (time) => vm.setTripTimeForWeekday(weekday, time),
                  ),
                  onToggle: (weekday, enabled) {
                    final currentlySelected =
                        vm.selectedWeekday.contains(weekday);
                    if (currentlySelected != enabled) {
                      vm.weekdaySelected(weekday);
                    }
                  },
                ),
              ],
            ),
          ),
        ];
      case 2:
        return [
          if (vm.selectedWeekday.isEmpty)
            const AutonannySectionContainer(
              title: 'Маршруты',
              child: AutonannyInlineBanner(
                title: 'Выберите дни контракта',
                message:
                    'Сначала выберите дни на предыдущем шаге, затем добавьте маршрут.',
                tone: AutonannyBannerTone.info,
                leading: AutonannyIcon(AutonannyIcons.calendar),
              ),
            )
          else ...[
            AutonannySectionContainer(
              child: _RouteNameBlock(controller: _routeTitleController),
            ),
            AutonannySectionContainer(
              child: _RouteTypeSelector(
                isRoundTrip: _draftRoundTrip,
                onChanged: (value) {
                  setState(() {
                    _draftRoundTrip = value;
                  });
                },
              ),
            ),
            AutonannySectionContainer(
              child: _RouteAddressesBlock(
                fromController: _fromAddressController,
                toController: _toAddressController,
                onPickFrom: () => _pickRouteAddress(isFrom: true),
                onPickTo: () => _pickRouteAddress(isFrom: false),
              ),
            ),
          ],
        ];
      case 3:
        return [
          _ChildrenSection(vm: vm),
        ];
      case 4:
        return [
          AutonannySectionContainer(
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
      case 5:
      default:
        return [
          _ContractDraftSummarySection(vm: vm),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return AutonannyAppScaffold(
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
                      ? (vm.canSubmit && !vm.isSubmitting
                          ? () async => vm.confirm()
                          : null)
                      : _continueFlow,
                  isLoading: _isLastStep && vm.isSubmitting,
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
              key: ValueKey<int>(_currentStepIndex),
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(
                AutonannySpacing.xl,
                AutonannySpacing.md,
                AutonannySpacing.xl,
                120,
              ),
              children: [
                _ContractStepHeader(
                  currentStepIndex: _currentStepIndex,
                  titles: _stepTitles,
                  descriptions: _stepDescriptions,
                  isEditMode: _isEditMode,
                  onBackPressed: () => Navigator.of(context).maybePop(),
                ),
                if (stepIssues.isNotEmpty &&
                    !_isLastStep &&
                    _currentStepIndex != 0 &&
                    _currentStepIndex != 1 &&
                    _currentStepIndex != 2 &&
                    _currentStepIndex != 3) ...[
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

  Future<void> _pickTime({
    required TimeOfDay initial,
    required ValueChanged<TimeOfDay> onSelected,
  }) async {
    final selected = await showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _MinuteWheelPickerSheet(initial: initial),
    );
    if (selected == null) {
      return;
    }
    onSelected(selected);
  }

  String _daysWord(int count) {
    if (count % 10 == 1 && count % 100 != 11) return 'день';
    if ([2, 3, 4].contains(count % 10) && ![12, 13, 14].contains(count % 100)) {
      return 'дня';
    }
    return 'дней';
  }
}

class _TimeFieldCard extends StatelessWidget {
  const _TimeFieldCard({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AutonannyRadii.brLg,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AutonannySpacing.md),
          decoration: BoxDecoration(
            color: colors.surfaceElevated,
            borderRadius: AutonannyRadii.brLg,
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AutonannyTypography.bodyM(color: colors.textPrimary),
                ),
              ),
              const SizedBox(width: AutonannySpacing.sm),
              Text(
                value,
                style: AutonannyTypography.labelL(color: colors.actionPrimary),
              ),
              const SizedBox(width: AutonannySpacing.xs),
              AutonannyIcon(
                AutonannyIcons.chevronRight,
                color: colors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MinuteWheelPickerSheet extends StatefulWidget {
  const _MinuteWheelPickerSheet({required this.initial});

  final TimeOfDay initial;

  @override
  State<_MinuteWheelPickerSheet> createState() => _MinuteWheelPickerSheetState();
}

class _MinuteWheelPickerSheetState extends State<_MinuteWheelPickerSheet> {
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selected = DateTime(
      now.year,
      now.month,
      now.day,
      widget.initial.hour,
      widget.initial.minute,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AutonannyBottomSheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Выберите время',
            style: AutonannyTypography.h3(
              color: context.autonannyColors.textPrimary,
            ),
          ),
          const SizedBox(height: AutonannySpacing.md),
          SizedBox(
            height: 180,
            child: AutonannyTimeWheelPicker(
              initialTime:
                  TimeOfDay(hour: _selected.hour, minute: _selected.minute),
              minuteInterval: 1,
              onChanged: (value) {
                final now = DateTime.now();
                setState(() {
                  _selected = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    value.hour,
                    value.minute,
                  );
                });
              },
            ),
          ),
          const SizedBox(height: AutonannySpacing.md),
          Row(
            children: [
              Expanded(
                child: AutonannyButton(
                  label: 'Отмена',
                  variant: AutonannyButtonVariant.secondary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: AutonannySpacing.sm),
              Expanded(
                child: AutonannyButton(
                  label: 'Готово',
                  onPressed: () => Navigator.of(context).pop(
                    TimeOfDay(hour: _selected.hour, minute: _selected.minute),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekdayPillsSelector extends StatelessWidget {
  const _WeekdayPillsSelector({
    required this.selectedWeekday,
    required this.onChanged,
  });

  final List<NannyWeekday> selectedWeekday;
  final ValueChanged<NannyWeekday> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;
    return Wrap(
      spacing: AutonannySpacing.sm,
      runSpacing: AutonannySpacing.sm,
      children: NannyWeekday.values.map((weekday) {
        final isSelected = selectedWeekday.contains(weekday);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onChanged(weekday),
            borderRadius: AutonannyRadii.brFull,
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? colors.actionPrimary : colors.surfaceElevated,
                borderRadius: AutonannyRadii.brFull,
                border: Border.all(
                  color: isSelected ? colors.actionPrimary : colors.borderSubtle,
                ),
              ),
              child: Text(
                weekday.shortName,
                style: AutonannyTypography.labelM(
                  color: isSelected ? colors.textInverse : colors.textSecondary,
                ),
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _WeekdayToggleList extends StatelessWidget {
  const _WeekdayToggleList({
    required this.selectedWeekdays,
    required this.onToggle,
    required this.showIndividualTimes,
    required this.timeLabelBuilder,
    required this.onPickTime,
  });

  final List<NannyWeekday> selectedWeekdays;
  final void Function(NannyWeekday weekday, bool enabled) onToggle;
  final bool showIndividualTimes;
  final String Function(NannyWeekday weekday) timeLabelBuilder;
  final Future<void> Function(NannyWeekday weekday) onPickTime;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;
    return Column(
      children: NannyWeekday.values.map((weekday) {
        final isSelected = selectedWeekdays.contains(weekday);
        return Container(
          margin: const EdgeInsets.only(bottom: AutonannySpacing.sm),
          padding: const EdgeInsets.symmetric(
            horizontal: AutonannySpacing.md,
            vertical: AutonannySpacing.sm,
          ),
          decoration: BoxDecoration(
            color: colors.surfaceElevated,
            borderRadius: AutonannyRadii.brLg,
            border: Border.all(
              color: isSelected ? colors.actionPrimary : colors.borderSubtle,
              width: isSelected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  weekday.fullName,
                  style: AutonannyTypography.bodyM(
                    color: colors.textPrimary,
                  ),
                ),
              ),
              if (showIndividualTimes && isSelected) ...[
                GestureDetector(
                  onTap: () => onPickTime(weekday),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AutonannySpacing.sm,
                      vertical: AutonannySpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceSecondary,
                      borderRadius: AutonannyRadii.brMd,
                      border: Border.all(color: colors.borderSubtle),
                    ),
                    child: Text(
                      timeLabelBuilder(weekday),
                      style: AutonannyTypography.labelM(
                        color: colors.actionPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AutonannySpacing.sm),
              ],
              Switch(
                value: isSelected,
                onChanged: (value) => onToggle(weekday, value),
              ),
            ],
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _UnifiedRoutePanel extends StatelessWidget {
  const _UnifiedRoutePanel({
    required this.road,
    required this.roadsCount,
    required this.onEdit,
    required this.onDelete,
  });

  final Road road;
  final int roadsCount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _RoutePreviewCard(
          road: road,
          onEdit: onEdit,
          onDelete: onDelete,
        ),
        const SizedBox(height: AutonannySpacing.md),
        _TripsCounterBanner(roadsCount: roadsCount),
      ],
    );
  }
}

class _RouteNameBlock extends StatelessWidget {
  const _RouteNameBlock({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Название маршрута',
          style: AutonannyTypography.labelL(
            color: context.autonannyColors.textPrimary,
          ),
        ),
        const SizedBox(height: AutonannySpacing.sm),
        AutonannyTextField(
          controller: controller,
          hintText: 'Например, Дом -> Школа',
        ),
      ],
    );
  }
}

class _RouteTypeSelector extends StatelessWidget {
  const _RouteTypeSelector({
    required this.isRoundTrip,
    required this.onChanged,
  });

  final bool isRoundTrip;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Тип маршрута',
          style: AutonannyTypography.labelL(
            color: context.autonannyColors.textPrimary,
          ),
        ),
        const SizedBox(height: AutonannySpacing.sm),
        _RouteTypeCard(
          title: 'В один конец',
          subtitle: 'Только туда',
          selected: !isRoundTrip,
          onTap: () => onChanged(false),
        ),
        const SizedBox(height: AutonannySpacing.sm),
        _RouteTypeCard(
          title: 'Туда-обратно',
          subtitle: 'Забрать и привезти домой',
          selected: isRoundTrip,
          onTap: () => onChanged(true),
        ),
      ],
    );
  }
}

class _RouteAddressesBlock extends StatelessWidget {
  const _RouteAddressesBlock({
    required this.fromController,
    required this.toController,
    required this.onPickFrom,
    required this.onPickTo,
  });

  final TextEditingController fromController;
  final TextEditingController toController;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Адреса',
          style: AutonannyTypography.labelL(
            color: context.autonannyColors.textPrimary,
          ),
        ),
        const SizedBox(height: AutonannySpacing.sm),
        GestureDetector(
          onTap: onPickFrom,
          child: AbsorbPointer(
            child: AutonannyTextField(
              controller: fromController,
              labelText: 'Откуда (адрес)',
              hintText: 'Выберите адрес',
              suffix: const Icon(Icons.location_on_outlined),
            ),
          ),
        ),
        const SizedBox(height: AutonannySpacing.md),
        GestureDetector(
          onTap: onPickTo,
          child: AbsorbPointer(
            child: AutonannyTextField(
              controller: toController,
              labelText: 'Куда (адрес)',
              hintText: 'Выберите адрес',
              suffix: const Icon(Icons.location_on_outlined),
            ),
          ),
        ),
      ],
    );
  }
}

class _RouteTypeCard extends StatelessWidget {
  const _RouteTypeCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AutonannyRadii.brLg,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AutonannySpacing.md),
          decoration: BoxDecoration(
            color: colors.surfaceElevated,
            borderRadius: AutonannyRadii.brLg,
            border: Border.all(
              color: selected ? colors.actionPrimary : colors.borderSubtle,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AutonannyTypography.labelL(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AutonannySpacing.xxs),
                    Text(
                      subtitle,
                      style: AutonannyTypography.bodyS(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? colors.actionPrimary : colors.borderSubtle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteInlineEditor extends StatelessWidget {
  const _RouteInlineEditor({
    required this.titleController,
    required this.fromController,
    required this.toController,
    required this.estimate,
    required this.isEstimating,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onSave,
  });

  final TextEditingController titleController;
  final TextEditingController fromController;
  final TextEditingController toController;
  final double? estimate;
  final bool isEstimating;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  final VoidCallback onSave;

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
          AutonannyTextField(
            controller: titleController,
            labelText: 'Название маршрута',
            hintText: 'Например, Дом -> Школа',
          ),
          const SizedBox(height: AutonannySpacing.md),
          GestureDetector(
            onTap: onPickFrom,
            child: AbsorbPointer(
              child: AutonannyTextField(
                controller: fromController,
                labelText: 'Откуда (адрес)',
                hintText: 'Выберите адрес',
                suffix: const Icon(Icons.location_on_outlined),
              ),
            ),
          ),
          const SizedBox(height: AutonannySpacing.md),
          GestureDetector(
            onTap: onPickTo,
            child: AbsorbPointer(
              child: AutonannyTextField(
                controller: toController,
                labelText: 'Куда (адрес)',
                hintText: 'Выберите адрес',
                suffix: const Icon(Icons.location_on_outlined),
              ),
            ),
          ),
          const SizedBox(height: AutonannySpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AutonannySpacing.md,
              vertical: AutonannySpacing.sm,
            ),
            decoration: BoxDecoration(
              color: colors.statusSuccess.withValues(alpha: 0.12),
              borderRadius: AutonannyRadii.brMd,
              border: Border.all(
                color: colors.statusSuccess.withValues(alpha: 0.28),
              ),
            ),
            child: Text(
              isEstimating
                  ? 'Считаем предварительную стоимость...'
                  : (estimate == null
                      ? 'Предварительная стоимость появится после выбора адресов.'
                      : 'Предварительная стоимость маршрута: ${estimate!.toStringAsFixed(0)} ₽'),
              style: AutonannyTypography.bodyM(
                color: colors.statusSuccess,
              ),
            ),
          ),
          const SizedBox(height: AutonannySpacing.md),
          SizedBox(
            width: double.infinity,
            child: AutonannyButton(
              label: 'Сохранить маршрут',
              onPressed: onSave,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutePreviewCard extends StatelessWidget {
  const _RoutePreviewCard({
    required this.road,
    required this.onEdit,
    required this.onDelete,
  });

  final Road road;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;
    final fromAddress = road.addresses.isNotEmpty
        ? road.addresses.first.fromAddress.address
        : 'Не указан адрес отправления';
    final toAddress = road.addresses.isNotEmpty
        ? road.addresses.last.toAddress.address
        : 'Не указан адрес прибытия';
    final tripType = road.typeDrive.contains(DriveType.roundTrip)
        ? 'Туда-обратно'
        : 'В один конец';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Адреса',
          style: AutonannyTypography.labelL(
            color: colors.textTertiary,
          ),
        ),
        const SizedBox(height: AutonannySpacing.sm),
        Container(
          padding: const EdgeInsets.all(AutonannySpacing.md),
          decoration: BoxDecoration(
            color: colors.surfaceElevated,
            borderRadius: AutonannyRadii.brLg,
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (road.title.trim().isNotEmpty) ...[
                Text(
                  road.title.trim(),
                  style: AutonannyTypography.labelL(color: colors.textPrimary),
                ),
                const SizedBox(height: AutonannySpacing.xs),
              ],
              Text(
                tripType,
                style: AutonannyTypography.bodyS(color: colors.textSecondary),
              ),
              const SizedBox(height: AutonannySpacing.xs),
              Text(
                'Прибытие: ${road.startTime.formatTime()}',
                style: AutonannyTypography.bodyS(color: colors.textSecondary),
              ),
              const SizedBox(height: AutonannySpacing.md),
              _RouteAddressLine(
                label: 'Откуда',
                value: fromAddress,
                color: colors.actionPrimary,
                showConnector: true,
              ),
              _RouteAddressLine(
                label: 'Куда',
                value: toAddress,
                color: colors.statusDanger,
              ),
            ],
          ),
        ),
        const SizedBox(height: AutonannySpacing.md),
        if (_recentAddresses(road).isNotEmpty) ...[
          Text(
            'Недавние адреса',
            style: AutonannyTypography.labelL(
              color: colors.textTertiary,
            ),
          ),
          const SizedBox(height: AutonannySpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AutonannySpacing.md),
            decoration: BoxDecoration(
              color: colors.surfaceElevated,
              borderRadius: AutonannyRadii.brLg,
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _recentAddresses(road)
                  .map(
                    (address) => Padding(
                      padding: const EdgeInsets.only(bottom: AutonannySpacing.sm),
                      child: Text(
                        address,
                        style: AutonannyTypography.bodyM(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          const SizedBox(height: AutonannySpacing.md),
        ],
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
    );
  }

  List<String> _recentAddresses(Road road) {
    final items = <String>{};
    for (final item in road.addresses) {
      items.add(item.fromAddress.address);
      items.add(item.toAddress.address);
    }
    return items.where((e) => e.trim().isNotEmpty).take(2).toList();
  }
}

class _ContractTypeCard extends StatelessWidget {
  const _ContractTypeCard({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool isSelected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AutonannyRadii.brLg,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AutonannySpacing.md),
          decoration: BoxDecoration(
            color: colors.surfaceElevated,
            borderRadius: AutonannyRadii.brLg,
            border: Border.all(
              color: isSelected ? colors.actionPrimary : colors.borderSubtle,
              width: isSelected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colors.surfaceSecondary,
                  borderRadius: AutonannyRadii.brLg,
                ),
                child: Icon(icon, color: colors.actionPrimary),
              ),
              const SizedBox(width: AutonannySpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AutonannyTypography.h3(color: colors.textPrimary),
                    ),
                    const SizedBox(height: AutonannySpacing.xxs),
                    Text(
                      subtitle,
                      style: AutonannyTypography.bodyS(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected ? colors.actionPrimary : colors.borderSubtle,
              ),
            ],
          ),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            day.fullName,
            style: AutonannyTypography.labelL(
              color: context.autonannyColors.textPrimary,
            ),
          ),
          const SizedBox(height: AutonannySpacing.xs),
          Text(
            'Добавляйте маршруты для выбранного дня. Привязку детей можно настроить на следующем шаге.',
            style: AutonannyTypography.bodyS(
              color: context.autonannyColors.textSecondary,
            ),
          ),
          const SizedBox(height: AutonannySpacing.md),
          AutonannyButton(
            label: 'Добавить маршрут',
            size: AutonannyButtonSize.medium,
            variant: AutonannyButtonVariant.secondary,
            expand: false,
            leading: const AutonannyIcon(AutonannyIcons.add),
            onPressed: onAddRoute,
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

class _ContractStepHeader extends StatelessWidget {
  const _ContractStepHeader({
    required this.currentStepIndex,
    required this.titles,
    required this.descriptions,
    required this.isEditMode,
    required this.onBackPressed,
  });

  final int currentStepIndex;
  final List<String> titles;
  final List<String> descriptions;
  final bool isEditMode;
  final VoidCallback onBackPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;

    return Container(
      padding: const EdgeInsets.all(AutonannySpacing.xl),
      decoration: const BoxDecoration(
        gradient: AutonannyGradients.hero,
        borderRadius: AutonannyRadii.brLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AutonannyIconButton(
                icon: const AutonannyIcon(
                  AutonannyIcons.arrowLeft,
                  color: Colors.white,
                ),
                variant: AutonannyIconButtonVariant.ghost,
                onPressed: onBackPressed,
              ),
              const SizedBox(width: AutonannySpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titles[currentStepIndex],
                      style: AutonannyTypography.h2(
                        color: colors.textInverse,
                      ),
                    ),
                    const SizedBox(height: AutonannySpacing.xs),
                    Text(
                      isEditMode
                          ? 'Редактирование контракта'
                          : 'Новый контракт',
                      style: AutonannyTypography.caption(
                        color: colors.textInverse.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AutonannySpacing.md,
                  vertical: AutonannySpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: colors.textInverse.withValues(alpha: 0.14),
                  borderRadius: AutonannyRadii.brFull,
                  border: Border.all(
                    color: colors.textInverse.withValues(alpha: 0.18),
                  ),
                ),
                child: Text(
                  '${currentStepIndex + 1}/${titles.length}',
                  style: AutonannyTypography.labelM(
                    color: colors.textInverse,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AutonannySpacing.lg),
          Row(
            children: List.generate(titles.length, (index) {
              final isActive = index == currentStepIndex;
              final isCompleted = index < currentStepIndex;

              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: index == titles.length - 1 ? 0 : AutonannySpacing.xs,
                  ),
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive || isCompleted
                        ? colors.textInverse
                        : colors.textInverse.withValues(alpha: 0.22),
                    borderRadius: AutonannyRadii.brFull,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: AutonannySpacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AutonannySpacing.lg),
            decoration: BoxDecoration(
              color: colors.textInverse.withValues(alpha: 0.12),
              borderRadius: AutonannyRadii.brLg,
              border: Border.all(
                color: colors.textInverse.withValues(alpha: 0.16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Шаг ${currentStepIndex + 1}',
                  style: AutonannyTypography.caption(
                    color: colors.textInverse.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: AutonannySpacing.xs),
                Text(
                  descriptions[currentStepIndex],
                  style: AutonannyTypography.bodyS(
                    color: colors.textInverse.withValues(alpha: 0.88),
                  ),
                ),
              ],
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
    final maxSelectedReached = vm.selectedChildrenIds.length >= 4;
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
              children: [
                ...vm.children.map(
                  (child) {
                    final isSelected = child.id != null &&
                        vm.selectedChildrenIds.contains(child.id);
                    final isDisabled = !isSelected && maxSelectedReached;
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: AutonannySpacing.sm),
                      child: _ChildSelectionTile(
                        child: child,
                        isSelected: isSelected,
                        isDisabled: isDisabled,
                        onTap: child.id == null || isDisabled
                            ? null
                            : () => vm.toggleChildSelection(child.id!),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AutonannySpacing.sm),
                _AddChildButton(onTap: vm.addChildProfile),
              ],
            ),
    );
  }
}

class _ChildSelectionTile extends StatelessWidget {
  const _ChildSelectionTile({
    required this.child,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  final Child child;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;
    final imageUrl = NannyConsts.buildFileUrl(child.photoPath);
    final ageLabel = child.birthday == null
        ? null
        : 'Возраст: ${DateTime.now().year - child.birthday!.year} лет';

    final borderColor = isSelected
        ? colors.actionPrimary
        : (isDisabled ? colors.borderSubtle.withValues(alpha: 0.5) : colors.borderSubtle);
    return Opacity(
      opacity: isDisabled ? 0.55 : 1,
      child: Material(
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
              color: borderColor,
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
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? colors.actionPrimary : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? colors.actionPrimary : colors.borderSubtle,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ],
          ),
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

class _AddChildButton extends StatelessWidget {
  const _AddChildButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AutonannyRadii.brLg,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AutonannySpacing.md),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: AutonannyRadii.brLg,
            border: Border.all(
              color: colors.borderSubtle,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.surfaceSecondary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(width: AutonannySpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Добавить ребёнка',
                      style: AutonannyTypography.labelL(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AutonannySpacing.xxs),
                    Text(
                      'Создать новый профиль',
                      style: AutonannyTypography.bodyS(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                      'Прибытие к первой точке: ${road.startTime.formatTime()}',
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
          _RouteAddressLine(
            label: 'Откуда',
            value: fromAddress,
            color: colors.actionPrimary,
            showConnector: true,
          ),
          _RouteAddressLine(
            label: 'Куда',
            value: toAddress,
            color: colors.statusDanger,
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

class _RouteAddressLine extends StatelessWidget {
  const _RouteAddressLine({
    required this.label,
    required this.value,
    required this.color,
    this.showConnector = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 18,
          child: Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              if (showConnector)
                Container(
                  width: 2,
                  height: 22,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: context.autonannyColors.borderSubtle,
                    borderRadius: AutonannyRadii.brFull,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: AutonannySpacing.md),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AutonannySpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AutonannyTypography.caption(
                    color: context.autonannyColors.textTertiary,
                  ),
                ),
                const SizedBox(height: AutonannySpacing.xxs),
                Text(
                  value,
                  style: AutonannyTypography.bodyM(
                    color: context.autonannyColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
    final colors = context.autonannyColors;
    if (vm.tariffs.isEmpty) {
      return const AutonannyInlineBanner(
        title: 'Тарифы недоступны',
        message: 'Повторите попытку позже.',
        tone: AutonannyBannerTone.warning,
        leading: AutonannyIcon(AutonannyIcons.warning),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Тариф',
          style: AutonannyTypography.labelL(color: colors.textPrimary),
        ),
        const SizedBox(height: AutonannySpacing.sm),
        ...vm.tariffs.map((tariff) {
          final isSelected = vm.editor.tariff.id == tariff.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: AutonannySpacing.sm),
            child: _ChoiceTile(
              title: tariff.title ?? 'Неизвестный тариф',
              subtitle: 'Выберите подходящий тариф',
              isSelected: isSelected,
              onTap: () => vm.tariffSelected(tariff),
              trailingMode: _ChoiceTileTrailingMode.radio,
            ),
          );
        }),
      ],
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
    final colors = context.autonannyColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Дополнительные услуги',
          style: AutonannyTypography.labelL(color: colors.textPrimary),
        ),
        const SizedBox(height: AutonannySpacing.sm),
        ...widget.vm.params.map((param) {
          final isSelected = widget.vm.isParamSelected(param);
          final title = param.title ?? 'Неизвестная услуга';
          final subtitle = (param.amount != null && param.amount! > 0)
              ? '${param.amount!.round()} ₽'
              : 'Без доплаты';
          return Padding(
            padding: const EdgeInsets.only(bottom: AutonannySpacing.sm),
            child: _ChoiceTile(
              title: title,
              subtitle: subtitle,
              isSelected: isSelected,
              onTap: () {
                if (isSelected) {
                  widget.vm.removeParam(param);
                } else {
                  widget.vm.addParam(param);
                }
                setState(() {});
              },
              trailingMode: _ChoiceTileTrailingMode.checkbox,
            ),
          );
        }),
      ],
    );
  }
}

enum _ChoiceTileTrailingMode { radio, checkbox }

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    required this.trailingMode,
  });

  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final _ChoiceTileTrailingMode trailingMode;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;
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
              width: isSelected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colors.surfaceSecondary,
                  borderRadius: AutonannyRadii.brMd,
                ),
                child: Icon(
                  Icons.local_taxi_outlined,
                  color: colors.actionPrimary,
                ),
              ),
              const SizedBox(width: AutonannySpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AutonannyTypography.labelL(color: colors.textPrimary),
                    ),
                    const SizedBox(height: AutonannySpacing.xxs),
                    Text(
                      subtitle,
                      style: AutonannyTypography.bodyS(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AutonannySpacing.sm),
              if (trailingMode == _ChoiceTileTrailingMode.radio)
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: isSelected ? colors.actionPrimary : colors.borderSubtle,
                )
              else
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? colors.actionPrimary : Colors.transparent,
                    border: Border.all(
                      color:
                          isSelected ? colors.actionPrimary : colors.borderSubtle,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
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

class _ContractDraftSummarySection extends StatelessWidget {
  const _ContractDraftSummarySection({
    required this.vm,
  });

  final GraphCreateVM vm;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;
    final selectedChildren = vm.selectedContractChildren;
    final selectedChildLabel = selectedChildren.isEmpty
        ? '—'
        : selectedChildren.map((child) => child.fullName).join(', ');
    final daysLabel = vm.sortedSelectedWeekdays.map((day) => day.shortName).join(', ');
    final firstRoute = vm.editor.roads.firstOrNull;
    final firstFrom = firstRoute?.addresses.firstOrNull?.fromAddress.address ?? '—';
    final firstTo = firstRoute?.addresses.lastOrNull?.toAddress.address ?? '—';
    final routeLabel = firstRoute == null ? '—' : '$firstFrom -> $firstTo';
    final timeValues = vm.weekdayTripTimes.values.toSet();
    final timeLabel = timeValues.isEmpty
        ? '—'
        : (timeValues.length == 1
            ? timeValues.first.format(context)
            : '${timeValues.first.format(context)} и др.');
    final monthlyAmount = vm.estimatedMonthlyAmount;
    final weeklyReserve = vm.estimatedWeeklyAmount;
    final contractType = switch (vm.editor.type) {
      GraphType.week => 'Недельный',
      GraphType.month => 'Месячный',
      GraphType.halfYear => 'Полугодовой',
      GraphType.year => 'Годовой',
    };

    return AutonannySectionContainer(
      title: 'Подтверждение',
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
                  'КОНТРАКТ · ${contractType.toUpperCase()}',
                  style: AutonannyTypography.labelM(
                    color: colors.actionPrimary,
                  ),
                ),
                const SizedBox(height: AutonannySpacing.md),
                _ConfirmRow(label: 'Дни', value: daysLabel.isEmpty ? '—' : daysLabel),
                const SizedBox(height: AutonannySpacing.sm),
                _ConfirmRow(label: 'Время', value: timeLabel),
                const SizedBox(height: AutonannySpacing.sm),
                _ConfirmRow(label: 'Маршрут', value: routeLabel),
                const SizedBox(height: AutonannySpacing.sm),
                _ConfirmRow(label: 'Ребёнок', value: selectedChildLabel),
                const SizedBox(height: AutonannySpacing.sm),
                _ConfirmRow(
                  label: 'Доп. услуги',
                  value: vm.selectedServicesLabel,
                ),
                const SizedBox(height: AutonannySpacing.md),
                Container(
                  height: 1,
                  color: colors.borderSubtle,
                ),
                const SizedBox(height: AutonannySpacing.md),
                Row(
                  children: [
                    Text(
                      'Итого в месяц',
                      style: AutonannyTypography.labelL(
                        color: colors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatAmount(monthlyAmount),
                      style: AutonannyTypography.h2(
                        color: colors.actionPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AutonannySpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AutonannySpacing.md),
            decoration: BoxDecoration(
              color: colors.statusSuccess.withValues(alpha: 0.1),
              borderRadius: AutonannyRadii.brLg,
              border: Border.all(color: colors.statusSuccess.withValues(alpha: 0.35)),
            ),
            child: Text(
              'После публикации заказ увидят все подтверждённые водители. '
              'Водитель сам откликнется - вы выберете из списка кандидатов.',
              style: AutonannyTypography.bodyM(
                color: colors.statusSuccess,
              ),
            ),
          ),
          const SizedBox(height: AutonannySpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AutonannySpacing.md),
            decoration: BoxDecoration(
              color: colors.statusWarning.withValues(alpha: 0.12),
              borderRadius: AutonannyRadii.brLg,
              border: Border.all(color: colors.statusWarning.withValues(alpha: 0.35)),
            ),
            child: Text(
              weeklyReserve == null
                  ? 'Сумма для недельного резервирования появится после расчёта маршрутов.'
                  : 'Сразу зарезервируем ${weeklyReserve.round()} ₽ с баланса на первую неделю.',
              style: AutonannyTypography.bodyM(
                color: colors.statusWarning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double? value) {
    if (value == null || value <= 0) {
      return '—';
    }
    return '${value.round()} ₽';
  }
}

class _ConfirmRow extends StatelessWidget {
  const _ConfirmRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: AutonannyTypography.bodyM(
              color: colors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: AutonannySpacing.sm),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AutonannyTypography.labelL(
              color: colors.textPrimary,
            ),
          ),
        ),
      ],
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
