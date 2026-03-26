import 'package:autonanny_ui_core/autonanny_ui_core.dart';
import 'package:flutter/material.dart';
import 'package:nanny_components/base_views/view_models/add_card_vm.dart';
import 'package:nanny_core/nanny_core.dart';

class AddCardView extends StatefulWidget {
  final bool usePaymentInstead;
  final bool useSbpPayment;

  const AddCardView({
    super.key,
    this.usePaymentInstead = false,
    this.useSbpPayment = false,
  });

  @override
  State<AddCardView> createState() => _AddCardViewState();
}

class _AddCardViewState extends State<AddCardView> {
  late AddCardVM vm;

  @override
  void initState() {
    super.initState();
    vm = AddCardVM(
      context: context,
      update: setState,
      binding: WidgetsFlutterBinding.ensureInitialized(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AutonannyListScreenShell(
      appBar: AutonannyAppBar(
        title: _screenTitle(),
        leading: AutonannyIconButton(
          icon: const AutonannyIcon(AutonannyIcons.arrowLeft),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Назад',
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AutonannySpacing.lg,
        AutonannySpacing.sm,
        AutonannySpacing.lg,
        AutonannySpacing.xl,
      ),
      header: _buildHeader(),
      body: ListView(
        children: [
          if (!widget.useSbpPayment) _buildCardSection(),
          if (widget.usePaymentInstead) ...[
            if (!widget.useSbpPayment)
              const SizedBox(height: AutonannySpacing.lg),
            _buildPaymentSection(),
          ],
          const SizedBox(height: AutonannySpacing.lg),
          _buildPrimaryAction(),
          const SizedBox(height: AutonannySpacing.xxl),
        ],
      ),
    );
  }

  String _screenTitle() {
    if (!widget.usePaymentInstead) {
      return 'Новая карта';
    }
    if (widget.useSbpPayment) {
      return 'Пополнение по СБП';
    }
    return 'Пополнение картой';
  }

  Widget _buildHeader() {
    final colors = context.autonannyColors;

    return Container(
      padding: const EdgeInsets.all(AutonannySpacing.xl),
      decoration: const BoxDecoration(
        gradient: AutonannyGradients.hero,
        borderRadius: AutonannyRadii.brLg,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _headerTitle(),
                  style: AutonannyTypography.h2(color: colors.textInverse),
                ),
                const SizedBox(height: AutonannySpacing.xs),
                Text(
                  _headerDescription(),
                  style: AutonannyTypography.bodyS(
                    color: colors.textInverse.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AutonannySpacing.lg),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colors.textInverse.withValues(alpha: 0.16),
              borderRadius: AutonannyRadii.brMd,
            ),
            alignment: Alignment.center,
            child: AutonannyIcon(
              widget.useSbpPayment ? AutonannyIcons.qr : AutonannyIcons.card,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _headerTitle() {
    if (!widget.usePaymentInstead) {
      return 'Добавление карты';
    }
    return widget.useSbpPayment ? 'Оплата через СБП' : 'Пополнение баланса';
  }

  String _headerDescription() {
    if (!widget.usePaymentInstead) {
      return 'Сохраните карту, чтобы оплачивать поездки и управлять автоплатежами.';
    }
    if (widget.useSbpPayment) {
      return 'Укажите email и сумму, затем подтвердите оплату в банковском приложении.';
    }
    return 'Заполните данные карты, email и сумму пополнения для безопасной оплаты.';
  }

  Widget _buildCardSection() {
    return AutonannySectionContainer(
      title: 'Данные карты',
      subtitle: widget.usePaymentInstead
          ? 'Эта карта будет использована для пополнения.'
          : 'Карта сохранится в вашем кошельке.',
      child: Column(
        children: [
          Form(
            key: vm.fullNameState,
            child: AutonannyTextField(
              labelText: 'Имя и фамилия',
              hintText: 'Иван Иванов',
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              onChanged: (text) => vm.fullname = text,
              validator: (text) {
                if ((text ?? '').trim().split(' ').length < 2) {
                  return 'Введите имя и фамилию';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: AutonannySpacing.md),
          Form(
            key: vm.cardState,
            child: AutonannyTextField(
              labelText: 'Номер карты',
              hintText: '0000 0000 0000 0000',
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [vm.cardNumMask],
              onChanged: (_) => vm.cardState.currentState?.validate(),
              validator: (_) {
                if (vm.cardNumMask.getUnmaskedText().length < 16) {
                  return 'Введите данные карты';
                }
                if (!CardChecker.validateLuhnCard(
                  vm.cardNumMask.getUnmaskedText(),
                )) {
                  return 'Некорректный номер карты';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: AutonannySpacing.md),
          Form(
            key: vm.expState,
            child: AutonannyTextField(
              labelText: 'Срок действия',
              hintText: 'MM/YY',
              keyboardType: TextInputType.number,
              inputFormatters: [vm.expMask],
              validator: (_) {
                if (vm.expMask.getUnmaskedText().length < 4) {
                  return 'Введите срок действия';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return AutonannySectionContainer(
      title: 'Данные платежа',
      subtitle: 'Минимальная сумма пополнения — 100 ₽.',
      child: Column(
        children: [
          const AutonannyInlineBanner(
            title: 'Баланс обновится автоматически',
            message:
                'После подтверждения платежа система синхронизирует новый баланс и покажет его в кошельке.',
            tone: AutonannyBannerTone.info,
            leading: AutonannyIcon(AutonannyIcons.wallet),
          ),
          const SizedBox(height: AutonannySpacing.lg),
          Form(
            key: vm.emailState,
            child: AutonannyTextField(
              labelText: 'Email',
              hintText: 'example@mail.ru',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              onChanged: (text) => vm.email = text,
              validator: (text) {
                final value = (text ?? '').trim();
                if (!value.contains('@') || value.split('.').length < 2) {
                  return 'Введите корректный email';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: AutonannySpacing.md),
          Form(
            key: vm.moneyState,
            child: AutonannyTextField(
              labelText: 'Сумма',
              hintText: '1000',
              keyboardType: TextInputType.number,
              onChanged: (text) => vm.amount = text,
              validator: (text) {
                if ((text ?? '').isEmpty) {
                  return 'Введите сумму';
                }
                final amount = int.tryParse(text!);
                if (amount == null) {
                  return 'Введите корректное число';
                }
                if (amount < 100) {
                  return 'Минимальная сумма пополнения: 100 ₽';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryAction() {
    final isPayment = widget.usePaymentInstead;

    return AutonannyButton(
      label: isPayment ? 'Оплатить' : 'Добавить карту',
      leading: AutonannyIcon(
        isPayment ? AutonannyIcons.wallet : AutonannyIcons.add,
        color: Colors.white,
      ),
      onPressed: isPayment
          ? (widget.useSbpPayment ? vm.trySbpPay : vm.tryPay)
          : vm.trySendCardData,
    );
  }
}
