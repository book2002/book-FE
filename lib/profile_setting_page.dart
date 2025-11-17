import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/constants.dart'; // primaryColor, API URL 등
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // 1. http_parser 임포트
import 'dart:convert';
import 'package:intl/intl.dart'; // 날짜 포맷을 위해 추가

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// --- 1단계: 필수 정보 입력 페이지 (닉네임, 생년월일, 성별) ---
class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class BirthDatePicker extends StatelessWidget {
  final void Function(DateTime) onDateTimeChanged;
  final DateTime? initialDate; 

  const BirthDatePicker({
    super.key,
    required this.onDateTimeChanged,
    this.initialDate,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: CupertinoDatePicker(
        minimumYear: 1900,
        maximumYear: DateTime.now().year,
        initialDateTime: initialDate ?? DateTime(2000),   //초기 날짜
        maximumDate: DateTime.now(),
        onDateTimeChanged: onDateTimeChanged,
        mode: CupertinoDatePickerMode.date,
        //locale: const Locale('ko', 'KR'),
      ),
    );
  }
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _birthController = TextEditingController(); // 날짜 표기용

  //생년월일 저장 변수
  DateTime? _dateTime;

  String? _selectedGender;
  bool _isLoading = false;

  // Secure Storage 인스턴스 생성
  final _storage = const FlutterSecureStorage();

  @override
  void dispose() {
    _nicknameController.dispose();
    _birthController.dispose();
    super.dispose();
  }

  // --- 날짜 선택 (Date Picker) ---
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
                          _birthController.text =       //텍스트 필드 업데이트
                            DateFormat('yyyy년 MM월 dd일').format(_dateTime!);
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
                  initialDate: _dateTime,
                  onDateTimeChanged: (DateTime newDate) {
                    tempPickedDate = newDate;   //임시 날짜 업데이트
                  },
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  // --- 1단계 제출 (필수 정보 API 전송) ---
  Future<void> _submitStep1() async {
    // 1. 폼 유효성 검사
    if (!_formKey.currentState!.validate()) {
      return; // 유효하지 않으면 중단
    }

    // 2. 로딩 시작
    setState(() { _isLoading = true; });

    try {
      // API 호출 전 토큰 읽어오기
      final String? accessToken = await _storage.read(key: 'accessToken');

      if (accessToken == null) {
        // 토큰이 없는 비정상 상황.
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("인증 정보가 만료되었습니다. 다시 로그인해주세요.")),
        );
        // 로그인 페이지로 강제 이동 (모든 스택 제거 후 홈으로 이동 -> 홈에서 인증 체크)
         Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }

      // API 호출
      // http.post 대신 http.MultipartRequest 사용
      final url = Uri.parse(profileSetupApiUrl);
      var request = http.MultipartRequest('POST', url);
      
      // 헤더에 토큰 추가
      request.headers['Authorization'] = "Bearer $accessToken";

      // 폼 유효성 검사를 통과했으므로 _dateTime과 _selectedGender는 null이 아님
      // --- 서버 DTO에 맞게 JSON 생성 ---
      Map<String, String?> dtoMap = {
        "nickname": _nicknameController.text,
        // 'yyyyMMdd' 형식
        "birth": _dateTime != null ? DateFormat('yyyyMMdd').format(_dateTime!) : null,
        "gender": _selectedGender,
        // 1단계에서는 bio를 빈 문자열으로 전송
        "bio": "" 
      };

      // DTO Map을 JSON 문자열로 변환하여 'request' 파트로 추가
      request.files.add(
        http.MultipartFile.fromString(
          'request',
          jsonEncode(dtoMap),
          contentType: MediaType('application', 'json')
        )
      );

