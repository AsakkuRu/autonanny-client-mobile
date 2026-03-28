import 'package:flutter/material.dart';
import 'package:nanny_client/ui_sdk/client_ui_sdk.dart';
import 'package:nanny_client/view_models/map/drive_order_vm.dart';
import 'package:nanny_client/views/pages/child_edit.dart';
import 'package:nanny_core/api/google_map_api.dart';
import 'package:nanny_core/map_services/nanny_map_utils.dart';
import 'package:nanny_core/models/from_api/drive_and_map/address_data.dart';
import 'package:nanny_core/models/from_api/drive_and_map/geocoding_data.dart';
import 'package:nanny_core/nanny_search_delegate.dart';

class DriveOrderView extends StatefulWidget {
  final ScrollController? controller;
  final GeocodeResult initAddress;

  const DriveOrderView({
    super.key,
    required this.controller,
    required this.initAddress,
  });

  @override
  State<DriveOrderView> createState() => _DriveOrderViewState();
}

class _DriveOrderViewState extends State<DriveOrderView> {
  late DriveOrderVM vm;

  @override
  void initState() {
    super.initState();
    vm = DriveOrderVM(
      context: context,
      update: setState,
      initAddress: widget.initAddress,
    );
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  Future<void> _openAddChild() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChildEditView()),
    );
    await vm.reloadChildren();
  }

  Future<GeocodeResult?> _pickAddress() {
    return showSearch<GeocodeResult?>(
      context: context,
      delegate: NannySearchDelegate(
        onSearch: (query) => GoogleMapApi.geocode(address: query),
        onResponse: (response) => response.response?.geocodeResults,
        tileBuilder: (data, close) => ListTile(
          title: Text(NannyMapUtils.buildStreetAddress(data)),
          onTap: close,
        ),
      ),
    );
  }

  Future<void> _addAddress() async {
    final address = await _pickAddress();
    if (!mounted || address == null) return;

    final location = address.geometry?.location;
    if (location == null) return;

    vm.onAdd(
      AddressData(
        address: NannyMapUtils.buildStreetAddress(address),
        location: location,
      ),
    );
  }

  Future<void> _changeAddress(AddressData oldAddress) async {
    final address = await _pickAddress();
    if (!mounted || address == null) return;

    final location = address.geometry?.location;
    if (location == null) return;

    vm.onChange(
      oldAddress,
      AddressData(
        address: NannyMapUtils.buildStreetAddress(address),
        location: location,
      ),
    );
  }

  AddressData? _addressById(String id) {
    final index = int.tryParse(id);
    if (index == null || index < 0 || index >= vm.addresses.length) {
      return null;
    }
    return vm.addresses[index];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;

    return FutureBuilder<bool>(
      future: vm.loadRequest,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: AutonannyLoadingState(label: 'Загружаем параметры поездки'),
          );
        }

        if (snapshot.hasError || snapshot.data != true) {
          return AutonannyErrorState(
            title: 'Не удалось загрузить данные',
            description:
                'Попробуйте ещё раз: мы повторно запросим тарифы, детей и дополнительные услуги.',
            actionLabel: 'Повторить',
            onAction: vm.reloadPage,
          );
        }

        return SingleChildScrollView(
          controller: widget.controller,
          padding: const EdgeInsets.fromLTRB(
            AutonannySpacing.lg,
            AutonannySpacing.lg,
            AutonannySpacing.lg,
            AutonannySpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Куда поедем?',
                style: AutonannyTypography.h1(color: colors.textPrimary),
              ),
              const SizedBox(height: AutonannySpacing.xs),
              Text(
                'Уточните точки на карте, выберите тариф и участников поездки.',
                style: AutonannyTypography.bodyS(color: colors.textSecondary),
              ),
              const SizedBox(height: AutonannySpacing.lg),
              AddressEditor(
                items: vm.addressEditorItems,
                subtitle:
                    'Нажмите на адрес, чтобы изменить его. Удерживайте карточку, чтобы выбрать точку для уточнения на карте.',
                onAddTap: _addAddress,
                onItemTap: (id) {
                  final address = _addressById(id);
                  if (address != null) {
                    _changeAddress(address);
                  }
                },
                onItemLongPress: (id) {
                  final index = int.tryParse(id);
                  if (index != null) {
                    vm.selectAddress(index);
                  }
                },
                onDeleteTap: (id) {
                  final address = _addressById(id);
                  if (address != null) {
                    vm.onDelete(address);
                  }
                },
              ),
              const SizedBox(height: AutonannySpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Тариф',
                    style: AutonannyTypography.h3(color: colors.textPrimary),
                  ),
                  if (vm.distance > 0 && vm.duration > 0)
                    Text(
                      '${vm.distance.toStringAsFixed(1)} км · ${vm.duration.toStringAsFixed(0)} мин',
                      style: AutonannyTypography.caption(
                          color: colors.textTertiary),
                    ),
                ],
              ),
              const SizedBox(height: AutonannySpacing.md),
              if (vm.tariffs.isEmpty)
                const AutonannyInlineBanner(
                  title: 'Тарифы пока недоступны',
                  message:
                      'Как только сервис получит стоимость, варианты появятся здесь.',
                  tone: AutonannyBannerTone.info,
                  leading: AutonannyIcon(AutonannyIcons.car),
                )
              else
                TariffCarousel(
                  options: vm.tariffOptions,
                  onOptionTap: (id) {
                    for (final tariff in vm.tariffs) {
                      if ('${tariff.id}' == id) {
                        vm.selectTariff(tariff);
                        break;
                      }
                    }
                  },
                ),
              const SizedBox(height: AutonannySpacing.xl),
              AdditionalServicesSelector(
                subtitle:
                    'Дополнительные требования будут отправлены вместе с заказом.',
                options: vm.additionalParams
                    .map(
                      (param) => AdditionalServiceOptionData(
                        id: '${param.id ?? param.title}',
                        title: param.title ?? 'Неизвестная услуга',
                        isSelected: vm.isAdditionalParamSelected(param),
                        priceLabel: (param.amount != null && param.amount! > 0)
                            ? '${param.amount!.round()} ₽'
                            : null,
                        caption: param.count == null
                            ? null
                            : 'Количество: ${param.count}',
                      ),
                    )
                    .toList(growable: false),
                onToggle: (id) {
                  for (final param in vm.additionalParams) {
                    if ('${param.id ?? param.title}' == id) {
                      vm.toggleAdditionalParam(param);
                      break;
                    }
                  }
                },
              ),
              const SizedBox(height: AutonannySpacing.lg),
              const AutonannyInlineBanner(
                title: 'Нужны регулярные поездки?',
                message:
                    'Для поездок по расписанию используйте раздел «Контракты». Здесь оформляется разовый заказ.',
                tone: AutonannyBannerTone.info,
                leading: AutonannyIcon(AutonannyIcons.calendar),
              ),
              const SizedBox(height: AutonannySpacing.lg),
              AutonannySectionContainer(
                title: 'Кто едет',
                subtitle: 'Выберите детей для этой разовой поездки',
                trailing: AutonannyButton(
                  label: 'Добавить',
                  onPressed: _openAddChild,
                  variant: AutonannyButtonVariant.secondary,
                  size: AutonannyButtonSize.medium,
                  expand: false,
                  leading: const AutonannyIcon(AutonannyIcons.add),
                ),
                child: vm.children.isEmpty
                    ? const AutonannyInlineBanner(
                        title: 'Добавьте детей для поездки',
                        message:
                            'После добавления профиля ребёнка можно будет выбрать участников разовой поездки.',
                        tone: AutonannyBannerTone.warning,
                        leading: AutonannyIcon(AutonannyIcons.child),
                      )
                    : ChildSelector(
                        data: vm.childSelectorData,
                        onChildTap: (id) {
                          for (final child in vm.children) {
                            if ('${child.id}' == id) {
                              vm.toggleChild(child);
                              break;
                            }
                          }
                        },
                      ),
              ),
              const SizedBox(height: AutonannySpacing.xl),
              TripRequestSummary(data: vm.tripRequestSummaryData),
              const SizedBox(height: AutonannySpacing.xl),
              AutonannyButton(
                label: 'Заказать поездку',
                onPressed: vm.validDrive ? vm.searchForDrivers : null,
                leading: const AutonannyIcon(AutonannyIcons.route),
              ),
            ],
          ),
        );
      },
    );
  }
}
