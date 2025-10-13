import 'package:flutter/material.dart';
import 'package:flutter_app/login_page.dart';   //login_page import

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'book2002',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 243, 245, 241)),
      ),
      home: const MyHomePage(title: ''),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255), //배경색 지정
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(widget.title),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12, top: 6, bottom: 6),
            child: TextButton(
              style: TextButton.styleFrom(
                side: const BorderSide(color: Color.fromARGB(255, 190, 190, 190), width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),     //둥근 모서리
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),  //안쪽 여백 설정
              ),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context)=>const LoginPage()),);
                //Navigator -> 로그인 화면 전환
              },
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
          children: const [
            //추후 각 화면 위젯화하는 작업 필요
            const Text("도우미"),
            const Text("도서관"),
            const Text("홈"),
            const Text("책장"),
            const Text("프로필"),
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
          BottomNavigationBarItem(icon: Icon(Icons.map), label: '도서관'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: '책장'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '프로필'),
        ],
      ),
      
    );
  }
}
