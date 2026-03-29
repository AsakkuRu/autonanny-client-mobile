import 'package:flutter/material.dart';
import 'package:autonanny_ui_core/autonanny_ui_core.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/nanny_core.dart';
import 'package:nanny_components/styles/new_design_auth.dart';

class MapViewer extends StatefulWidget {
  final Widget body;
  final Widget panel;
  /// Если задан — используется вместо body. Позволяет строить карту с padding
  /// для центрирования относительно видимой области над панелью.
  final Widget Function(double panelHeight)? bodyBuilder;
  final String? currentLocName;
  final double minExtent;
  final double maxExtent;
  /// Доля высоты экрана для начального положения панели.
  /// 0.0 = minExtent (закрыта), 1.0 = maxExtent (открыта полностью).
  /// null = использовать minExtent (поведение по умолчанию).
  final double? initialExtent;
  /// Если true — высота панели подстраивается под содержимое (максимум maxExtent).
  /// Содержимое скроллится, если превышает maxExtent.
  final bool adaptToContent;
  final GoogleMapController Function()? onPosPressed;
  final void Function(ScrollController sc)? onPanelBuild;
  /// Кнопка SOS показывается только во время поездки (на главном экране скрыта).
  final bool showSosButton;

  const MapViewer({
    super.key,
    required this.body,
    required this.panel,
    this.bodyBuilder,
    this.currentLocName,
    this.onPosPressed,
    this.minExtent = .1,
    this.maxExtent = .5,
    this.initialExtent,
    this.adaptToContent = false,
    this.onPanelBuild,
    this.showSosButton = false,
  });

  @override
  State<MapViewer> createState() => _MapViewerState();
}

// Высота ручки панели (SizedBox(8) + Container(4) + SizedBox(12))
const double _kHandleHeight = 24.0;

class _MapViewerState extends State<MapViewer> {
  double minHeight = 0;
  double _absoluteMaxHeight = 0;
  // Измеренная высота контента + ручка; 0 = ещё не измерено
  double _measuredPanelHeight = 0;
  /// Текущая высота панели для bodyBuilder (centering карты над панелью).
  double _panelHeight = 0;
  final GlobalKey _panelContentKey = GlobalKey();
  final PanelController _panelController = PanelController();
  bool _initialPositionSet = false;

  double get _effectiveMaxHeight {
    if (widget.adaptToContent && _measuredPanelHeight > 0) {
      return _measuredPanelHeight.clamp(minHeight, _absoluteMaxHeight);
    }
    return _absoluteMaxHeight;
  }

  bool _measureScheduled = false;