      // 요청 전송 및 응답 처리
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        // 성공 시 2단계(Bio) 페이지로 이동
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("프로필 저장 성공! 다음 단계로 이동합니다.")),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BioSetupPage()),
        );
      } else {
        // 실패 시
        final errorBody = jsonDecode(response.body);
        print(errorBody);
        final errorMessage = errorBody["message"] ?? "프로필 저장에 실패했습니다. (코드: ${response.statusCode})";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("오류 발생: $e")),
      );
    } finally {
      // 6. 로딩 종료
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("프로필 설정 (1/2)", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade300, height: 1.0),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUnfocus,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    "환영합니다! \n서비스 이용을 위한 필수 정보를 입력해주세요.",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 40),

                // --- 닉네임 ---
                TextFormField(
                  controller: _nicknameController,
                  decoration: const InputDecoration(
                    labelText: "닉네임",
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primaryColor, width: 1.8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "닉네임을 입력해주세요.";
                    }
                    if (value.trim().length < 2 || value.trim().length > 20) {
                      return "닉네임은 2자 이상 20자 이하로 입력해주세요.";
                    }
                    // TODO: 닉네임 중복 검사 API 연동
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // --- 생년월일 (Date Picker) ---
                TextFormField(
                  controller: _birthController,
                  readOnly: true, // 직접 입력을 막고 탭만 가능하게
                  decoration: const InputDecoration(
                    labelText: "생년월일",
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primaryColor, width: 1.8),
                    ),
                    suffixIcon: Icon(Icons.calendar_month),
                  ),
                  onTap: () => _showCupertinoDatePicker(context),   //Cupertino 피커 호출
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "생년월일을 선택해주세요.";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // --- 성별 ---
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: const InputDecoration(
                    labelText: "성별",
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primaryColor, width: 1.8),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: "MALE", child: Text("남성")),
                    DropdownMenuItem(value: "FEMALE", child: Text("여성")),
                    DropdownMenuItem(value: "NONE", child: Text("선택 안함")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return "성별을 선택해주세요.";
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                
                const SizedBox(height: 40),

                // --- 다음 버튼 ---
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitStep1,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                        )
                      : Text(
                          "다음",
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- 2단계: 선택 정보 입력 페이지 (Bio) ---
class BioSetupPage extends StatefulWidget {
  const BioSetupPage({super.key});

  @override
  State<BioSetupPage> createState() => _BioSetupPageState();
}

class _BioSetupPageState extends State<BioSetupPage> {
  final _bioController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  // --- 홈 화면으로 이동 (로그인 스택 모두 제거) ---
  void _goToHome() {
    // 로그인 페이지, 1단계, 2단계 페이지를 모두 스택에서 제거하고 홈으로 이동
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // --- 2단계 제출 (Bio 정보 API 전송) ---
  Future<void> _submitStep2() async {
    if (_bioController.text.trim().isEmpty) {
      // Bio가 비어있으면 그냥 '완료' (홈으로)
      _goToHome();
      return;
    }

    setState(() { _isLoading = true; });

    // try {
    //   // TODO: API 호출
    //   // 1단계와 마찬가지로 Authorization 헤더 필요
    //   final url = Uri.parse(bioSetupApiUrl);
    //   final response = await http.put( // 또는 POST
    //     url,
    //     headers: {
    //       "Content-Type": "application/json",
    //       // "Authorization": "Bearer YOUR_AUTH_TOKEN", // ✅ 실제 구현 시 주석 해제
    //     },
    //     body: jsonEncode({
    //       "bio": _bioController.text,
    //     }),
    //   );

    //   if (!mounted) return;

    //   if (response.statusCode == 200 || response.statusCode == 201) {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       const SnackBar(content: Text("자기소개가 저장되었습니다! 환영합니다.")),
    //     );
    //   } else {
    //      ScaffoldMessenger.of(context).showSnackBar(
    //       const SnackBar(content: Text("자기소개 저장에 실패했습니다. (나중에 다시 시도해주세요)")),
    //     );
    //   }
    // } catch (e) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text("오류 발생: $e")),
    //   );
    // } finally {
    //   // API 성공/실패 여부와 관계없이 홈으로 이동
    //   setState(() { _isLoading = false; });
    //   _goToHome();
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("프로필 설정 (2/2)", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        automaticallyImplyLeading: false, // 1단계로 돌아가는 '뒤로가기' 버튼 숨김
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade300, height: 1.0),
        ),
        actions: [
          // --- 건너뛰기 버튼 ---
          TextButton(
            onPressed: _goToHome, // 누르면 바로 홈으로
            child: const Text(
              "건너뛰기",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text(
                "마지막 단계입니다. \n자신을 소개하는 글을 작성해보세요.",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 40),

              // --- (주석) 향후 프로필/헤더 이미지 추가 영역 ---
              /*
              Container(
                height: 150,
                color: Colors.grey.shade200,
                child: Center(child: Text("프로필/헤더 이미지 업로더 영역")),
              ),
              const SizedBox(height: 24),
              */
              // --- (주석) ---

              // --- Bio 입력 ---
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: "자기소개 (선택)",
                  hintText: "관심사, 좋아하는 것 등을 자유롭게 적어주세요.",
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: primaryColor, width: 1.8),
                  ),
                ),
                maxLines: 5, // 여러 줄 입력
                maxLength: 200, // 최대 200자
              ),
              const SizedBox(height: 40),

              // --- 완료 버튼 ---
              ElevatedButton(
                onPressed: _isLoading ? null : _submitStep2,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                      )
                    : Text(
                        "완료",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                      ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}