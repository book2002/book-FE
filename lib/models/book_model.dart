// 도서 검색 결과, 신간 도서 목록 공용 모델
class BookDto {
  final String title;
  final List<String> authors;
  final String publisher;
  final String isbn;
  final String thumbnail;
  final String datetime;
  final String contents;

  BookDto({
    required this.title,
    required this.authors,
    required this.publisher,
    required this.isbn,
    required this.thumbnail,
    required this.datetime,
    required this.contents,
  });

  factory BookDto.fromJson(Map<String, dynamic> json) {
    return BookDto(
      title: json['title'] ?? '',
      // [변경] authors가 null일 경우 빈 리스트 처리, dynamic 리스트를 String 리스트로 변환
      authors: (json['authors'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      publisher: json['publisher'] ?? '',
      isbn: json['isbn'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      datetime: json['datetime'] ?? '',
      contents: json['contents'] ?? '',
    );
  }
  // UI 표시용 저자 문자열 (예: "저자1, 저자2")
  String get authorsString => authors.isNotEmpty ? authors.join(", ") : "저자 미상";
}

// 내 서재에 저장된 책 정보, 저장된 목록 조회용
class BookShelfItemDto {
  final int itemId;
  final String isbn;
  final String title;
  final String author;
  final String? thumbnail;
  final String state; // WANT_TO_READ, READING, COMPLETED
  final int currentPage;
  final int? totalPage;

  BookShelfItemDto({
    required this.itemId,
    required this.isbn,
    required this.title,
    required this.author,
    this.thumbnail,
    required this.state,
    required this.currentPage,
    this.totalPage,
  });

  factory BookShelfItemDto.fromJson(Map<String, dynamic> json) {
    return BookShelfItemDto(
      itemId: json['itemId'] ?? 0,
      isbn: json['isbn'] ?? '',
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      thumbnail: json['thumbnail'],
      state: json['state'] ?? 'WANT_TO_READ',
      currentPage: json['currentPage'] ?? 0,
      totalPage: json['totalPage'],
    );
  }

  // 진행률 계산 getter (퍼센트 문자열 반환)
  String get progressPercent {
    if (totalPage == null || totalPage == 0) return "0%";
    return "${(currentPage / totalPage! * 100).toStringAsFixed(0)}%";
  }
  
  // 진행률 값 getter (0.0 ~ 1.0 double)
  double get progressValue {
    if (totalPage == null || totalPage == 0) return 0.0;
    return currentPage / totalPage!;
  }
}

// 서재 저장 요청
class BookSaveRequest {
  final String isbn;
  final String title;
  final List<String> authors;
  final String thumbnail;
  final String state; // WANT_TO_READ, READING, COMPLETED
  final int? currentPage;
  final int? totalPage;

  BookSaveRequest({
    required this.isbn,
    required this.title,
    required this.authors,
    required this.thumbnail,
    required this.state,
    this.currentPage,
    this.totalPage,
  });

  Map<String, dynamic> toJson() => {
    'isbn': isbn,
    'title': title,
    'authors': authors,
    'thumbnail': thumbnail,
    'state': state,
    'currentPage': currentPage,
    'totalPage': totalPage,
  };
}

// 도서 상태 변경 요청 (BookStateUpdateRequestDto 대응)
class BookStateUpdateRequest {
  final String newState; // WANT_TO_READ, READING, COMPLETED
  final int? currentPage;
  final int? totalPage;

  BookStateUpdateRequest({
    required this.newState,
    this.currentPage,
    this.totalPage,
  });

  Map<String, dynamic> toJson() => {
    'newState': newState,
    'currentPage': currentPage,
    'totalPage': totalPage,
  };
}

// 독서 진행률 수정 요청 (ProgressUpdateRequestDto 대응)
class ProgressUpdateRequest {
  final int currentPage;
  final int? totalPage;

  ProgressUpdateRequest({
    required this.currentPage,
    this.totalPage,
  });

  Map<String, dynamic> toJson() => {
    'currentPage': currentPage,
    'totalPage': totalPage,
  };
}