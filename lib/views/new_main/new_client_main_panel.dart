import 'package:flutter/material.dart';
import 'package:nanny_components/widgets/map/full_screen_map_address_picker.dart';
import 'package:nanny_client/views/new_main/new_client_main_vm.dart';
import 'package:nanny_client/views/pages/child_edit.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_components/new_design/new_design.dart';
import 'package:nanny_components/styles/new_design_app.dart';
import 'package:nanny_core/api/google_map_api.dart';
import 'package:nanny_core/models/from_api/drive_and_map/address_data.dart';
import 'package:nanny_core/models/from_api/drive_and_map/geocoding_data.dart';
import 'package:nanny_core/models/from_api/child_short.dart';
import 'package:nanny_core/models/from_api/drive_and_map/drive_tariff.dart';
import 'package:nanny_core/nanny_core.dart';

class NewClientMainPanel extends StatelessWidget {
  final NewClientMainVM vm;

  const NewClientMainPanel({
    super.key,
    required this.vm,
  });

  void _showToast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: NDT.bodyM.copyWith(color: NDT.neutral0)),
        backgroundColor: NDT.neutral900,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: NDT.brMd),
        margin: const EdgeInsets.all(NDT.sp16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureLoader(
      future: vm.loadRequest,
      completeView: (_, ok) {
        if (ok != true) {
          return _ErrorPanel(onRetry: vm.reloadPage);
        }
        return _PanelContent(
          vm: vm,
          showToast: (msg) => _showToast(context, msg),
        );
      },
      errorView: (_, e) =>
          _ErrorPanel(message: e.toString(), onRetry: vm.reloadPage),
    );
  }
}

// ─── Ошибка ──────────────────────────────────────────────────────────────────

class _ErrorPanel extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;

  const _ErrorPanel({this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(NDT.sp24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message ?? 'Не удалось загрузить данные',
            style: NDT.bodyM,
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: NDT.sp16),
            NdPrimaryButton(label: 'Повторить', onTap: onRetry),
          ],
        ],
      ),
    );
  }
}

// ─── Основной контент ─────────────────────────────────────────────────────────

class _PanelContent extends StatelessWidget {
  final NewClientMainVM vm;
  final void Function(String) showToast;

  const _PanelContent({
    required this.vm,
    required this.showToast,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        NDT.sp16,
        NDT.sp4,
        NDT.sp16,
        MediaQuery.of(context).padding.bottom + NDT.sp16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _AddressCard(vm: vm),
          const SizedBox(height: NDT.sp20),
          _TariffBlock(vm: vm),
          const SizedBox(height: NDT.sp20),
          _ChildrenBlock(vm: vm, showToast: showToast),
          const SizedBox(height: NDT.sp24),
          NdPrimaryButton(
            label: 'Найти автоняню',
            trailingIcon: Icons.arrow_forward_rounded,
            isEnabled: vm.canOrder,
            onTap: () => vm.searchForDrivers(),
          ),
        ],
      ),
    );
  }
}

// ─── Карточка адресов ────────────────────────────────────────────────────────

class _AddressCard extends StatelessWidget {
  final NewClientMainVM vm;

  const _AddressCard({required this.vm});

  static const Color _fromDot = Color(0xFF5B4FCF);
  static const Color _toDot   = Color(0xFFEF4444);
  static const Color _viaDot  = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    final addrs = vm.addresses;
    // Всегда показываем минимум 2 ряда: ОТКУДА и КУДА
    final rows = <Widget>[];

    // ОТКУДА
    rows.add(_AddressRow(
      label: 'ОТКУДА',
      text: addrs.isNotEmpty
          ? NannyMapUtils.simplifyAddress(addrs[0].address)
          : 'Определяю адрес…',
      dotColor: _fromDot,
      isActive: vm.selectedAddressIndex == 0,
      isFirst: true,
      isLast: false,
      onTap: () {
        vm.selectAddress(0);
        _pickAddress(context, 0);
      },
      onActivate: () => vm.selectedAddressIndex == 0
          ? vm.clearAddressSelection()
          : vm.selectAddress(0),
      trailing: _PlusButton(onTap: () => _pickWaypoint(context)),
    ));

