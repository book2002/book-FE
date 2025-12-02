import 'package:flutter/material.dart';
import 'package:flutter_app/login_page.dart';   //login_page import
import 'package:flutter_app/profile_setting_page.dart';
import 'package:flutter_app/service/auth_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; 

//하단 네비게이터로 전환될 screen import
import 'screens/home_screen.dart';
import 'screens/booklist_screen.dart';
import 'screens/profile_screen.dart';
import 'package:flutter_app/screens/grop_screen.dart';
import 'package:flutter_app/screens/helper_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Readly',
      theme: ThemeData(
        useMaterial3: true,   // Material 3 사용 설정
        scaffoldBackgroundColor: Colors.white,    // 기본 배경색 설정

        // 앱바 테마
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black, // 뒤로가기 버튼, 제목 색상
          elevation: 0,
          scrolledUnderElevation: 0, // 스크롤 시 색상 변경 방지
        ),

        // 다이얼로그(모달/알림창) 테마
        dialogTheme: const DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent, // M3 틴트 색상 제거 (순수 흰색 유지)
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),

        // 바텀 시트 테마
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
        ),

        // 카드 테마 (Card 위젯)
        cardTheme: const CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0, 
        ),

        // 팝업 메뉴(드롭다운 등) 테마
        popupMenuTheme: const PopupMenuThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),

        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green, // 앱의 메인 색상
          background: Colors.white,
          surface: Colors.white, // 컴포넌트 표면 색상 강제 지정
        ),
      ),
      
      debugShowCheckedModeBanner: false,

      // 한국어 로컬라이제이션 설정 추가
      locale: const Locale('ko', 'KR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'), // ( fallback )
      ],

      // home을 AuthGate로 설정하여 상태에 따라 화면 분기
      home: const AuthGate(),
    );
  }
}

// 인증 상태에 따라 화면을 결정하는 관문 위젯
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _authService = AuthService();
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    await _authService.checkLoginStatus();
    setState(() {
      _isInit = true; // 초기화 완료
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInit) {
      // 로딩 중일 때 (스플래시 화면 등)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return ValueListenableBuilder<bool>(
      valueListenable: _authService.isLoggedInNotifier,
      builder: (context, isLoggedIn, child) {
        if (!isLoggedIn) {
          // 1. 비로그인 상태 -> 로그인 페이지 (시작 화면)
          return const LoginPage();
        }

        return ValueListenableBuilder<bool>(
          valueListenable: _authService.hasProfileNotifier,
          builder: (context, hasProfile, child) {
            if (!hasProfile) {
              // 2. 로그인 O, 프로필 X -> 프로필 설정 페이지
              return const ProfileSetupPage();
            }
            // 3. 로그인 O, 프로필 O -> 메인 홈 화면
            return const MyHomePage(title: '');
          },
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 2;   //하단 네비게이터 탭 인덱스, 중앙의 홈을 디폴트로 설정

  //탭 클릭 시 호출되는 함수
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();

    //현재 로그인 상태 확인
    _authService.checkLoginStatus();
  }

  void _goToLoginPage() async {
    // 로그인 페이지 이동
    Navigator.push(context, MaterialPageRoute(builder: (context)=>const LoginPage()));
  }

  void _logout() {
    _authService.logout();    // 로그아웃 시 AuthGate에 의해 자동으로 LoginPage로 전환
    // //로그아웃 시, 탭 인덱스를 '홈' (index 2)으로 강제 이동
    // setState(() {
    //   _selectedIndex = 2;
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255), //배경색 지정
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(widget.title),
        actions: [
          // ValuListenableBuilder로 AuthService의 Notifier 구독
          // ValueListenableBuilder(
          //   valueListenable: _authService.isLoggedInNotifier, 
          //   builder: (context, isLoggedIn, child) {
          //     //isLoggedIn 에 따라 ui 분기
          //     if (isLoggedIn) {   // 로그인 상태
          //       return IconButton(
          //         icon: const Icon(Icons.account_circle,),
          //         onPressed: _logout,
          //       );
          //     } else {            // 로그아웃 상태 
          //       return Container(
          //         margin: const EdgeInsets.only(right: 12, top: 6, bottom: 6),
          //         child: TextButton(
          //           style: TextButton.styleFrom(
          //             side: const BorderSide(color: Color.fromARGB(255, 190, 190, 190), width: 1),
          //             shape: RoundedRectangleBorder(
          //               borderRadius: BorderRadius.circular(8),     //둥근 모서리
          //             ),
          //             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),  //안쪽 여백 설정
          //           ),
          //           onPressed: _goToLoginPage,
          //           child: const Text(
          //             "로그인",
          //             style: TextStyle(color: Color.fromARGB(255, 110, 110, 110)),
          //           ),
          //         ),
          //       );
          //     }
          //   }
          // )
          IconButton(
            icon: const Icon(Icons.logout), // 로그아웃 아이콘으로 변경
            onPressed: _logout,
          ),
        ],
      ),
      //메인 화면 내용
      body: Center(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            HelperScreen(),
            GroupScreen(),
            HomeScreen(),
            BooklistScreen(),
            ProfileScreen()
          ],
        ),
      ),
        
      //하단 네비게이터바
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,     //인덱스 지정
        onTap: _onItemTapped,

        //레이블 이름 표시 끔
        showSelectedLabels: false,
        showUnselectedLabels: false,

        selectedItemColor: const Color.fromARGB(255, 18, 110, 21),
        unselectedItemColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.help), label: '도우미'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: '모임'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: '책장'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '프로필'),
        ],
      ),
      
    );
  }
}

// 로그인이 필요할 때 보여줄 공용 위젯
// class LoginPageRequiredWidget extends StatelessWidget {
//   final String tabName;
//   const LoginPageRequiredWidget({super.key, required this.tabName});

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Text(
//             "'$tabName' 서비스는 로그인이 필요합니다.",
//             style: const TextStyle(fontSize: 16, color: Colors.black54),
//           ),
//           const SizedBox(height: 20),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.green, // 예시 색상
//               padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
//             ),
//             onPressed: () {
//               // LoginPage로 이동
//               Navigator.push(context,
//                   MaterialPageRoute(builder: (context) => const LoginPage()));
//             },
//             child: const Text(
//               "로그인하러 가기",
//               style: TextStyle(color: Colors.white, fontSize: 16),
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }