import 'package:flutter/material.dart';
import 'package:flutter_app/models/loan_model.dart';
import 'package:flutter_app/screens/details/loan_creat_page.dart';
import 'package:flutter_app/service/book_service.dart';
import 'package:flutter_app/service/loan_service.dart';

// [신규 추가] 대출 기록 데이터 모델
class LoanRecordModel {
  final String title;       // 책 제목
  final String libraryName; // 도서관 이름
  final String loanDate;    // 대출일
  final String returnDate;  // 반납일
  final Color coverColor;   // 책 표지 색상 (이미지 대신 사용)

  LoanRecordModel({
    required this.title,
    required this.libraryName,
    required this.loanDate,
    required this.returnDate,
    required this.coverColor,
  });
}

class LoanInfoPage extends StatefulWidget {
  const LoanInfoPage({
    Key? key,
  }) : super(key: key);

  @override
  State<LoanInfoPage> createState() => _LoanInfoPageState();
}

class _LoanInfoPageState extends State<LoanInfoPage> {
  final LoanService _loanService = LoanService();
  final BookService _bookService = BookService();   // 이미지 불러오기 위한 bookService

  List<LoanResponse> _loans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLoans();
  }

  Future<void> _fetchLoans() async {
    setState(() { _isLoading = true; });
    final loans = await _loanService.getLoans();
    if (mounted) {
      setState(() {
        _loans = loans;
        _isLoading = false;
      });
    }
  }

  // 책 제목으로 이미지 URL을 가져오는 함수 (메모이제이션 고려 가능하나 여기선 단순 호출)
  Future<String?> _fetchBookImage(String title) async {
    try {
      // 제목으로 검색
      final results = await _bookService.getSearchBooks(title);
      if (results.isNotEmpty) {
        // 첫 번째 결과의 썸네일 반환
        return results.first.thumbnail;
      }
    } catch (e) {
      print("이미지 검색 실패 ($title): $e");
    }
    return null;
  }

  // 생성/수정 페이지 이동
  void _goToCreatePage({LoanResponse? loan}) async {
    final bool? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoanCreatePage(loanToEdit: loan)),
    );
    if (result == true) {
      _fetchLoans(); // 갱신
    }
  }

  // 삭제 로직
  void _deleteLoan(int loanId) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("삭제 확인"),
        content: const Text("이 대출 기록을 삭제하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("삭제", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      bool success = await _loanService.deleteLoan(loanId);
      if (success) {
        _fetchLoans();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("삭제되었습니다.")));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("삭제 실패")));
      }
    }
  }

  // 반납 처리
  void _returnLoan(int loanId) async {
    bool success = await _loanService.returnLoan(loanId);
    if (success) {
      _fetchLoans();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("반납 처리되었습니다.")));
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("반납 처리 실패")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      
      appBar: AppBar(
        title: const Text("대출", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _goToCreatePage(),
        backgroundColor: Colors.green, // 앱 테마에 맞춰 색상 조정 가능
        child: const Icon(Icons.add, color: Colors.white),
      ),

      // [변경] 기존 텍스트 위젯을 제거하고 리스트뷰로 대체
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _loans.isEmpty
          ? const Center(child: Text("대출 기록이 없습니다."))
          : ListView.separated(
              padding: const EdgeInsets.all(20.0),
              itemCount: _loans.length,
              separatorBuilder: (context, index) => const SizedBox(height: 24), // 아이템 간 간격
              itemBuilder: (context, index) {
                return _buildLoanItem(_loans[index]);
              },
            ),
    );
  }

  // 대출 기록 아이템 위젯 (테두리 없는 카드 형태)
  Widget _buildLoanItem(LoanResponse loan) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 왼편: 책 표지
        FutureBuilder(
          future: _fetchBookImage(loan.bookTitle), 
          builder: (context, snapshot) {
            // 로딩 중 or 이미지 없는 경우
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                width: 80, height: 110,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            final imageUrl = snapshot.data;

            return Container(
              width: 80,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.grey[200], // 기본 배경
                borderRadius: BorderRadius.circular(8),
              ),
              child: imageUrl != null && imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(Icons.book, color: Colors.grey, size: 30),
                        );
                      },
                    ),
                  )
                : Center(
                    child: Center(child: Icon(Icons.book, color: Colors.grey, size: 30)),
                  )              
            );
          }
        ),
        
        const SizedBox(width: 16), // 이미지와 텍스트 사이 간격

        // 2. 오른편: 정보 및 수정 버튼
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단: 제목과 수정 버튼
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 책 제목 (공간 차지)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsetsGeometry.only(top: 10),
                      child: Text(
                        loan.bookTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: loan.returned ? Colors.grey : Colors.black87,
                          decoration: loan.returned ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                    
                  ),
                  // 수정/삭제 메뉴
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                    onSelected: (val) {
                      if (val == 'edit') _goToCreatePage(loan: loan);
                      else if (val == 'delete') _deleteLoan(loan.loanId);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text("수정")),
                      const PopupMenuItem(value: 'delete', child: Text("삭제", style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 8),

              // 도서관 이름
              Text(
                loan.libraryName,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: 8),

              // 대출일 및 반납일
              // 가독성을 위해 아이콘을 곁들인 UI로 구성
              Row(
                children: [
                  const Text("대출 ", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(loan.checkoutDate, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                  const SizedBox(width: 10),
                  const Text("반납 ", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(loan.dueDate, style: const TextStyle(fontSize: 12, color: Colors.redAccent)), // 반납일 강조
                  const SizedBox(width: 10),
                  
                ],
              ),
              const SizedBox(height: 5,),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (loan.returned)
                    const Text("[반납완료]", style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold))
                  else
                    InkWell(
                      onTap: () => _returnLoan(loan.loanId),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(border: Border.all(color: Colors.green), borderRadius: BorderRadius.circular(12)),
                        child: const Text("반납하기", style: TextStyle(fontSize: 10, color: Colors.green)),
                      ),
                    ),
                  const SizedBox(width: 15,),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }
}