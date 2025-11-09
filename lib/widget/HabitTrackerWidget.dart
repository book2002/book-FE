import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 날짜 포맷용

class HabitTracker extends StatefulWidget {
  const HabitTracker({Key? key}) : super(key: key);

  @override
  State<HabitTracker> createState() => _HabitTrackerState();
}

class _HabitTrackerState extends State<HabitTracker> {
  late DateTime today;
  late List<DateTime> weekDays;
  late Map<String, bool> habitStatus; // 날짜별 체크 상태 저장

  @override
  void initState() {
    super.initState();
    today = DateTime.now();
    _generateWeekDays();
  }

  void _generateWeekDays() {
    // 일주일 전 ~ 오늘 ~ 일주일 후 날짜 계산
    weekDays = List.generate(7, (index) {
      // 오늘을 중앙(인덱스 3)에 위치하도록
      return today.subtract(Duration(days: 3 - index));
    });

    // 상태 초기화
    habitStatus = {
      for (var day in weekDays) _formatDate(day): false,
    };
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  bool _isFuture(DateTime date) {
    return date.isAfter(today);
  }

  void _toggleHabit(DateTime date) {
    final key = _formatDate(date);
    if (!_isFuture(date)) {
      setState(() {
        habitStatus[key] = !(habitStatus[key] ?? false);
      });
    }
  }

  void _checkToday() {
    final key = _formatDate(today);
    setState(() {
      habitStatus[key] = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // const Text(
        //   '이번 주 목표 달성 현황',
        //   style: TextStyle(
        //     fontSize: 18,
        //     fontWeight: FontWeight.bold,
        //   ),
        // ),
        const SizedBox(height: 16),

        // 해빗트래커 표시 영역
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(7, (index) {
            final date = weekDays[index];
            final formatted = _formatDate(date);
            final isToday = _formatDate(date) == _formatDate(today);
            final isChecked = habitStatus[formatted] ?? false;
            final isFuture = _isFuture(date);

            return GestureDetector(
              onTap: isFuture ? null : () => _toggleHabit(date),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  children: [
                    const SizedBox(height: 6),
                    // 원형 아이콘
                    CircleAvatar(
                      radius: isToday ? 22 : 22,
                      backgroundColor: isChecked
                          ? Colors.green
                          : Colors.grey[300],
                      child: isToday
                          ? const Icon(Icons.star, color: Colors.white, size: 20)
                          : null,
                    ),
                    const SizedBox(height: 4),
                    // 날짜 숫자
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isFuture ? Colors.grey[400] : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 24),

        // 오늘 체크 버튼
        ElevatedButton(
          onPressed: () {
            _checkToday();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          ),
          child: const Text(
            "오늘의 목표 달성 체크하기",
            style: TextStyle(fontSize: 20, color: Colors.white, ),
          ),
        ),
      ],
    );
  }
}
