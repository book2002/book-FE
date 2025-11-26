// 독서 모임 관련 API 통신 서비스

import 'dart:convert';
import 'package:flutter_app/constants.dart';
import 'package:flutter_app/models/group_model.dart';
import 'package:flutter_app/service/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class GroupService {
  final AuthService _authService = AuthService();

  // [1] 독서 모임 목록 조회 (최신순) - GET /api/v1/groups
  Future<List<GroupResponse>> getGroups() async {
    final url = Uri.parse('$baseUrl/api/v1/groups');
    try {
      final token = await _authService.getAccessToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        return body.map((json) => GroupResponse.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("모임 목록 조회 오류: $e");
      return [];
    }
  }

  // [2] 독서 모임 목록 조회 (인기순) - GET /api/v1/groups/popular
  Future<List<GroupResponse>> getPopularGroups() async {
    final url = Uri.parse('$baseUrl/api/v1/groups/popular');
    try {
      final token = await _authService.getAccessToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        return body.map((json) => GroupResponse.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("인기 모임 조회 오류: $e");
      return [];
    }
  }

  // [3] 내 모임 목록 조회 - GET /api/v1/groups/my
  Future<List<GroupResponse>> getMyGroups() async {
    final url = Uri.parse('$baseUrl/api/v1/groups/my');
    try {
      final token = await _authService.getAccessToken();
      if (token == null) return []; // 비로그인 시 빈 목록

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        return body.map((json) => GroupResponse.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("내 모임 조회 오류: $e");
      return [];
    }
  }

  // [4] 독서 모임 생성 - POST /api/v1/groups
  Future<bool> createGroup(GroupCreateRequest requestDto) async {
    final url = Uri.parse('$baseUrl/api/v1/groups');
    try {
      final token = await _authService.getAccessToken();
      if (token == null) return false;

      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';   // 헤더 설정 (Authorization만 추가, Content-Type은 자동 설정됨)

      request.files.add(
        http.MultipartFile.fromString(
          'request', 
          jsonEncode(requestDto.toJson()),
          contentType: MediaType('application', 'json'), // JSON 타입 명시 필수
        )
      );

      // todo: 이미지 추가

      // 요청 전송
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      print("request: $request");
      print("response: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print("모임 생성 실패: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      print("모임 생성 오류: $e");
      return false;
    }
  }

  // [5] 독서 모임 가입 - POST /api/v1/groups/{groupId}/join
  Future<bool> joinGroup(int groupId) async {
    final url = Uri.parse('$baseUrl/api/v1/groups/$groupId/join');
    try {
      final token = await _authService.getAccessToken();
      if (token == null) return false;

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return (response.statusCode == 200 || response.statusCode == 201);
    } catch (e) {
      print("모임 가입 오류: $e");
      return false;
    }
  }
}