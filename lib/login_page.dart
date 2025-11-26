import 'package:flutter/material.dart';
import 'package:flutter_app/constants.dart';
import 'package:flutter_app/google_auth_webview.dart';
import 'package:flutter_app/models/auth_model.dart';
import 'package:flutter_app/profile_setting_page.dart';
import 'package:flutter_app/service/auth_service.dart';
import 'package:flutter_app/signup_page.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:http/http.dart' as http;
import 'dart:convert'; // JSON 인코딩/디코딩

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();

}

class _LoginPageState extends State<LoginPage> {
  // 폼 키 추가
  final _formKey = GlobalKey<FormState>();

  // 컨트롤러
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  // 비밀번호 숨김/표시 상태 변수 추가
  bool _isPasswordObscured = true;

  bool _isLoading = false; // 로딩 상태 표시용

  @override
  void dispose() {
    //메모리 누수 방지
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _logIn() async {
    final email = _idController.text;
    final password = _passwordController.text;

    if (password.isEmpty || email.isEmpty) {
      print("로그인 시도");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      //final url = Uri.parse("http://172.30.1.53:8080/api/v1/member/signup");
      final url = Uri.parse("$baseUrl/api/v1/member/login");

      final loginRequest = LoginRequest(email: email, password: password);

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(loginRequest.toJson()),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        final loginResponse = LoginResponse.fromJson(jsonResponse);
        
        // 서버로부터 받은 토큰을 AuthService로 storage에 저장
        if (loginResponse.accessToken.isNotEmpty) {
          await _authService.login(loginResponse.accessToken, loginResponse.refreshToken);
          print("토큰 저장 성공"); // 디버깅용
        } else {
          print("경고: 서버 응답에 accessToken이 없습니다.");
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("로그인 성공! $response"))
        );

        print(loginResponse.isNewUser);
        // 모델의 isNewUser 필드로 NewUser 여부 확인
        if (loginResponse.isNewUser) {
          //프로필 생성 화면으로 이동
          Navigator.pushReplacement( // 로그인 페이지로 다시 돌아오지 않도록 'Replacement' 사용
            context,
            MaterialPageRoute(
              builder: (context) => const ProfileSetupPage(),
            ),
          );
        } else {
          Navigator.pop(context);   // 홈화면으로 돌아감
        }

      } else {
        // 400 오류 등 다른 상태 코드 처리
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody["message"] ?? "로그인에 실패했습니다.";
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage))
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("오류 발생: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 구글 로그인 함수
  Future<void> _signInWithGoogle() async {
    //웹 브라우저(혹은 웹뷰)가 해당 주소를 GET 방식으로 방문하는 방식
    //flutter_inappwebview 사용

    //웹뷰 이동 -> 결과 기다림
    final googleToken = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GoogleAuthWebViewPage(initialUrl: googleApiUrl),
      ),
    );

    if (googleToken != null) {
      if (mounted) {
        print("구글 로그인 시도");
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Google 로그인을 취소했습니다."))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,

        title: const Text(
          "로그인",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,    //title 중앙정렬

        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new), //뒤로가기 아이콘 변경
          onPressed: () {
            Navigator.pop(context);   //뒤로가기 기능 유지
          },
        ),
        
        //하단 구분선 추가
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey.shade300,
            height: 1.0,
          ),
        ),
      ),
      // 키보드가 올라옴으로 화면이 깨지는 것을 방지하기 위해 SingleChildScrollView 사용
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUnfocus,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40,),
                TextField(
                  controller: _idController,
                  decoration: const InputDecoration(
                    labelText: "이메일",
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primaryColor, width: 1.8)
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16,),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: "비밀번호",
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primaryColor, width: 1.8)
                    ),

                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordObscured ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        //setState 호출로 상태 변경
                        setState(() {
                          _isPasswordObscured = !_isPasswordObscured;
                        });
                      },
                      padding: EdgeInsets.only(right: 15),
                    )
                  ),
                  obscureText: _isPasswordObscured,  //텍스트 가림 처리

                  
                ),
                const SizedBox(height: 24,),
                
                ElevatedButton(
                  onPressed: _isLoading ? null : _logIn,    //로딩 중 비활성화
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    elevation: 0,
                  ),
                  child: _isLoading
                    // 로딩 중일 때 스피너 표시
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        "로그인",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                ),
                
                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("아직 회원이 아니신가요?"),
                    SizedBox(width: 15,),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (context)=>const SignupPage()),
                        );
                      },
                      child: Text(
                        "회원가입 하기",
                        style: TextStyle(
                          color: primaryColor,
                          decorationColor: primaryColor,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    )
                  ],
                ),

                // google 로그인 섹션
                const SizedBox(height: 40,),
                // "또는" 구분선
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade400)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        "OR", 
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade400)),
                  ],
                ),
                const SizedBox(height: 20),

                // Google 로그인 버튼
                OutlinedButton.icon(
                  icon: const FaIcon(FontAwesomeIcons.google, color: Colors.red),
                  label: const Text(
                    "Google 계정으로 로그인",
                    style: TextStyle(
                      color: Colors.black87, 
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade400, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _signInWithGoogle, // ✅ 새 함수 연결
                ),
              ],
            ),
          )
        ),

      )
          );
  }

}