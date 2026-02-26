import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/api/dio_request.dart';
import 'package:nanny_core/api/request_builder.dart';
import 'package:nanny_core/nanny_core.dart';

class ReferralVM {
  ReferralVM({
    required this.context,
    required this.update,
  }) {
    _loadData();
  }

  final BuildContext context;
  final void Function(void Function()) update;

  String promoCode = '';
  int invitedCount = 0;
  int activeCount = 0;
  double bonusEarned = 0;
  bool isLoading = true;
  bool isApplying = false;

  final promoInputController = TextEditingController();

  Future<void> _loadData() async {
    update(() => isLoading = true);

    try {
      final result = await RequestBuilder<Map<String, dynamic>>().create(
        dioRequest: DioRequest.dio.get('/users/referral_code'),
        onSuccess: (response) => response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{},
      );

      if (result.success && result.response != null) {
        final data = result.response!;
        promoCode = data['code'] ?? '';
        invitedCount = data['invited_count'] ?? 0;
        activeCount = data['active_count'] ?? 0;
        bonusEarned = (data['bonus_earned'] ?? 0).toDouble();
      } else {
        _loadMockData();
      }
    } catch (_) {
      _loadMockData();
    }

    update(() => isLoading = false);
  }

  void _loadMockData() {
    promoCode = 'NANNY-${NannyUser.userInfo?.id ?? 0}';
    invitedCount = 3;
    activeCount = 2;
    bonusEarned = 1500;
  }

  void copyCode() {
    Clipboard.setData(ClipboardData(text: promoCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Промокод скопирован'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> shareCode() async {
    final text = 'Попробуйте АвтоНяня — безопасная перевозка детей! '
        'Используйте мой промокод $promoCode и получите скидку 15% на первый заказ.';

    Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Текст приглашения скопирован в буфер обмена'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> applyPromo() async {
    final code = promoInputController.text.trim();
    if (code.isEmpty) {
      NannyDialogs.showMessageBox(context, 'Ошибка', 'Введите промокод');
      return;
    }

    update(() => isApplying = true);

    try {
      final result = await RequestBuilder<bool>().create(
        dioRequest: DioRequest.dio.post('/users/apply_promo', data: {'code': code}),
        onSuccess: (response) => true,
      );

      if (context.mounted) {
        if (result.success) {
          promoInputController.clear();
          NannyDialogs.showMessageBox(
            context,
            'Промокод активирован',
            'Скидка 15% будет применена к вашему следующему заказу.',
          );
        } else {
          NannyDialogs.showMessageBox(
            context,
            'Ошибка',
            result.errorMessage.isNotEmpty ? result.errorMessage : 'Недействительный промокод',
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        NannyDialogs.showMessageBox(context, 'Ошибка', 'Не удалось применить промокод');
      }
    }

    update(() => isApplying = false);
  }

  void dispose() {
    promoInputController.dispose();
  }
}
