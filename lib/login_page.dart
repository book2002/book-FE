import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: const Text("로그인"),
      ),
      body: const Center(
        child: Text("login test"),
      ),
    );

    throw UnimplementedError();
  }
}