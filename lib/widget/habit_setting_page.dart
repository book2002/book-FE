import 'package:flutter/material.dart';
import 'package:Readly/models/habit_model.dart';
import 'package:Readly/service/habit_service.dart';

class HabitSettingPage extends StatefulWidget {
  const HabitSettingPage({Key? key}) : super(key: key);

  @override
  State<HabitSettingPage> createState() => _HabitSettingPageState();
}

class _HabitSettingPageState extends State<HabitSettingPage> {
  final HabitService _habitService = HabitService();
  List<ReadingHabitResponse> _habits = [];
  bool _isLoading = true;

  // 요일 매핑 (백엔드 코드 -> 표시용 텍스트)
  final Map<String, String> _dayMap = {
    "MON": "월", "TUE": "화", "WED": "수", "THU": "목", "FRI": "금", "SAT": "토", "SUN": "일"
  };
  final List<String> _dayKeys = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"];

  @override
  void initState() {
    super.initState();
    _fetchHabits();
  }

  Future<void> _fetchHabits() async {
    setState(() { _isLoading = true; });
    try {
      final habits = await _habitService.getHabits();
      if (mounted) {
        setState(() {
          _habits = habits;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  // 습관 생성/수정 모달
  void _showHabitModal({ReadingHabitResponse? habit}) {
    // 초기값 설정
    TimeOfDay selectedTime = TimeOfDay.now();
    if (habit != null) {
      final parts = habit.targetTime.split(":");
      selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    
    // 선택된 요일 Set
    Set<String> selectedDays = habit != null ? habit.recurringDays.toSet() : {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return StatefulBuilder( // 모달 내부 상태 갱신을 위해 사용
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20, right: 20, top: 20
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(habit == null ? "습관 추가하기" : "습관 수정하기", 
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), 
                    textAlign: TextAlign.center
                  ),
                  const SizedBox(height: 30),
                  
                  // 1. 시간 선택
                  const Text("시간 선택", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (picked != null) {
                        setModalState(() { selectedTime = picked; });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}",
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 2. 요일 선택
                  const Text("요일 반복", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _dayKeys.map((dayKey) {
                      bool isSelected = selectedDays.contains(dayKey);
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            if (isSelected) {
                              selectedDays.remove(dayKey);
                            } else {
                              selectedDays.add(dayKey);
                            }
                          });
                        },
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? Colors.green : Colors.transparent,
                            border: Border.all(color: isSelected ? Colors.green : Colors.grey.shade400),
                          ),
                          child: Center(
                            child: Text(
                              _dayMap[dayKey]!,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey,
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 40),

                  // 저장 버튼
                  ElevatedButton(
                    onPressed: () async {
                      if (selectedDays.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("요일을 하나 이상 선택해주세요.")));
                        return;
                      }
                      
                      Navigator.pop(context); // 모달 닫기

                      // HH:mm 포맷팅
                      String formattedTime = "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}";
                      
                      bool success;
                      if (habit == null) {
                        success = await _habitService.createHabit(formattedTime, selectedDays.toList());
                      } else {
                        success = await _habitService.updateHabit(habit.id, formattedTime, selectedDays.toList());
                      }

                      if (success) {
                        _fetchHabits();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("저장되었습니다.")));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("저장 실패")));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("저장", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 습관 삭제
  void _deleteHabit(int habitId) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("삭제 확인"),
        content: const Text("이 습관을 삭제하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("삭제", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      bool success = await _habitService.deleteHabit(habitId);
      if (success) {
        _fetchHabits();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("삭제되었습니다.")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("삭제 실패")));
      }
    }
  }

  // 알림 활성화 토글
  void _toggleActive(int habitId, bool newValue) async {
    bool success = await _habitService.updateHabitActive(habitId, newValue);
    print(newValue);
    if (success) {
      _fetchHabits(); // 목록 전체 갱신 (또는 로컬 상태만 변경 가능)
    } else {
      print("상태 변경 실패");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("상태 변경 실패")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("독서 습관 설정", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showHabitModal(),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _habits.isEmpty
          ? const Center(child: Text("등록된 독서 습관이 없습니다.\n알림을 추가해보세요!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _habits.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final habit = _habits[index];
                // 요일 표시 문자열 생성 (순서 보장을 위해 _dayKeys 순회)
                List<String> displayDays = [];
                for (var key in _dayKeys) {
                  if (habit.recurringDays.contains(key)) {
                    displayDays.add(_dayMap[key]!);
                  }
                }
                String dayString = displayDays.join(", ");

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      // 알림 스위치
                      Switch(
                        value: habit.isActive,
                        activeColor: Colors.green,
                        onChanged: (val) => _toggleActive(habit.id, val),
                      ),
                      const SizedBox(width: 8),
                      // 정보
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(habit.targetTime, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: habit.isActive ? Colors.black : Colors.grey)),
                            Text(dayString, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      ),
                      // 더보기 버튼
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                        onSelected: (val) {
                          if (val == 'edit') _showHabitModal(habit: habit);
                          else if (val == 'delete') _deleteHabit(habit.id);
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text("수정")),
                          const PopupMenuItem(value: 'delete', child: Text("삭제", style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}