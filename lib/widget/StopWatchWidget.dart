import 'dart:async';
import 'package:flutter/material.dart';

class StopwatchWidget extends StatefulWidget {
  const StopwatchWidget({Key? key}) : super(key: key);

  @override
  State<StopwatchWidget> createState() => _StopwatchWidgetState();
}

class _StopwatchWidgetState extends State<StopwatchWidget> {
  late Stopwatch _stopwatch;
  late Timer _timer;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
  }

  @override
  void dispose() {
    if (_timer.isActive) _timer.cancel();
    super.dispose();
  }

  void _startOrPauseTimer() {
    setState(() {
      if (_isRunning) {
        _stopwatch.stop();
        _timer.cancel();
      } else {
        _stopwatch.start();
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          setState(() {}); // 매초마다 UI 업데이트
        });
      }
      _isRunning = !_isRunning;
    });
  }

  void _resetTimer() {
    setState(() {
      //타이머가 동작 중이라면 멈추고 리셋되도록 설정
      if (_isRunning) {
        _stopwatch.stop();
        _timer.cancel();
        _isRunning = !_isRunning;
      }
      _stopwatch.reset();
    });
  }

  String _formatTime() {
    final elapsed = _stopwatch.elapsed;
    final hours = elapsed.inHours.toString().padLeft(2, '0');
    final minutes = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return "$hours : $minutes : $seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(width: 1, color: Colors.grey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "독서 타이머",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 🔹 시:분:초 표시
              Text(
                _formatTime(),
                style: const TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),

              // 🔹 타이머 컨트롤 버튼
              Row(
                children: [
                  IconButton(
                    onPressed: _startOrPauseTimer,
                    icon: Icon(
                      _isRunning ? Icons.pause_circle_filled : Icons.play_circle_fill,
                      color: _isRunning ? Colors.orange : Colors.green,
                      size: 40,
                    ),
                  ),
                  IconButton(
                    onPressed: _resetTimer,
                    icon: const Icon(Icons.refresh, color: Colors.grey, size: 35),
                  ),
                ],
              ),
            ],
          ),
        ],
      )
    );
  }
}
