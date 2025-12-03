import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:Readly/constants.dart';
import 'package:Readly/models/auth_model.dart';

import 'package:intl/intl.dart';          //DateFormat 사용을 위한 intl 패키지
//flutter pub add intl로 다운로드 후 사용

import 'package:http/http.dart' as http;
import 'dart:convert'; // JSON 인코딩/디코딩

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  State<SignupPage> createState() => _SignupPageState();
}

//BirthDatePicker 클래스 추가
class BirthDatePicker extends StatelessWidget {
  final void Function(DateTime) onDateTimeChanged;
  final String? initDateStr;

  const BirthDatePicker({
    //Key? key,
    required this.onDateTimeChanged,
    required this.initDateStr,
  });

  @override
  Widget build(BuildContext context) {
    final initDate =
        DateFormat('yyyy-MM-dd').parse(initDateStr ?? '2000-01-01');
    return SizedBox(
      height: 300,
      child: CupertinoDatePicker(
        minimumYear: 1900,
        maximumYear: DateTime.now().year,
        initialDateTime: initDate,
        maximumDate: DateTime.now(),
        onDateTimeChanged: onDateTimeChanged,
        mode: CupertinoDatePickerMode.date,
        //locale: const Locale('ko', 'KR'),
      ),
    );
  }
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();    //폼 전체 관리를 위한 키 추가

  //컨트롤러
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false; // 로딩 상태 표시용

  // 비밀번호 숨김/표시 상태 변수 추가
  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;

