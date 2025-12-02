// 토론 목록/상세 조회 응답
class DiscussionResponse {
  final int discussionId;
  final int groupId;
  final String authorNickname;
  final String topicTitle;
  final String topicContent;
  final String createdAt;
  final int commentCount;
  final bool isClosed; // 토론 마감 여부
  final bool isMyDiscussion;
  final bool canModify;

  // UI 로직용
  final String category = '토론'; 

  DiscussionResponse({
    required this.discussionId,
    required this.groupId,
    required this.authorNickname,
    required this.topicTitle,
    required this.topicContent,
    required this.createdAt,
    required this.commentCount,
    required this.isClosed,
    required this.isMyDiscussion,
    required this.canModify,
  });

  factory DiscussionResponse.fromJson(Map<String, dynamic> json) {
    return DiscussionResponse(
      discussionId: json['discussionId'] ?? 0,
      groupId: json['groupId'] ?? 0,
      authorNickname: json['authorNickname'] ?? '알 수 없음',
      topicTitle: json['topicTitle'] ?? '제목 없음',
      topicContent: json['topicContent'] ?? '',
      createdAt: json['createdAt'] ?? '',
      commentCount: json['commentCount'] ?? 0,
      isClosed: json['closed'] ?? false,
      isMyDiscussion: json['isMyDiscussion'] ?? false,
      canModify: json['canModify'] ?? false,
    );
  }

  // 시간 포맷 (GroupPostResponse와 동일 로직)
  String get timeAgo {
    if (createdAt.isEmpty) return "";
    try {
      final date = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) return "방금 전";
      if (difference.inMinutes < 60) return "${difference.inMinutes}분 전";
      if (difference.inHours < 24) return "${difference.inHours}시간 전";
      if (difference.inDays < 7) return "${difference.inDays}일 전";
      return "${date.year}.${date.month}.${date.day}";
    } catch (e) {
      return createdAt;
    }
  }
}

// 토론 생성/수정 요청
class DiscussionRequest {
  final String topicTitle;
  final String topicContent;

  DiscussionRequest({
    required this.topicTitle,
    required this.topicContent,
  });

  Map<String, dynamic> toJson() => {
    'topicTitle': topicTitle,
    'topicContent': topicContent,
  };
}

// 토론 상태 변경 요청
class DiscussionStatusRequest {
  final bool isClosed;

  DiscussionStatusRequest({required this.isClosed});

  Map<String, dynamic> toJson() => {
    'isClosed': isClosed,
  };
}

// 토론 댓글 응답
class DiscussionCommentResponse {
  final int commentId;
  final int discussionId;
  final String authorNickname;
  final String content;
  final String createdAt;
  final bool isMyComment;
  final bool canModify;

  DiscussionCommentResponse({
    required this.commentId,
    required this.discussionId,
    required this.authorNickname,
    required this.content,
    required this.createdAt,
    required this.isMyComment,
    required this.canModify,
  });

  factory DiscussionCommentResponse.fromJson(Map<String, dynamic> json) {
    return DiscussionCommentResponse(
      commentId: json['commentId'] ?? 0,
      discussionId: json['discussionId'] ?? 0,
      authorNickname: json['authorNickname'] ?? '익명',
      content: json['content'] ?? '',
      createdAt: json['createdAt'] ?? '',
      isMyComment: json['isMyComment'] ?? false,
      canModify: json['canModify'] ?? false,
    );
  }

  String get timeAgo {
    if (createdAt.isEmpty) return "";
    try {
      final date = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(date);
      if (difference.inMinutes < 1) return "방금 전";
      if (difference.inMinutes < 60) return "${difference.inMinutes}분 전";
      if (difference.inHours < 24) return "${difference.inHours}시간 전";
      if (difference.inDays < 7) return "${difference.inDays}일 전";
      return "${date.year}.${date.month}.${date.day}";
    } catch (e) {
      return createdAt;
    }
  }
}

// 토론 댓글 작성/수정 요청
class DiscussionCommentRequest {
  final String content;

  DiscussionCommentRequest({required this.content});

  Map<String, dynamic> toJson() => {
    'content': content,
  };
}