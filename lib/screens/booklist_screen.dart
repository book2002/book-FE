import 'package:flutter/material.dart';
import 'package:Readly/models/book_model.dart';
import 'package:Readly/service/book_service.dart';
import 'package:Readly/service/refresh_service.dart';
import 'package:Readly/widget/BookListWidget.dart';

class BooklistScreen extends StatefulWidget {

  const BooklistScreen ({
    Key? key,
  }) : super(key: key);

  @override
  State<BooklistScreen> createState() => _BooklistScreenState();
}

class _BooklistScreenState extends State<BooklistScreen> {
  final BookService _bookService = BookService();
  
  List<BookShelfItemDto> _readingBooks = [];      // 읽는 중
  List<BookShelfItemDto> _wantToReadBooks = [];   // 읽기 전
  List<BookShelfItemDto> _completedBooks = [];    // 다 읽은

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchShelfBooks();

    RefreshService().bookShelfNotifier.addListener(_onShelfUpdated);
  }

  @override
  void dispose() {
    // [신규] 해제
    RefreshService().bookShelfNotifier.removeListener(_onShelfUpdated);
    super.dispose();
  }

  void _onShelfUpdated() {
    print("책장 화면: 변경 감지 -> 갱신");
    _fetchShelfBooks();
  }

  // 책장 데이터 가져오기 및 상태별 분류 함수
  Future<void> _fetchShelfBooks() async {
    setState(() { _isLoading = true; });
    try {
      // 전체 목록 조회
      final allBooks = await _bookService.getMyShelfBooks();

      // 상태(State)별 필터링
      // 상태 코드: READING, WANT_TO_READ, COMPLETED (백엔드와 일치해야 함)
      if (mounted) {
        setState(() {
          _readingBooks = allBooks.where((b) => b.state == 'READING').toList();
          _wantToReadBooks = allBooks.where((b) => b.state == 'WANT_TO_READ').toList();
          _completedBooks = allBooks.where((b) => b.state == 'COMPLETED').toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print("책장 로드 실패: $e");
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Padding(
        padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0),
        child: Column(
          children: [
            //상단 탭바
            const TabBar(
              labelColor: Colors.black,
              indicatorColor: Colors.green,
              tabs: [
                Tab(text: "읽는 중"),
                Tab(text: "읽기 전"),
                Tab(text: "다 읽은"),
              ]
            ),
            //하단
            Expanded(
              child: TabBarView(
                children: [
                  // 화면 갱신(당겨서 새로고침) 기능을 넣으려면 RefreshIndicator 감싸기 권장
                  RefreshIndicator(
                    onRefresh: _fetchShelfBooks,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: BookListWidget(books: _readingBooks, tabType: 'reading'),
                    ),
                  ),
                  RefreshIndicator(
                    onRefresh: _fetchShelfBooks,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: BookListWidget(books: _wantToReadBooks, tabType: 'before'),
                    ),
                  ),
                  RefreshIndicator(
                    onRefresh: _fetchShelfBooks,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: BookListWidget(books: _completedBooks, tabType: 'done'),
                    ),
                  ),
                ]
              ),
            ),
          ],
        ),
      ),
    );
  }
}