// 해빗 트래커 + 목표

class ReadingGoalResponse {
  final int id;
  final int year;
  final int targetBooks;

  ReadingGoalResponse({required this.id, required this.year, required this.targetBooks});

  factory ReadingGoalResponse.fromJson(Map<String, dynamic> json) {
    return ReadingGoalResponse(
      id: json['id'] ?? 0,
      year: json['year'] ?? DateTime.now().year,
      targetBooks: json['targetBooks'] ?? 0,
    );
  }
}

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

class ReadingHabitResponse {
  final int id;
  final String targetTime; // HH:mm
  final List<String> recurringDays; // ["MON", "TUE"]
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

class HabitTrackerResponse {
  final int memberId;
  final String recordDate; // YYYY-MM-DD
  final String message;

  HabitTrackerResponse({required this.memberId, required this.recordDate, required this.message});

  factory HabitTrackerResponse.fromJson(Map<String, dynamic> json) {
    return HabitTrackerResponse(
      memberId: json['memberId'] ?? 0,
      recordDate: json['recordDate'] ?? '',
      message: json['message'] ?? '',
    );
  }
}

class HabitTrackerRequest {
  final String recordDate; // "2025-10-11" 형식

  HabitTrackerRequest({required this.recordDate});

  Map<String, dynamic> toJson() => {
    'recordDate': recordDate,
  };
}

// 습관/해빗트래커 알림 상태 변경 요청 모델 (HabitStatusUpdateRequestDTO 대응)
class HabitStatusUpdateRequest {
  final bool isActive;

  HabitStatusUpdateRequest({required this.isActive});

  Map<String, dynamic> toJson() => {
    'isActive': isActive,
  };
}