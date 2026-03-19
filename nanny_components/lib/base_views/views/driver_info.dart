import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nanny_components/base_views/view_models/driver_info_vm.dart';
import 'package:nanny_components/base_views/views/driver_orders.dart';
import 'package:nanny_components/base_views/views/video_view.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/api/api_models/driver_user_data.dart';
import 'package:nanny_core/models/from_api/drive_and_map/schedule_responses_data.dart';
import 'package:nanny_core/models/from_api/roles/driver_data.dart';
import 'package:nanny_core/models/from_api/user_info.dart';
import 'package:nanny_core/nanny_core.dart';

/// Используется для просмотра данных профиля водителя.
///
/// Если стоит флаг [viewingOrder], то [scheduleData] НЕ должно быть пустым
class DriverInfoView extends StatefulWidget {
  final int id;
  final bool hasPaymentButtons;
  final bool franchiseView;
  final bool viewingOrder;
  final ScheduleResponsesData? scheduleData;

  const DriverInfoView(
      {super.key,
      required this.id,
      this.hasPaymentButtons = false,
      this.franchiseView = false,
      this.viewingOrder = false,
      this.scheduleData});

  @override
  State<DriverInfoView> createState() => _DriverInfoViewState();
}

class _DriverInfoViewState extends State<DriverInfoView> {
  late DriverInfoVM vm;

