import 'package:flutter/material.dart';
import 'package:flutter_app/service/habit_service.dart';
import 'package:intl/intl.dart'; // 날짜 포맷용
import 'package:table_calendar/table_calendar.dart'; // [필수] 달력 패키지 추가 (pubspec.yaml에 table_calendar 추가 필요)

class HabitTracker extends StatefulWidget {
  const HabitTracker({Key? key}) : super(key: key);

  @override
  State<HabitTracker> createState() => _HabitTrackerState();
}

class _HabitTrackerState extends State<HabitTracker> {
  final HabitService _habitService = HabitService();

  late DateTime today;
  late List<DateTime> weekDays;
  
  // 날짜별 체크 여부 (YYYY-MM-DD : bool)
  Map<String, bool> habitStatus = {}; 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    today = DateTime.now();
    _generateWeekDays();
    _fetchWeeklyStatus();
  }

  void _generateWeekDays() {
    // 일주일 전 ~ 오늘 ~ 일주일 후 날짜 계산
    weekDays = List.generate(7, (index) {
      return today.subtract(Duration(days: 3 - index));   // 오늘- 중앙(인덱스 3)에 위치
    });
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // 서버에서 이번 달 기록을 가져와서 주간 상태 갱신
  Future<void> _fetchWeeklyStatus() async {
    try {
      // 이번 주에 걸쳐있는 달(Month)이 다를 수 있음 (월말/월초)
      // 간단하게 오늘이 속한 달의 기록만 가져오거나, 
      // 필요하면 이전달/다음달도 가져와야 함. 여기선 '오늘 기준 월'만 조회
      final records = await _habitService.getMonthlyRecords(today.year, today.month);
      
      // 만약 주간 범위가 지난달/다음달에 걸쳐있다면 추가 조회 로직 필요 (생략 가능)

      if (mounted) {
        setState(() {
          for (var recordDate in records) {
            habitStatus[recordDate] = true;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _checkToday() async {
    final todayStr = _formatDate(today);
    
    // 이미 체크되어 있다면 중복 방지
    if (habitStatus[todayStr] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("이미 기록되었습니다.")));
      return;
    }

    final result = await _habitService.saveHabitRecord(todayStr);
    if (result != null) {
      setState(() {
        habitStatus[todayStr] = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("기록에 실패했습니다.")));
    }
  }

  // 달력 모달
  void _showCalendarModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _CalendarModal(habitService: _habitService),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final circleSize = (screenWidth - 40 - (12 * 6)) / 7;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 16),

        // 해빗트래커 표시 영역
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(7, (index) {
            final date = weekDays[index];
            final formatted = _formatDate(date);
            final isToday = formatted == _formatDate(today);
            final isChecked = habitStatus[formatted] ?? false;
            final isFuture = date.isAfter(today);   // 미래 날짜인지 확인

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                children: [
                  const SizedBox(height: 6),
                  // 원형 아이콘
                  CircleAvatar(
                    radius: circleSize/2 - 1,   // 반지름
                    backgroundColor: isChecked
                        ? Colors.green
                        : Colors.grey[300],
                    child: isChecked
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : (isToday ? const Icon(Icons.star, color: Colors.white, size: 16) : null),
                  ),
                  const SizedBox(height: 4),
                  // 날짜 숫자
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isFuture ? Colors.grey[400] : Colors.black,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),

        const SizedBox(height: 12),

        // 오늘 체크 버튼
        ElevatedButton(
          onPressed: _checkToday,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
          ),
          child: const Text(
            "오늘의 독서 기록하기",
            style: TextStyle(fontSize: 12, color: Colors.white, ),
          ),
        ),
        SizedBox(height: 12,),

        InkWell(
          onTap: _showCalendarModal,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "독서 달력 확인하기",
                  style: TextStyle(
                    color: Colors.grey
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_right_rounded,
                  color: Colors.grey[300],
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// 달력 모달 위젯
class _CalendarModal extends StatefulWidget {
  final HabitService habitService;
  const _CalendarModal({Key? key, required this.habitService}) : super(key: key);

  @override
  State<_CalendarModal> createState() => _CalendarModalState();
}

class _CalendarModalState extends State<_CalendarModal> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<String> _monthlyRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMonthly(_focusedDay);
  }

  void _fetchMonthly(DateTime date) async {
    setState(() { _isLoading = true; });
    final records = await widget.habitService.getMonthlyRecords(date.year, date.month);
    if (mounted) {
      setState(() {
        _monthlyRecords = records;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text("나의 독서 기록", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _isLoading 
            ? const Expanded(child: Center(child: CircularProgressIndicator()))
            : TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                locale: 'ko_KR', // 로케일 설정 (main.dart 설정 필요)
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                calendarStyle: const CalendarStyle(
                  todayDecoration: BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                  selectedDecoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                  markerDecoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                ),
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                  _fetchMonthly(focusedDay); // 월 변경 시 데이터 다시 로드
                },
                
                // 마커 빌더 (기록 있는 날 동그라미 표시)
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    final dateStr = DateFormat('yyyy-MM-dd').format(date);
                    if (_monthlyRecords.contains(dateStr)) {
                      return Positioned(
                        bottom: 1,
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green,
                          ),
                          width: 6.0,
                          height: 6.0,
                        ),
                      );
                    }
                    return null;
                  },
                  // 기록이 있는 날짜의 텍스트 스타일 변경 (선택 사항)
                  defaultBuilder: (context, day, focusedDay) {
                    final dateStr = DateFormat('yyyy-MM-dd').format(day);
                    if (_monthlyRecords.contains(dateStr)) {
                      return Center(
                        child: Container(
                          width: 35, height: 35,
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(child: Text('${day.day}')),
                        ),
                      );
                    }
                    return null;
                  },
                ),
              ),
        ],
      ),
    );
  }
}