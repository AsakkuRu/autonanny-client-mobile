import 'package:flutter/material.dart';
import 'package:nanny_client/views/new_main/new_home_view.dart';

/// Legacy entry point kept for older navigation paths.
/// The actual client shell now lives in [NewHomeView].
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return const NewHomeView();
  }
}
