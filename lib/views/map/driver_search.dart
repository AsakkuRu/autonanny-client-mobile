import 'package:flutter/material.dart';
import 'package:nanny_client/view_models/map/drive_search_vm.dart';
import 'package:nanny_components/nanny_components.dart';

class DriverSearchView extends StatefulWidget {
  const DriverSearchView({super.key, required this.token});

  final String token;

  @override
  State<DriverSearchView> createState() => _DriverSearchViewState();
}

class _DriverSearchViewState extends State<DriverSearchView>
    with SingleTickerProviderStateMixin {
  late DriveSearchVM vm;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    vm = DriveSearchVM(
      context: context,
      update: setState,
      token: widget.token,
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    vm.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureLoader(
      future: vm.loadRequest,
      completeView: (context, data) {
        if (!data) {
          return const ErrorView(errorText: "Не удалось загрузить данные!");
        }

        return Scaffold(
          backgroundColor: NannyTheme.background,
          body: Stack(
            children: [
              Column(
                children: [
                  const SizedBox(height: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: _buildMapStub(context),
                    ),
                  ),
                  _buildBottomSheet(context),
                ],
              ),

              // Баннер срочного заказа «На замену»
              if (vm.isUrgentReplacement)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: NannyTheme.warning,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.swap_horiz,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Водитель на замену',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              if (vm.urgentReason != null)
                                Text(
                                  vm.urgentReason!,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (vm.urgentMultiplier != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'x${vm.urgentMultiplier!.toStringAsFixed(1)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

              // Bottom sheet с альтернативными тарифами
              if (vm.showAlternatives)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildAlternativesSheet(context),
                ),
            ],
          ),
        );
      },
      errorView: (context, error) => ErrorView(errorText: error.toString()),
    );
  }

  Widget _buildMapStub(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEEF0FF),
            Color(0xFFE4E4EF),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _RoadsPainter(),
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final t = _controller.value;
                final scale = 1 + 0.12 * t;
                final opacity = 1 - 0.6 * t;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: opacity,
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color:
                                NannyTheme.primary.withOpacity(0.12 * opacity),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: NannyTheme.primary.withOpacity(0.26),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        vm.driverFound
                            ? Icons.directions_car_filled_rounded
                            : Icons.search,
                        color:
                            vm.driverFound ? NannyTheme.success : NannyTheme.primary,
                        size: 32,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: NannyTheme.shadow.withOpacity(0.18),
            blurRadius: 28,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: NannyTheme.neutral200,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            vm.driverFound ? 'Водитель найден' : 'Ищем водителя',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            vm.statusText,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: NannyTheme.neutral500),
          ),
          const SizedBox(height: 16),
          if (vm.driverLocation != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: NannyTheme.neutral50,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.route_rounded,
                    size: 18,
                    color: NannyTheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Координаты водителя: '
                    '${vm.driverLocation!['lat']?.toStringAsFixed(4)}, '
                    '${vm.driverLocation!['lon']?.toStringAsFixed(4)}',
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: NannyTheme.neutral600),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: vm.isSearching
                ? ElevatedButton(
                    onPressed: vm.cancelSearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NannyTheme.danger,
                    ),
                    child: const Text('Отменить поиск'),
                  )
                : ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(vm.driverFound ? 'Перейти к поездке' : 'Закрыть'),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlternativesSheet(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Водителей этого класса нет',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Попробуйте другой класс авто',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: NannyTheme.neutral500),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: vm.dismissAlternatives,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...vm.alternatives.map((alt) => _buildAlternativeTile(context, alt)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: vm.dismissAlternatives,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                side: BorderSide(color: NannyTheme.neutral200),
              ),
              child: const Text('Продолжить ожидание'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlternativeTile(BuildContext context, alt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border.all(color: NannyTheme.neutral100),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: NannyTheme.primary.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.directions_car, color: NannyTheme.primary),
        ),
        title: Text(
          alt.tariffName,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        subtitle: Text(
          'Ожидание ~${alt.estimatedWaitMinutes} мин',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: NannyTheme.neutral500),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${alt.price.toStringAsFixed(0)} ₽',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap:
                  vm.isSwitchingTariff ? null : () => vm.switchTariff(alt),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: NannyTheme.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: vm.isSwitchingTariff
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Выбрать',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
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

class _RoadsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD5D3F5)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path1 = Path()
      ..moveTo(24, size.height * 0.2)
      ..quadraticBezierTo(
        size.width * 0.3,
        size.height * 0.15,
        size.width * 0.5,
        size.height * 0.3,
      )
      ..quadraticBezierTo(
        size.width * 0.7,
        size.height * 0.45,
        size.width - 24,
        size.height * 0.4,
      );

    final path2 = Path()
      ..moveTo(size.width - 32, size.height * 0.7)
      ..quadraticBezierTo(
        size.width * 0.6,
        size.height * 0.8,
        size.width * 0.4,
        size.height * 0.65,
      )
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.55,
        24,
        size.height * 0.6,
      );

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
