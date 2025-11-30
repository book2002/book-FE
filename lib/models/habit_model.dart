// 1. 독서 목표 응답 (GET /api/v1/reading-goal/current)
class ReadingGoalResponse {
  final int id;
  final int year;
  final int targetBooks;
  // [추가] 현재 읽은 권수 등 진행 상황은 별도 API가 없다면 
  // 내 서재('COMPLETED' 상태 책 수)를 통해 계산해야 할 수도 있습니다.
  // 일단 백엔드 명세에는 id, year, targetBooks만 있으므로 이것만 받습니다.

  ReadingGoalResponse({required this.id, required this.year, required this.targetBooks});

  factory ReadingGoalResponse.fromJson(Map<String, dynamic> json) {
    return ReadingGoalResponse(
      id: json['id'] ?? 0,
      year: json['year'] ?? DateTime.now().year,
      targetBooks: json['targetBooks'] ?? 0,
    );
  }
}

// 2. 독서 목표 설정 요청 (POST /api/v1/reading-goal)
class ReadingGoalRequest {
  final int year;
  final int targetBooks;

  ReadingGoalRequest({
    required this.year, 
    required this.targetBooks
  });

  Map<String, dynamic> toJson() => {
    'year': year,
    'targetBooks': targetBooks,
  };
}

// 3. 독서 기록 저장 요청 (POST /api/v1/habit-tracker)
class HabitTrackerRequest {
  final String recordDate; // "YYYY-MM-DD" 형식

  HabitTrackerRequest({required this.recordDate});

  Map<String, dynamic> toJson() => {
    'recordDate': recordDate,
  };
}

// 4. 독서 기록 저장/조회 응답 (공통)
class HabitTrackerResponse {
  final int id;
  final int memberId;
  final String recordDate; // YYYY-MM-DD
  final String message;

  HabitTrackerResponse({
    required this.id, 
    required this.memberId, 
    required this.recordDate, 
    required this.message
  });

  factory HabitTrackerResponse.fromJson(Map<String, dynamic> json) {
    return HabitTrackerResponse(
      id: json['id'] ?? 0,
      memberId: json['memberId'] ?? 0,
      recordDate: json['recordDate'] ?? '',
      message: json['message'] ?? '',
    );
  }
}

// 5. 습관(알림) 설정 모델 (기존 코드 유지 여부 확인 필요하나 일단 유지)
class ReadingHabitResponse {
  final int id;
  final String targetTime; 
  final List<String> recurringDays; 
  final bool isActive;

  ReadingHabitResponse({
    required this.id,
    required this.targetTime,
    required this.recurringDays,
    required this.isActive,
  });

  factory ReadingHabitResponse.fromJson(Map<String, dynamic> json) {
    return ReadingHabitResponse(
      id: json['id'] ?? 0,
      targetTime: json['targetTime'] ?? '',
      recurringDays: List<String>.from(json['recurringDays'] ?? []),
      isActive: json['isActive'] ?? false,
    );
  }
}

class HabitStatusUpdateRequest {
  final bool isActive;

  HabitStatusUpdateRequest({required this.isActive});

  Map<String, dynamic> toJson() => {
    'isActive': isActive,
  };
}