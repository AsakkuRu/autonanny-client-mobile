import 'package:flutter/material.dart';
import 'package:nanny_client/view_models/referral/referral_vm.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:intl/intl.dart';

class ReferralView extends StatefulWidget {
  const ReferralView({super.key});

  @override
  State<ReferralView> createState() => _ReferralViewState();
}

class _ReferralViewState extends State<ReferralView> {
  late ReferralVM vm;

  @override
  void initState() {
    super.initState();
    vm = ReferralVM(context: context, update: setState);
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NannyTheme.background,
      appBar: const NannyAppBar.light(
        title: 'Реферальная программа',
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: vm.loadData,
              color: NannyTheme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildPromoCard(),
                    const SizedBox(height: 16),
                    _buildPeriodFilter(),
                    const SizedBox(height: 16),
                    _buildStatsGrid(),
                    const SizedBox(height: 16),
                    _buildReferralsList(),
                    const SizedBox(height: 16),
                    _buildBonusHistory(),
                    const SizedBox(height: 16),
                    _buildRules(),
                    const SizedBox(height: 16),
                    _buildApplyPromo(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPromoCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            NannyTheme.primary,
            NannyTheme.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.card_giftcard, color: Colors.white, size: 40),
            const SizedBox(height: 12),
            const Text(
              'Ваш промокод',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                vm.promoCode,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _actionButton(Icons.copy, 'Копировать', vm.copyCode),
                const SizedBox(width: 16),
                _actionButton(Icons.share, 'Поделиться', vm.shareCode),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildPeriodFilter() {
    final periods = [
      ('week', 'Неделя'),
      ('month', 'Месяц'),
      ('all', 'Всё время'),
    ];
    return Row(
      children: periods.map((p) {
        final isSelected = vm.selectedPeriod == p.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => vm.changePeriod(p.$1),
            child: Container(
              margin: EdgeInsets.only(
                right: p.$1 != 'all' ? 6 : 0,
                left: p.$1 != 'week' ? 6 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? NannyTheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? NannyTheme.primary : Colors.grey[300]!,
                ),
              ),
              child: Text(
                p.$2,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatsGrid() {
    final s = vm.stats;
    if (s == null) return const SizedBox.shrink();
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(
                  'Приглашено',
                  '${s.totalInvited}',
                  Icons.person_add,
                  Colors.blue),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _statCard(
                  'Зарегистрировано',
                  '${s.registered}',
                  Icons.how_to_reg,
                  Colors.indigo),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _statCard('Активных', '${s.active}',
                  Icons.check_circle, Colors.green),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _statCard(
                  'Бонус за период',
                  '${s.periodBonus.toStringAsFixed(0)} ₽',
                  Icons.monetization_on,
                  NannyTheme.primary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: NannyTheme.shadow.withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.account_balance_wallet,
                  color: NannyTheme.primary, size: 24),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${s.totalBonus.toStringAsFixed(0)} ₽',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    'Всего заработано',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: NannyTheme.neutral500),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: NannyTheme.shadow.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: NannyTheme.neutral500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReferralsList() {
    final referrals = vm.stats?.referrals ?? [];
    if (referrals.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: NannyTheme.shadow.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Мои рефералы',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...referrals.map((r) => _buildReferralTile(r)),
        ],
      ),
    );
  }

  Widget _buildReferralTile(ReferralUser r) {
    final fmt = DateFormat('dd.MM.yyyy');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: NannyTheme.primary.withOpacity(0.1),
            child: Text(
              r.name.isNotEmpty ? r.name[0] : '?',
              style: const TextStyle(color: NannyTheme.primary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                Text(
                  'Зарегистрирован ${fmt.format(r.registeredAt)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: vm.statusColor(r.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  vm.statusLabel(r.status),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: vm.statusColor(r.status),
                  ),
                ),
              ),
              if (r.bonusEarned > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+${r.bonusEarned.toStringAsFixed(0)} ₽',
                    style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w500),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBonusHistory() {
    final history = vm.stats?.bonusHistory ?? [];
    if (history.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: NannyTheme.shadow.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: vm.toggleBonusHistory,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'История начислений',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Icon(
                  vm.showBonusHistory
                      ? Icons.expand_less
                      : Icons.expand_more,
                  color: NannyTheme.neutral500,
                ),
              ],
            ),
          ),
          if (vm.showBonusHistory) ...[
            const SizedBox(height: 12),
            ...history.map((h) => _buildBonusTile(h)),
          ],
        ],
      ),
    );
  }

  Widget _buildBonusTile(BonusHistoryItem h) {
    final fmt = DateFormat('dd.MM.yyyy');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: Colors.green, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(h.description, style: const TextStyle(fontSize: 13)),
                Text(fmt.format(h.date), style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),
          Text(
            '+${h.amount.toStringAsFixed(0)} ₽',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRules() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: NannyTheme.shadow.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: vm.toggleRules,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Как это работает',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Icon(
                  vm.showRules ? Icons.expand_less : Icons.expand_more,
                  color: NannyTheme.neutral500,
                ),
              ],
            ),
          ),
          if (vm.showRules) ...[
            const SizedBox(height: 12),
            _stepTile('1', 'Поделитесь промокодом с друзьями'),
            _stepTile('2', 'Друг регистрируется и вводит промокод'),
            _stepTile('3', 'Друг получает скидку 15% на первый заказ'),
            _stepTile('4',
                'Вы получаете 500 ₽ бонуса после первой поездки друга'),
            const Divider(height: 20),
            Text(
              'Бонусы начисляются автоматически после завершения первой поездки приглашённого. Бонусы не имеют срока действия и могут быть использованы для оплаты поездок.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: NannyTheme.neutral600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stepTile(String step, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: NannyTheme.primary.withOpacity(0.1),
            child: Text(
              step,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: NannyTheme.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildApplyPromo() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: NannyTheme.shadow.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'У вас есть промокод?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: vm.promoInputController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Введите промокод',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          BorderSide(color: NannyTheme.neutral200),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: vm.isApplying ? null : vm.applyPromo,
                  child: vm.isApplying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Применить'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
