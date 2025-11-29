// 독서 모임

class GroupResponse {
  final int groupId;
  final String name;
  final String description;
  final String goal;
  final String ownerName;
  final int maxMembers;
  final int currentMembers;
  final String? groupImageUrl;
  final bool isJoined;

  GroupResponse({
    required this.groupId,
    required this.name,
    required this.description,
    required this.goal,
    required this.ownerName,
    required this.maxMembers,
    required this.currentMembers,
    this.groupImageUrl,
    required this.isJoined,
  });

  factory GroupResponse.fromJson(Map<String, dynamic> json) {
    return GroupResponse(
      groupId: json['groupId'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      goal: json['goal'] ?? '',
      ownerName: json['ownerName'] ?? '',
      maxMembers: json['maxMembers'] ?? 0,
      currentMembers: json['currentMembers'] ?? 0,
      groupImageUrl: json['groupImageUrl'],
      isJoined: json['joined'] ?? false,
    );
  }
}

// 모임 생성 요청 DTO
class GroupCreateRequest {
  final String name;
  final String description;
  final String goal;
  final int maxMembers;

  GroupCreateRequest({
    required this.name,
    required this.description,
    required this.goal,
    required this.maxMembers,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'goal': goal,
    'maxMembers': maxMembers,
  };
}

class GroupPostResponse {
  final int postId;
  final int groupId;
  final String authorNickname;
  final String title;
  final String content;
  final String createdAt;
  final int commentCount;

  GroupPostResponse({
    required this.postId,
    required this.groupId,
    required this.authorNickname,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.commentCount,
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
    );
  }
}

class DiscussionResponse {
  final int discussionId;
  final int groupId;
  final String authorNickname;
  final String topicTitle;
  final String topicContent;
  final bool isClosed;
  final String createdAt;
  final int commentCount;

  DiscussionResponse({
    required this.discussionId,
    required this.groupId,
    required this.authorNickname,
    required this.topicTitle,
    required this.topicContent,
    required this.isClosed,
    required this.createdAt,
    required this.commentCount,
  });

  factory DiscussionResponse.fromJson(Map<String, dynamic> json) {
    return DiscussionResponse(
      discussionId: json['discussionId'] ?? 0,
      groupId: json['groupId'] ?? 0,
      authorNickname: json['authorNickname'] ?? '',
      topicTitle: json['topicTitle'] ?? '',
      topicContent: json['topicContent'] ?? '',
      isClosed: json['isClosed'] ?? false,
      createdAt: json['createdAt'] ?? '',
      commentCount: json['commentCount'] ?? 0,
    );
  }
}