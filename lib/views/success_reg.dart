import 'package:flutter/material.dart';
import 'package:nanny_client/views/home.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/nanny_core.dart';

class SuccessRegView extends StatelessWidget {
  const SuccessRegView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('packages/nanny_components/assets/images/connection.png'),
            const Text("Вы успешно зарегистрировались!"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeView()),
                (route) => false,
              ),
              child: const Text("Продолжить"),
            ),
          ],
        ),
      ),
    );
  }
}