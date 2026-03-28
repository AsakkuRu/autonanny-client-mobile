import 'package:autonanny_ui_core/autonanny_ui_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/constants.dart';
import 'package:nanny_core/models/from_api/driver_contact.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverContactCard extends StatelessWidget {
  final DriverContact driver;
  final VoidCallback? onChatPressed;
  final VoidCallback? onShowQR; // FE-MVP-017

  const DriverContactCard({
    super.key,
    required this.driver,
    this.onChatPressed,
    this.onShowQR, // FE-MVP-017
  });

  @override
  Widget build(BuildContext context) {
    final initials = driver.fullName
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .take(2)
        .map((part) => part.trim()[0])
        .join()
        .toUpperCase();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          const Text(
            'Ваша автоняня',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF757575),
            ),
          ),
          const SizedBox(height: 12),
          
          // Информация о водителе
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Фото водителя
              AutonannyAvatar(
                imageUrl: NannyConsts.buildFileUrl(driver.photo),
                initials: initials.isEmpty ? 'В' : initials,
                size: 100,
                borderRadius: BorderRadius.circular(50),
              ),
              const SizedBox(width: 16),
              
              // ФИО и квалификация
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2B2B2B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Рейтинг и опыт (АКЦЕНТ НА КВАЛИФИКАЦИИ)
                    if (driver.rating != null || driver.experienceYears != null) ...[
                      Row(
                        children: [
                          // Рейтинг
                          if (driver.rating != null) ...[
                            const Icon(
                              Icons.star,
                              size: 18,
                              color: Color(0xFFFFA726),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              driver.rating!.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2B2B2B),
                              ),
                            ),
                          ],
                          
                          // Разделитель
                          if (driver.rating != null && driver.experienceYears != null) ...[
                            const SizedBox(width: 12),
                            Container(
                              width: 1,
                              height: 16,
                              color: const Color(0xFFE0E0E0),
                            ),
                            const SizedBox(width: 12),
                          ],
                          
                          // Опыт работы
                          if (driver.experienceYears != null) ...[
                            const Icon(
                              Icons.work_outline,
                              size: 18,
                              color: NannyTheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${driver.experienceYears} ${_getYearWord(driver.experienceYears!)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF2B2B2B),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    // Количество поездок и отзывов
                    if (driver.totalTrips != null || driver.reviewsCount != null) ...[
                      Row(
                        children: [
                          if (driver.totalTrips != null) ...[
                            Text(
                              '${driver.totalTrips} ${_getTripWord(driver.totalTrips!)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF757575),
                              ),
                            ),
                          ],
                          if (driver.totalTrips != null && driver.reviewsCount != null) ...[
                            const Text(
                              ' • ',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF757575),
                              ),
                            ),
                          ],
                          if (driver.reviewsCount != null) ...[
                            Text(
                              '${driver.reviewsCount} ${_getReviewWord(driver.reviewsCount!)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF757575),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    // Телефон с кнопками
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            TextMasks.phoneMask().maskText(driver.phone.substring(1)),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF757575),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _copyPhone(context),
                          icon: const Icon(Icons.copy, size: 18),
                          color: NannyTheme.primary,
                          splashRadius: 20,
                          tooltip: 'Копировать номер',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _callDriver,
                          icon: const Icon(Icons.phone, size: 18),
                          color: NannyTheme.primary,
                          splashRadius: 20,
                          tooltip: 'Позвонить',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Информация о машине (минимизирована)
          if (driver.car != null && driver.car!.colorAndNumber.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.directions_car,
                  size: 16,
                  color: Color(0xFF9E9E9E),
                ),
                const SizedBox(width: 6),
                Text(
                  driver.car!.colorAndNumber,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
          ],
          
          // Кнопки действий
          if (onChatPressed != null || onShowQR != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                // FE-MVP-017: Кнопка "Показать QR-код"
                if (onShowQR != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onShowQR,
                      icon: const Icon(Icons.qr_code, size: 20),
                      label: const Text('QR-код'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                if (onChatPressed != null && onShowQR != null)
                  const SizedBox(width: 12),
                // Кнопка "Написать водителю"
                if (onChatPressed != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onChatPressed,
                      icon: const Icon(Icons.chat_bubble_outline, size: 20),
                      label: const Text('Написать'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NannyTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _copyPhone(BuildContext context) {
    Clipboard.setData(ClipboardData(text: driver.phone));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Номер телефона скопирован'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _callDriver() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: driver.phone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  // Вспомогательные функции для склонения слов
  String _getYearWord(int years) {
    if (years % 10 == 1 && years % 100 != 11) {
      return 'год';
    } else if ([2, 3, 4].contains(years % 10) && ![12, 13, 14].contains(years % 100)) {
      return 'года';
    } else {
      return 'лет';
    }
  }

  String _getTripWord(int trips) {
    if (trips % 10 == 1 && trips % 100 != 11) {
      return 'поездка';
    } else if ([2, 3, 4].contains(trips % 10) && ![12, 13, 14].contains(trips % 100)) {
      return 'поездки';
    } else {
      return 'поездок';
    }
  }

  String _getReviewWord(int reviews) {
    if (reviews % 10 == 1 && reviews % 100 != 11) {
      return 'отзыв';
    } else if ([2, 3, 4].contains(reviews % 10) && ![12, 13, 14].contains(reviews % 100)) {
      return 'отзыва';
    } else {
      return 'отзывов';
    }
  }
}
