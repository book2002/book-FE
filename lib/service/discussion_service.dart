import 'dart:convert';
import 'package:flutter_app/constants.dart';
import 'package:flutter_app/models/discussion_model.dart';
import 'package:flutter_app/service/auth_service.dart';
import 'package:http/http.dart' as http;

class DiscussionService {
  final AuthService _authService = AuthService();

  // [1] 토론 목록 조회 (GET /api/v1/groups/{groupId}/discussions)
  Future<List<DiscussionResponse>> getDiscussions(int groupId, {int page = 0, int size = 20}) async {
    final url = Uri.parse('$baseUrl/api/v1/groups/$groupId/discussions?page=$page&size=$size&sort=createdAt,desc');
    try {
      final token = await _authService.getAccessToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body.containsKey('content')) {
          final List<dynamic> content = body['content'];
          return content.map((json) => DiscussionResponse.fromJson(json)).toList();
        }
        return [];
      }
      return [];
    } catch (e) {
      print("토론 목록 조회 오류: $e");
      return [];
    }
  }

  // [2] 토론 주제 생성 (POST /api/v1/groups/{groupId}/discussions)
  Future<bool> createDiscussion(int groupId, String title, String content) async {
    final url = Uri.parse('$baseUrl/api/v1/groups/$groupId/discussions');
    try {
      final token = await _authService.getAccessToken();
      if (token == null) return false;

      final requestDto = DiscussionRequest(topicTitle: title, topicContent: content);

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
      print("토론 생성 오류: $e");
      return false;
    }
  }

  // [3] 토론 상세 조회 (GET /api/v1/discussions/{discussionId})
  Future<DiscussionResponse?> getDiscussionDetail(int discussionId) async {
    final url = Uri.parse('$baseUrl/api/v1/discussions/$discussionId');
    try {
      final token = await _authService.getAccessToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        return DiscussionResponse.fromJson(body);
      }
      return null;
    } catch (e) {
      print("토론 상세 조회 오류: $e");
      return null;
    }
  }

  // [4] 토론 수정 (PUT /api/v1/discussions/{discussionId})
  Future<bool> updateDiscussion(int discussionId, String title, String content) async {
    final url = Uri.parse('$baseUrl/api/v1/discussions/$discussionId');
    try {
      final token = await _authService.getAccessToken();
      if (token == null) return false;

      final requestDto = DiscussionRequest(topicTitle: title, topicContent: content);

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
      print("토론 수정 오류: $e");
      return false;
    }
  }

  // [5] 토론 상태 변경 (PUT /api/v1/discussions/{discussionId}/status)
  Future<bool> updateDiscussionStatus(int discussionId, bool isClosed) async {
    final url = Uri.parse('$baseUrl/api/v1/discussions/$discussionId/status');
    try {
      final token = await _authService.getAccessToken();
      if (token == null) return false;

      final requestDto = DiscussionStatusRequest(isClosed: isClosed);

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
      print("토론 상태 변경 오류: $e");
      return false;
    }
  }

  // [6] 토론 삭제 (DELETE /api/v1/discussions/{discussionId})
  Future<bool> deleteDiscussion(int discussionId) async {
    final url = Uri.parse('$baseUrl/api/v1/discussions/$discussionId');
    try {
      final token = await _authService.getAccessToken();
      if (token == null) return false;

      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("토론 삭제 오류: $e");
      return false;
    }
  }

  // --- 토론 댓글 관련 ---

  // [7] 댓글 목록 조회
  Future<List<DiscussionCommentResponse>> getComments(int discussionId) async {
    final url = Uri.parse('$baseUrl/api/v1/discussions/$discussionId/comments');
    try {
      final token = await _authService.getAccessToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        return body.map((json) => DiscussionCommentResponse.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("토론 댓글 조회 오류: $e");
      return [];
    }
  }

  // [8] 댓글 작성
  Future<bool> createComment(int discussionId, String content) async {
    final url = Uri.parse('$baseUrl/api/v1/discussions/$discussionId/comments');
    try {
      final token = await _authService.getAccessToken();
      if (token == null) return false;

      final requestDto = DiscussionCommentRequest(content: content);

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
      print("토론 댓글 작성 오류: $e");
      return false;
    }
  }

  // [9] 댓글 수정
  Future<bool> updateComment(int commentId, String content) async {
    final url = Uri.parse('$baseUrl/api/v1/discussions/comments/$commentId');
    try {
      final token = await _authService.getAccessToken();
      if (token == null) return false;

      final requestDto = DiscussionCommentRequest(content: content);

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
      print("토론 댓글 수정 오류: $e");
      return false;
    }
  }

  // [10] 댓글 삭제
  Future<bool> deleteComment(int commentId) async {
    final url = Uri.parse('$baseUrl/api/v1/discussions/comments/$commentId');
    try {
      final token = await _authService.getAccessToken();
      if (token == null) return false;

      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("토론 댓글 삭제 오류: $e");
      return false;
    }
  }
}