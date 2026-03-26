import 'package:autonanny_ui_core/autonanny_ui_core.dart';
import 'package:flutter/material.dart';
import 'package:nanny_components/base_views/views/route_sheet.dart';
import 'package:nanny_core/models/from_api/drive_and_map/schedule.dart';
import 'package:nanny_core/nanny_core.dart';

class NannyDialogs {
  static Future<void> showMessageBox(
    BuildContext context,
    String title,
    String msg, {
    String buttonText = 'Продолжить',
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        backgroundColor: Colors.transparent,
        child: AutonannyDialogSurface(
          title: title.isEmpty ? null : title,
          actions: [
            AutonannyButton(
              label: buttonText,
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
          child: msg.isEmpty
              ? const SizedBox.shrink()
              : Text(
                  msg,
                  textAlign: TextAlign.center,
                  style: AutonannyTypography.bodyM(
                    color: dialogContext.autonannyColors.textSecondary,
                  ),
                ),
        ),
      ),
    );
  }

  static Future<bool> showModalDialog({
    required BuildContext context,
    required Widget child,
    String? title,
    List<Widget>? actions,
    bool hasDefaultBtn = true,
  }) async {
    return (await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            final resolvedActions = <Widget>[
              ...?actions,
              if (hasDefaultBtn)
                AutonannyButton(
                  label: 'Ок',
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                ),
            ];

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              backgroundColor: Colors.transparent,
              child: AutonannyDialogSurface(
                title: title,
                actions: resolvedActions,
                child: child,
              ),
            );
          },
        )) ??
        false;
  }

  static Future<bool> confirmAction(
    BuildContext context,
    String prompt, {
    String title = 'Подтверждение действия',
    String confirmText = 'Ок',
    String cancelText = 'Отмена',
  }) async {
    return (await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            backgroundColor: Colors.transparent,
            child: AutonannyDialogSurface(
              title: title,
              actions: [
                AutonannyButton(
                  label: confirmText,
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                ),
                AutonannyButton(
                  label: cancelText,
                  variant: AutonannyButtonVariant.secondary,
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                ),
              ],
              child: Text(
                prompt,
                textAlign: TextAlign.center,
                style: AutonannyTypography.bodyM(
                  color: dialogContext.autonannyColors.textSecondary,
                ),
              ),
            ),
          ),
        )) ??
        false;
  }

  static Future<RouteSheetResult?> showRouteCreateOrEditSheet(
    BuildContext context,
    NannyWeekday weekday, {
    Road? road,
    int? tariffId,
    List<NannyWeekday>? allSelectedWeekdays,
    bool applyToAllDaysDefault = true,
  }) async {
    return showModalBottomSheet<RouteSheetResult>(
      context: context,
      enableDrag: false,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: RouteSheetView(
          weekday: weekday,
          road: road,
          tariffId: tariffId,
          allSelectedWeekdays: allSelectedWeekdays,
          applyToAllDaysDefault: applyToAllDaysDefault,
        ),
      ),
    );
  }
}
