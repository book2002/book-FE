// 독서 모임 관련 API 통신 서비스

import 'dart:convert';
import 'package:flutter_app/constants.dart';
import 'package:flutter_app/models/group_model.dart';
import 'package:flutter_app/service/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class GroupService {
  final AuthService _authService = AuthService();

  // [디버깅용 함수] 토큰에서 User ID(sub) 추출 및 정보 출력
  void _debugPrintTokenInfo(String tag, String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        print("🔴 [$tag] 올바르지 않은 JWT 형식입니다.");
        return;
      }

      final payload = parts[1];
      String normalized = base64Url.normalize(payload);
      String decodedString = utf8.decode(base64Url.decode(normalized));
      Map<String, dynamic> json = jsonDecode(decodedString);

      print("========= 🕵️‍♀️ [$tag] 토큰 사용자 확인 🕵️‍♀️ =========");
      print("Token 끝자리: ...${token.substring(token.length - 6)}");
      print("User ID (sub): ${json['sub']}"); // ★ 여기가 1번 계정 ID인지 2번 계정 ID인지 확인 필수
      print("만료 시간 (exp): ${json['exp']}");
      print("================================================");
      
    } catch (e) {
      print("🔴 [$tag] 토큰 분석 실패: $e");
    }
  }

  // [1] 독서 모임 목록 조회 (최신순) - GET /api/v1/groups
  Future<List<GroupResponse>> getGroups() async {
    final url = Uri.parse('$baseUrl/api/v1/groups');
    try {
      final token = await _authService.getAccessToken();
      // [디버깅] 목록 조회 시 사용된 토큰 확인
      if (token != null) _debugPrintTokenInfo("getGroups", token);

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
      print("🔴 [joinGroup] 토큰이 없습니다. 로그인이 필요합니다.");
      if (token == null) return false;

      _debugPrintTokenInfo("joinGroup 요청", token);

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print(response.body);

      return (response.statusCode == 200 || response.statusCode == 201);
    } catch (e) {
      print("모임 가입 오류: $e");
      return false;
    }
  }

  // [6] 독서 모임 탈퇴
  Future<bool> leaveGroup(int groupId) async {
    final url = Uri.parse('$baseUrl/api/v1/groups/$groupId/leave');
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
        print("모임 탈퇴 성공");
        return true;
      } else {
        print("모임 탈퇴 실패: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      print("모임 탈퇴 오류: $e");
      return false;
    }
  }
}