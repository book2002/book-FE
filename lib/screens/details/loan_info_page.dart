import 'package:flutter/material.dart';

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
  // [신규 추가] 더미 데이터 리스트
  final List<LoanRecordModel> _dummyLoans = [
    LoanRecordModel(
      title: "클린 코드",
      libraryName: "부경대학교 중앙도서관",
      loanDate: "2025.10.07",
      returnDate: "2025.11.24",
      coverColor: Colors.teal,
    ),
    LoanRecordModel(
      title: "지적 대화를 위한 넓고 얕은 지식 1",
      libraryName: "부경대학교 중앙도서관",
      loanDate: "2025.10.07",
      returnDate: "2025.11.24",
      coverColor: Colors.blueAccent,
    ),
    LoanRecordModel(
      title: "불편한 편의점",
      libraryName: "서초구립반포도서관",
      loanDate: "2025.10.25",
      returnDate: "2025.11.28",
      coverColor: Colors.orangeAccent,
    ),
    LoanRecordModel(
      title: "총 균 쇠",
      libraryName: "국립중앙도서관",
      loanDate: "2025.11.01",
      returnDate: "2025.11.30",
      coverColor: Colors.brown,
    ),
    
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // [조건 적용] 배경 흰색 설정
      backgroundColor: Colors.white,
      
      // [유지] 앱바 스타일 유지
      appBar: AppBar(
        title: const Text("대출", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [],
      ),

      // [조건 적용] 우측 하단 플로팅 버튼 추가
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: 대출 기록 추가 페이지 이동 또는 모달 띄우기
          print("대출 기록 추가 버튼 클릭");
        },
        backgroundColor: Colors.green, // 앱 테마에 맞춰 색상 조정 가능
        child: const Icon(Icons.add, color: Colors.white),
      ),

      // [변경] 기존 텍스트 위젯을 제거하고 리스트뷰로 대체
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _dummyLoans.isEmpty
            ? const Center(child: Text("대출 기록이 없습니다."))
            : ListView.separated(
                itemCount: _dummyLoans.length,
                separatorBuilder: (context, index) => const SizedBox(height: 24), // 아이템 간 간격
                itemBuilder: (context, index) {
                  return _buildLoanItem(_dummyLoans[index]);
                },
              ),
      ),
    );
  }

  // [신규 추가] 대출 기록 아이템 위젯 (테두리 없는 카드 형태)
  Widget _buildLoanItem(LoanRecordModel loan) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 왼편: 책 표지 (이미지 대신 컬러 박스로 대체)
        Container(
          width: 80,
          height: 110,
          decoration: BoxDecoration(
            color: loan.coverColor.withOpacity(0.3), // 더미 색상
            borderRadius: BorderRadius.circular(8),
            // 실제 이미지 사용 시 아래 코드 활용
            // image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
          ),
          child: Center(
            child: Icon(Icons.book, color: loan.coverColor, size: 30),
          ),
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
                    child: Text(
                      loan.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // [조건 적용] 오른편 상단: 수정 버튼
                  InkWell(
                    onTap: () {
                      // TODO: 수정 기능 구현
                      print("${loan.title} 수정 클릭");
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: const Icon(Icons.edit, size: 18, color: Colors.grey),
                    ),
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
                  Text(loan.loanDate, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                  const SizedBox(width: 10),
                  const Text("반납 ", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(loan.returnDate, style: const TextStyle(fontSize: 12, color: Colors.redAccent)), // 반납일 강조
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}