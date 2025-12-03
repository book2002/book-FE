import 'dart:convert';
import 'package:Readly/constants.dart';
import 'package:Readly/models/loan_model.dart';
import 'package:Readly/service/auth_service.dart';
import 'package:http/http.dart' as http;

class LoanService {
  final AuthService _authService = AuthService();

  // [1] 도서관 검색 (GET /api/v1/libraries/search)
  Future<List<LibraryResponse>> searchLibraries(int region, String keyword) async {
    final url = Uri.parse('$baseUrl/api/v1/libraries/search')
        .replace(queryParameters: {'region': '$region', 'keyword': keyword});
    
    try {
      final token = await _authService.getAccessToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        return body.map((json) => LibraryResponse.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("도서관 검색 오류: $e");
      return [];
    }
  }

  // [2] 대출 목록 저장 (POST /api/v1/loans)
  Future<bool> createLoan(LoanRequest request) async {
    final url = Uri.parse('$baseUrl/api/v1/loans');
    try {
      final token = await _authService.getAccessToken();
      if (token == null) return false;

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("대출 저장 오류: $e");
      return false;
    }
  }

  // [3] 대출 목록 조회 (GET /api/v1/loans)
  // 단건 반환인지 리스트 반환인지 확인 필요. 명세 상 단건 예시이나 보통 목록 조회는 리스트.
  // 여기서는 List<LoanResponse>로 처리하고, 만약 단건이면 리스트로 감싸서 반환.
  Future<List<LoanResponse>> getLoans() async {
    final url = Uri.parse('$baseUrl/api/v1/loans');
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
          return body.map((json) => LoanResponse.fromJson(json)).toList();
        } else {
          return [LoanResponse.fromJson(body)];
        }
      }
      return [];
    } catch (e) {
      print("대출 목록 조회 오류: $e");
      return [];
    }
  }

  // [4] 대출 반납 처리 (PATCH /api/v1/loan/{loanId}/return)
  Future<bool> returnLoan(int loanId) async {
    final url = Uri.parse('$baseUrl/api/v1/loans/$loanId/return');
    try {
      final token = await _authService.getAccessToken();
      if (token == null) return false;

      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print("반납 처리 오류: $e");
      return false;
    }
  }

  // [5] 대출 목록 삭제 (DELETE /api/v1/loans/{loanId})
  Future<bool> deleteLoan(int loanId) async {
    final url = Uri.parse('$baseUrl/api/v1/loans/$loanId');
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
      print("대출 삭제 오류: $e");
      return false;
    }
  }

  // [6] 대출 목록 수정 (PUT /api/v1/loans/{loanId})
  Future<bool> updateLoan(int loanId, LoanRequest request) async {
    final url = Uri.parse('$baseUrl/api/v1/loans/$loanId');
    try {
      final token = await _authService.getAccessToken();
      if (token == null) return false;

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("대출 수정 오류: $e");
      return false;
    }
  }

  // [7] 즐겨찾기 추가 (POST /api/v1/favorites/libraries)
  Future<bool> addFavoriteLibrary(String libName) async {
    final url = Uri.parse('$baseUrl/api/v1/favorites/libraries');
    try {
      final token = await _authService.getAccessToken();
      if (token == null) return false;

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(FavoriteLibraryRequest(libName: libName).toJson()),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("즐겨찾기 추가 오류: $e");
      return false;
    }
  }

  // [8] 즐겨찾기 조회 (GET /api/v1/favorites/libraries)
  Future<List<FavoriteLibraryResponse>> getFavoriteLibraries() async {
    final url = Uri.parse('$baseUrl/api/v1/favorites/libraries');
    try {
      final token = await _authService.getAccessToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        return body.map((json) => FavoriteLibraryResponse.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("즐겨찾기 조회 오류: $e");
      return [];
    }
  }

  // [9] 즐겨찾기 삭제 (DELETE /api/v1/favorites/libraries/{favoriteId})
  Future<bool> deleteFavoriteLibrary(int favoriteId) async {
    final url = Uri.parse('$baseUrl/api/v1/favorites/libraries/$favoriteId');
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
      print("즐겨찾기 삭제 오류: $e");
      return false;
    }
  }
}