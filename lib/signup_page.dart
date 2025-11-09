import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';          //DateFormat 사용을 위한 intl 패키지
//flutter pub add intl로 다운로드 후 사용

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
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  //라디오 버튼 초기값 설정
  String? _sexValue;        //? -> null 값 허용, null 초기화

  //생년월일 저장 변수
  DateTime? _dateTime;

  void _showCupertinoDatePicker(BuildContext context) async {
    DateTime tempPickedDate = _dateTime ?? DateTime(2000);    //임시 날짜 저장

    showModalBottomSheet(
      context: context, 
      shape: const RoundedRectangleBorder(  //둥근 모서리 설정
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))
      ),
      builder: (BuildContext builder) {
        return Container(
          color: Colors.white,
          height: 300,
          child: Column(
            children: [
              //상단 버튼
              SizedBox(
                height: 50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("취소"),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _dateTime = tempPickedDate;   //최종 날짜 전달
                        });
                        Navigator.pop(context);
                      },
                      child: const Text("확인"),
                    ),
                    
                  ],
                ),
              ),

              Expanded(
                child: BirthDatePicker(
                  initDateStr: _dateTime == null
                      ? '2000-01-01'
                      : DateFormat('yyyy-MM-dd').format(_dateTime!),
                  onDateTimeChanged: (DateTime newDate) {
                    setState(() {
                      tempPickedDate = newDate;   //임시 날짜 업데이트
                    });
                  },
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  // void _selectDate(BuildContext context) async {
  //   final DateTime? pickedDate = await showDatePicker(
  //     context: context,
  //     initialDate: DateTime(2000),  //기본 표시 날짜
  //     firstDate: DateTime(1900),    //선택 가능한 가장 오랜 날짜
  //     lastDate: DateTime.now(),     //선택 가능한 가장 늦은 날짜 -> 현재로 지정
  //     helpText: '생년월일',         //다이얼로그 상단 문구
  //     cancelText: '취소',           //취소 버튼 문구
  //     confirmText: '확인',          //확인 버튼 문구
  //   );

  //   if (pickedDate != null && pickedDate != _dateTime) {
  //     setState(() {
  //       _dateTime = pickedDate;
  //     });
  //   }
  // }

  @override
  void dispose() {
    // TODO: implement dispose
    //메모리 누수 방지
    _emailController.dispose();
    _usernameController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _signUp() {

    final formState = _formKey.currentState;
    if (formState == null) {
      //form key 연결되지 않았을 경우 대비
      debugPrint("⚠️ FormState is null. Form이 key에 연결되지 않았을 가능성이 있습니다.");
      return;
    }

    if (!_formKey.currentState!.validate()) {
      // 폼 검증 실패 시 함수 종료
      return;
    }

    final email = _emailController.text.trim();
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
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(    // 추후 변경될 가능성이 있으므로 const 사용 x
                  labelText: "email",
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00AA00), width: 1.8)
                  ),

                  //오류 시 테두리 style 지정
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: const Color(0xFFCC0000), width: 1.5)
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: const Color(0xFFCC0000), width: 2.5)
                  ),

                  //오류 메시지 style 지정
                  errorStyle: TextStyle(
                    color: const Color(0xFFCC0000),
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
                controller: _idController,
                decoration: const InputDecoration(
                  labelText: "id",
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00AA00), width: 1.8)
                  )
                ),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 18,),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: "비밀번호",
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00AA00), width: 1.8)
                  )
                ),
                obscureText: true,  //텍스트 가림 처리
              ),
              const SizedBox(height: 18,),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: "비밀번호 확인",
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00AA00), width: 1.8)
                  )
                ),
                obscureText: true,
              ),
              const SizedBox(height: 18,),
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
              const SizedBox(height: 16,),
              GestureDetector(
                onTap: ()=>_showCupertinoDatePicker(context),
                child: AbsorbPointer(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: '2000-01-01',
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    controller: TextEditingController(
                      text: _dateTime==null
                      ? ''
                      : "${_dateTime!.year}-${_dateTime!.month.toString().padLeft(2, '0')}-${_dateTime!.day.toString().padLeft(2, '0')}",
                    ),
                    readOnly: true,
                  ),
                ),
              ),
              const SizedBox(height: 24,),
              ElevatedButton(onPressed: _signUp, child: const Text("회원가입"))
            ],
          ),
        )
        
      ),
    );
  }
}