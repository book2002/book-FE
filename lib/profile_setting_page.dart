import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/constants.dart'; // primaryColor, API URL 등
import 'package:flutter_app/models/profile_model.dart';
import 'package:flutter_app/service/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // http_parser 임포트
import 'dart:convert';
import 'package:intl/intl.dart'; // 날짜 포맷을 위해 추가

import 'dart:io';   // 네이티브용 FileImage를 위해 임포트
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // kIsWeb 임포트

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

  // AuthService 인스턴스 생성
  final AuthService _authService = AuthService();

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
      final String? accessToken = await _authService.getAccessToken();

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
      final url = Uri.parse("$baseUrl/api/v1/profile/create");
      var request = http.MultipartRequest('POST', url);
      
      // 헤더에 토큰 추가
      request.headers['Authorization'] = "Bearer $accessToken";

      // 폼 유효성 검사를 통과했으므로 _dateTime과 _selectedGender는 null이 아님
      // --- 서버 DTO에 맞게 JSON 생성 ---
      final profileRequest = ProfileRequest(
        nickname: _nicknameController.text, 
        birth: _dateTime != null ? DateFormat('yyyyMMdd').format(_dateTime!) : "", 
        gender: _selectedGender!, 
        bio: "",    // 1단계에서는 bio 설정 x
      );

      // 모델의 joJson 사용해 JSON 문자열로 변환하여 'request' 파트로 추가
      request.files.add(
        http.MultipartFile.fromString(
          'request',
          jsonEncode(profileRequest.toJson()),
          contentType: MediaType('application', 'json')
        )
      );

      // 요청 전송 및 응답 처리
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        // [변경] 응답 데이터를 ProfileResponse 객체로 변환 (검증 및 로깅용)
        final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        final profileResponse = ProfileResponse.fromJson(jsonResponse);

        if (!profileResponse.profileId.isNaN) {
          await _authService.saveProfileId(profileResponse.profileId);
          print("토큰 저장 성공"); // 디버깅용
        } else {
          print("경고: 서버 응답에 profileId가 없습니다.");
        }

        // 성공 시 2단계(Bio) 페이지로 이동
        Navigator.pushReplacement(    //profileSetupPage(1/2)를 스택에서 제거한 후 다음 단계로 이동
          context,
          MaterialPageRoute(builder: (context) => BioSetupPage(nickname: profileResponse.nickname)),
        );
      } else {
        // 실패 시
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody["message"] ?? "프로필 저장에 실패했습니다. (코드: ${response.statusCode})";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      print("오류 발생: $e");
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
  // 1단계에서 받아올 닉네임 변수 선언
  final String nickname;

  const BioSetupPage({super.key, required this.nickname});  // nickname 필수로 받음

  @override
  State<BioSetupPage> createState() => _BioSetupPageState();
}

class _BioSetupPageState extends State<BioSetupPage> {
  final _bioController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  XFile? _imageXFile;
  final ImagePicker _picker = ImagePicker();

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

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageXFile = pickedFile;   // _imageXFile에 XFile 자체를 저장
        });
      }
    } catch (e) {
      print("이미지를 가져오는 데 실패했습니다: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("이미지를 가져오는 데 실패했습니다: $e")),
      );
    }
  }

  // --- 2단계 제출 (Bio 정보 API 전송) ---
  Future<void> _submitStep2() async {
    if (_bioController.text.trim().isEmpty && _imageXFile == null) {
      // Bio, 이미지가 비어있으면 그냥 '완료' (홈으로)
      _goToHome();
      return;
    }

    setState(() { _isLoading = true; });

    try {
      // API 호출
      final String? accessToken = await _authService.getAccessToken();
      if (accessToken == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("인증 정보가 만료되었습니다.")),
        );
        _goToHome(); // 에러가 나도 일단 홈으로 보냄
        return;
      }

      final url = Uri.parse(profileEditApiUrl);
      var request = http.MultipartRequest('PUT', url);

      request.headers['Authorization'] = "Bearer $accessToken";

      Map<String, String?> dtoMap = {
        "bio": _bioController.text,
        "nickname": widget.nickname,    //받아온 nickname 전달
      };

      request.files.add(
        http.MultipartFile.fromString(
          'request', // 백엔드 @RequestPart("request")
          jsonEncode(dtoMap),
          contentType: MediaType('application', 'json'),
        ),
      );

      // 이미지가 있으면 'image' 파트로 추가
      if (_imageXFile != null) {
        final bytes = await _imageXFile!.readAsBytes();   // 파일의 바이트 데이터

        // 확장자 추출 (예: image.png -> png)
        String extension = _imageXFile!.path.split('.').last.toLowerCase();

        // 기본값은 jpeg
        String subtype = 'jpeg';
        if (extension == 'png') subtype = 'png';

        request.files.add(
          await http.MultipartFile.fromBytes(
            'image', // 백엔드 @RequestPart("image")
            bytes,
            filename: _imageXFile!.name,
            contentType: MediaType('image', subtype), // (파일 형식에 맞게 조절)
          ),
        );
      }

      print(request);
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("자기소개가 저장되었습니다! 환영합니다.")),
        );
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody["message"] ?? "업데이트에 실패했습니다.";
        print(errorMessage);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      print("오류 발생: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("오류 발생: $e")),
      );
    } finally {
      // API 성공/실패 여부와 관계없이 홈으로 이동
      setState(() { _isLoading = false; });
      _goToHome();
    }
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
                "${widget.nickname}님, 마지막 단계입니다! \n자신을 소개하는 프로필을 작성해보세요.",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 40),

              // 이미지 피커 UI 추가
              GestureDetector(
                onTap: _pickImage,
                child: Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade200,

                    // --- 플랫폼 분기 ---
                    backgroundImage:
                        _imageXFile == null
                        ? null
                        : kIsWeb
                            // Web: blob URL이므로 NetworkImage 사용
                            ? NetworkImage(_imageXFile!.path)
                            // Native: 로컬 파일 경로이므로 FileImage 사용 (dart:io 필요)
                            : FileImage(File(_imageXFile!.path))
                                as ImageProvider, // 타입 명시

                    child: _imageXFile == null
                        ? Icon(Icons.camera_alt,
                            color: Colors.grey.shade700, size: 40)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 30),

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