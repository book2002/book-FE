// 백엔드 명세에 맞춰 DTO 수정 및 SentenceSaveRequest 추가

class ReviewResponse {
  final int reviewId;
  final String content;
  final String bookTitle;
  final double rating;
  final bool isPublic;
  final String createdAt;
  final int itemId;

  ReviewResponse({
    required this.reviewId,
    required this.content,
    required this.bookTitle,
    required this.rating,
    required this.isPublic,
    required this.createdAt,
    required this.itemId,
  });

  factory ReviewResponse.fromJson(Map<String, dynamic> json) {
    return ReviewResponse(
      reviewId: json['reviewId'] ?? 0,
      content: json['content'] ?? '',
      bookTitle: json['bookTitle'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      isPublic: json['isPublic'] ?? json['public'] ?? false,    // isPublic 필드 우선 확인 후, 없으면 public 필드 확인
      createdAt: json['createdAt'] ?? '',
      itemId: json['itemId'] ?? 0,
    );
  }
}

class ReviewSaveRequest {
  final int itemId;
  final String content;
  final double rating;
  final bool isPublic;

  ReviewSaveRequest({
    required this.itemId,
    required this.content,
    required this.rating,
    required this.isPublic,
  });

  Map<String, dynamic> toJson() => {
    'itemId': itemId,
    'content': content,
    'rating': rating,
    'public': isPublic,
  };
}

// 감상문 수정 요청 DTO
class ReviewUpdateRequest {
  final String content;
  final double rating;
  final bool isPublic;
  final int itemId;

  ReviewUpdateRequest({
    required this.content,
    required this.rating,
    required this.isPublic,
    required this.itemId,
  });

  Map<String, dynamic> toJson() => {
    'content': content,
    'rating': rating,
    'isPublic': isPublic,
    'itemId': itemId,
  };
}

class SentenceResponse {
  final int sentenceId;
  final String content;
  final int page;
  final String createdAt;
  final int itemId;
  final String bookTitle;

  SentenceResponse({
    required this.sentenceId,
    required this.content,
    required this.page,
    required this.createdAt,
    required this.itemId,
    required this.bookTitle,
  });

  factory SentenceResponse.fromJson(Map<String, dynamic> json) {
    return SentenceResponse(
      sentenceId: json['sentenceId'] ?? 0,
      content: json['content'] ?? '',
      page: json['page'] ?? 0,
      createdAt: json['createdAt'] ?? '',
      itemId: json['itemId'] ?? 0,
      bookTitle: json['bookTitle'] ?? '',
    );
  }
}

// 문장 저장 요청 DTO 추가
class SentenceSaveRequest {
  final int itemId;
  final String content;
  final int page;

  SentenceSaveRequest({
    required this.itemId,
    required this.content,
    required this.page,
  });

  Map<String, dynamic> toJson() => {
    'itemId': itemId,
    'content': content,
    'page': page,
  };
}

// 문장 수정 요청 DTO
class SentenceUpdateRequest {
  final int itemId;
  final String content;
  final int page;

  SentenceUpdateRequest({
    required this.itemId,
    required this.content,
    required this.page,
  });

  Map<String, dynamic> toJson() => {
    'itemId': itemId,
    'content': content,
    'page': page,
  };
}