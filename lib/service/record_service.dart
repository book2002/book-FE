// [신규] 감상문 및 문장 기록 API 통신을 담당하는 서비스

import 'dart:convert';
import 'package:flutter_app/constants.dart';
import 'package:flutter_app/models/record_model.dart';
import 'package:flutter_app/service/auth_service.dart';
import 'package:http/http.dart' as http;

class RecordService {
  final AuthService _authService = AuthService();

  // --- 독서 감상문 (Review) ---

  // [1] 감상문 저장 (POST /api/v1/reviews/write)
  Future<bool> createReview(ReviewSaveRequest request) async {
    final url = Uri.parse('$baseUrl/api/v1/reviews/write');
    print(request.toJson());
    try {
      final token = await _authService.getAccessToken();
      if (token == null) return false;

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );
      print(response.body);

      return (response.statusCode == 200 || response.statusCode == 201);
    } catch (e) {
      print("감상문 저장 오류: $e");
      return false;
    }
  }

  // [2] 감상문 목록 조회 (GET /api/v1/reviews/book/{itemId}) - 특정 도서 감상문 목록 조회
  Future<List<ReviewResponse>> getReviewsByBookId(int itemId) async {
    final url = Uri.parse('$baseUrl/api/v1/reviews/book/$itemId');
    try {
      final token = await _authService.getAccessToken();
      // 공개 리뷰일 수도 있으나, 헤더에 토큰 포함 권장
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        // 응답이 리스트 형태인지 확인
        final dynamic body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body is List) {
          return body.map((json) => ReviewResponse.fromJson(json)).toList();
        } else {
          // 단건인 경우 리스트로 감싸서 반환 (혹시 모를 예외 처리)
          return [ReviewResponse.fromJson(body)];
        }
      }
      return [];
    } catch (e) {
      print("감상문 조회 오류: $e");
      return [];
    }
  }

  Future<List<ReviewResponse>> getReviewsByProfileId() async {
    final url = Uri.parse('$baseUrl/api/v1/reviews/my');
    try {
      final token = await _authService.getAccessToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(url, headers: headers);
      print("getReviews : ${response.body}");

      if (response.statusCode == 200) {
        final dynamic body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body is List) {
          return body.map((json) => ReviewResponse.fromJson(json)).toList();
        } else {
          return [ReviewResponse.fromJson(body)];
        }
      }
      return [];
    } catch (e) {
      print("사용자 감상문 조회 오류: $e");
      return [];
    }
  }
  
  // 감상문 수정 (PATCH /api/v1/reviews/{reviewId})
  Future<bool> updateReview(int reviewId, ReviewUpdateRequest request) async {
    final url = Uri.parse('$baseUrl/api/v1/reviews/$reviewId');
    try {
      final token = await _authService.getAccessToken();
      if (token == null) return false;

      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );
      print(response.body);

      return (response.statusCode == 200);
    } catch (e) {
      print("감상문 수정 오류: $e");
      return false;
    }
  }

  // 감상문 삭제 (DELETE /api/v1/reviews/{reviewId})
  Future<bool> deleteReview(int reviewId) async {
    final url = Uri.parse('$baseUrl/api/v1/reviews/$reviewId');
    print(reviewId);
    try {
      final token = await _authService.getAccessToken();
      if (token == null) return false;

      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return (response.statusCode == 200 || response.statusCode == 204);
    } catch (e) {
      print("감상문 삭제 오류: $e");
      return false;
    }
  }

  // --- 기억에 남는 문장 (Sentence) ---

  // [3] 문장 저장 (POST /api/v1/sentences)
  Future<bool> createSentence(SentenceSaveRequest request) async {
    final url = Uri.parse('$baseUrl/api/v1/sentences');
    try {
      final token = await _authService.getAccessToken();
      if (token == null) return false;

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      return (response.statusCode == 200 || response.statusCode == 201);
    } catch (e) {
      print("문장 저장 오류: $e");
      return false;
    }
  }

  // [4] 문장 목록 조회 (GET /api/v1/sentences/book/{itemId})
  // 명세서에는 book/{sentenceId}만 있으나 리스트 조회를 위해 itemId 경로 추정하여 구현
  Future<List<SentenceResponse>> getSentencesByBookId(int itemId) async {
    final url = Uri.parse('$baseUrl/api/v1/sentences/book/$itemId');
    try {
      final token = await _authService.getAccessToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final dynamic body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body is List) {
          return body.map((json) => SentenceResponse.fromJson(json)).toList();
        } else {
           // 단건 리턴 대비
           return [SentenceResponse.fromJson(body)];
        }
      }
      return [];
    } catch (e) {
      print("문장 조회 오류: $e");
      return [];
    }
  }

  // 문장 수정 (PUT /api/v1/sentences/{sentenceId})
  Future<bool> updateSentence(int sentenceId, SentenceUpdateRequest request) async {
    final url = Uri.parse('$baseUrl/api/v1/sentences/$sentenceId');
    print(request.toJson());
    try {
      final token = await _authService.getAccessToken();
      if (token == null) return false;

      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      print(response.body);

      return (response.statusCode == 200);
    } catch (e) {
      print("문장 수정 오류: $e");
      return false;
    }
  }

  // 문장 삭제 (DELETE /api/v1/sentences/{sentenceId})
  Future<bool> deleteSentence(int sentenceId) async {
    final url = Uri.parse('$baseUrl/api/v1/sentences/$sentenceId');
    try {
      final token = await _authService.getAccessToken();
      if (token == null) return false;

      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return (response.statusCode == 200 || response.statusCode == 204);
    } catch (e) {
      print("문장 삭제 오류: $e");
      return false;
    }
  }
}