import 'package:nanny_client/views/pages/graph_create.dart';
import 'package:nanny_components/dialogs/loading.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/models/from_api/drive_and_map/schedule.dart';
import 'package:nanny_core/models/from_api/drive_and_map/schedule_responses_data.dart';
import 'package:nanny_core/models/from_api/driver_contact.dart';
import 'package:nanny_core/api/api_models/answer_schedule_request.dart';
import 'package:nanny_core/api/nanny_orders_api.dart';
import 'package:nanny_core/nanny_core.dart';

class GraphVM extends ViewModelBase {
  GraphVM({
    required super.context,
    required super.update,
  });

  String spentsInWeek = "~ 0 ₽";
  String spentsInMonth = "~ 0 ₽";

  List<Schedule> schedules = [];
  Schedule? selectedSchedule;
  DriverContact? driverContact;
  List<ScheduleResponsesData> responses = [];

  List<NannyWeekday> selectedWeekday = [
    NannyWeekday.values[DateTime.now().weekday - 1]
  ];

  Future<void> createOrEditRoute({Road? editingRoad}) async {
    if (selectedSchedule == null) return;

    var road = await NannyDialogs.showRouteCreateOrEditSheet(
        context, selectedWeekday.first,
        road: editingRoad);

    if (road == null) return;

    if (!context.mounted) return;

    LoadScreen.showLoad(context, true);

    var result = editingRoad == null
        ? await NannyOrdersApi.createScheduleRoadById(
            selectedSchedule!.id!, road)
        : await NannyOrdersApi.updateScheduleRoadById(road);

    if (!result.success) {
      if (context.mounted) {
        LoadScreen.showLoad(context, false);
        NannyDialogs.showMessageBox(context, "Ошибка", result.errorMessage);
      }

      return;
    }

    if (!context.mounted) return;

    LoadScreen.showLoad(context, false);

    NannyDialogs.showMessageBox(context, "Успех",
        editingRoad == null ? "Маршрут добавлен" : "Маршрут обновлён");
    reloadPage();
  }

  void toGraphCreate() async {
    await navigateToView(const GraphCreate());
    reloadPage();
  }

  void toGraphEdit({required Schedule schedule}) async {
    await navigateToView(GraphCreate(schedule: schedule));
    reloadPage();
  }

  void weekdaySelected(DateTime date) {
    //selectedWeekday.add(NannyWeekday.values[date.weekday - 1]);
    selectedWeekday[0] = NannyWeekday.values[date.weekday - 1];
    update(() {});
  }

  void scheduleSelected(Schedule schedule) async {
    update(() {
      selectedSchedule = schedule;
      driverContact = null; // Сбрасываем предыдущие контакты
    });
    
    // Загружаем контакты водителя
    await loadDriverContact();
  }
  
  Future<void> loadDriverContact() async {
    if (selectedSchedule == null || selectedSchedule!.id == null) return;
    
    var result = await NannyUsersApi.getDriverContact(selectedSchedule!.id!);
    if (result.success && result.response != null) {
      update(() {
        driverContact = result.response;
      });
    }
  }

  void deleteSchedule(Schedule schedule) async {
    if (!await NannyDialogs.confirmAction(context, "Удалить выбранный график?"))
      return;
    if (!context.mounted) return;

    LoadScreen.showLoad(context, true);

    var result = await NannyOrdersApi.deleteScheduleById(schedule.id!);
    if (!result.success) {
      if (context.mounted)
        NannyDialogs.showMessageBox(context, "Ошибка", result.errorMessage);
    }

    if (context.mounted) LoadScreen.showLoad(context, false);

    await reloadPage();
  }

  void tryDeleteRoad(Road road) async {
    bool confirm =
        await NannyDialogs.confirmAction(context, "Удалить выбранный маршрут?");

    if (!confirm) return;
    if (!context.mounted) return;

    LoadScreen.showLoad(context, true);

    var result = await NannyOrdersApi.deleteScheduleRoadById(road.id!);
    if (!result.success) {
      if (context.mounted) {
        LoadScreen.showLoad(context, false);
        NannyDialogs.showMessageBox(context, "Ошибка", result.errorMessage);
      }
      return;
    }

    if (context.mounted) LoadScreen.showLoad(context, false);

    reloadPage();
  }

  // FE-MVP-017: Показ QR-кода для верификации водителя
  void showDriverQR() {
    if (selectedSchedule == null || driverContact == null) {
      NannyDialogs.showMessageBox(
        context,
        "Ошибка",
        "Информация о водителе недоступна",
      );
      return;
    }

    // Генерируем данные для QR-кода
    // Формат: schedule_id:user_id:timestamp
    final qrData = '${selectedSchedule!.id}:${NannyUser.userInfo!.id}:${DateTime.now().millisecondsSinceEpoch}';

    DriverQRDialog.show(
      context,
      driverName: '${driverContact!.name} ${driverContact!.surname}',
      carNumber: driverContact!.car?.number,
      carInfo: driverContact!.car?.fullInfo,
      photoPath: driverContact!.photo,
      qrData: qrData,
    );
  }

  // FE-MVP-010: Открытие чата с водителем
  Future<void> openDriverChat() async {
    if (selectedSchedule == null) {
      NannyDialogs.showMessageBox(
        context,
        "Ошибка",
        "Выберите расписание",
      );
      return;
    }

    LoadScreen.showLoad(context, true);

    // Создаём или получаем чат с водителем
    final result = await NannyChatsApi.createDriverChat(selectedSchedule!.id!);

    if (!context.mounted) return;
    LoadScreen.showLoad(context, false);

    if (!result.success) {
      NannyDialogs.showMessageBox(
        context,
        "Ошибка",
        result.errorMessage,
      );
      return;
    }

    // Открываем экран чатов
    // Чат с водителем будет в списке чатов
    NannyDialogs.showMessageBox(
      context,
      "Успех",
      "Чат с водителем создан. Перейдите в раздел 'Чаты' для общения.",
    );
  }

  void answerResponse(ScheduleResponsesData response, bool accept) async {
    LoadScreen.showLoad(context, true);
    var result = await NannyOrdersApi.answerScheduleRequest(
      AnswerScheduleRequest(
        idSchedule: response.idSchedule,
        idResponse: response.id,
        flag: accept,
      ),
    );
    if (!context.mounted) return;
    LoadScreen.showLoad(context, false);
    if (!result.success) {
      NannyDialogs.showMessageBox(context, 'Ошибка', result.errorMessage);
      return;
    }
    NannyDialogs.showMessageBox(
      context,
      'Успех',
      accept ? 'Водитель принят' : 'Отклик отклонён',
    );
    reloadPage();
  }

  @override
  Future<bool> loadPage() async {
    var scheduleResult = await NannyOrdersApi.getSchedules();
    if (!scheduleResult.success) return false;

    schedules = scheduleResult.response!;
    selectedSchedule = schedules.firstOrNull;

    var responsesResult = await NannyOrdersApi.getScheduleResponses();
    if (responsesResult.success && responsesResult.response != null) {
      responses = responsesResult.response!;
    }

    return true;
  }
}
