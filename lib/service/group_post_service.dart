import 'dart:convert';
import 'package:Readly/constants.dart';
import 'package:Readly/models/group_post_model.dart';
import 'package:Readly/service/auth_service.dart';
import 'package:http/http.dart' as http;

class GroupPostService {
  final AuthService _authService = AuthService();

  // [1] 모임 내 게시글 목록 조회
  Future<List<GroupPostResponse>> getGroupPosts(int groupId, {int page = 0, int size = 20}) async {
    final url = Uri.parse('$baseUrl/api/v1/groups/$groupId/posts?page=$page&size=$size&sort=createdAt,desc');
    
    try {
      final token = await _authService.getAccessToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        // 응답 구조: { "content": [...], "totalElements": ... }
        final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body.containsKey('content')) {
          final List<dynamic> content = body['content'];
          return content.map((json) => GroupPostResponse.fromJson(json)).toList();
        }
        return [];
      } else {
        print("게시글 조회 실패: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("게시글 조회 오류: $e");
      return [];
    }
  }

  // [2] 모임 내 게시글 작성
  Future<bool> createPost(int groupId, String title, String content) async {
    final url = Uri.parse('$baseUrl/api/v1/groups/$groupId/posts');
    
    try {
      final token = await _authService.getAccessToken();
      if (token == null) return false;

      final requestDto = GroupPostRequest(title: title, content: content);

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestDto.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print("게시글 작성 실패: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      print("게시글 작성 오류: $e");
      return false;
    }
  }

  // [3] 게시글 상세 조회
  Future<GroupPostResponse?> getPostDetail(int postId) async {
    final url = Uri.parse('$baseUrl/api/v1/posts/$postId');

    try {
      final token = await _authService.getAccessToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        return GroupPostResponse.fromJson(body);
      } else {
        print("게시글 상세 조회 실패: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("게시글 상세 조회 오류: $e");
      return null;
    }
  }

  // 게시글 수정
  Future<bool> updatePost(int postId, String title, String content) async {
    final url = Uri.parse('$baseUrl/api/v1/posts/$postId');
    try {
      final token = await _authService.getAccessToken();
      if (token == null) return false;

      final requestDto = GroupPostRequest(title: title, content: content);

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestDto.toJson()),
      );

      if (response.statusCode == 200) {
        print("게시글 수정 성공");
        return true;
      } else {
        print("게시글 수정 실패: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("게시글 수정 오류: $e");
      return false;
    }
  }

  // 게시글 삭제
  Future<bool> deletePost(int postId) async {
    final url = Uri.parse('$baseUrl/api/v1/posts/$postId');
    try {
      final token = await _authService.getAccessToken();
      if (token == null) return false;

      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        print("게시글 삭제 성공");
        return true;
      } else {
        print("게시글 삭제 실패: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("게시글 삭제 오류: $e");
      return false;
    }
  }

  // [1] 댓글 목록 조회
  Future<List<GroupCommentResponse>> getComments(int postId) async {
    final url = Uri.parse('$baseUrl/api/v1/posts/$postId/comments');
    try {
      final token = await _authService.getAccessToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        return body.map((json) => GroupCommentResponse.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("댓글 조회 오류: $e");
      return [];
    }
  }

  // [2] 댓글 작성
  Future<bool> createComment(int postId, String content) async {
    final url = Uri.parse('$baseUrl/api/v1/posts/$postId/comments');
    try {
      final token = await _authService.getAccessToken();
      if (token == null) return false;

      final requestDto = GroupCommentRequest(content: content);

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
      print("댓글 작성 오류: $e");
      return false;
    }
  }

  // [3] 댓글 수정
  Future<bool> updateComment(int commentId, String content) async {
    final url = Uri.parse('$baseUrl/api/v1/posts/comments/$commentId');
    try {
      final token = await _authService.getAccessToken();
      if (token == null) return false;

      final requestDto = GroupCommentRequest(content: content);

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
      print("댓글 수정 오류: $e");
      return false;
    }
  }

  // [4] 댓글 삭제
  Future<bool> deleteComment(int commentId) async {
    final url = Uri.parse('$baseUrl/api/v1/posts/comments/$commentId');
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
      print("댓글 삭제 오류: $e");
      return false;
    }
  }
}