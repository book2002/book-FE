import 'package:flutter/material.dart';
import 'package:flutter_app/models/book_model.dart';
import 'package:flutter_app/models/record_model.dart';
import 'package:flutter_app/service/book_service.dart';
import 'package:flutter_app/service/record_service.dart';
import 'package:flutter_app/service/refresh_service.dart';

class BookDetailPage extends StatefulWidget {
  final String isbn;  // api 요청에 필수적
  final String title;
  final String author;
  final String thumbnail;
  final String description; 
  final String publisher;
  final String publishedDate;

  const BookDetailPage ({
    Key? key,
    required this.isbn,
    required this.title,
    required this.author,
    required this.thumbnail,
    this.description = '',
    this.publisher = '',
    this.publishedDate = '',
  }) : super(key: key);

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

// 탭 컨트롤러 사용을 위해 SingleTickerProviderStateMixin 추가
class _BookDetailPageState extends State<BookDetailPage> with SingleTickerProviderStateMixin {
  final BookService _bookService = BookService();
  final RecordService _recordService = RecordService();
  final RefreshService _refreshService = RefreshService();

  late TabController _tabController; // 탭 컨트롤러

  bool _isSaving = false;   // 저장 중 로딩 상태
  bool _isInShelf = false;  // 내 책장 포함 여부 관리
  BookShelfItemDto? _myShelfItem;   // 현재 저장된 아이템 정보

  // 메모(기록) 데이터 리스트
  List<ReviewResponse> _reviews = [];
  List<SentenceResponse> _sentences = [];
  bool _isLoadingRecords = false;

  bool _isMenuOpen = false; // 플로팅 버튼 메뉴 확장 여부
  bool _showFab = false; // FAB 표시 여부 (탭에 따라 변경)

  @override
  void initState() {
    super.initState();

    // 탭 컨트롤러 초기화 및 리스너 등록
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);

    _checkIfInShelf().then((_) {
      // 책장에 있는 책이라면 기록 데이터를 불러옴
      if (_isInShelf && _myShelfItem != null) {
        _fetchRecords();
      }
    });
  }

  // 탭 변경 시 호출되는 함수
  void _handleTabSelection() {
    // 탭이 변경되는 중이 아니라 완료되었을 때만 상태 업데이트
    if (!_tabController.indexIsChanging) {
      setState(() {
        // 인덱스 1(독서 노트)일 때만 FAB 표시
        _showFab = _tabController.index == 1;
        // 탭을 옮기면 열려있던 메뉴는 닫음
        _isMenuOpen = false;
      });
    }
  }

  @override
  void dispose() {
    //컨트롤러 해제
    _tabController.dispose(); 
    super.dispose();
  }

  // 해당 책이 책장에 이미 존재하는지 확인하는 함수
  Future<void> _checkIfInShelf() async {
    try {
      // 내 책장 목록을 가져와서 ISBN 비교
      // (TODO: 추후 단건 조회 API가 생긴다면 그것으로 대체하는 것이 성능상 유리함)
      final myBooks = await _bookService.getMyShelfBooks();
      final targetItem = myBooks.firstWhere(
        (item) => item.isbn == widget.isbn, 
        orElse: () => BookShelfItemDto(itemId: -1, isbn: '', title: '', author: '', state: '', currentPage: 0),
      );

      if (targetItem.itemId != -1) {
        if (mounted) {
          setState(() {
            _isInShelf = true;
            _myShelfItem = targetItem;
          });
        }
      }
    } catch (e) {
      print("책장 확인 중 오류: $e");
    }
  }

