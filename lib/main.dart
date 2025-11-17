import 'package:flutter/material.dart';
import 'package:flutter_app/login_page.dart';   //login_page import
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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 243, 245, 241)),
      ),

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

      home: const MyHomePage(title: ''),
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
    _authService.logout();
    //로그아웃 시, 탭 인덱스를 '홈' (index 2)으로 강제 이동
    setState(() {
      _selectedIndex = 2;
    });
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
          ValueListenableBuilder(
            valueListenable: _authService.isLoggedInNotifier, 
            builder: (context, isLoggedIn, child) {
              //isLoggedIn 에 따라 ui 분기
              if (isLoggedIn) {   // 로그인 상태
                return IconButton(
                  icon: const Icon(Icons.account_circle,),
                  onPressed: _logout,
                );
              } else {            // 로그아웃 상태 
                return Container(
                  margin: const EdgeInsets.only(right: 12, top: 6, bottom: 6),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      side: const BorderSide(color: Color.fromARGB(255, 190, 190, 190), width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),     //둥근 모서리
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),  //안쪽 여백 설정
                    ),
                    onPressed: _goToLoginPage,
                    child: const Text(
                      "로그인",
                      style: TextStyle(color: Color.fromARGB(255, 110, 110, 110)),
                    ),
                  ),
                );
              }
            }
          )
        ],
      ),
      //메인 화면 내용
      body:ValueListenableBuilder<bool>(
        valueListenable: _authService.isLoggedInNotifier,
        builder: (context, isLoggedIn, child) {
          // ✅ 2. 이제 'isLoggedIn' 변수를 body에서도 사용할 수 있습니다.
          return Center(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                // 0: HelperScreen
                isLoggedIn
                    ? const HelperScreen()
                    : const LoginPageRequiredWidget(tabName: "도우미"),

                // 1: GroupScreen (로그인 여부와 관계없이 항상 표시)
                GroupScreen(),

                // 2: HomeScreen (로그인 여부와 관계없이 항상 표시)
                HomeScreen(),

                // 3: BooklistScreen
                isLoggedIn
                    ? const BooklistScreen()
                    : const LoginPageRequiredWidget(tabName: "책장"),

                // 4: ProfileScreen
                isLoggedIn
                    ? const ProfileScreen()
                    : const LoginPageRequiredWidget(tabName: "프로필"),
              ],
            ),
          );
        }
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
class LoginPageRequiredWidget extends StatelessWidget {
  final String tabName;
  const LoginPageRequiredWidget({super.key, required this.tabName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "'$tabName' 서비스는 로그인이 필요합니다.",
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green, // 예시 색상
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
            onPressed: () {
              // LoginPage로 이동
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const LoginPage()));
            },
            child: const Text(
              "로그인하러 가기",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          )
        ],
      ),
    );
  }
}