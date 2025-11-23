import 'dart:convert';
import 'package:flutter_app/constants.dart';
import 'package:flutter_app/models/book_model.dart';
import 'package:flutter_app/service/auth_service.dart';
import 'package:http/http.dart' as http;

class BookService {
  // [설정] 백엔드 서버 주소 (실제 서버 IP나 도메인으로 변경 필요)
  // 안드로이드 에뮬레이터: 10.0.2.2, iOS 시뮬레이터: 127.0.0.1
  final AuthService _authService = AuthService();

  // 도서 검색 (GET /api/v1/books/search)
  Future<List<BookDto>> getSearchBooks(String query) async {
    final url = Uri.parse('$baseUrl/api/v1/books/search').replace(queryParameters: {'query': query});

    try {
      // 검색은 비로그인 상태에서도 가능하다고 가정 (토큰 있으면 포함)
      final token = await _authService.getAccessToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        // UTF-8 디코딩 처리 (한글 깨짐 방지)
        final List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        
        // JSON 리스트를 BookDto 리스트로 변환
        return body.map((json) => BookDto.fromJson(json)).toList();
      } else {
        print('도서 검색 실패: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('도서 검색 API 에러: $e');
      // 에러 발생 시 빈 리스트 반환하거나 에러 처리
      return [];
    }
  }

  // [기능] 추천 도서 (베스트셀러) 조회 연결
  // HTTP Method: GET /api/v1/books/bestseller
  Future<List<BookDto>> getBestsellers() async {
    final url = Uri.parse('$baseUrl/api/v1/books/bestseller');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // UTF-8 디코딩 처리 (한글 깨짐 방지)
        final List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        // JSON 리스트를 BookDto 리스트로 변환
        return body.map((json) => BookDto.fromJson(json)).toList();
      } else {
        print('베스트셀러 조회 실패: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('베스트셀러 API 에러: $e');
      return [];
    }
  }

  // 신간 도서 조회
  Future<List<BookDto>> getNewReleases() async {
    final url = Uri.parse('$baseUrl/api/v1/books/new-releases');
    // ... (위와 동일한 로직)
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // UTF-8 디코딩 처리 (한글 깨짐 방지)
        final List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        // JSON 리스트를 BookDto 리스트로 변환
        return body.map((json) => BookDto.fromJson(json)).toList();
      } else {
        print('신간 조회 실패: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('신간 API 에러: $e');
      return [];
    }
  }

  // 내 서재(MyShelf) 조회 (GET /api/v1/books/myshelf)
  Future<List<BookShelfItemDto>> getMyShelfBooks() async {
    final url = Uri.parse('$baseUrl/api/v1/books/my-shelf/items');

    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        print('내 서재 조회 실패: 토큰 없음');
        return [];
      }

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        return body.map((json) => BookShelfItemDto.fromJson(json)).toList();
      } else {
        print('내 서재 조회 실패: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('내 서재 API 에러: $e');
      return [];
    }
  }
}