  /// Замеряет высоту контента и обновляет maxHeight панели.
  /// Вызывается как из build(), так и из SizeChangedLayoutNotifier
  /// (когда контент внутри панели изменяет свой размер).
  void _scheduleMeasurement() {
    if (!widget.adaptToContent) return;
    if (_measureScheduled) return;
    _measureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureScheduled = false;
      if (!mounted) return;
      final ctx = _panelContentKey.currentContext;
      if (ctx == null) return;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;
      // Высота контента (внутри SingleChildScrollView) + ручка
      final newH = box.size.height + _kHandleHeight;
      // Игнорируем микро-изменения и слишком маленькие значения (loading-заглушки)
      if ((newH - _measuredPanelHeight).abs() <= 4.0 || newH < 80) return;

      setState(() => _measuredPanelHeight = newH);

      // После rebuild (с новым maxHeight) анимируем панель в открытое положение
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_panelController.isAttached) return;
        _panelController.animatePanelToPosition(
          1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    });
  }

  void _setInitialPosition() {
    if (_initialPositionSet) return;
    final ext = widget.initialExtent;
    if (ext == null || ext <= 0) return;
    _initialPositionSet = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_panelController.isAttached) {
        _panelController.animatePanelToPosition(
          ext.clamp(0.0, 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdaptBuilder(builder: (context, size) {
      final colors = context.autonannyColors;
      final isDark = Theme.of(context).brightness == Brightness.dark;
      minHeight = size.height * widget.minExtent;
      _absoluteMaxHeight = size.height * widget.maxExtent;
      final maxHeight = _effectiveMaxHeight;

      _scheduleMeasurement();
      _setInitialPosition();

      // panelHeight для bodyBuilder: при первом frame используем maxHeight
      final effectivePanelHeight = _panelHeight > 0 ? _panelHeight : maxHeight;
      final mapBody = widget.bodyBuilder != null
          ? widget.bodyBuilder!(effectivePanelHeight)
          : widget.body;

      return Stack(
        children: [
          // ─ Карта + скользящая панель ─
          SlidingUpPanel(
            controller: _panelController,
            minHeight: minHeight,
            maxHeight: maxHeight,
            color: colors.surfaceBase,
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.28)
                    : const Color.fromRGBO(0, 0, 0, 0.18),
                blurRadius: 18,
                offset: const Offset(0, -4),
              ),
            ],
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(32)),
            parallaxEnabled: false,
            body: mapBody,
            onPanelSlide: widget.bodyBuilder != null
                ? (double position) {
                    final h =
                        minHeight + (maxHeight - minHeight) * position;
                    if ((_panelHeight - h).abs() > 1.0) {
                      setState(() => _panelHeight = h);
                    }
                  }
                : null,
            panelBuilder: (sc) {
              widget.onPanelBuild?.call(sc);
              return NotificationListener<SizeChangedLayoutNotification>(
                // Когда контент внутри панели меняет высоту (например,
                // после загрузки данных) — пересчитываем maxHeight.
                onNotification: (_) {
                  _scheduleMeasurement();
                  return false;
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.borderSubtle,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: sc,
                        // SizeChangedLayoutNotifier отслеживает изменения
                        // высоты контента (e.g. FutureLoader завершился).
                        // KeyedSubtree позволяет измерить натуральную высоту:
                        // SingleChildScrollView рендерит дочерний виджет
                        // с неограниченной высотой.
                        child: SizeChangedLayoutNotifier(
                          child: KeyedSubtree(
                            key: _panelContentKey,
                            child: widget.panel,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // ─ Оверлей: всегда фиксирован поверх карты и панели ─
          if (widget.currentLocName != null)
            Positioned(
              top: 52,
              left: 16,
              right: 16,
              child: _GreetingAndControls(
                currentLocName: widget.currentLocName!,
                onRecenter: widget.onPosPressed != null ? toMyPos : null,
                showSosButton: widget.showSosButton,
              ),
            ),

        ],
      );
    });
  }

  void toMyPos() async {
    try {
      // Проверяем разрешения
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return;
      }

      LocationService.curLoc ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      GoogleMapController? controller = widget.onPosPressed!.call();
      var location = LocationService.curLoc;
      if (location == null) return;
      controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: NannyMapUtils.position2LatLng(location),
        zoom: 15,
      )));
    } catch (e) {
      // Игнорируем ошибки геолокации
      print('Error getting location: $e');
    }
  }
}

class _GreetingAndControls extends StatelessWidget {
  final String currentLocName;
  final VoidCallback? onRecenter;
  final bool showSosButton;

  const _GreetingAndControls({
    required this.currentLocName,
    this.onRecenter,
    this.showSosButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = NannyUser.userInfo;
    final name = user?.name ?? '';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: colors.surfaceElevated.withValues(
              alpha: isDark ? 0.94 : 0.95,
            ),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.22)
                    : const Color.fromRGBO(91, 79, 207, 0.08),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      NewDesignAuthTokens.primaryLight,
                      NewDesignAuthTokens.primaryDark,
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  name.isNotEmpty ? name.characters.first.toUpperCase() : 'А',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                name.isNotEmpty ? "Привет, $name" : "Привет",
                style: AutonannyTypography.bodyM(
                  color: colors.textPrimary,
                ).copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            _CircleIconButton(
              icon: Icons.notifications_none_rounded,
              hasDot: false,
              onTap: () {
                Navigator.pushNamed(context, '/notifications');
              },
            ),
            if (showSosButton) ...[
              const SizedBox(width: 8),
              _CircleIconButton(
                label: 'SOS',
                isDanger: true,
                onTap: () {
                  // TODO: SOS action
                },
              ),
            ],
            const SizedBox(width: 8),
            if (onRecenter != null)
              _CircleIconButton(
                icon: Icons.my_location_rounded,
                onTap: onRecenter!,
              ),
          ],
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData? icon;
  final String? label;
  final bool hasDot;
  final bool isDanger;
  final VoidCallback onTap;

  const _CircleIconButton({
    this.icon,
    this.label,
    this.hasDot = false,
    this.isDanger = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDanger ? NewDesignAuthTokens.danger : colors.surfaceElevated;
    final shadowColor = isDanger
        ? const Color.fromRGBO(239, 68, 68, 0.4)
        : isDark
            ? Colors.black.withValues(alpha: 0.24)
            : const Color.fromRGBO(15, 15, 30, 0.10);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (icon != null)
              Icon(
                icon,
                size: 20,
                color: isDanger
                    ? Colors.white
                    : colors.textPrimary,
              ),
            if (label != null)
              Text(
                label!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            if (hasDot)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: NewDesignAuthTokens.danger,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: bgColor, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
