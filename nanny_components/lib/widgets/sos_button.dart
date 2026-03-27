import 'package:flutter/material.dart';
import 'package:autonanny_ui_core/autonanny_ui_core.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/api/api_models/sos_activate_request.dart';
import 'package:nanny_core/nanny_core.dart';

class SOSButton extends StatefulWidget {
  final int? orderId;
  final VoidCallback? onSOSActivated;

  const SOSButton({
    super.key,
    this.orderId,
    this.onSOSActivated,
  });

  @override
  State<SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends State<SOSButton> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isActivating = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> _activateSOS() async {
    if (_isActivating) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              20 + MediaQuery.of(sheetContext).padding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEF2F2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.sos_rounded,
                        color: Color(0xFFDC2626),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Вызов SOS',
                            style: AutonannyTypography.h2(
                              color: sheetContext.autonannyColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Сигнал будет отправлен администратору и экстренным контактам по текущей поездке.',
                            style: AutonannyTypography.bodyS(
                              color:
                                  sheetContext.autonannyColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const AutonannyInlineBanner(
                  title: 'Используйте только в экстренной ситуации',
                  message:
                      'Мы отправим ваш текущий маршрут и GPS-координаты. Если ситуация угрожает жизни, сразу звоните в экстренные службы.',
                  tone: AutonannyBannerTone.danger,
                  leading: AutonannyIcon(AutonannyIcons.warning),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: () => Navigator.of(sheetContext).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Подтвердить SOS'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(sheetContext).pop(false),
                    child: const Text('Отмена'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isActivating = true);

    try {
      final position = await _getCurrentLocation();
      final request = SOSActivateRequest(
        latitude: position?.latitude,
        longitude: position?.longitude,
        idOrder: widget.orderId,
      );

      final result = await NannyUsersApi.activateSOS(request);

      if (!mounted) return;

      if (result.success) {
        await showModalBottomSheet<void>(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (sheetContext) => SafeArea(
            top: false,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: Color(0xFFECFDF5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF16A34A),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SOS активирован',
                              style: AutonannyTypography.h2(
                                color: sheetContext
                                    .autonannyColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Мы отправили экстренное уведомление и ваши координаты. Поддержка уже получила сигнал.',
                              style: AutonannyTypography.bodyS(
                                color: sheetContext
                                    .autonannyColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const AutonannyInlineBanner(
                    title: 'Оставайтесь на связи',
                    message:
                        'Если это безопасно, дождитесь звонка поддержки и при необходимости используйте чат для связи с участниками поездки.',
                    tone: AutonannyBannerTone.success,
                    leading: AutonannyIcon(AutonannyIcons.checkCircle),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      child: const Text('Понятно'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        widget.onSOSActivated?.call();
      } else {
        Logger().e(
          "SOS activateSOS failed: baseUrl=${NannyConsts.baseUrl}, "
          "errorMessage=${result.errorMessage}, statusCode=${result.statusCode}",
        );
        NannyDialogs.showMessageBox(
          context,
          "Ошибка",
          result.errorMessage.isNotEmpty
              ? result.errorMessage
              : "Не удалось отправить SOS. Проверьте интернет.",
        );
      }
    } catch (e) {
      Logger().e("SOS unexpected error: $e");
      if (mounted) {
        NannyDialogs.showMessageBox(
          context,
          "Ошибка",
          "Не удалось отправить SOS. Проверьте подключение к интернету.",
        );
      }
    } finally {
      if (mounted) setState(() => _isActivating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isActivating ? null : _activateSOS,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 8,
          ),
          child: _isActivating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sos, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'SOS',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
