import 'package:flutter/material.dart';
import 'package:flutter_app/models/loan_model.dart';
import 'package:flutter_app/service/loan_service.dart';
import 'package:intl/intl.dart';

class LoanCreatePage extends StatefulWidget {
  // 수정 모드일 때 전달받을 데이터
  final LoanResponse? loanToEdit;

  const LoanCreatePage({Key? key, this.loanToEdit}) : super(key: key);

  @override
  State<LoanCreatePage> createState() => _LoanCreatePageState();
}

class _LoanCreatePageState extends State<LoanCreatePage> {
  final LoanService _loanService = LoanService();

  final TextEditingController _bookTitleController = TextEditingController();
  final TextEditingController _libraryController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  DateTime _checkoutDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 14));

  // 지역 코드 매핑 (백엔드 명세 기준)
  final Map<int, String> _regions = {
    11: '서울', 21: '부산', 22: '대구', 23: '인천', 24: '광주', 25: '대전', 26: '울산', 31: '경기',
    32: '강원', 33: '충북', 34: '충남', 35: '전북', 36: '전남', 37: '경북', 38: '경남', 39: '제주'
  };
  int _selectedRegion = 11; // 기본값 서울

  List<LibraryResponse> _searchResults = [];
  List<FavoriteLibraryResponse> _favorites = [];
  bool _isSearching = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // 수정 모드 초기화
    if (widget.loanToEdit != null) {
      _bookTitleController.text = widget.loanToEdit!.bookTitle;
      _libraryController.text = widget.loanToEdit!.libraryName;
      _checkoutDate = DateTime.parse(widget.loanToEdit!.checkoutDate);
      _dueDate = DateTime.parse(widget.loanToEdit!.dueDate);
    }
    _fetchFavorites(); // 즐겨찾기 목록 로드
  }

  @override
  void dispose() {
    _bookTitleController.dispose();
    _libraryController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // 즐겨찾기 목록 조회
  Future<void> _fetchFavorites() async {
    final favs = await _loanService.getFavoriteLibraries();
    if (mounted) {
      setState(() {
        _favorites = favs;
      });
    }
  }

  // 도서관 검색
  void _searchLibrary() async {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) return;

    setState(() { _isSearching = true; });
    
    final results = await _loanService.searchLibraries(_selectedRegion, keyword);
    
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  // 즐겨찾기 추가/삭제 (UI상 추가만 구현되어 있음, 삭제는 ID 필요하므로 생략하거나 목록에서 처리)
  void _toggleFavorite(String libName) async {
    // 이미 즐겨찾기에 있는지 확인
    final existing = _favorites.where((f) => f.libName == libName).firstOrNull;
    
    if (existing != null) {
      // 삭제
      await _loanService.deleteFavoriteLibrary(existing.favoriteId);
    } else {
      // 추가
      await _loanService.addFavoriteLibrary(libName);
    }
    _fetchFavorites(); // 갱신
  }

  // 날짜 선택기
  Future<void> _selectDate(BuildContext context, bool isCheckout) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isCheckout ? _checkoutDate : _dueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isCheckout) {
          _checkoutDate = picked;
          // 반납일은 자동으로 2주 뒤로 설정 (편의성)
          _dueDate = picked.add(const Duration(days: 14));
        } else {
          _dueDate = picked;
        }
      });
    }
  }

  // 저장
  void _submit() async {
    if (_bookTitleController.text.isEmpty || _libraryController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("도서명과 도서관을 입력해주세요.")));
      return;
    }

    setState(() { _isSubmitting = true; });

    final request = LoanRequest(
      bookTitle: _bookTitleController.text,
      libraryName: _libraryController.text,
      checkoutDate: DateFormat('yyyy-MM-dd').format(_checkoutDate),
      dueDate: DateFormat('yyyy-MM-dd').format(_dueDate),
    );

    bool success;
    if (widget.loanToEdit != null) {
      success = await _loanService.updateLoan(widget.loanToEdit!.loanId, request);
    } else {
      success = await _loanService.createLoan(request);
    }

    if (mounted) {
      setState(() { _isSubmitting = false; });
      if (success) {
        Navigator.pop(context, true); // 성공 시 true 반환
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.loanToEdit != null ? "수정되었습니다." : "저장되었습니다.")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("저장 실패")));
      }
    }
  }

  // 도서관 검색 모달
  void _showLibrarySearchModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.8,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Text("도서관 찾기", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      // 지역 선택 & 검색창
                      Row(
                        children: [
                          DropdownButton<int>(
                            value: _selectedRegion,
                            items: _regions.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                            onChanged: (val) {
                              if (val != null) setModalState(() => _selectedRegion = val);
                            },
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: "도서관 이름 검색",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.search),
                                  onPressed: () async {
                                    final keyword = _searchController.text.trim();
                                    if (keyword.isEmpty) return;
                                    setModalState(() => _isSearching = true);
                                    // 서비스 호출 (비동기 처리 주의: 부모 state의 함수 호출)
                                    final results = await _loanService.searchLibraries(_selectedRegion, keyword);
                                    setModalState(() {
                                      _searchResults = results;
                                      _isSearching = false;
                                    });
                                  },
                                ),
                              ),
                              onSubmitted: (_) async {
                                // 상동
                                final keyword = _searchController.text.trim();
                                if (keyword.isEmpty) return;
                                setModalState(() => _isSearching = true);
                                final results = await _loanService.searchLibraries(_selectedRegion, keyword);
                                setModalState(() {
                                  _searchResults = results;
                                  _isSearching = false;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(),
                      Expanded(
                        child: _isSearching
                          ? const Center(child: CircularProgressIndicator())
                          : ListView(
                              controller: scrollController,
                              children: [
                                // 즐겨찾기 목록 (검색 결과가 없을 때 혹은 항상 상단에 표시)
                                if (_searchController.text.isEmpty && _favorites.isNotEmpty) ...[
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8.0),
                                    child: Text("즐겨찾는 도서관", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                  ),
                                  ..._favorites.map((fav) => ListTile(
                                    leading: IconButton(
                                      icon: const Icon(Icons.star, color: Colors.amber),
                                      onPressed: () async {
                                        // 즐겨찾기 삭제
                                        await _loanService.deleteFavoriteLibrary(fav.favoriteId);
                                        // 목록 갱신
                                        final newFavs = await _loanService.getFavoriteLibraries();
                                        setModalState(() => _favorites = newFavs); // 모달 내부 갱신
                                        setState(() => _favorites = newFavs); // 부모 갱신
                                      },
                                    ),
                                    title: Text(fav.libName),
                                    onTap: () {
                                      setState(() => _libraryController.text = fav.libName);
                                      Navigator.pop(context);
                                    },
                                  )),
                                  const Divider(),
                                ],

                                // 검색 결과 목록
                                ..._searchResults.map((lib) {
                                  final isFav = _favorites.any((f) => f.libName == lib.libName);
                                  return ListTile(
                                    leading: IconButton(
                                      icon: Icon(isFav ? Icons.star : Icons.star_border, color: isFav ? Colors.amber : Colors.grey),
                                      onPressed: () async {
                                        // 즐겨찾기 토글
                                        if (isFav) {
                                          final target = _favorites.firstWhere((f) => f.libName == lib.libName);
                                          await _loanService.deleteFavoriteLibrary(target.favoriteId);
                                        } else {
                                          await _loanService.addFavoriteLibrary(lib.libName);
                                        }
                                        // 갱신
                                        final newFavs = await _loanService.getFavoriteLibraries();
                                        setModalState(() => _favorites = newFavs);
                                        setState(() => _favorites = newFavs);
                                      },
                                    ),
                                    title: Text(lib.libName),
                                    onTap: () {
                                      setState(() => _libraryController.text = lib.libName);
                                      Navigator.pop(context);
                                    },
                                  );
                                }),
                                if (_searchResults.isEmpty && _searchController.text.isNotEmpty)
                                  const Padding(padding: EdgeInsets.all(20), child: Center(child: Text("검색 결과가 없습니다."))),
                              ],
                            ),
                      ),
                    ],
                  ),
                );
              },
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.loanToEdit == null ? "대출 기록 추가" : "대출 기록 수정", style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 도서명
            TextField(
              controller: _bookTitleController,
              decoration: const InputDecoration(
                labelText: "도서명",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.book),
              ),
            ),
            const SizedBox(height: 20),

            // 도서관 선택 (Read Only -> 모달 호출)
            TextField(
              controller: _libraryController,
              readOnly: true,
              onTap: _showLibrarySearchModal,
              decoration: const InputDecoration(
                labelText: "도서관",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
                suffixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 20),

            // 날짜 선택
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: "대출일",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(DateFormat('yyyy-MM-dd').format(_checkoutDate)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, false),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: "반납일",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.event_available),
                      ),
                      child: Text(DateFormat('yyyy-MM-dd').format(_dueDate)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // 저장 버튼
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isSubmitting 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(widget.loanToEdit == null ? "저장하기" : "수정하기", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}