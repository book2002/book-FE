import 'package:flutter/material.dart';
import 'package:flutter_app/signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();

}

class _LoginPageState extends State<LoginPage> {
  //컨트롤러
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    // TODO: implement dispose
    //메모리 누수 방지
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _logIn() {
    final id = _idController.text.trim();
    final password = _passwordController.text.trim();

    if (password == " " && id ==" ") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("아이디와 비밀번호가 일치하지 않습니다."))
      );
      return;
    }

    // TODO: 로그인 로직 구현
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("로그인 시도"))
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(title: const Text("로그인"),),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40,),
            TextField(
              controller: _idController,
              decoration: const InputDecoration(
                labelText: "id",
                border: OutlineInputBorder()
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16,),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: "비밀번호",
                border: OutlineInputBorder()
              ),
              obscureText: true,  //텍스트 가림 처리
            ),
            const SizedBox(height: 24,),
            
            ElevatedButton(onPressed: _logIn, child: const Text("로그인")),
            
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context)=>const SignupPage()),
                );
              }, 
              child: const Text("회원가입")),
          ],
        ),
      ),
    );
  }

}