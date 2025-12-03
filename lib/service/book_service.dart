import 'dart:convert';
import 'package:Readly/constants.dart';
import 'package:Readly/models/book_model.dart';
import 'package:Readly/service/auth_service.dart';
import 'package:http/http.dart' as http;

class BookService {
  // 모든 기능 로그인 전제로 수행됨
  // 안드로이드 에뮬레이터: 10.0.2.2, iOS 시뮬레이터: 127.0.0.1
  final AuthService _authService = AuthService();

  // 도서 검색 (GET /api/v1/books/search)
  Future<List<BookDto>> getSearchBooks(String query) async {
    final url = Uri.parse('$baseUrl/api/v1/books/search').replace(queryParameters: {'query': query});

    try {
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
  // Return: List<BookDto>
  Future<List<BookDto>> getBestsellers() async {
    final url = Uri.parse('$baseUrl/api/v1/books/bestseller');

    try {
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
        print('베스트셀러 조회 실패: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('베스트셀러 API 에러: $e');
      return [];
    }
  }

  // 도서 추천 API
  // GET /api/v1/recommendations?category={category}
  Future<List<BookDto>> getRecommendations(String category) async {
    final url = Uri.parse('$baseUrl/api/v1/recommendations')
        .replace(queryParameters: {'category': category});

    try {
      final token = await _authService.getAccessToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(url, headers: headers);
      print(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        // BookDto 변환
        return (body).map((json) => BookDto.fromJson(json)).toList();
      } else {
        print('추천 도서 조회 실패: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('추천 도서 API 에러: $e');
      return [];
    }
  }

  // 신간 도서 조회
  Future<List<BookDto>> getNewReleases() async {
    final url = Uri.parse('$baseUrl/api/v1/books/new-releases');
    // ... (위와 동일한 로직)
    try {
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
        print('신간 조회 실패: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('신간 API 에러: $e');
      return [];
    }
  }

  // 내 서재(MyShelf) 조회 (GET /api/v1/books/my-shelf)
  Future<List<BookShelfItemDto>> getMyShelfBooks() async {
    final url = Uri.parse('$baseUrl/api/v1/my-shelf/items');

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

  // 책장에 책 저장 (POST /api/my-shelf/items)
  Future<BookShelfItemDto?> saveBookToShelf(BookSaveRequest requestDto) async {
    // 요청 URL: POST /api/my-shelf/items
    final url = Uri.parse('$baseUrl/api/v1/my-shelf/items');

    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        print('책장 저장 실패: 로그인 필요');
        return null;
      }

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestDto.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("책장 저장 성공: ${response.body}");
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        return BookShelfItemDto.fromJson(body);
      } else {
        // [디버깅] 오류 메시지 출력 (UTF-8 디코딩 시도)
        try {
           print("책장 저장 실패: ${utf8.decode(response.bodyBytes)}");
        } catch (_) {
           print("책장 저장 실패: ${response.statusCode}");
        }
        return null;
      }
    } catch (e) {
      print('책장 저장 API 에러: $e');
      return null;
    }
  }

  // 저장된 도서 상태 변경 (PATCH api/my-shelf/items/{itemId}/state)
  Future<bool> updateBookState(int itemId, BookStateUpdateRequest requestDto) async {
    final url = Uri.parse('$baseUrl/api/v1/my-shelf/items/$itemId/state');

    try {
      final token = await _authService.getAccessToken();
      if (token == null) return false;

      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestDto.toJson()),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print("상태 변경 실패: ${response.body}");
        return false;
      }
    } catch (e) {
      print('상태 변경 API 에러: $e');
      return false;
    }
  }

  // 저장된 도서 목록 삭제 (DELETE api/v1/my-shelf/{itemId})
  Future<bool> deleteBookFromShelf(int itemId) async {
    final url = Uri.parse('$baseUrl/api/v1/my-shelf/items/$itemId');

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
        return true;
      } else {
        print("삭제 실패: ${response.body}");
        return false;
      }
    } catch (e) {
      print('삭제 API 에러: $e');
      return false;
    }
  }
}