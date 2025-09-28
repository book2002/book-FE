import 'package:flutter/material.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  //컨트롤러
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  //라디오 버튼 초기값 설정
  String? _sexValue;        //? -> null 값 허용, null 초기화

  @override
  void dispose() {
    // TODO: implement dispose
    //메모리 누수 방지
    _usernameController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _signUp() {
    final username = _usernameController.text.trim();
    final id = _idController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("비밀번호가 일치하지 않습니다."))
      );
      return;
    }

    // TODO: 회원가입 로직 구현
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("회원가입 시도"))
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(title: const Text("회원가입"),),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: "username",
                border: OutlineInputBorder()
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16,),
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
            const SizedBox(height: 16,),
            TextField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(
                labelText: "비밀번호 확인",
                border: OutlineInputBorder()
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16,),
            const Text("성별", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            // 첫 번째 라디오 버튼 (여성)
            RadioListTile<String>(
              title: const Text("여성"),
              value: 'female',
              groupValue: _sexValue,
              onChanged: (String? value) {
                setState(() {
                  _sexValue = value;
                });
              },
            ),
            // 두 번째 라디오 버튼 (남성)
            RadioListTile<String>(
              title: const Text("남성"),
              value: 'male',
              groupValue: _sexValue,
              onChanged: (String? value) {
                setState(() {
                  _sexValue = value;
                });
              },
            ),
            // 세 번째 라디오 버튼 (선택 안 함)
            RadioListTile<String>(
              title: const Text("선택 안 함"),
              value: 'none',
              groupValue: _sexValue,
              onChanged: (String? value) {
                setState(() {
                  _sexValue = value;
                });
              },
            ),
            const SizedBox(height: 24,),
            ElevatedButton(onPressed: _signUp, child: const Text("회원가입"))
          ],
        ),
      ),
    );
  }
}