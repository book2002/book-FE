// 대출 및 도서관 관련 모델

// 1. 도서관 검색 응답 (GET /api/v1/libraries/search)
class LibraryResponse {
  final String libName;

  LibraryResponse({required this.libName});

  factory LibraryResponse.fromJson(Map<String, dynamic> json) {
    return LibraryResponse(
      libName: json['libName'] ?? '',
    );
  }
}

// 2. 대출 목록 저장/수정 요청 (POST /api/v1/loans, POST /api/v1/loans/{loanId})
class LoanRequest {
  final String bookTitle;
  final String libraryName;
  final String checkoutDate; // YYYY-MM-DD
  final String dueDate;      // YYYY-MM-DD

  LoanRequest({
    required this.bookTitle,
    required this.libraryName,
    required this.checkoutDate,
    required this.dueDate,
  });

  Map<String, dynamic> toJson() => {
    'bookTitle': bookTitle,
    'libraryName': libraryName,
    'checkoutDate': checkoutDate,
    'dueDate': dueDate,
  };
}

// 3. 대출 목록 응답 (GET /api/v1/loans, etc.)
class LoanResponse {
  final int loanId;
  final int profileId;
  final String bookTitle;
  final String libraryName;
  final String checkoutDate;
  final String dueDate;
  final bool returned;

  LoanResponse({
    required this.loanId,
    required this.profileId,
    required this.bookTitle,
    required this.libraryName,
    required this.checkoutDate,
    required this.dueDate,
    required this.returned,
  });

  factory LoanResponse.fromJson(Map<String, dynamic> json) {
    return LoanResponse(
      loanId: json['loanId'] ?? 0,
      profileId: json['profileId'] ?? 0,
      bookTitle: json['bookTitle'] ?? '',
      libraryName: json['libraryName'] ?? '',
      checkoutDate: json['checkoutDate'] ?? '',
      dueDate: json['dueDate'] ?? '',
      returned: json['returned'] ?? false,
    );
  }

  // D-Day 계산 유틸리티
  String get dDay {
    if (returned) return "반납완료";
    if (dueDate.isEmpty) return "";
    try {
      final due = DateTime.parse(dueDate);
      final now = DateTime.now();
      // 시간 제거 후 날짜만 비교
      final dDay = DateTime(due.year, due.month, due.day)
          .difference(DateTime(now.year, now.month, now.day))
          .inDays;

      if (dDay > 0) return "D-$dDay";
      if (dDay == 0) return "D-Day";
      return "D+${dDay.abs()}"; // 연체
    } catch (e) {
      return "";
    }
  }
  
  // D-Day 정렬을 위한 getter
  int get dDayValue {
    if (dueDate.isEmpty) return 9999;
    try {
      final due = DateTime.parse(dueDate);
      final now = DateTime.now();
      return DateTime(due.year, due.month, due.day)
          .difference(DateTime(now.year, now.month, now.day))
          .inDays;
    } catch (e) {
      return 9999;
    }
  }
}

// 4. 즐겨찾기 추가 요청 (POST /api/v1/favorites/libraries)
class FavoriteLibraryRequest {
  final String libName;

  FavoriteLibraryRequest({required this.libName});

  Map<String, dynamic> toJson() => {
    'libName': libName,
  };
}

// 5. 즐겨찾기 조회 응답 (GET /api/v1/favorites/libraries)
class FavoriteLibraryResponse {
  final int favoriteId;
  final String libName;
  final String createdAt;

  FavoriteLibraryResponse({
    required this.favoriteId,
    required this.libName,
    required this.createdAt,
  });

  factory FavoriteLibraryResponse.fromJson(Map<String, dynamic> json) {
    return FavoriteLibraryResponse(
      favoriteId: json['favoriteId'] ?? 0,
      libName: json['libName'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }
}