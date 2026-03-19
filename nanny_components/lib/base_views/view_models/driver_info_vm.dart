import 'package:nanny_components/dialogs/loading.dart';
import 'package:nanny_components/dialogs/nanny_dialogs.dart';
import 'package:nanny_components/view_model_base.dart';
import 'package:nanny_core/api/api_models/answer_schedule_request.dart';
import 'package:nanny_core/api/nanny_franchise_api.dart';
import 'package:nanny_core/api/nanny_orders_api.dart';
import 'package:nanny_core/models/from_api/drive_and_map/schedule_responses_data.dart';
import 'package:nanny_core/nanny_core.dart';

class DriverInfoVM extends ViewModelBase {
  DriverInfoVM(
      {required super.context,
      required super.update,
      required this.id,
      required this.viewingOrder,
      this.scheduleData}) {
    if (viewingOrder) {
      assert(scheduleData != null);
      request.idSchedule = scheduleData!.idSchedule;
      request.idResponses = [scheduleData!.id];
    }
  }

  final int id;
  final bool viewingOrder;
  final ScheduleResponsesData? scheduleData;

  final AnswerScheduleRequest request = AnswerScheduleRequest();

  int bonusAmount = 0;
  int fineAmount = 0;

  Future<ApiResponse<DriverUserTextData>> get getDriver =>
      NannyOrdersApi.getDriver(id);

  void answerSchedule({required bool confirm}) async {
    LoadScreen.showLoad(context, true);
    // Бэкенд по одному id автоматически обрабатывает всю программу.
    request.flag = confirm;
    var result = await NannyOrdersApi.answerScheduleRequest(request);

    if (!context.mounted) return;
    if (!result.success) {
      LoadScreen.showLoad(context, false);
      NannyDialogs.showMessageBox(context, "Ошибка",
          "Не удалось ${confirm ? 'подтвердить' : 'отклонить'} заявку!");
      return;
    }

    LoadScreen.showLoad(context, false);
    await NannyDialogs.showMessageBox(
        context, "Успех", "Заявка ${confirm ? "одобрена" : "отклонена"}");
    popView();
  }

  void addBonus() async {
    LoadScreen.showLoad(context, true);

    bool success = await DioRequest.handleRequest(
        context, NannyFranchiseApi.addBonusMoney(id: id, amount: bonusAmount));

    if (!success) return;
    if (!context.mounted) return;

    LoadScreen.showLoad(context, false);
  }

  void addFines() async {
    LoadScreen.showLoad(context, true);

    bool success = await DioRequest.handleRequest(
        context, NannyFranchiseApi.addFinemoney(id: id, amount: fineAmount));

    if (!success) return;
    if (!context.mounted) return;

    LoadScreen.showLoad(context, false);
  }
}
