import 'package:flutter/material.dart';
import 'package:nanny_client/view_models/pages/balance_vm.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/models/from_api/user_money.dart';

class BalanceView extends StatefulWidget {
  final bool persistState;

  const BalanceView({
    super.key,
    this.persistState = false,
  });

  @override
  State<BalanceView> createState() => _BalanceViewState();
}

class _BalanceViewState extends State<BalanceView>
    with AutomaticKeepAliveClientMixin {
  late BalanceVM vm;

  @override
  void initState() {
    super.initState();
    vm = BalanceVM(context: context, update: setState);
  }

  @override
  Widget build(BuildContext context) {
    if (wantKeepAlive) super.build(context);

    return Scaffold(
      appBar: NannyAppBar(
        title: "Баланс",
        color: NannyTheme.secondary,
        isTransparent: false,
        hasBackButton: false,
        actions: [
          IconButton(
            onPressed: () => NannyDialogs.showMessageBox(
                context,
                "Информация",
                "Для того, чтобы отправить предложение о работе понравившемуся водителю, "
                    "вы обязаны пополнить свой баланс на сумму равную стоимости 1 недели работы.\n\n"
                    "Раз в неделю, эта сумма будет списываться с вашего кошелька. "
                    "В случае, если вы вовремя не пополните баланс, то все ваши контракты будут приостановлены."),
            splashRadius: 30,
            icon: const Icon(Icons.info_outline_rounded),
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
      body: Center(
        child: RefreshIndicator(
          onRefresh: () async => vm.updateState(),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text("Текущий баланс:"),
                const SizedBox(height: 10),
                FutureLoader(
                  future: vm.currentBalance,
                  completeView: (context, data) => Text(
                      vm.formatCurrency(double.tryParse(data) ?? 0),
                      style: Theme.of(context).textTheme.titleMedium),
                  errorView: (context, error) =>
                      ErrorView(errorText: error.toString()),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 80),
                  child: Image.asset(
                      "packages/nanny_components/assets/images/card.png"),
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(bottom: 20, left: 16, right: 16),
                  child: ElevatedButton(
                    onPressed: vm.navigateToWallet,
                    style: NannyButtonStyles.main.copyWith(
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    child: const Text("Пополнить баланс"),
                  ),
                ),
                const SizedBox(height: 20),
                ConstrainedBox(
                  constraints: BoxConstraints(
                      minHeight: MediaQuery.sizeOf(context).height * .5),
                  child: NannyBottomSheet(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: RequestLoader(
                        request: vm.getMoney,
                        completeView: (context, data) => Builder(
                          builder: (context) {
                            List<History> history = data!.history
                                .where((el) => el.title
                                    .toLowerCase()
                                    .contains("пополнение"))
                                .toList();
                            return history.isEmpty
                                ? Padding(
                                    padding: EdgeInsets.only(
                                        bottom:
                                            MediaQuery.sizeOf(context).height *
                                                0.1),
                                    child: const Center(
                                      child: Text(
                                          'Вы еще не совершили ни одной операции'),
                                    ),
                                  )
                                : ListView.separated(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    itemBuilder: (context, index) => Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            color: NannyTheme.secondary,
                                            boxShadow: [
                                              BoxShadow(
                                                  color: const Color(0xFF021C3B)
                                                      .withOpacity(.12),
                                                  offset: const Offset(0, 4),
                                                  blurRadius: 11),
                                            ],
                                          ),
                                          child: ListTile(
                                            leading: Text(history[index].title),
                                            trailing: Text(
                                              "${history[index].amount} Р",
                                              style: const TextStyle(
                                                  fontFamily: 'Nunito',
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                  color: NannyTheme.primary),
                                            ),
                                          ),
                                        ),
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: 10),
                                    itemCount: history.length);
                          },
                        ),
                        errorView: (context, error) =>
                            ErrorView(errorText: error.toString()),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => widget.persistState;
}
