import 'package:flutter/material.dart';
import 'package:flutter_app/models/book_model.dart';
import 'package:flutter_app/service/book_service.dart';

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

class _BookDetailPageState extends State<BookDetailPage> {
  final BookService _bookService = BookService();
  bool _isSaving = false; // 저장 중 로딩 상태

  // 내 책장 포함 여부 관리
  bool _isInShelf = false;
  BookShelfItemDto? _myShelfItem;   // 현재 저장된 아이템 정보

  @override
  void initState() {
    super.initState();
    _checkIfInShelf();
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

                      // 로딩 시작 (UI 갱신을 위해 setState가 아닌 setModalState는 필요 없지만, 부모 위젯 리빌드 고려)
                      // 여기서는 단순히 비동기 로직 실행
                      
                      // final request = BookSaveRequest(
                      //   isbn: widget.isbn,
                      //   title: widget.title,
                      //   authors: [widget.author], // 작가가 String으로 오므로 리스트로 변환
                      //   thumbnail: widget.thumbnail,
                      //   state: selectedState,
                      //   currentPage: current ?? 0,
                      //   totalPage: total,
                      // );

                      // 모달 닫기 (UX상 로딩을 보여주거나 닫고나서 처리할 수 있음. 여기선 닫고 처리)
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
        // 성공 시 로컬 상태도 갱신 (단순화를 위해 다시 fetch하거나 값을 수동 업데이트)
        // 여기선 수동 업데이트
        setState(() {
           // _myShelfItem 객체 내용 갱신이 필요하다면 여기서 수행
           // 단순 아이콘 유지를 위해서는 별도 작업 불필요하나,
           // 모달 다시 열었을 때 반영되도록 값 갱신
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("삭제되었습니다.")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("삭제 실패")));
      }
    } finally {
      if (mounted) setState(() { _isSaving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,        //탭 개수
      child:  Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
          actions: [],
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              //상단
              Container(
                height: 300,
                padding: const EdgeInsets.only(left: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //책 표지
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.thumbnail,
                        height: 250,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 250, width: 170, 
                            color: Colors.grey[300], 
                            child: const Icon(Icons.broken_image, size: 50, color: Colors.grey)
                          );
                        },
                      ),
                    ),
                    //책 정보
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            //제목
                            Text(
                              widget.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              //textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10,),
                            //저자
                            Text(
                              widget.author,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 10,),
                            // 출판사 및 출판일 표시 추가
                            if (widget.publisher.isNotEmpty)
                              Text(
                                widget.publisher,
                                style: const TextStyle(fontSize: 14, color: Colors.black54),
                              ),
                              const SizedBox(height: 10,),
                            if (widget.publishedDate.isNotEmpty)
                              Text(
                                widget.publishedDate.length >= 10 
                                    ? widget.publishedDate.substring(0, 10) // 날짜 포맷 (YYYY-MM-DD)
                                    : widget.publishedDate,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 10,),

                            // 책장 추가 버튼
                            ElevatedButton.icon(
                              onPressed: () {
                                if (_isInShelf) {
                                  // 이미 추가된 경우 -> 수정/삭제 모달
                                  _showActionModal(context);
                                } else {
                                  // 없는 경우 -> 추가 모달
                                  _showShelfModal(context, isEdit: false);
                                }
                              }, 
                              icon: Icon(_isInShelf ? Icons.bookmark : Icons.bookmark_outline),   // 책장 추가 여부에 따라 아이콘 지정
                              label: Text(_isInShelf ? "저장됨" : "책장에 추가"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                )
                              )
                            )
                          ],
                        ),
                      )
                    ),
                  ],
                ),
              ),
              
              //const SizedBox(height: 10,),
              
              //하단 탭 윈도우
              const TabBar(
                labelColor: Colors.black,
                indicatorColor: Colors.green,
                tabs:[
                  Tab(text: "책 정보",),
                  Tab(text: "독서 노트",),
                ] 
              ),

              Expanded(
                child: TabBarView(
                  children: [
                    //책 정보
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        widget.description.isNotEmpty 
                            ? widget.description 
                            : '상세 설명이 없습니다.',
                        style: const TextStyle(fontSize: 14, height: 1.5), // 줄간격 추가
                        textAlign: TextAlign.justify, // 양쪽 정렬
                      ),
                    ),
                    //독서 노트
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      //TODO: 가운데 정렬 구현
                      child: const Text(
                        '작성한 독서 노트가 없어요. 노트를 추가해보세요!',
                        style: TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ]
                ),
              ),

            ],
          ),
        ),
        //독서노트 탭을 클릭했을 때만 해당 버튼이 출력되도록 변경
        floatingActionButton: FloatingActionButton(
          onPressed: () {

          },
          child: Icon(Icons.add, color: Colors.white,),
          backgroundColor: Colors.green,
          elevation: 0,
          shape: CircleBorder(),
        ),
      )

    );
  }
}