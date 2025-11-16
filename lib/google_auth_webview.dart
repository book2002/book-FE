import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
//import 'package:shared_preferences/shared_preferences.dart'; // 토큰 저장을 위해

class GoogleAuthWebViewPage extends StatefulWidget {
  final String initialUrl;

  const GoogleAuthWebViewPage({Key? key, required this.initialUrl})
      : super(key: key);

  @override
  State<GoogleAuthWebViewPage> createState() => _GoogleAuthWebViewPageState();
}

class _GoogleAuthWebViewPageState extends State<GoogleAuthWebViewPage> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;

  // 백엔드가 로그인을 완료하고 토큰을 전달해주는 최종 목적지 URL입니다.
  final String _successRedirectUrlPrefix = "https://your-backend.com/auth/success";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Google 로그인"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            // 사용자가 수동으로 닫으면 '실패' (null)를 반환
            Navigator.pop(context, false);
          },
        ),
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl)),
            onWebViewCreated: (controller) {
              _webViewController = controller;
            },
            onLoadStart: (controller, url) {
              setState(() {
                _isLoading = true;
              });
              // ✅ 1. URL이 변경될 때마다 감지
              _handleUrlChange(url);
            },
            onLoadStop: (controller, url) {
              setState(() {
                _isLoading = false;
              });
              // ✅ 2. (선택) 페이지 로드가 멈췄을 때도 감지
              _handleUrlChange(url);
            },
            onLoadError: (controller, url, code, message) {
              setState(() {
                _isLoading = false;
              });
              // (선택) 오류 처리
              print("WebView Error: $message");
            },
          ),
          // 로딩 중일 때 스피너 표시
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  void _handleUrlChange(WebUri? url) {
    if (url == null) return;

    final currentUrl = url.toString();

    // ✅ 3. 백엔드가 지정한 성공 URL에 도달했는지 확인
    if (currentUrl.startsWith(_successRedirectUrlPrefix)) {
      setState(() {
        _isLoading = true; // 화면 닫기 전까지 로딩 표시
      });

      // ✅ 4. URL에서 'token' 쿼리 파라미터 추출
      final String? token = url.queryParameters['token'];

      if (token != null && token.isNotEmpty) {
        // ✅ 5. 토큰 저장 및 로그인 성공 처리
        _saveTokenAndClose(token);
      } else {
        // (예외 처리) 성공 URL은 맞는데 토큰이 없는 경우
        print("Success URL detected, but no token found.");
        Navigator.pop(context, false); // 실패로 닫기
      }
    }
  }

  Future<void> _saveTokenAndClose(String token) async {
    try {
      // (예시) SharedPreferences에 토큰 저장
      //final prefs = await SharedPreferences.getInstance();
      //await prefs.setString('authToken', token);

      if (mounted) {
        // ✅ 6. 성공(true)을 반환하며 웹뷰 닫기
        Navigator.pop(context, true);
      }
    } catch (e) {
      print("Failed to save token: $e");
      if (mounted) {
        Navigator.pop(context, false); // 실패로 닫기
      }
    }
  }
}