  @override
  void initState() {
    super.initState();
    vm = DriverInfoVM(
        context: context,
        update: setState,
        id: widget.id,
        viewingOrder: widget.viewingOrder,
        scheduleData: widget.scheduleData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        appBar: const NannyAppBar(
          title: "Профиль водителя",
          isTransparent: false,
          color: NannyTheme.secondary,
        ),
        body: RequestLoader(
            request: vm.getDriver,
            completeView: (context, driverData) {
              // Используем реальные данные, полученные с бэкенда.
              final DriverUserTextData data = driverData!;
              data.userData = data.userData.asDriver();

              return Column(children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                  child: Row(
                    children: [
                      ProfileImage(url: data.userData.photoPath, radius: 77),
                      const SizedBox(width: 29),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${data.userData.name} ${data.userData.surname}",
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                height: 20 / 18,
                                color: NannyTheme.onSecondary),
                          ),
                          if (data.userData.videoPath.isNotEmpty)
                            TextButton(
                              style: const ButtonStyle(
                                  padding:
                                      WidgetStatePropertyAll(EdgeInsets.zero)),
                              onPressed: () => vm.navigateToView(
                                VideoView(url: data.userData.videoPath),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.play_circle_outline_outlined,
                                    color: Color(0xFF6D6D6D),
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    "Видео-описание",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                      height: 17.6 / 16,
                                      color: Color(0xFF6D6D6D),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          //RichText(
                          //  text: TextSpan(
                          //    children: [
                          //      const TextSpan(
                          //        text: "ИНН: ",
                          //        style: TextStyle(
                          //            fontSize: 16,
                          //            fontWeight: FontWeight.w400,
                          //            height: 17.6 / 16,
                          //            color: NannyTheme.onSecondary),
                          //      ),
                          //      TextSpan(
                          //        text: data.userData.roleData?.inn ?? "Пусто",
                          //        style: const TextStyle(
                          //            fontSize: 16,
                          //            fontWeight: FontWeight.w400,
                          //            height: 17.6 / 16,
                          //            color: NannyTheme.primary),
                          //      )
                          //    ],
                          //  ),
                          //)
                        ],
                      )
                    ],
                  ),
                ),
                if (widget.hasPaymentButtons)
                  Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Column(children: [
                        ElevatedButton.icon(
                          onPressed: () =>
                              vm.navigateToView(const DriverOrdersView()),
                          style: NannyButtonStyles.whiteButton,
                          icon: const Text("Управление заказами"),
                          label: Image.asset(
                              "packages/nanny_components/assets/images/taxi.png"),
                        ),
                        const SizedBox(height: 20),
                        Row(children: [
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                                onPressed: () => vm.navigateToView(
                                    const WalletView(
                                        title: "Выплата заработной платы",
                                        subtitle: "Выберите способ оплаты",
                                        hasReplenishButtons: false)),
                                child: const Text("Сделать выплату")),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                              child: ElevatedButton(
                                  onPressed: () => vm.navigateToView(
                                      const WalletView(
                                          title: "Выплата заработной платы",
                                          subtitle: "Выберите способ оплаты",
                                          hasReplenishButtons: false)),
                                  style: NannyButtonStyles.whiteButton,
                                  child: const Text("Получить процент"))),
                          const SizedBox(width: 10)
                        ])
                      ])),
                Expanded(
                    child: NannyBottomSheet(
                        child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: !widget.franchiseView
                                ? Column(children: [
                                    Expanded(
                                        child: ListView(
                                            shrinkWrap: true,
                                            children: [
                                          Text("Информация об авто",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium,
                                              textAlign: TextAlign.center),
                                          const SizedBox(height: 30),
                                          carInfoPlate(
                                              title: "Марка",
                                              value: data.carDataText.autoMark),
                                          const SizedBox(height: 10),
                                          carInfoPlate(
                                              title: "Модель",
                                              value:
                                                  data.carDataText.autoModel),
                                          const SizedBox(height: 10),
                                          carInfoPlate(
                                              title: "Цвет",
                                              value:
                                                  data.carDataText.autoColor),
                                          const SizedBox(height: 10),
                                          carInfoPlate(
                                              title: "Год выпуска",
                                              value: data
                                                  .carDataText.releaseYear
                                                  .toString()),
                                          const SizedBox(height: 10),
                                          carInfoPlate(
                                              title: "Гос номер",
                                              value:
                                                  data.carDataText.stateNumber),
                                          const SizedBox(height: 10),
                                          carInfoPlate(
                                              title: "СТС",
                                              value: data.carDataText.ctc)
                                        ])),
                                    if (widget.viewingOrder)
                                      const SizedBox(height: 20),
                                    if (widget.viewingOrder)
                                      Row(children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () => vm.answerSchedule(
                                                confirm: false),
                                            style: ButtonStyle(
                                              backgroundColor:
                                                  WidgetStatePropertyAll(
                                                      Colors.red.shade400),
                                              shape: WidgetStatePropertyAll(
                                                RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                              minimumSize:
                                                  const WidgetStatePropertyAll(
                                                Size(double.infinity, 60),
                                              ),
                                            ),
                                            child:
                                                const Text("Отклонить заявку"),
                                          ),
                                        ),
                                        const SizedBox(width: 20),
                                        Expanded(
                                            child: ElevatedButton(
                                                onPressed: () =>
                                                    vm.answerSchedule(
                                                        confirm: true),
                                                style: ButtonStyle(
                                                  backgroundColor:
                                                      const WidgetStatePropertyAll(
                                                          NannyTheme
                                                              .lightGreen),
                                                  foregroundColor:
                                                      const WidgetStatePropertyAll(
                                                          NannyTheme
                                                              .onSecondary),
                                                  shape: WidgetStatePropertyAll(
                                                    RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                  ),
                                                  minimumSize:
                                                      const WidgetStatePropertyAll(
                                                    Size(double.infinity, 60),
                                                  ),
                                                ),
                                                child: const Text(
                                                    "Одобрить заявку")))
                                      ])
                                  ])
                                : ListView(
                                    shrinkWrap: true,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    children: [
                                        ExpansionTile(
                                            title:
                                                infoText("Информация об авто"),
                                            children: [
                                              const SizedBox(height: 30),
                                              carInfoPlate(
                                                  title: "Марка",
                                                  value: data
                                                      .carDataText.autoMark),
                                              const SizedBox(height: 10),
                                              carInfoPlate(
                                                  title: "Модель",
                                                  value: data
                                                      .carDataText.autoModel),
                                              const SizedBox(height: 10),
                                              carInfoPlate(
                                                  title: "Цвет",
                                                  value: data
                                                      .carDataText.autoColor),
                                              const SizedBox(height: 10),
                                              carInfoPlate(
                                                  title: "Год выпуска",
                                                  value: data
                                                      .carDataText.releaseYear
                                                      .toString()),
                                              const SizedBox(height: 10),
                                              carInfoPlate(
                                                  title: "Гос номер",
                                                  value: data
                                                      .carDataText.stateNumber),
                                              const SizedBox(height: 10),
                                              carInfoPlate(
                                                  title: "СТС",
                                                  value: data.carDataText.ctc),
                                            ]),
                                        const SizedBox(height: 20),
                                        ExpansionTile(
                                            title: infoText(
                                                "Выплата заработной платы"),
                                            children: [
                                              Padding(
                                                  padding:
                                                      const EdgeInsets.all(10),
                                                  child: ElevatedButton(
                                                      onPressed: () {},
                                                      child: const Text(
                                                          "Сделать выплату")))
                                            ]),
                                        const SizedBox(height: 20),
                                        ExpansionTile(
                                            title: infoText(
                                                "Начисление бонусов и комиссий"),
                                            children: [
                                              Padding(
                                                  padding:
                                                      const EdgeInsets.all(10),
                                                  child: Column(children: [
                                                    NannyTextForm(
                                                        labelText: "Бонусы",
                                                        formatters: [
                                                          FilteringTextInputFormatter
                                                              .digitsOnly
                                                        ],
                                                        keyType: TextInputType
                                                            .number,
                                                        onChanged: (text) => vm
                                                                .bonusAmount =
                                                            int.parse(text)),
                                                    TextButton(
                                                        onPressed: vm.addBonus,
                                                        child: const Text(
                                                            "Готово")),
                                                    const SizedBox(height: 20),
                                                    NannyTextForm(
                                                        labelText: "Комиссии",
                                                        formatters: [
                                                          FilteringTextInputFormatter
                                                              .digitsOnly
                                                        ],
                                                        keyType: TextInputType
                                                            .number,
                                                        onChanged: (text) => vm
                                                                .fineAmount =
                                                            int.parse(text)),
                                                    TextButton(
                                                        onPressed: vm.addFines,
                                                        child: const Text(
                                                            "Готово"))
                                                  ]))
                                            ]),
                                        const SizedBox(height: 20),
                                        ExpansionTile(
                                            title: infoText(
                                                "Просмотр бухгалтерских отчетов"),
                                            children: [])
                                      ]))))
              ]);
            },
            errorView: (context, error) =>
                ErrorView(errorText: error.toString())));
  }

  Widget infoText(String text) =>
      Text(text, style: Theme.of(context).textTheme.titleMedium);

  Widget carInfoPlate({
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.maxFinite,
      decoration: BoxDecoration(
          color: NannyTheme.secondary,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 4),
              blurRadius: 14,
              color: const Color(0xFF021C3B).withOpacity(.1),
            ),
          ]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 17.6 / 16,
              color: Color(0xFF6D6D6D),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                height: 20 / 18,
                color: NannyTheme.primary),
          ),
        ],
      ),
    );
  }
}
