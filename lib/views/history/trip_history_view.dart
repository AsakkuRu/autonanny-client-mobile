import 'package:autonanny_ui_core/autonanny_ui_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nanny_client/view_models/history/trip_history_vm.dart';
import 'package:nanny_core/models/from_api/trip_history.dart';

class TripHistoryView extends StatefulWidget {
  const TripHistoryView({super.key});

  @override
  State<TripHistoryView> createState() => _TripHistoryViewState();
}

class _TripHistoryViewState extends State<TripHistoryView> {
  late TripHistoryVM vm;

  @override
  void initState() {
    super.initState();
    vm = TripHistoryVM(context: context, update: setState);
    vm.loadPage();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;

    return AutonannyAppScaffold(
      appBar: AutonannyAppBar(
        title: 'История поездок',
        leading: AutonannyIconButton(
          icon: const AutonannyIcon(AutonannyIcons.chevronLeft),
          onPressed: () => Navigator.of(context).maybePop(),
          variant: AutonannyIconButtonVariant.ghost,
          size: 36,
        ),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.filteredTrips.isEmpty
              ? const AutonannyEmptyState(
                  title: 'Нет поездок',
                  description:
                      'Ваши завершённые и отменённые поездки появятся здесь после первых заказов.',
                  icon: AutonannyIcon(AutonannyIcons.calendar, size: 36),
                )
              : RefreshIndicator(
                  onRefresh: vm.refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AutonannySpacing.lg,
                      AutonannySpacing.sm,
                      AutonannySpacing.lg,
                      100,
                    ),
                    itemCount: vm.filteredTrips.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: AutonannySpacing.md,
                        ),
                        child: _TripCard(
                          trip: vm.filteredTrips[index],
                          onTap: () =>
                              vm.showTripDetails(vm.filteredTrips[index]),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: vm.showFilterDialog,
        backgroundColor: colors.actionPrimary,
        foregroundColor: colors.textInverse,
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            const AutonannyIcon(
              AutonannyIcons.list,
              color: Colors.white,
              size: 18,
            ),
            if (vm.hasActiveFilters)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF22C55E),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        label: Text(
          'Фильтры',
          style: AutonannyTypography.labelL(color: colors.textInverse),
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({
    required this.trip,
    required this.onTap,
  });

  final TripHistory trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'ru');
    final isCancelled = trip.isCancelled;

    return AutonannyCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateFormat.format(trip.date),
                style: AutonannyTypography.caption(
                  color: colors.textTertiary,
                ),
              ),
              _StatusChip(
                label: trip.statusText,
                isCompleted: trip.isCompleted,
                isCancelled: isCancelled,
              ),
            ],
          ),
          const SizedBox(height: AutonannySpacing.lg),
          _RoutePreview(
            fromAddress: trip.addressFrom.isNotEmpty
                ? trip.addressFrom
                : 'Адрес отправления не указан',
            toAddress: trip.addressTo.isNotEmpty
                ? trip.addressTo
                : 'Адрес назначения не указан',
          ),
          const SizedBox(height: AutonannySpacing.lg),
          Row(
            children: [
              Expanded(
                child: trip.driverName != null
                    ? _DriverInfo(
                        name: trip.driverName!,
                        photoUrl: trip.driverPhoto,
                        rating: trip.rating,
                      )
                    : Text(
                        'Водитель не указан',
                        style: AutonannyTypography.bodyS(
                          color: colors.textTertiary,
                        ),
                      ),
              ),
              if (trip.price != null) ...[
                const SizedBox(width: AutonannySpacing.md),
                Text(
                  '${trip.price!.toStringAsFixed(0)} ₽',
                  style: AutonannyTypography.h3(color: colors.textPrimary),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.isCompleted,
    required this.isCancelled,
  });

  final String label;
  final bool isCompleted;
  final bool isCancelled;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;
    final background = isCompleted
        ? colors.statusSuccessSurface
        : isCancelled
            ? colors.statusDangerSurface
            : colors.statusInfoSurface;
    final foreground = isCompleted
        ? colors.statusSuccess
        : isCancelled
            ? colors.statusDanger
            : colors.statusInfo;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AutonannySpacing.sm,
        vertical: AutonannySpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AutonannyRadii.brFull,
      ),
      child: Text(
        label,
        style: AutonannyTypography.labelM(color: foreground),
      ),
    );
  }
}

class _RoutePreview extends StatelessWidget {
  const _RoutePreview({
    required this.fromAddress,
    required this.toAddress,
  });

  final String fromAddress;
  final String toAddress;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: colors.actionPrimary,
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 2,
              height: 28,
              margin: const EdgeInsets.symmetric(vertical: 4),
              color: colors.borderSubtle,
            ),
            AutonannyIcon(
              AutonannyIcons.location,
              size: 16,
              color: colors.statusDanger,
            ),
          ],
        ),
        const SizedBox(width: AutonannySpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fromAddress,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AutonannyTypography.bodyM(color: colors.textPrimary),
              ),
              const SizedBox(height: AutonannySpacing.md),
              Text(
                toAddress,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AutonannyTypography.bodyM(color: colors.textPrimary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DriverInfo extends StatelessWidget {
  const _DriverInfo({
    required this.name,
    required this.photoUrl,
    required this.rating,
  });

  final String name;
  final String? photoUrl;
  final int? rating;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;

    return Row(
      children: [
        AutonannyAvatar(
          size: 44,
          image: (photoUrl ?? '').isNotEmpty ? NetworkImage(photoUrl!) : null,
          initials: _initials(name),
        ),
        const SizedBox(width: AutonannySpacing.sm),
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AutonannyTypography.bodyM(color: colors.textPrimary)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (rating != null) ...[
                const SizedBox(width: AutonannySpacing.xs),
                AutonannyIcon(
                  AutonannyIcons.star,
                  size: 14,
                  color: colors.statusWarning,
                ),
                const SizedBox(width: 2),
                Text(
                  rating.toString(),
                  style: AutonannyTypography.caption(
                    color: colors.textTertiary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _initials(String value) {
    final parts = value
        .split(' ')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return 'D';
    final first = parts.first.substring(0, 1).toUpperCase();
    final second =
        parts.length > 1 ? parts[1].substring(0, 1).toUpperCase() : '';
    return '$first$second';
  }
}
