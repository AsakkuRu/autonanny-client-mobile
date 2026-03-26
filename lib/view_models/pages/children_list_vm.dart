import 'package:nanny_client/views/pages/child_edit.dart';
import 'package:nanny_client/ui_sdk/support/ui_sdk_dialogs.dart';
import 'package:nanny_client/ui_sdk/support/ui_sdk_loading_overlay.dart';
import 'package:nanny_client/ui_sdk/support/ui_sdk_view_model_base.dart';
import 'package:nanny_core/models/from_api/child.dart';
import 'package:nanny_core/nanny_core.dart';

class ChildrenListVM extends ViewModelBase {
  ChildrenListVM({
    required super.context,
    required super.update,
  });

  List<Child> children = [];

  @override
  Future<bool> loadPage() async {
    var result = await NannyChildrenApi.getChildren();
    if (!result.success || result.response == null) return false;

    children = result.response!;
    return true;
  }

  Future<void> addChild() async {
    await navigateToView(const ChildEditView());
    reloadPage();
  }

  Future<void> editChild(Child child) async {
    await navigateToView(ChildEditView(child: child));
    reloadPage();
  }

  Future<void> deleteChild(Child child) async {
    final confirmed = await NannyDialogs.confirmAction(
      context,
      "Удалить профиль ребенка \"${child.fullName}\"?",
    );

    if (!confirmed || !context.mounted) return;

    LoadScreen.showLoad(context, true);

    final result = await NannyChildrenApi.deleteChild(child.id!);

    if (!context.mounted) return;
    LoadScreen.showLoad(context, false);

    if (!result.success) {
      await NannyDialogs.showMessageBox(
        context,
        "Ошибка",
        result.errorMessage,
      );
      return;
    }

    await NannyDialogs.showMessageBox(
      context,
      "Успех",
      "Профиль ребенка удален",
    );
    reloadPage();
  }
}
