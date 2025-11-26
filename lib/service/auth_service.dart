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

  // 'isLoggedIn' 상태를 관찰(Listen)할 수 있는 Notifier false로 시작
  final ValueNotifier<bool> isLoggedInNotifier = ValueNotifier<bool>(false);
  // 현재 로그인 상태인지 (외부에서 .value로 접근)
  bool get isLoggedIn => isLoggedInNotifier.value;

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

    if (refreshToken == null) {
      // refreshToken이 없으면 무조건 로그아웃 상태
      isLoggedInNotifier.value = false;
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
        print("AuthService: accessToken 존재. 우선 로그인 상태로 설정.");
        return;
    }
  }
  
  // 로그인 시 호출 (LoginPage에서 사용)
  Future<void> login(String accessToken, String refreshToken) async {
    await _storage.write(key: 'accessToken', value: accessToken);
    await _storage.write(key: 'refreshToken', value: refreshToken);
    // 상태가 true로 변경되었음을 Notifier에 알림
    isLoggedInNotifier.value = true;
    print("AuthService: 로그인 성공. 상태 변경 알림.");
  }

  // 로그아웃 시 호출
  Future<void> logout() async {
    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'refreshToken');
    // 상태가 false로 변경되었음을 Notifier에 알림
    isLoggedInNotifier.value = false;
    print("AuthService: 로그아웃 성공. 상태 변경 알림.");
  }

  Future<void> saveProfileId(int profileId) async {
    await _storage.write(key: 'profileId', value: "$profileId");
    print("profile 아이디 저장 완료. profileId : $profileId");
  }

  Future<String?> getProfileId() async {
    try {
      return await _storage.read(key: 'profileId');
    } catch (e) {
      print("AuthService(getProfileId) 오류: $e");
      return null;
    }
  }

  // JWT 토큰에서 profileId 추출
  Future<String?> getProfileIdFromToken() async {
    try {
      final token = await getAccessToken();
      if (token == null) return null;

      final parts = token.split('.');
      if (parts.length != 3) return null;

      // Payload 부분 (두 번째 부분) 디코딩
      final payload = _decodeBase64(parts[1]);
      final payloadMap = json.decode(payload);

      print("토큰 Payload 데이터: $payloadMap"); // 디버깅용: 콘솔에서 키 이름을 확인

      if (payloadMap is Map<String, dynamic>) {
        // 1순위: profileId, 2순위: id, 3순위: sub
        return payloadMap['profileId']?.toString() ?? 
               payloadMap['id']?.toString() ?? 
               payloadMap['sub']?.toString();
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