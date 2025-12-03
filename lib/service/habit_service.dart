import 'dart:convert';
import 'package:Readly/constants.dart';
import 'package:Readly/models/habit_model.dart';
import 'package:Readly/service/auth_service.dart';
import 'package:http/http.dart' as http;

class HabitService {
  final AuthService _authService = AuthService();

  // [1] 독서 목표 설정/수정 (POST /api/v1/reading-goal)
  Future<bool> createReadingGoal(int year, int targetBooks) async {
    final url = Uri.parse('$baseUrl/api/v1/reading-goal');
    try {
      final token = await _authService.getAccessToken();
      if (token == null) return false;

      final requestDto = ReadingGoalRequest(year: year, targetBooks: targetBooks);

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestDto.toJson()),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("목표 설정 오류: $e");
      return false;
    }
  }

  // [2] 올해 독서 목표 조회 (GET /api/v1/reading-goal/current)
  Future<ReadingGoalResponse?> getCurrentReadingGoal() async {
    final url = Uri.parse('$baseUrl/api/v1/reading-goal/current');
    try {
      final token = await _authService.getAccessToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        return ReadingGoalResponse.fromJson(body);
      }
      return null;
    } catch (e) {
      print("목표 조회 오류: $e");
      return null;
    }
  }

  // [3] 독서 기록 저장 (POST /api/v1/habit-tracker)
  Future<HabitTrackerResponse?> saveHabitRecord(String date) async {
    final url = Uri.parse('$baseUrl/api/v1/habit-tracker/record');
    try {
      final token = await _authService.getAccessToken();
      if (token == null) return null;

      final requestDto = HabitTrackerRequest(recordDate: date);

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestDto.toJson()),
      );

      print(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        return HabitTrackerResponse.fromJson(body);
      }
      return null;
    } catch (e) {
      print("기록 저장 오류: $e");
      return null;
    }
  }

  // [4] 월별 독서 기록 조회 (GET /api/v1/habit-tracker/monthly)
  // 반환값: ["2025-10-10", "2025-10-11"] 형태의 날짜 문자열 리스트
  Future<List<String>> getMonthlyRecords(int year, int month) async {
    final url = Uri.parse('$baseUrl/api/v1/habit-tracker/monthly')
        .replace(queryParameters: {'year': '$year', 'month': '$month'});
    
    try {
      final token = await _authService.getAccessToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        return body.map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      print("월별 기록 조회 오류: $e");
      return [];
    }
  }

  // [5] 오늘 독서 기록 조회 (GET /api/v1/habit-tracker/today)
  Future<HabitTrackerResponse?> getTodayRecord() async {
    final url = Uri.parse('$baseUrl/api/v1/habit-tracker/today');
    try {
      final token = await _authService.getAccessToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        return HabitTrackerResponse.fromJson(body);
      }
      return null;
    } catch (e) {
      // 404 등 기록이 없을 때 null 반환
      return null;
    }
  }

  // [6] 독서 습관 목록 조회
  Future<List<ReadingHabitResponse>> getHabits() async {
    final url = Uri.parse('$baseUrl/api/v1/reading-habit');
    try {
      final token = await _authService.getAccessToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        return body.map((json) => ReadingHabitResponse.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("습관 목록 조회 오류: $e");
      return [];
    }
  }

  // [7] 독서 습관 생성
  Future<bool> createHabit(String targetTime, List<String> daysOfWeek) async {
    final url = Uri.parse('$baseUrl/api/v1/reading-habit');
    try {
      final token = await _authService.getAccessToken();
      if (token == null) return false;

      final requestDto = ReadingHabitRequest(targetTime: targetTime, daysOfWeek: daysOfWeek);

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestDto.toJson()),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("습관 생성 오류: $e");
      return false;
    }
  }

  // [8] 독서 습관 수정
  Future<bool> updateHabit(int habitId, String targetTime, List<String> daysOfWeek) async {
    final url = Uri.parse('$baseUrl/api/v1/reading-habit/$habitId');
    try {
      final token = await _authService.getAccessToken();
      if (token == null) return false;

      final requestDto = ReadingHabitRequest(targetTime: targetTime, daysOfWeek: daysOfWeek);

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestDto.toJson()),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("습관 수정 오류: $e");
      return false;
    }
  }

  // [9] 독서 습관 삭제
  Future<bool> deleteHabit(int habitId) async {
    final url = Uri.parse('$baseUrl/api/v1/reading-habit/$habitId');
    try {
      final token = await _authService.getAccessToken();
      if (token == null) return false;

      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("습관 삭제 오류: $e");
      return false;
    }
  }

  // [10] 알림 활성화/비활성화
  Future<bool> updateHabitActive(int habitId, bool isActive) async {
    final url = Uri.parse('$baseUrl/api/v1/reading-habit/$habitId/active');
    try {
      final token = await _authService.getAccessToken();
      if (token == null) return false;

      final requestDto = HabitActiveUpdateRequest(active: isActive);

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestDto.toJson()),
      );

      print(response.body);

      return response.statusCode == 200;
    } catch (e) {
      print("습관 상태 변경 오류: $e");
      return false;
    }
  }
}