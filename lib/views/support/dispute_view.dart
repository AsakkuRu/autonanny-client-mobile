import 'package:flutter/material.dart';
import 'package:nanny_client/ui_sdk/client_ui_sdk.dart';
import 'package:nanny_client/view_models/support/dispute_vm.dart';

/// B-013 TASK-B13: Экран оспаривания платежа
class DisputeView extends StatefulWidget {
  final int orderId;
  final double amount;
  final String route;

  const DisputeView({
    super.key,
    required this.orderId,
    required this.amount,
    required this.route,
  });

  @override
  State<DisputeView> createState() => _DisputeViewState();
}

class _DisputeViewState extends State<DisputeView> {
  late final DisputeVM vm;

  @override
  void initState() {
    super.initState();
    vm = DisputeVM(
      context: context,
      update: setState,
      orderId: widget.orderId,
      amount: widget.amount,
      route: widget.route,
    );
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;

    return Scaffold(
      backgroundColor: colors.surfaceBase,
      appBar: AutonannyAppBar(
        title: 'Оспорить платёж',
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: AutonannyIcon(
            AutonannyIcons.chevronLeft,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderInfo(),
            const SizedBox(height: 24),
            const Text(
              'Причина спора',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...(vm.reasons.map((reason) => _buildReasonTile(reason))),
            const SizedBox(height: 24),
            const Text(
              'Описание (необязательно)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: vm.descriptionController,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Опишите ситуацию подробнее...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.actionPrimary),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.statusInfoSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: colors.statusInfo, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Спор будет рассмотрен в течение 3 рабочих дней. Мы свяжемся с вами через поддержку.',
                      style: TextStyle(fontSize: 12, color: colors.statusInfo),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AutonannyButton(
              label: 'Подать спор',
              isLoading: vm.isSubmitting,
              onPressed: vm.isSubmitting ? null : vm.submitDispute,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfo() {
    final colors = context.autonannyColors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Заказ',
            style: TextStyle(fontSize: 13, color: colors.textTertiary),
          ),
          const SizedBox(height: 4),
          Text(
            widget.route,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Сумма: ${widget.amount.toStringAsFixed(0)} ₽',
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              Text(
                '#${widget.orderId}',
                style: TextStyle(fontSize: 12, color: colors.textTertiary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReasonTile(String reason) {
    final isSelected = vm.selectedReason == reason;
    final colors = context.autonannyColors;

    return GestureDetector(
      onTap: () => vm.selectReason(reason),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colors.statusInfoSurface : colors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? colors.actionPrimary : colors.borderSubtle,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? colors.actionPrimary : colors.textTertiary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              reason,
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? colors.actionPrimary : colors.textPrimary,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