  //회원가입 성공 시 호출할 다이얼로그 함수
  Future<void> _showSignupSuccessDialog() async {
    //async 작업 후 context 사용 시, 위젯이 여전히 마운트되어 있는지 확인
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,    //바깥쪽 탭해도 닫히지 않게 설정
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          // 둥근 모서리
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
          ),
          backgroundColor: Colors.white, // 배경 하얗게
          contentPadding: EdgeInsets.symmetric(horizontal: 60, vertical: 20),
          title: const Text(
            "회원가입 성공!",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "로그인 화면으로 이동하시겠어요?",
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center, // 버튼 중앙 정렬
          actions: [
            // "아니요" 버튼
            TextButton(
              child: const Text("아니요", style: TextStyle(color: Colors.grey)),
              onPressed: () {
                // 1. 다이얼로그만 닫기
                Navigator.of(dialogContext).pop();
                
                // 2. 홈 화면 이동
                // popUntil 사용 -> 스택 맨 밑의 메인 화면으로 돌아감
                // route.isFirst = 스택 맨 밑의 메인 화면
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
            // "예" 버튼
            TextButton(
              child: const Text("예", style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                // 1. 다이얼로그 닫기
                Navigator.of(dialogContext).pop();
                
                // 2. 회원가입창을 닫고 로그인 페이지로 이동
                Navigator.of(context).pop();
              },
            ),
          ]
        );
      },
    );
  }

  @override
  void dispose() {
    //메모리 누수 방지
    _emailController.dispose();
    _nameController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final formState = _formKey.currentState;
    if (formState == null) {
      //form key 연결되지 않았을 경우 대비
      debugPrint("⚠️ FormState is null. Form이 key에 연결되지 않았을 가능성이 있습니다.");
      return;
    }

    if (!formState.validate()) {
      // 폼 검증 실패 시 함수 종료
      return;
    }

    final email = _emailController.text.trim();
    final name = _nameController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("비밀번호가 일치하지 않습니다."))
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse("$baseUrl/api/v1/member/signup");    //웹 환경에서는 localhost 사용

      final memberRequest = MemberRequest(email: email, password: password, name: name);
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(memberRequest.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // 응답 데이터를 MemberResponse 모델로 변환하여 처리
        final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        final memberResponse = MemberResponse.fromJson(jsonResponse);

        // 디버깅용 로그: 서버가 반환한 회원 ID와 상태 확인
        print("회원가입 완료 - ID: ${memberResponse.memberId}, Status: ${memberResponse.status}");

        _showSignupSuccessDialog();   //회원가입 확인창
      } else {
        // 400 오류 등 다른 상태 코드 처리
        String errorMessage = "회원가입에 실패했습니다.";
        try {
           final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
           errorMessage = errorBody["message"] ?? errorMessage;
        } catch (_) {
           // JSON 파싱 실패 시 raw body 사용
           errorMessage = response.body;
        }
        
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "회원가입",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new), //뒤로가기 아이콘 변경
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            // 실시간 유효성 검사 모드 -> 입력 후 다른 곳 터치 시 자동으로 유효성 검사 수행
            autovalidateMode: AutovalidateMode.onUnfocus,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(    // 추후 변경될 가능성이 있으므로 const 사용 x
                    labelText: "이메일",
                    border: const OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primaryColor, width: 1.8)
                    ),

                    //오류 시 테두리 style 지정
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: errorColor, width: 1.5)
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: errorColor, width: 2.5)
                    ),

                    //오류 메시지 style 지정
                    errorStyle: TextStyle(
                      color: errorColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  keyboardType: TextInputType.emailAddress,   //키보드 스타일 지정

                  //Form 위젯과 함께 사용 - 사용자 입력이 유효한지 실시간으로 확인
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '이메일을 입력해주세요.'; // 1. 입력이 비어있을 때 표시할 문구
                    }
                    // 이메일 형식 검사를 위한 정규식
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value)) {
                      return '유효한 이메일 형식이 아닙니다.'; // 2. 형식 오류
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 18,),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "이름",
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primaryColor, width: 1.8)
                    ),

                    //오류 시 테두리 style 지정
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: errorColor, width: 1.5)
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: errorColor, width: 2.5)
                    ),

                    //오류 메시지 style 지정
                    errorStyle: TextStyle(
                      color: errorColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  keyboardType: TextInputType.text,

                  //사용자 입력이 유효한지 실시간으로 확인
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '이름을 입력해주세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18,),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _isPasswordObscured,  //텍스트 가림 처리
                  decoration: InputDecoration(
                    labelText: "비밀번호",
                    border: const OutlineInputBorder(),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: primaryColor, width: 1.8)
                    ),

                    //오류 시 테두리 style 지정
                    errorBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: errorColor, width: 1.5)
                    ),
                    focusedErrorBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: errorColor, width: 2.5)
                    ),

                    //오류 메시지 style 지정
                    errorStyle: const TextStyle(
                      color: errorColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
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

                  //사용자 입력이 유효한지 실시간으로 확인
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호를 입력해주세요.'; // 1. 입력이 비어있을 때 표시할 문구
                    }
                    if (value.length < 8) {
                      return '비밀번호를 8자 이상 입력하세요.'; // 2. 형식 오류
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 18,),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _isConfirmPasswordObscured,
                  decoration: InputDecoration(
                    labelText: "비밀번호 확인",
                    border: const OutlineInputBorder(),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: primaryColor, width: 1.8)
                    ),

                    //오류 시 테두리 style 지정
                    errorBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: errorColor, width: 1.5)
                    ),
                    focusedErrorBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: errorColor, width: 2.5)
                    ),

                    //오류 메시지 style 지정
                    errorStyle: const TextStyle(
                      color: errorColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),

                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordObscured ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        //setState 호출로 상태 변경
                        setState(() {
                          _isConfirmPasswordObscured = !_isConfirmPasswordObscured;
                        });
                      },
                      padding: EdgeInsets.only(right: 15),
                    )
                  ),

                  validator: (value) {
                    if (value != _passwordController.text.trim()) {
                      return '비밀번호가 일치하지 않습니다.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 24,),
                ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,   //로딩 중일 경우 버튼 비활성화
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 20),
                    elevation: 0,
                  ),
                  child: _isLoading
                  ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  ) 
                  : Text(
                    "회원가입",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 ? 20 : 0),
              ],
            ),
          )
        ),
      ),
    );
  }
}