// 프로필

class ProfileRequest {
  final String nickname;
  final String birth; // YYYYMMDD
  final String gender; // "MALE" or "FEMALE"
  final String bio;

  ProfileRequest({
    required this.nickname,
    required this.birth,
    required this.gender,
    required this.bio,
  });

  Map<String, dynamic> toJson() => {
    'nickname': nickname,
    'birth': birth,
    'gender': gender,
    'bio': bio,
  };
}

class ProfileResponse {
  final int profileId;
  final String nickname;
  final String bio;
  final String? profileImageUrl;
  final int followerCount;
  final int followingCount;
  final bool isMyProfile;
  final bool isFollowing;

  ProfileResponse({
    required this.profileId,
    required this.nickname,
    required this.bio,
    this.profileImageUrl,
    required this.followerCount,
    required this.followingCount,
    this.isMyProfile = false,
    this.isFollowing = false,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    return ProfileResponse(
      profileId: json['profileId'] ?? 0,
      nickname: json['nickname'] ?? '',
      bio: json['bio'] ?? '',
      profileImageUrl: json['profileImageUrl'],
      followerCount: json['followerCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      isMyProfile: json['isMyProfile'] ?? false,
      isFollowing: json['isFollowing'] ?? false,
    );
  }
}

class ProfileListResponse {
  final int profileId;
  final String nickname;
  final String bio;
  final String? profileImageUrl;
  final bool isFollowing;

  ProfileListResponse({
    required this.profileId,
    required this.nickname,
    required this.bio,
    this.profileImageUrl,
    required this.isFollowing,
  });

  factory ProfileListResponse.fromJson(Map<String, dynamic> json) {
    return ProfileListResponse(
      profileId: json['profileId'] ?? 0,
      nickname: json['nickname'] ?? '',
      bio: json['bio'] ?? '',
      profileImageUrl: json['profileImageUrl'],
      isFollowing: json['isFollowing'] ?? false,
    );
  }
}