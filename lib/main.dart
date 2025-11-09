import 'package:flutter/material.dart';
import 'package:flutter_app/login_page.dart';   //login_page import

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
  bool _isLoggedIn = false; //로그인 여부 확인 변수

  //탭 클릭 시 호출되는 함수
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _goToLoginPage() async {
    final result = await Navigator.push(
      context, 
      MaterialPageRoute(builder: (context)=> const LoginPage()),
    );

    //로그인 상태 전환
    if (result==true) {
      setState(() {
        _isLoggedIn = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255), //배경색 지정
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(widget.title),
        actions: [
          _isLoggedIn
          ? IconButton(
            icon: const Icon(Icons.account_circle,),
            onPressed: () {
              //TODO: 프로필 페이지 이동 로직 추가 예정
              setState(() {
                _isLoggedIn = false;
              });
            },
          )
          : Container(
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
          ),
          //로그인 버튼
          
        ],
      ),
      //메인 화면 내용
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            //추후 각 화면 위젯화하는 작업 필요
            //TODO: 로그인 상태에 따른 화면 로직
            const HelperScreen(),
            GroupScreen(),
            HomeScreen(),
            
            _isLoggedIn
              ? const BooklistScreen()
              : const Center(
                child: Text('로그인이 필요한 서비스입니다.'),
              ),

            _isLoggedIn
              ? const ProfileScreen()
              : const Center(
                child: Text('로그인이 필요한 서비스입니다.'),
              ),
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
