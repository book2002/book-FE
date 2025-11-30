// 백엔드: GroupPostRequestDTO 대응
class GroupPostRequest {
  final String title;
  final String content;

  GroupPostRequest({
    required this.title, 
    required this.content
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'content': content,
  };
}

// 백엔드: GroupPostResponseDTO 대응
class GroupPostResponse {
  final int postId;
  final int groupId;
  final String authorNickname;
  final String title;
  final String content;
  final String createdAt;
  final int commentCount;

  final String category;    // ui에서 필터링을 위해 사용

  GroupPostResponse({
    required this.postId,
    required this.groupId,
    required this.authorNickname,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.commentCount,
    this.category = '일반', // 기본값 설정
  });

  factory GroupPostResponse.fromJson(Map<String, dynamic> json) {
    return GroupPostResponse(
      postId: json['postId'] ?? 0,
      groupId: json['groupId'] ?? 0,
      authorNickname: json['authorNickname'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      createdAt: json['createdAt'] ?? '',
      commentCount: json['commentCount'] ?? 0,

      category: json['category'] ?? '일반', 
    );
  }

  // [UI 편의] 날짜 형식 변환 (ex: 10분 전, 2023.10.20)
  String get timeAgo {
    if (createdAt.isEmpty) return "";
    try {
      final date = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return "방금 전";
      } else if (difference.inMinutes < 60) {
        return "${difference.inMinutes}분 전";
      } else if (difference.inHours < 24) {
        return "${difference.inHours}시간 전";
      } else if (difference.inDays < 7) {
        return "${difference.inDays}일 전";
      } else {
        return "${date.year}.${date.month}.${date.day}";
      }
    } catch (e) {
      return createdAt;
    }
  }
}

// 백엔드: GroupCommentRequestDTO 대응
class GroupCommentRequest {
  final String content;

  GroupCommentRequest({required this.content});

  Map<String, dynamic> toJson() => {
    'content': content,
  };
}

// 백엔드: GroupCommentResponseDTO 대응
class GroupCommentResponse {
  final int commentId;
  final int postId;
  final String authorNickname;
  final String content;
  final String createdAt;
  final bool isMyComment; // 수정/삭제 버튼 표시 여부 결정

  GroupCommentResponse({
    required this.commentId,
    required this.postId,
    required this.authorNickname,
    required this.content,
    required this.createdAt,
    required this.isMyComment,
  });

  factory GroupCommentResponse.fromJson(Map<String, dynamic> json) {
    return GroupCommentResponse(
      commentId: json['commentId'] ?? 0,
      postId: json['postId'] ?? 0,
      authorNickname: json['authorNickname'] ?? '',
      content: json['content'] ?? '',
      createdAt: json['createdAt'] ?? '',
      isMyComment: json['myComment'] ?? false, // 백엔드 필드명 확인 필요 (isMyComment vs myComment)
    );
  }
}