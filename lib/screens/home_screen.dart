import 'package:flutter/material.dart';
import 'package:flutter_app/bookpage/book_detail.dart';
import 'package:flutter_app/service/book_service.dart';
import 'package:flutter_app/models/book_model.dart';
import 'package:flutter_app/widget/BookListWidget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  // BookService 인스턴스 생성
  final BookService _bookService = BookService();

  // 서버 데이터를 저장할 리스트 변수 추가
  List<BookDto> _searchResults = [];   // 검색 결과
  List<BookShelfItemDto> _myReadingBooks = []; // 읽고 있는 책
  List<BookDto> _bestSellerBooks = []; // 베스트셀러
  List<BookDto> _newReleaseBooks = []; // 신간 도서
  List<BookDto> _recommendedBooks = [];

  bool _isLoading = true;   // 로딩 상태 추가
  bool _isRecommendationLoading = false;

  // 카테고리 목록
  final List<String> _categories = [
    "10대", "20대", "30대", "40대", "50대",
    "힐링", "재테크", "자기개발", "여행", "추리/공포", "트렌드"
  ];
  String _selectedCategory = "20대";    // 기본값 20대

  // 초기 데이터 로딩을 위한 initState
  @override
  void initState() {
    super.initState();
    _fetchHomeData();
    _fetchRecommendations(_selectedCategory);
  }

  // 홈 화면에 필요한 데이터(내 책장, 추천, 신간)를 병렬로 가져오는 함수
  Future<void> _fetchHomeData() async {
    setState(() { _isLoading = true; });
    try {
      // Future.wait를 사용하여 모든 API 요청 동시에 시작
      final results = await Future.wait([
        _bookService.getMyShelfBooks(),
        _bookService.getNewReleases(),
        _bookService.getBestsellers(),
      ]);

      // 결과 할당 (타입 캐스팅 주의)
      final allShelfBooks = results[0] as List<BookShelfItemDto>;
      final newReleases = results[1] as List<BookDto>;
      final bestsellers = results[2] as List<BookDto>;

      if (mounted) {
        setState(() {
          // 내 책장 중 상태가 'READING'인 것만 필터링
          _myReadingBooks = allShelfBooks.where((item) => item.state == 'READING').toList();
          _bestSellerBooks = bestsellers.take(5).toList();
          _newReleaseBooks = newReleases.take(5).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print("홈 데이터 로드 중 오류 발생: $e");
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  // 추천 도서 로드 함수
  Future<void> _fetchRecommendations(String category) async {
    setState(() {
      _selectedCategory = category;
      _isRecommendationLoading = true;
    });

    try {
      final books = await _bookService.getRecommendations(category);
      if (mounted) {
        setState(() {
          _recommendedBooks = books.take(5).toList(); // 5권 정도만 표시
          _isRecommendationLoading = false;
        });
      }
    } catch (e) {
      print("추천 도서 로드 오류: $e");
      if (mounted) setState(() { _isRecommendationLoading = false; });
    }
  }

  void _onSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    print("$query");

    FocusScope.of(context).unfocus(); // 키보드 숨김

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('검색어: $query')),
    );

    try {
      final results = await _bookService.getSearchBooks(query);
      
      if (mounted) {
        setState(() {
          _searchResults = results;
        });
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    } catch (e) {
      print("검색 오류: $e");
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await _fetchHomeData();
        await _fetchRecommendations(_selectedCategory);
      },
      color: Colors.green,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),  //margin 설정
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            //도서 검색창
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '도서명을 입력하세요',
                //prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (_) => _onSearch(),
            ),
            const SizedBox(height: 16,),

            // 검색 결과가 있을 경우 검색 결과 목록 표시
            if (_searchResults.isNotEmpty) ...[
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("검색 결과",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchResults.clear();
                        });
                      },
                      child: const Text("닫기")
                    )
                  ],
                ),
              BookListWidget(books: _searchResults, tabType: 'before'),
            ] else ...[
              // 검색 결과 없을 때 -> 기존 화면
              Padding(
                padding: EdgeInsetsGeometry.only(left: 10),
                child: Text(
                  '현재 읽고 있는 책이에요.',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                  )
                ),
              ),
              const SizedBox(height: 8,),
              //카드뷰
              SizedBox(
                height: 100,
                child: _isLoading
                ? const Center(child: CircularProgressIndicator(),)
                : _myReadingBooks.isEmpty
                  ? const Center(child: Text("읽고 있는 책이 없어요. 책을 추가해보세요!"),)
                  : ListView.builder(
                      scrollDirection: Axis.horizontal, //가로 스크롤
                      itemCount: _myReadingBooks.length,
                      shrinkWrap: true,         //내부 높이 내용에 맞게 계산
                      physics: const AlwaysScrollableScrollPhysics(), //스크롤 허용
                      itemBuilder: (context, index) {
                        final book = _myReadingBooks[index];
                        final screenWidth = MediaQuery.of(context).size.width;
                        final cardWidth = screenWidth/2-30;   //화면 절반, 여백 보정
                        
                        return Container(
                          width: cardWidth,
                          margin: const EdgeInsets.only(right: 12),
                          child: Card(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                          //margin: const EdgeInsets.symmetric(vertical: 8),
                          child: InkWell(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                //왼편: 이미지
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    bottomLeft: Radius.circular(12),
                                  ),
                                  child: Image.network(
                                    book.thumbnail ?? "https://via.placeholder.com/100",
                                    width: cardWidth*0.3, //카드 너비 약 40% 사용
                                    height: 120,
                                    fit: BoxFit.cover,    //이미지를 영역에 가득 채움
                                    errorBuilder: (ctx, err, stack) => Container(
                                      width: cardWidth*0.3, color: Colors.grey[300], child: const Icon(Icons.book),
                                    ),
                                  ),
                                ),
                                //오른편: 책 정보
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          book.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          book.author,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12
                                          ),
                                        ),
                                        Text(
                                          "진행률 : ${book.progressPercent}",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                )
                                
                              ],
                            ),
                            onTap: () {
                              // TODO: 책 상세 페이지로 이동
                              Navigator.push(
                                context, 
                                MaterialPageRoute(
                                  builder: (context) => BookDetailPage(
                                    isbn: book.isbn,
                                    title: book.title, 
                                    author: book.author, 
                                    thumbnail: book.thumbnail ?? "",
                                  ),
                                ),
                              );
                            },
                          ),
                        ) 
                          
                        );
                      },
                    ),
              ),
              
              const SizedBox(height: 18,),

              // --- 신간 도서 ---
              Padding(
                padding: EdgeInsetsGeometry.only(left: 10),
                child: Text("🆕 따끈따끈 신간",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                  )
                ),
              ),
              _isLoading
                ? const SizedBox.shrink()
                : BookListWidget(books: _newReleaseBooks, tabType: 'before'),

              const SizedBox(height: 20,),
              
              // --- [신규] 3. 추천 도서 섹션 ---
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Text("📚 맞춤 추천 도서", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),
              
              // 카테고리 태그 (가로 스크롤)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: (_categories as List? ?? []).map((category) {
                    final isSelected = _selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            _fetchRecommendations(category);
                          }
                        },
                        selectedColor: Colors.green,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        backgroundColor: Colors.grey[100],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),

              // 추천 도서 목록
              _isRecommendationLoading
                ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                : _recommendedBooks.isEmpty
                  ? const Padding(padding: EdgeInsets.all(20), child: Center(child: Text("추천 도서가 없습니다.")))
                  : BookListWidget(books: _recommendedBooks, tabType: 'before'),
              
              const SizedBox(height: 20),

            ]

          ],
        ),
      ), 
    );
    

  }
}