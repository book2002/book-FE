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