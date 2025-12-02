import 'dart:convert';

import 'package:flutter/foundation.dart'; // ValueNotifier를 위해 임포트
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// 앱 전역에서 접근할 수 있는 싱글톤(Singleton)
class AuthService {
  // 싱글톤 인스턴스
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    // 앱 시작 시, 스토리지의 토큰을 확인하여 로그인 상태 초기화
    checkLoginStatus();
  }

  final _storage = const FlutterSecureStorage();

  final ValueNotifier<bool> isLoggedInNotifier = ValueNotifier<bool>(false);    // 로그인 여부
  final ValueNotifier<bool> hasProfileNotifier = ValueNotifier<bool>(false);    // 프로필 생성 여부

  // 현재 로그인 상태인지 (외부에서 .value로 접근)
  bool get isLoggedIn => isLoggedInNotifier.value;
  bool get hasProfile => hasProfileNotifier.value;

    // API 호출을 위한 AccessToken 게터 ---
  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: 'accessToken');
    } catch (e) {
      print("AuthService(getAccessToken) 오류: $e");
      return null;
    }
  }

  // 앱 시작 시 호출되는 함수
  Future<void> checkLoginStatus() async {
    final accessToken = await _storage.read(key: 'accessToken');
    final refreshToken = await _storage.read(key: 'refreshToken');
    final profileStatus = await _storage.read(key: 'hasProfile');

    if (refreshToken == null) {
      // refreshToken이 없으면 무조건 로그아웃 상태
      isLoggedInNotifier.value = false;
      hasProfileNotifier.value = false;
      print("AuthService: refreshToken 없음. 로그아웃 상태.");
      return;
    }

    // TODO: accessToken을 검증하는 API(예: /api/v1/member/me)를 호출하는 것이 가장 이상적
    if (accessToken != null) {
        // (이상적인 로직) 
        // 1. /member/me API 호출
        // 2. 성공 -> isLoggedInNotifier.value = true;
        // 3. 401 에러 -> 4단계(refreshToken으로 갱신)로 이동

        isLoggedInNotifier.value = true;
        hasProfileNotifier.value = (profileStatus == 'true'); 
        print("AuthService: accessToken 존재. 프로필 여부: ${hasProfileNotifier.value}");
        return;
    }
  }
  
  // 로그인 시 호출 (LoginPage에서 사용)
  Future<void> login(String accessToken, String refreshToken, bool isNewUser) async {
    await _storage.write(key: 'accessToken', value: accessToken);
    await _storage.write(key: 'refreshToken', value: refreshToken);

    bool profileExists = !isNewUser; 
    await _storage.write(key: 'hasProfile', value: profileExists.toString());

    isLoggedInNotifier.value = true;
    hasProfileNotifier.value = profileExists;
    print("AuthService: 로그인 성공. 신규 유저 여부: $isNewUser");
  }

  // 프로필 생성 완료 시 호출
  Future<void> completeProfile() async {
    await _storage.write(key: 'hasProfile', value: 'true');
    hasProfileNotifier.value = true;
    print("AuthService: 프로필 생성 완료 처리됨.");
  }

  // 로그아웃 시 호출
  Future<void> logout() async {
    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'refreshToken');
    await _storage.delete(key: 'hasProfile');
    await _storage.delete(key: 'profileId');

    isLoggedInNotifier.value = false;
    hasProfileNotifier.value = false;
    print("AuthService: 로그아웃 성공. 상태 변경 알림.");
  }

  Future<void> saveProfileId(int profileId) async {
    await _storage.write(key: 'profileId', value: "$profileId");
    print("profile 아이디 저장 완료. profileId : $profileId");
  }

  // JWT 토큰에서 profileId 추출
  Future<String?> getProfileIdFromToken() async {
    try {
      final token = await getAccessToken();
      if (token == null) return null;

      final parts = token.split('.');
      if (parts.length != 3) {
        print("🔴 올바르지 않은 JWT 형식입니다.");
        return null;
      }

      final payload = parts[1];
      String normalized = base64Url.normalize(payload);
      String decodedString = utf8.decode(base64Url.decode(normalized));
      Map<String, dynamic> json = jsonDecode(decodedString);

      print("========= 🕵️‍♀️ 토큰 사용자 확인 🕵️‍♀️ =========");
      print("Token 끝자리: ...${token.substring(token.length - 6)}");
      print("User ID (sub): ${json['sub']}"); // ★ 여기가 1번 계정 ID인지 2번 계정 ID인지 확인 필수
      print("profile ID (sub): ${json['profileId']}"); // ★ 여기가 1번 계정 ID인지 2번 계정 ID인지 확인 필수
      print("만료 시간 (exp): ${json['exp']}");
      print("================================================");

      // print("토큰 Payload 데이터: $payloadMap"); // 디버깅용: 콘솔에서 키 이름을 확인

      if (json['profileId'] != null) {
        // 1순위: profileId, 2순위: id, 3순위: sub
        return json['profileId']?.toString() ?? 
               json['id']?.toString() ?? 
               json['sub']?.toString();
      }
      return null;
    } catch (e) {
      print("토큰 디코딩 실패: $e");
      return null;
    }
  }

  String _decodeBase64(String str) {
    String output = str.replaceAll('-', '+').replaceAll('_', '/');
    switch (output.length % 4) {
      case 0: break;
      case 2: output += '=='; break;
      case 3: output += '='; break;
      default: throw Exception('Illegal base64url string!"');
    }
    return utf8.decode(base64Url.decode(output));
  }
}