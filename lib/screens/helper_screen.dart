import 'package:flutter/material.dart';
import 'package:flutter_app/models/habit_model.dart';
import 'package:flutter_app/models/loan_model.dart';
import 'package:flutter_app/screens/details/loan_info_page.dart';
import 'package:flutter_app/service/book_service.dart';
import 'package:flutter_app/service/habit_service.dart';
import 'package:flutter_app/service/loan_service.dart';
import 'package:flutter_app/widget/HabitTrackerWidget.dart';
import 'package:flutter_app/widget/habit_setting_page.dart';
import 'package:flutter_app/widget/timer_page.dart';

class HelperScreen extends StatefulWidget {
  const HelperScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _HelperScreenState();
}

class _HelperScreenState extends State<HelperScreen> {
  final HabitService _habitService = HabitService();
  final BookService _bookService = BookService();
  final LoanService _loanService = LoanService();

  ReadingGoalResponse? _goal;
  int _readCount = 0; // 올해 읽은 책 수 (COMPLETED 상태)

  LoanResponse? _urgentLoan;  //대출 정보
  String? _urgentBookImage;   // 썸네일 URL

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  // 목표 및 진행 상황 조회
  Future<void> _fetchAllData() async {
    setState(() { _isLoading = true; });
    try {
      final results = await Future.wait([
        _habitService.getCurrentReadingGoal(),
        _bookService.getMyShelfBooks(), // 내 책장 목록
        _loanService.getLoans(),        // 대출 목록 조회
      ]);

      final goal = results[0] as ReadingGoalResponse?;
      final books = results[1] as List<dynamic>; //
      final loans = results[2] as List<LoanResponse>;

      // 읽은 책 수 계산 (COMPLETED 상태인 책)
      // 정확히는 '올해' 읽은 책이어야 하나, BookShelfItem에 완독일 정보가 없음 -> 전체 완독 수로 대체
      // 추후 BookShelfItem에 finishedDate 필드가 추가되어야 함.
      int count = books.where((b) => b.state == 'COMPLETED').length;

      // 반납일 가장 가까운 책 추출
      final activeLoans = loans.where((l) => !l.returned).toList();
      activeLoans.sort((a, b) => a.dDayValue.compareTo(b.dDayValue)); // 오름차순 정렬
      final urgent = activeLoans.isNotEmpty ? activeLoans.first : null;

      // 이미지 미리 가져오기
      String? imageUrl;
      if (urgent != null) {
        final searchRes = await _bookService.getSearchBooks(urgent.bookTitle);
        if (searchRes.isNotEmpty) imageUrl = searchRes.first.thumbnail;
      }

      if (mounted) {
        setState(() {
          _goal = goal;
          _readCount = count;
          _urgentLoan = urgent;
          _urgentBookImage = imageUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("도우미 데이터 로드 오류: $e");
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  // 목표 생성 모달
  void _showGoalDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("올해 독서 목표 설정"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("올해 몇 권의 책을 읽고 싶으신가요?"),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "목표 권수",
                border: OutlineInputBorder(),
                suffixText: "권",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소")),
          ElevatedButton(
            onPressed: () async {
              final target = int.tryParse(controller.text);
              if (target == null || target <= 0) return;
              
              Navigator.pop(context);
              // 기본적으로 올해(Current Year)로 설정
              bool success = await _habitService.createReadingGoal(DateTime.now().year, target);
              if (success) {
                _fetchAllData(); // 갱신
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("목표가 설정되었습니다!")));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("설정 실패")));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("설정", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(    // 노치나 하단 홈 바 영역을 침범하지 않도록 보호
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 30,),
            Center(
              child: _isLoading 
                ? const CircularProgressIndicator()
                : _goal == null
                  // 목표가 없을 때
                  ? GestureDetector(
                      onTap: _showGoalDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "올해 목표가 없어요.\n목표를 생성해보세요!",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  // 목표가 있을 때
                  : Text.rich(
                    TextSpan(
                      // 전체 텍스트에 공통으로 적용될 기본 스타일
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 30,
                      ),
                      children: [
                        const TextSpan(text: "목표까지 "),
                        TextSpan(
                          text: "${(_goal!.targetBooks - _readCount).clamp(0, 999)}",   // 남은 권수 (음수 방지)
                          style: TextStyle(color: Colors.green), 
                        ),
                        const TextSpan(text: "권 남았어요!"),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
            ),
            
            const Expanded(
              flex: 2, // 필요에 따라 flex 값 조절 (공간 차지 비율 설정)
              child: HabitTracker(), 
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    // 습관 설정 버튼
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const HabitSettingPage()));
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.orange.withOpacity(0.3)),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.alarm, color: Colors.orange, size: 36),
                              SizedBox(height: 8),
                              Text("습관 설정", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 독서 타이머 버튼
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const TimerPage()));
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.blue.withOpacity(0.3)),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.timer, color: Colors.blue, size: 36),
                              SizedBox(height: 8),
                              Text("독서 타이머", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
            // 대출 정보 섹션
            Padding(
              padding: EdgeInsetsGeometry.symmetric(horizontal: 10, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_urgentLoan != null)
                    Text.rich(
                      TextSpan(
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          //fontSize: 30,
                        ),
                        children: [
                          TextSpan(text: "  ${_urgentLoan!.bookTitle} 반납일이 "),
                          TextSpan(
                            text: _urgentLoan!.dDay,
                            style: const TextStyle(color: Colors.orange)
                          ),
                          const TextSpan(text: "에요."),
                        ]
                      ),
                      textAlign: TextAlign.center,
                    )
                  else
                    Text("  반납 예정인 도서가 없어요.", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  
                  SizedBox(height: 10,),
                  Container(
                    width: double.infinity,   // 부모 위젯이 허락하는 최대 너비를 가짐
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(width: 1, color: const Color(0xFFE1E1E1)),
                    ),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_urgentLoan != null)
                            Expanded( // 텍스트 넘침 방지
                              child: Row(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                              Text(
                                "📍 ${_urgentLoan!.libraryName}",
                                style: const TextStyle(
                                  fontSize: 10
                                ),
                              ),
                              SizedBox(height: 6,),
                              Row(
                                children: [
                                  SizedBox(width: 6,),
                                  // [수정] Image 위젯을 SizedBox로 감싸서 명확한 크기 제약을 제공
                                  // Image.memory 내부의 width/height 속성 대신 SizedBox를 사용하면
                                  // 'Infinity or NaN toInt' 오류를 방지할 수 있습니다.
                                  SizedBox(
                                    width: 50,
                                    height: 75,
                                    child: _urgentBookImage != null 
                                      ? Image.network(
                                        _urgentBookImage!,
                                        fit: BoxFit.cover, // 이미지가 영역을 벗어나지 않도록 fit 설정
                                      )
                                      : Container(color: Colors.grey[200], child: const Icon(Icons.book, size: 30, color: Colors.grey)),
                                  ),
                                  
                                  const SizedBox(width: 12,),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _urgentLoan!.bookTitle,
                                        maxLines: 1, overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      ),
                                      Text("반납일 : ${_urgentLoan!.dueDate}")
                                    ],
                                  )
                                ],
                              )
                            ],
                                  ),
                                  
                                ],                    
                              )
                            )
                          else
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Text("대출 중인 도서가 없습니다."),
                            ),
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const LoanInfoPage()),
                              ).then((_) => _fetchAllData());
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Icon(
                              Icons.keyboard_arrow_right_rounded,
                              size: 30,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                    )
                  ),
                ],
              )
            ),
          ],
        )
      ),
    );
  }
}