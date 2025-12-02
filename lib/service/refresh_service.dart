import 'package:flutter/foundation.dart';

// 앱 전역에서 데이터 변경 이벤트를 관리하는 서비스
class RefreshService {
  static final RefreshService _instance = RefreshService._internal();
  factory RefreshService() => _instance;
  RefreshService._internal();

  // 책장(내 서재) 변경 감지 Notifier (책 추가, 상태 변경, 삭제)
  final ValueNotifier<int> bookShelfNotifier = ValueNotifier<int>(0);

  // 리뷰(감상문) 변경 감지 Notifier (작성, 수정, 삭제)
  final ValueNotifier<int> reviewNotifier = ValueNotifier<int>(0);

  // 책장 변경 알림 발생
  void notifyBookShelfChanged() {
    bookShelfNotifier.value++; // 값을 변경하여 리스너들에게 알림
    print("🔔 책장 변경 알림 발송");
  }

  // 리뷰 변경 알림 발생
  void notifyReviewChanged() {
    reviewNotifier.value++;
    print("🔔 리뷰 변경 알림 발송");
  }
}