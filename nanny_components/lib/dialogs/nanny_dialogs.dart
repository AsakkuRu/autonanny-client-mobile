import 'package:flutter/material.dart';
import 'package:nanny_components/base_views/views/route_sheet.dart';
import 'package:nanny_core/models/from_api/child.dart';
import 'package:nanny_core/models/from_api/drive_and_map/schedule.dart';
import 'package:nanny_core/nanny_core.dart';

class NannyDialogs {
  static Future<void> showResultSheet(
    BuildContext context, {
    required String title,
    required String msg,
    IconData icon = Icons.info_outline_rounded,
    Color iconColor = Colors.orange,
    String buttonText = 'Понятно',
  }) async {
    await showModalBottomSheet<void>(
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
              24,
              16,
              24,
              24 + MediaQuery.of(sheetContext).padding.bottom,
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
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, color: iconColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(sheetContext)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          if (msg.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              msg,
                              style: Theme.of(sheetContext)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.black87),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: Text(buttonText),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> showMessageBox(
    BuildContext context,
    String title,
    String msg,
  ) async {
    await showDialog(
      context: context,
      builder: (dContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (title.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    if (msg.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          msg,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(dContext),
                        style: ButtonStyle(
                          shape: WidgetStatePropertyAll(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          minimumSize: const WidgetStatePropertyAll(
                            Size(double.infinity, 60),
                          ),
                        ),
                        child: const Text("Продолжить"),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  static Future<bool> showModalDialog({
    required BuildContext context,
    required Widget child,
    String? title,
    List<Widget>? actions,
    bool hasDefaultBtn = true,
  }) async {
    actions ??= [];

    if (hasDefaultBtn) {
      actions.add(
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ButtonStyle(
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            minimumSize: const WidgetStatePropertyAll(
              Size(double.infinity, 60),
            ),
          ),
          child: const Text("Ок"),
        ),
      );
    }

    return await showDialog(
          context: context,
          builder: (dContext) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    width: MediaQuery.of(context).size.width,
                    padding: const EdgeInsets.all(10),
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(dContext, false),
                          child: const Icon(Icons.close, size: 30),
                        ),
                        //),
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (title != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              child,
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  runAlignment: WrapAlignment.center,
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: actions!,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ) ??
        false;
  }

  static Future<bool> confirmAction(
    BuildContext context,
    String prompt, {
    String title = "Подтверждение действия",
    String confirmText = "Ок",
    String cancelText = "Отмена",
  }) async {
    return await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dContext) {
              return SimpleDialog(
                contentPadding: const EdgeInsets.only(
                    left: 10, right: 10, bottom: 20, top: 10),
                insetPadding: const EdgeInsets.symmetric(horizontal: 20),
                titleTextStyle: const TextStyle(
                    fontSize: 20,
                    height: 20.6 / 20,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Fregat'),
                children: [
                  Stack(
                    alignment: Alignment.topLeft,
                    children: [
                      IconButton(
                          onPressed: () => Navigator.pop(dContext, false),
                          icon: const Icon(Icons.close),
                          iconSize: 30,
                          splashRadius: 30),
                      Align(
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: Text(
                                title,
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 20,
                                  height: 20.6 / 20,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Fregat',
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                prompt,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 20 / 16,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Wrap(
                              alignment: WrapAlignment.center,
                              runAlignment: WrapAlignment.center,
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.pop(dContext, true),
                                  style: ButtonStyle(
                                    shape: WidgetStatePropertyAll(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    minimumSize: WidgetStatePropertyAll(
                                      Size(
                                          MediaQuery.of(context).size.width -
                                              80,
                                          60),
                                    ),
                                  ),
                                  child: Text(confirmText),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.pop(dContext, false),
                                  style: ButtonStyle(
                                    shape: WidgetStatePropertyAll(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    minimumSize: WidgetStatePropertyAll(
                                      Size(
                                          MediaQuery.of(context).size.width -
                                              80,
                                          60),
                                    ),
                                  ),
                                  child: Text(cancelText),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }) ??
        false;
  }

  static Future<RouteSheetResult?> showRouteCreateOrEditSheet(
      BuildContext context, NannyWeekday weekday,
      {Road? road,
      int? tariffId,
      List<NannyWeekday>? allSelectedWeekdays,
      bool applyToAllDaysDefault = true,
      List<Child>? availableChildren,
      List<int>? initialSelectedChildIds}) async {
    return await showModalBottomSheet(
      context: context,
      enableDrag: false,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: RouteSheetView(
          weekday: weekday,
          road: road,
          tariffId: tariffId,
          allSelectedWeekdays: allSelectedWeekdays,
          applyToAllDaysDefault: applyToAllDaysDefault,
          availableChildren: availableChildren,
          initialSelectedChildIds: initialSelectedChildIds,
        ),
      ),
    );
  }

  /// Показывает диалог о недостаточном балансе с предложением пополнения
  static Future<bool> showInsufficientBalanceDialog(
    BuildContext context, {
    double currentBalance = 0.0,
  }) async {
    return await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dContext) {
            return SimpleDialog(
              contentPadding: const EdgeInsets.only(
                  left: 10, right: 10, bottom: 20, top: 10),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              titleTextStyle: const TextStyle(
                  fontSize: 20,
                  height: 20.6 / 20,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Fregat'),
              children: [
                Stack(
                  alignment: Alignment.topLeft,
                  children: [
                    IconButton(
                        onPressed: () => Navigator.pop(dContext, false),
                        icon: const Icon(Icons.close),
                        iconSize: 30,
                        splashRadius: 30),
                    Align(
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 20),
                            child: Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 60,
                              color: Color(0xFFFF6B6B),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Недостаточно средств',
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              height: 20.6 / 20,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Fregat',
                            ),
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'Ваш текущий баланс: ${currentBalance.toStringAsFixed(2)} ₽\n\nДля создания расписания поездок необходимо иметь положительный баланс. Пополните баланс, чтобы продолжить.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 20 / 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Wrap(
                            alignment: WrapAlignment.center,
                            runAlignment: WrapAlignment.center,
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              ElevatedButton(
                                onPressed: () => Navigator.pop(dContext, true),
                                style: ButtonStyle(
                                  shape: WidgetStatePropertyAll(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  minimumSize: WidgetStatePropertyAll(
                                    Size(MediaQuery.of(context).size.width - 80,
                                        60),
                                  ),
                                ),
                                child: const Text('Пополнить баланс'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(dContext, false),
                                style: ButtonStyle(
                                  backgroundColor: WidgetStatePropertyAll(
                                    Colors.grey[300],
                                  ),
                                  foregroundColor: const WidgetStatePropertyAll(
                                    Colors.black87,
                                  ),
                                  shape: WidgetStatePropertyAll(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  minimumSize: WidgetStatePropertyAll(
                                    Size(MediaQuery.of(context).size.width - 80,
                                        60),
                                  ),
                                ),
                                child: const Text('Отмена'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ) ??
        false;
  }
}
