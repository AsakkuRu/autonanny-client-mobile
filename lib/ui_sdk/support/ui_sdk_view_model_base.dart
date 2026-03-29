import 'package:flutter/material.dart';

class ViewModelBase {
  ViewModelBase({
    required this.context,
    required this.update,
  }) {
    _loadRequest = loadPage();
  }

  final BuildContext context;
  final void Function(VoidCallback fun) update;

  Future<void> navigateToView(Widget view) async => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => view),
      );

  Future<void> slideNavigateToView(
    Widget view, {
    Offset beginOffset = const Offset(0, 1),
  }) async =>
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => view,
          transitionsBuilder: (_, animation, __, child) {
            const end = Offset.zero;
            final tween = Tween(begin: beginOffset, end: end);
            final curve = CurveTween(curve: Curves.easeInOut);
            return SlideTransition(
              position: animation.drive(tween.chain(curve)),
              child: child,
            );
          },
        ),
      );

  void popView() => Navigator.of(context).maybePop();

  Future<bool> _loadRequest = Future.value(true);
  Future<bool> get loadRequest => _loadRequest;

  Future<bool> loadPage() async => true;

  Future<void> reloadPage() async {
    _loadRequest = loadPage();
    update(() {});
    await _loadRequest;
  }

  void dispose() {}
}
