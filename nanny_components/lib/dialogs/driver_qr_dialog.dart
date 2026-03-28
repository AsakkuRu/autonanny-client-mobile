import 'package:autonanny_ui_core/autonanny_ui_core.dart';
import 'package:flutter/material.dart';
import 'package:nanny_core/nanny_core.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// FE-MVP-017: Диалог с QR-кодом для верификации водителя (QR + PIN для ввода водителем)
class DriverQRDialog extends StatelessWidget {
  final String driverName;
  final String? carNumber;
  final String? carInfo;
  final String? photoPath;
  final String qrData;

  /// 4-значный код, который водитель может ввести вместо сканирования QR
  final String? meetingCodePin;

  const DriverQRDialog({
    super.key,
    required this.driverName,
    this.carNumber,
    this.carInfo,
    this.photoPath,
    required this.qrData,
    this.meetingCodePin,
  });

  static Future<void> show(
    BuildContext context, {
    required String driverName,
    String? carNumber,
    String? carInfo,
    String? photoPath,
    required String qrData,
    String? meetingCodePin,
  }) {
    return showDialog(
      context: context,
      builder: (context) => DriverQRDialog(
        driverName: driverName,
        carNumber: carNumber,
        carInfo: carInfo,
        photoPath: photoPath,
        qrData: qrData,
        meetingCodePin: meetingCodePin,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initials = driverName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.characters.first)
        .join()
        .toUpperCase();
    final imageUrl = NannyConsts.buildFileUrl(photoPath);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Заголовок
            const Text(
              'Верификация водителя',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2B2B2B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Покажите этот QR-код водителю',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF757575),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Фото водителя
            AutonannyAvatar(
              imageUrl: imageUrl,
              initials: initials.isEmpty ? 'В' : initials,
              size: 100,
              borderRadius: BorderRadius.circular(50),
            ),
            const SizedBox(height: 16),

            // Имя водителя
            Text(
              driverName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2B2B2B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Информация об автомобиле
            if (carNumber != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.directions_car,
                        size: 20, color: Color(0xFF757575)),
                    const SizedBox(width: 8),
                    Text(
                      carNumber!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2B2B2B),
                      ),
                    ),
                  ],
                ),
              ),
              if (carInfo != null) ...[
                const SizedBox(height: 4),
                Text(
                  carInfo!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF757575),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
            const SizedBox(height: 24),

            // QR-код
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E0E0), width: 2),
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // PIN-код для ввода водителем (альтернатива QR)
            if (meetingCodePin != null && meetingCodePin!.isNotEmpty) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Или введите код вручную в приложении водителя',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF757575),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      meetingCodePin!,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 8,
                        color: Color(0xFF2B2B2B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Информационное сообщение
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Color(0xFF1976D2)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Водитель отсканирует код или введёт его вручную для подтверждения встречи',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Кнопка закрытия
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6750A4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Закрыть',
                  style: TextStyle(
                    fontSize: 16,
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
