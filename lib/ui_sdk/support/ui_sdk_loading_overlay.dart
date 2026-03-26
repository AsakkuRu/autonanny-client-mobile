import 'dart:async';

import 'package:autonanny_ui_core/autonanny_ui_core.dart';
import 'package:flutter/material.dart';

class LoadScreen {
  static BuildContext? _lastContext;
  static Completer<void>? _showCompleter;
  static bool _visible = false;

  static Future<void> showLoad(BuildContext context, bool show) async {
    if (show) {
      if (_visible) return;

      final pending = _showCompleter;
      if (pending != null) {
        await pending.future;
        return;
      }

      if (_lastContext != null && _lastContext!.mounted) {
        await Navigator.of(_lastContext!).maybePop();
      }

      _lastContext = null;
      final completer = Completer<void>();
      _showCompleter = completer;

      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          _lastContext = dialogContext;
          _visible = true;
          if (!completer.isCompleted) {
            completer.complete();
          }

          final colors = dialogContext.autonannyColors;
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.all(48),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(AutonannySpacing.xl),
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  borderRadius: AutonannyRadii.brXl,
                ),
                child: CircularProgressIndicator(
                  color: colors.actionPrimary,
                ),
              ),
            ),
          );
        },
      ).whenComplete(() {
        _visible = false;
        _lastContext = null;
        if (!completer.isCompleted) {
          completer.complete();
        }
        if (identical(_showCompleter, completer)) {
          _showCompleter = null;
        }
      });

      await completer.future;
      return;
    }

    final pending = _showCompleter;
    if (pending != null && !pending.isCompleted) {
      await pending.future;
    }

    if (_lastContext != null && _lastContext!.mounted) {
      try {
        await Navigator.of(_lastContext!).maybePop();
      } catch (_) {}
    }

    _visible = false;
    _lastContext = null;
    _showCompleter = null;
  }
}
