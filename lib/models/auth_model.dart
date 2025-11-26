// 인증 & 회원

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
  };
}

class LoginResponse {
  final String grantType;
  final String accessToken;
  final String refreshToken;
  final bool isNewUser;

  LoginResponse({
    required this.grantType,
    required this.accessToken,
    required this.refreshToken,
    required this.isNewUser,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      grantType: json['grantType'] ?? '',
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      isNewUser: json['newUser'] ?? false,
    );
  }
}

class MemberRequest {
  final String email;
  final String password;
  final String name;

  MemberRequest({required this.email, required this.password, required this.name});

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    'name': name,
  };
}

class MemberResponse {
  final int memberId;
  final String status; // ACTIVE, INACTIVE, SUSPENDED
  final String role;   // USER, ADMIN
  final String createdAt;

  MemberResponse({
    required this.memberId,
    required this.status,
    required this.role,
    required this.createdAt,
  });

  factory MemberResponse.fromJson(Map<String, dynamic> json) {
    return MemberResponse(
      memberId: json['memberId'] ?? 0,
      status: json['status'] ?? '',
      role: json['role'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class PasswordChangeRequest {
  final String oldPassword;
  final String newPassword;

  PasswordChangeRequest({
    required this.oldPassword,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() => {
    'oldPassword': oldPassword,
    'newPassword': newPassword,
  };
}

class FcmTokenRequest {
  final String fcmToken;

  FcmTokenRequest({required this.fcmToken});

  Map<String, dynamic> toJson() => {
    'fcmToken': fcmToken,
  };
}