  // 감상문 및 문장 목록 불러오기
  Future<void> _fetchRecords() async {
    if (_myShelfItem == null) return;
    setState(() { _isLoadingRecords = true; });

    try {
      final reviews = await _recordService.getReviewsByBookId(_myShelfItem!.itemId);
      final sentences = await _recordService.getSentencesByBookId(_myShelfItem!.itemId);

      if (mounted) {
        setState(() {
          _reviews = reviews;
          _sentences = sentences;
          _isLoadingRecords = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoadingRecords = false; });
    }
  }

  // --- 감상문/문장 삭제 로직 ---
  Future<void> _deleteReview(int reviewId) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("삭제 확인"),
        content: const Text("감상문을 삭제하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("삭제", style: TextStyle(color: Colors.red))),
        ],
      )
    );

    if (confirm == true) {
      bool success = await _recordService.deleteReview(reviewId);
      if (success) {
        _fetchRecords();
        _refreshService.notifyReviewChanged();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("감상문이 삭제되었습니다.")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("삭제 실패")));
      }
    }
  }

  Future<void> _deleteSentence(int sentenceId) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("삭제 확인"),
        content: const Text("해당 문장을 삭제하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("삭제", style: TextStyle(color: Colors.red))),
        ],
      )
    );

    if (confirm == true) {
      bool success = await _recordService.deleteSentence(sentenceId);
      if (success) {
        _fetchRecords();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("문장이 삭제되었습니다.")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("삭제 실패")));
      }
    }
  }

  // 책장 추가/수정 모달창 함수
  void _showShelfModal(BuildContext context, {bool isEdit = false}) {
    // 초기값 설정
    String selectedState = isEdit ? (_myShelfItem?.state ?? 'WANT_TO_READ') : 'WANT_TO_READ'; // 기본값: 읽고 싶은 책
    final TextEditingController currentPageController = TextEditingController(
      text: isEdit ? (_myShelfItem?.currentPage.toString() ?? '') : ''
    );
    final TextEditingController totalPageController = TextEditingController(
      text: isEdit ? (_myShelfItem?.totalPage?.toString() ?? '') : ''
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 키보드 올라왔을 때 화면 가림 방지
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        // 모달 내부에서 상태 변경(화면 갱신)을 위해 StatefulBuilder 사용
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom, // 키보드 높이만큼 패딩
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, // 내용물 크기만큼만 높이 차지
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 모달 제목
                  Text(
                    isEdit ? "독서 상태 수정하기" : "책장에 추가하기",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // 1. 독서 상태 선택 (Dropdown)
                  DropdownButtonFormField<String>(
                    value: selectedState,
                    decoration: const InputDecoration(
                      labelText: '독서 상태',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'WANT_TO_READ', child: Text('읽기 전')),
                      DropdownMenuItem(value: 'READING', child: Text('읽는 중')),
                      DropdownMenuItem(value: 'COMPLETED', child: Text('다 읽은')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setModalState(() {
                          selectedState = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // 2. 상태에 따른 동적 입력 필드
                  // '읽는 중'일 때: 현재 페이지 + 전체 페이지 입력
                  if (selectedState == 'READING') ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: currentPageController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: '현재 페이지',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: totalPageController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: '전체 페이지',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  // '다 읽은' 상태일 때: 전체 페이지 입력
                  ] else if (selectedState == 'COMPLETED') ...[
                    TextField(
                      controller: totalPageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '전체 페이지',
                        border: OutlineInputBorder(),
                        hintText: '책의 총 페이지 수를 입력하세요',
                      ),
                    ),
                  ],
                  // '읽고 싶은' 상태일 때는 추가 입력 필드 없음

                  const SizedBox(height: 24),

                  // 3. 저장 버튼
                  ElevatedButton(
                    onPressed: _isSaving ? null : () async {
                      // 입력값 파싱
                      int? current = int.tryParse(currentPageController.text);
                      int? total = int.tryParse(totalPageController.text);

                      // 유효성 검사 (간단 예시)
                      if (selectedState == 'READING' && (current == null || total == null)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("페이지 정보를 입력해주세요.")),
                        );
                        return;
                      }

                      Navigator.pop(context);

                      if (isEdit && _myShelfItem != null) {
                        // [수정 로직]
                        _updateBookState(_myShelfItem!.itemId, BookStateUpdateRequest(
                          newState: selectedState,
                          currentPage: current,
                          totalPage: total
                        ));
                      } else {
                        // [추가 로직]
                        _saveBookToShelf(BookSaveRequest(
                          isbn: widget.isbn,
                          title: widget.title,
                          authors: [widget.author],
                          thumbnail: widget.thumbnail,
                          state: selectedState,
                          currentPage: current ?? 0,
                          totalPage: total,
                        ));
                      }
                      _refreshService.notifyBookShelfChanged();

                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      isEdit ? "수정 완료" : "저장", 
                      style: TextStyle(color: Colors.white, fontSize: 16)
                    ),
                  ),
                  const SizedBox(height: 30), // 하단 여백
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showActionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text("상태 수정하기"),
                onTap: () {
                  Navigator.pop(context);
                  _showShelfModal(context, isEdit: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text("책장에서 삭제하기"),
                onTap: () async {
                  Navigator.pop(context);
                  // 삭제 확인 다이얼로그
                  bool? confirm = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("삭제 확인"),
                      content: const Text("정말 책장에서 삭제하시겠습니까?"),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("취소")),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("삭제", style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                  if (confirm == true && _myShelfItem != null) {
                    _deleteBook(_myShelfItem!.itemId);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // api 호출 함수
  Future<void> _saveBookToShelf(BookSaveRequest request) async {
    setState(() { _isSaving = true; });
    try {
      final savedItem = await _bookService.saveBookToShelf(request);
      
      if (!mounted) return;

      if (savedItem != null) {
        setState(() {
          _isInShelf = true; // 아이콘 변경
          _myShelfItem = savedItem; // itemId 저장
        });
        _refreshService.notifyBookShelfChanged();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("책장에 추가되었습니다!")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("책장 추가에 실패했습니다.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("오류 발생: $e")),
        );
      }
    } finally {
      if (mounted) setState(() { _isSaving = false; });
    }
  }

  Future<void> _updateBookState(int itemId, BookStateUpdateRequest request) async {
    setState(() { _isSaving = true; });
    try {
      bool success = await _bookService.updateBookState(itemId, request);
      
      if (!mounted) return;
      if (success) {
        setState(() {
           _myShelfItem = BookShelfItemDto(
             itemId: _myShelfItem!.itemId,
             isbn: _myShelfItem!.isbn,
             title: _myShelfItem!.title,
             author: _myShelfItem!.author,
             thumbnail: _myShelfItem!.thumbnail,
             state: request.newState,
             currentPage: request.currentPage ?? 0,
             totalPage: request.totalPage,
           );
        });
        _refreshService.notifyBookShelfChanged();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("수정되었습니다.")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("수정 실패")));
      }
    } finally {
      if (mounted) setState(() { _isSaving = false; });
    }
  }

  Future<void> _deleteBook(int itemId) async {
    setState(() { _isSaving = true; });
    try {
      bool success = await _bookService.deleteBookFromShelf(itemId);
      
      if (!mounted) return;
      if (success) {
        setState(() {
          _isInShelf = false;
          _myShelfItem = null;
        });
        _refreshService.notifyBookShelfChanged();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("삭제되었습니다.")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("삭제 실패")));
      }
    } finally {
      if (mounted) setState(() { _isSaving = false; });
    }
  }

  // 플로팅 버튼 메뉴 토글
  void _toggleMenu() {
    if (!_isInShelf) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("책장에 추가된 도서만 기록할 수 있습니다.")));
      return;
    }
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

  // 별점 위젯 빌더
  Widget _buildStarRating(double currentRating, Function(double) onRatingChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          onPressed: () {
            onRatingChanged(index + 1.0);
          },
          icon: Icon(
            index < currentRating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 40,
          ),
        );
      }),
    );
  }

  // 감상문 작성 및 수정 모달 통합
  void _showReviewModal(BuildContext context, {ReviewResponse? existingReview}) {
    bool isEdit = existingReview != null;
    double rating = isEdit ? existingReview.rating : 0.0;    // 기본 3점
    bool isPublic = isEdit ? existingReview.isPublic : false;  // 공개 여부 변수
    final contentController = TextEditingController(text: isEdit ? existingReview.content : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 전체 화면 사용 가능하도록
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20, right: 20, top: 20
              ),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.8, // 화면의 80% 높이 사용
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text("감상문 남기기", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    
                    // 별점 영역
                    _buildStarRating(rating, (newRating) {
                      setModalState(() { rating = newRating; });
                    }),
                    const Center(child: Text("별점을 선택해주세요", style: TextStyle(color: Colors.grey))),
                    const SizedBox(height: 20),

                    // 공개 여부 설정 체크박스
                    CheckboxListTile(
                      title: const Text("전체 공개"),
                      subtitle: const Text("다른 사용자들에게도 이 감상문을 공개합니다."),
                      value: isPublic,
                      activeColor: Colors.green,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (bool? value) {
                        setModalState(() {
                          isPublic = value ?? false;
                        });
                      },
                    ),
                    const SizedBox(height: 10),

                    // 내용 입력
                    Expanded(
                      child: TextField(
                        controller: contentController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: InputDecoration(
                          hintText: "이 책에 대한 감상을 자유롭게 적어보세요.",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: () async {
                        if (contentController.text.trim().isEmpty) return;
                        Navigator.pop(context);
                        
                        // API 호출
                        bool success;
                        if (isEdit) {
                          // 수정 API 호출
                          success = await _recordService.updateReview(existingReview.reviewId, ReviewUpdateRequest(
                            content: contentController.text,
                            rating: rating,
                            isPublic: isPublic,
                            itemId: _myShelfItem!.itemId,
                          ));
                        } else {
                          // 생성 API 호출
                          success = await _recordService.createReview(ReviewSaveRequest(
                            itemId: _myShelfItem!.itemId,
                            content: contentController.text,
                            rating: rating,
                            isPublic: isPublic,
                          ));
                        }
                        print(success);

                        if (success) {
                          _fetchRecords(); // 목록 갱신
                          _refreshService.notifyReviewChanged();   // 프로필 감상평 갱신
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("감상문이 저장되었습니다.")));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("저장 실패")));
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: Text(isEdit ? "수정 완료" : "등록하기", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  // 감상문 상세 조회 (View Only) 모달
  void _showReviewDetailModal(BuildContext context, ReviewResponse review) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20, right: 20, top: 20
          ),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.8, 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 별점 및 공개 여부 등 입력 필드 제거 -> 정보 표시로 변경
                Text("감상문 내용", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                
                // 읽기 전용 별점 표시
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return Icon(
                      index < review.rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 30,
                    );
                  }),
                ),
                Center(child: Text("${review.rating.toInt()}점", style: const TextStyle(color: Colors.grey))),
                const SizedBox(height: 20),

                // 내용 표시 (읽기 전용)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[50],
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        review.content,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text("확인", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      }
    );
  }

  // 문장 작성 및 수정 모달 통합
  void _showSentenceModal(BuildContext context, {SentenceResponse? existingSentence}) {
    bool isEdit = existingSentence != null;
    final contentController = TextEditingController(text: isEdit ? existingSentence.content : '');
    final pageController = TextEditingController(text: isEdit ? existingSentence.page.toString() : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20, right: 20, top: 20
          ),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.5, // 화면 절반
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(isEdit ? "문장 수정하기" : "기억하고 싶은 문장", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                
                // 페이지 입력
                TextField(
                  controller: pageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "페이지 (선택)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // 문장 입력
                Expanded(
                  child: TextField(
                    controller: contentController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: InputDecoration(
                      hintText: "인상 깊은 문장을 기록해보세요.",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () async {
                    if (contentController.text.trim().isEmpty) return;
                    Navigator.pop(context);
                    
                    // API 호출
                    bool success;
                    int page = int.tryParse(pageController.text) ?? 0;

                    print(existingSentence?.sentenceId);
                    if (isEdit) {
                      success = await _recordService.updateSentence(existingSentence.sentenceId, SentenceUpdateRequest(
                        itemId: _myShelfItem!.itemId,
                        content: contentController.text,
                        page: page
                      ));
                    } else {
                      success = await _recordService.createSentence(SentenceSaveRequest(
                        itemId: _myShelfItem!.itemId,
                        content: contentController.text,
                        page: page,
                      ));
                    }
                    print(success);

                    if (success) {
                      _fetchRecords(); // 목록 갱신
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? "수정되었습니다." : "문장이 저장되었습니다.")));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("저장 실패")));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: Text(isEdit ? "수정 완료" : "등록하기", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      }
    );
  }
    
    // --- [신규] 문장 상세 조회 (View Only) 모달 ---
  void _showSentenceDetailModal(BuildContext context, SentenceResponse sentence) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20, right: 20, top: 20
          ),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.5, 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text("기억하고 싶은 문장", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                
                Text("p.${sentence.page}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                const SizedBox(height: 10),

                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[50],
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        sentence.content,
                        style: const TextStyle(fontSize: 16, height: 1.5, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text("확인", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                SliverAppBar(
                  title: Text(widget.title),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 1,
                  pinned: true,
                  forceElevated: innerBoxIsScrolled,
                ),
                // 상단 책 정보 영역 (SliverToBoxAdapter)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Container(
                      height: 240,
                      padding: const EdgeInsets.only(left: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              widget.thumbnail,
                              height: 180, fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(height: 250, width: 170, color: Colors.grey[300], child: const Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 30),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), maxLines: 3, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 10),
                                  Text(widget.author, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                                  const SizedBox(height: 5),
                                  if (widget.publisher.isNotEmpty) Text(widget.publisher, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                                  const SizedBox(height: 10),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      if (_isInShelf) { _showActionModal(context); } 
                                      else { _showShelfModal(context, isEdit: false); }
                                    }, 
                                    icon: Icon(_isInShelf ? Icons.bookmark : Icons.bookmark_outline),
                                    label: Text(_isInShelf ? "책장 관리" : "책장에 추가"),
                                    style: ElevatedButton.styleFrom(backgroundColor: _isInShelf ? Colors.green : Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)))
                                  )
                                ],
                              ),
                            )
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // 탭바 (SliverPersistentHeader 사용)
                SliverPersistentHeader(
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      labelColor: Colors.black,
                      indicatorColor: Colors.green,
                      tabs:[Tab(text: "책 정보"), Tab(text: "독서 노트")],
                      //backgroundColor: Colors.white, // 배경색 지정
                    ),
                  ),
                  pinned: true,
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                // 탭 1: 책 정보
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(widget.description.isNotEmpty ? widget.description : '상세 설명이 없습니다.', style: const TextStyle(fontSize: 14, height: 1.5), textAlign: TextAlign.justify),
                ),
                
                // 탭 2: 독서 노트 (메모 보기)
                _isLoadingRecords 
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_reviews.isEmpty && _sentences.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 50),
                            child: Center(child: Text('작성한 독서 노트가 없어요.\n+ 버튼을 눌러 기록을 남겨보세요!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))),
                          ),

                        if (_reviews.isNotEmpty) ...[
                          const Text("📄 감상문", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(height: 10),
                          ..._reviews.map((review) => InkWell(
                            onTap: () => _showReviewDetailModal(context, review), // [신규] 상세 조회 모달
                            child: Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(children: List.generate(5, (i) => Icon(i < review.rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 16))),
                                      Row(
                                        children: [
                                          Text(review.createdAt.split('T')[0], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                          // 점 세개 메뉴 (수정/삭제)
                                          PopupMenuButton<String>(
                                            icon: const Icon(Icons.more_horiz, color: Colors.grey),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onSelected: (value) {
                                              if (value == 'edit') {
                                                _showReviewModal(context, existingReview: review); // 수정 모달 연결
                                              } else if (value == 'delete') {
                                                _deleteReview(review.reviewId); // 삭제 연결
                                              }
                                            },
                                            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                              const PopupMenuItem<String>(value: 'edit', child: Text('수정')),
                                              const PopupMenuItem<String>(value: 'delete', child: Text('삭제')),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // [변경 사항] 3줄 제한
                                  Text(
                                    review.content, 
                                    style: const TextStyle(fontSize: 15),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (review.isPublic) const Padding(padding: EdgeInsets.only(top: 8), child: Text("공개됨", style: TextStyle(fontSize: 11, color: Colors.green))),
                                ],
                              ),
                            ),
                          )),
                          const SizedBox(height: 20),
                        ],

                        if (_sentences.isNotEmpty) ...[
                          const Text("🔖 기억하고 싶은 문장", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(height: 10),
                          ..._sentences.map((sentence) => InkWell(
                            onTap: () => _showSentenceDetailModal(context, sentence), // [신규] 상세 조회 모달
                            child: Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.format_quote, color: Colors.green, size: 20),
                                      const SizedBox(width: 8),
                                      Text("p.${sentence.page}", style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                                      const Spacer(),
                                      Text(sentence.createdAt.split('T')[0], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      // [신규] 점 세개 메뉴 (수정/삭제)
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_horiz, color: Colors.grey),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            _showSentenceModal(context, existingSentence: sentence); // 수정 모달 연결
                                          } else if (value == 'delete') {
                                            _deleteSentence(sentence.sentenceId); // 삭제 연결
                                          }
                                        },
                                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                          const PopupMenuItem<String>(value: 'edit', child: Text('수정')),
                                          const PopupMenuItem<String>(value: 'delete', child: Text('삭제')),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // [변경 사항] 3줄 제한
                                  Text(
                                    sentence.content, 
                                    style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          )),
                        ]
                      ],
                    ),
                  ),
              ]
            ),
          ),

          // 플로팅 버튼 및 메뉴 (기존 유지)
          if (_isMenuOpen && _showFab)
            Positioned(
              bottom: 90, right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)]),
                child: Column(
                  children: [
                    InkWell(onTap: () { _toggleMenu(); _showReviewModal(context); }, child: Container(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20), child: const Row(children: [Icon(Icons.edit_note, color: Colors.orange), SizedBox(width: 8), Text("감상문 쓰기", style: TextStyle(fontWeight: FontWeight.bold))]))),
                    Divider(height: 1, color: Colors.grey[300]),
                    InkWell(onTap: () { _toggleMenu(); _showSentenceModal(context); }, child: Container(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20), child: const Row(children: [Icon(Icons.short_text, color: Colors.blue), SizedBox(width: 8), Text("문장 기록  ", style: TextStyle(fontWeight: FontWeight.bold))]))),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _showFab ? FloatingActionButton(
        onPressed: _toggleMenu,
        backgroundColor: Colors.green,
        elevation: 4,
        shape: const CircleBorder(),
        child: Icon(_isMenuOpen ? Icons.close : Icons.add, color: Colors.white),
      ) : null,
    );
  }
}

// [신규] NestedScrollView에서 TabBar를 고정하기 위한 Delegate 클래스
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}