    // Промежуточные точки (индексы 1..n-2)
    if (addrs.length > 2) {
      for (var i = 1; i < addrs.length - 1; i++) {
        final idx = i;
        rows.add(Divider(height: 1, thickness: 1, color: NDT.neutral100));
        rows.add(_AddressRow(
          label: 'ЧЕРЕЗ ${idx}',
          text: NannyMapUtils.simplifyAddress(addrs[idx].address),
          dotColor: _viaDot,
          isActive: vm.selectedAddressIndex == idx,
          isFirst: false,
          isLast: false,
          onTap: () {
            vm.selectAddress(idx);
            _pickAddress(context, idx);
          },
          onActivate: () => vm.selectedAddressIndex == idx
              ? vm.clearAddressSelection()
              : vm.selectAddress(idx),
          trailing: GestureDetector(
            onTap: () => vm.onDelete(addrs[idx]),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close_rounded, size: 16, color: NDT.neutral400),
            ),
          ),
        ));
      }
    }

    // КУДА
    rows.add(Divider(height: 1, thickness: 1, color: NDT.neutral100));
    final toIndex = addrs.length > 1 ? addrs.length - 1 : -1;
    final toAddr = toIndex >= 0 ? addrs[toIndex] : null;
    rows.add(_AddressRow(
      label: 'КУДА',
      text: toAddr != null
          ? NannyMapUtils.simplifyAddress(toAddr.address)
          : 'Выберите пункт назначения',
      dotColor: toAddr != null ? _toDot : NDT.neutral300,
      isPlaceholder: toAddr == null,
      isActive: toIndex >= 0 && vm.selectedAddressIndex == toIndex,
      isFirst: false,
      isLast: true,
      onTap: () {
        final activeIdx = toIndex >= 0 ? toIndex : addrs.length;
        vm.selectAddress(activeIdx >= 0 ? activeIdx : 1);
        _pickAddress(context, toIndex);
      },
      onActivate: () {
        final activeIdx = toIndex >= 0 ? toIndex : 1;
        vm.selectedAddressIndex == activeIdx
            ? vm.clearAddressSelection()
            : vm.selectAddress(activeIdx);
      },
    ));

    return Container(
      decoration: NDT.cardDecoration,
      child: Column(children: rows),
    );
  }

  Future<void> _pickAddress(BuildContext context, int index) async {
    // BUG-140326-001: диалог с выбором «Поиск» или «Указать на карте»
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(NDT.sp16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NdPrimaryButton(
                label: 'Поиск по адресу',
                onTap: () => Navigator.of(ctx).pop('search'),
              ),
              const SizedBox(height: NDT.sp12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop('map'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: NDT.primary,
                    side: const BorderSide(color: NDT.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: NDT.brXl,
                    ),
                  ),
                  child: const Text('Указать на карте'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (choice == null || !context.mounted) return;
    if (choice == 'map') {
      final result = await Navigator.of(context).push<AddressData>(
        MaterialPageRoute(
          builder: (_) => const FullScreenMapAddressPicker(),
        ),
      );
      if (result != null) {
        if (index >= 0 && index < vm.addresses.length) {
          vm.onChangeAtIndex(index, result);
        } else {
          vm.onAdd(result);
        }
      }
      return;
    }
    final result = await showSearch<GeocodeResult?>(
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
    if (result == null) return;
    final location = result.geometry?.location;
    if (location == null) return;
    final newAddr = AddressData(
      address: NannyMapUtils.buildStreetAddress(result),
      location: location,
    );
    if (index >= 0 && index < vm.addresses.length) {
      vm.onChangeAtIndex(index, newAddr);
    } else {
      vm.onAdd(newAddr);
    }
  }

  Future<void> _pickWaypoint(BuildContext context) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(NDT.sp16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NdPrimaryButton(
                label: 'Поиск по адресу',
                onTap: () => Navigator.of(ctx).pop('search'),
              ),
              const SizedBox(height: NDT.sp12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop('map'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: NDT.primary,
                    side: const BorderSide(color: NDT.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: NDT.brXl,
                    ),
                  ),
                  child: const Text('Указать на карте'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (choice == null || !context.mounted) return;
    if (choice == 'map') {
      final result = await Navigator.of(context).push<AddressData>(
        MaterialPageRoute(
          builder: (_) => const FullScreenMapAddressPicker(),
        ),
      );
      if (result != null) {
        vm.insertWaypoint(result);
      }
      return;
    }
    final result = await showSearch<GeocodeResult?>(
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
    if (result == null) return;
    final location = result.geometry?.location;
    if (location == null) return;
    vm.insertWaypoint(AddressData(
      address: NannyMapUtils.buildStreetAddress(result),
      location: location,
    ));
  }
}

// ─── Один ряд адреса ─────────────────────────────────────────────────────────

class _AddressRow extends StatelessWidget {
  final String label;
  final String text;
  final Color dotColor;
  final bool isPlaceholder;
  final bool isActive;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onActivate;
  final Widget? trailing;

  const _AddressRow({
    required this.label,
    required this.text,
    required this.dotColor,
    required this.isActive,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
    required this.onActivate,
    this.isPlaceholder = false,
    this.trailing,
  });

  BorderRadius get _borderRadius {
    if (isFirst) {
      return const BorderRadius.vertical(top: Radius.circular(NDT.radiusLg));
    }
    if (isLast) {
      return const BorderRadius.vertical(bottom: Radius.circular(NDT.radiusLg));
    }
    return BorderRadius.zero;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: isActive ? NDT.primary100 : Colors.transparent,
        borderRadius: _borderRadius,
      ),
      child: InkWell(
        borderRadius: _borderRadius,
        onTap: onTap,
        onLongPress: onActivate,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: NDT.sp16, vertical: NDT.sp14),
          child: Row(
            children: [
              // Маркер активности (боковая полоска)
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 3,
                height: 32,
                margin: const EdgeInsets.only(right: NDT.sp10),
                decoration: BoxDecoration(
                  color: isActive ? NDT.primary : Colors.transparent,
                  borderRadius: NDT.brFull,
                ),
              ),
              _Dot(color: dotColor),
              const SizedBox(width: NDT.sp12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: NDT.sectionCaption),
                    const SizedBox(height: NDT.sp2),
                    Text(
                      text,
                      style: NDT.bodyM.copyWith(
                        color: isPlaceholder ? NDT.neutral400 : NDT.neutral900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: NDT.sp8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Вспомогательные виджеты ─────────────────────────────────────────────────

class _Dot extends StatelessWidget {
  final Color color;

  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _PlusButton extends StatelessWidget {
  final VoidCallback onTap;

  const _PlusButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: NDT.neutral100,
          borderRadius: NDT.brFull,
        ),
        child: const Icon(Icons.add_rounded, size: 18, color: NDT.neutral500),
      ),
    );
  }
}

// ─── Блок тарифов ────────────────────────────────────────────────────────────

class _TariffBlock extends StatelessWidget {
  final NewClientMainVM vm;

  const _TariffBlock({required this.vm});

  @override
  Widget build(BuildContext context) {
    if (vm.tariffs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('ТАРИФ', style: NDT.sectionCaption),
            if (vm.distance > 0 && vm.duration > 0)
              Text(
                '${vm.distance.toStringAsFixed(1)} км · '
                '${vm.duration.toStringAsFixed(0)} мин',
                style: NDT.bodyS,
              ),
          ],
        ),
        const SizedBox(height: NDT.sp10),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: NDT.sp2),
            itemCount: vm.tariffs.length,
            separatorBuilder: (_, __) => const SizedBox(width: NDT.sp10),
            itemBuilder: (_, i) => _TariffCard(
              tariff: vm.tariffs[i],
              isSelected: vm.selectedTariff == vm.tariffs[i],
              routeCalculated: vm.distance > 0 && vm.duration > 0,
              onTap: () => vm.selectTariff(vm.tariffs[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _TariffCard extends StatelessWidget {
  final DriveTariff tariff;
  final bool isSelected;
  final bool routeCalculated;
  final VoidCallback onTap;

  const _TariffCard({
    required this.tariff,
    required this.isSelected,
    required this.routeCalculated,
    required this.onTap,
  });

  IconData get _icon {
    switch (tariff.id) {
      case 2:
        return Icons.directions_car_filled_rounded;
      case 3:
        return Icons.airport_shuttle_rounded;
      case 4:
        return Icons.local_taxi_rounded;
      default:
        return Icons.directions_car_rounded;
    }
  }

  String get _subtitle {
    final t = (tariff.title ?? '').toLowerCase();
    if (t.contains('комфорт+') || t.contains('комфорт +')) return 'бизнес класс';
    switch (tariff.id) {
      case 1:
        return 'до 4 детей';
      case 2:
        return 'авто 2020+';
      case 3:
        return 'бизнес класс';
      default:
        return 'Фиксированная цена';
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = isSelected ? NDT.neutral0 : NDT.neutral900;
    final subColor = isSelected
        ? NDT.neutral0.withOpacity(0.75)
        : NDT.neutral500;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 160,
        padding: const EdgeInsets.all(NDT.sp12),
        decoration: isSelected
            ? BoxDecoration(
                gradient: NDT.ctaGradient,
                borderRadius: NDT.brLg,
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(91, 79, 207, 0.30),
                    offset: Offset(0, 8),
                    blurRadius: 20,
                  ),
                ],
              )
            : BoxDecoration(
                color: NDT.neutral0,
                borderRadius: NDT.brLg,
                border: Border.all(color: NDT.neutral200),
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tariff.displayTitle,
                  style: NDT.bodyM.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Icon(_icon,
                    size: 18,
                    color: isSelected
                        ? NDT.neutral0.withOpacity(0.9)
                        : NDT.neutral400),
              ],
            ),
            const SizedBox(height: NDT.sp8),
            Text(
              routeCalculated
                  ? '${(tariff.amount ?? 0).toStringAsFixed(0)} ₽'
                  : '${(tariff.amount ?? 0).toStringAsFixed(0)} ₽/км',
              style: NDT.h3.copyWith(color: textColor),
            ),
            const SizedBox(height: NDT.sp2),
            Text(
              _subtitle,
              style: NDT.labelM.copyWith(color: subColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Блок «Кто едет» ─────────────────────────────────────────────────────────

class _ChildrenBlock extends StatelessWidget {
  final NewClientMainVM vm;
  final void Function(String) showToast;

  const _ChildrenBlock({required this.vm, required this.showToast});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('КТО ЕДЕТ', style: NDT.sectionCaption),
        const SizedBox(height: NDT.sp10),
        _ChildrenRow(vm: vm, showToast: showToast),
      ],
    );
  }
}

class _ChildrenRow extends StatelessWidget {
  final NewClientMainVM vm;
  final void Function(String) showToast;

  const _ChildrenRow({required this.vm, required this.showToast});

  Future<void> _openAddChild(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChildEditView()),
    );
    await vm.reloadChildren();
  }

  @override
  Widget build(BuildContext context) {
    final children = vm.children;

    if (children.isEmpty) {
      return Row(
        children: [
          Expanded(
            child: Text(
              'Добавьте детей для поездки',
              style: NDT.bodyS,
            ),
          ),
          const SizedBox(width: NDT.sp8),
          NdAddChildButton(onTap: () => _openAddChild(context)),
        ],
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...children.map((child) => Padding(
                padding: const EdgeInsets.only(right: NDT.sp8),
                child: NdChildChip(
                  name: child.displayName,
                  photoUrl: NannyConsts.buildFileUrl(child.photoPath),
                  isSelected: vm.isChildSelected(child),
                  onTap: () => vm.toggleChild(child, showToast: showToast),
                ),
              )),
          NdAddChildButton(onTap: () => _openAddChild(context)),
        ],
      ),
    );
  }
}
