import 'dart:convert';
import 'package:flutter_app/constants.dart';
import 'package:flutter_app/models/group_post_model.dart';
import 'package:flutter_app/service/auth_service.dart';
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
}