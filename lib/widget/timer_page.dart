import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_app/constants.dart';

class TimerPage extends StatefulWidget {
  const TimerPage({Key? key}) : super(key: key);

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
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
    if (_isRunning) _timer.cancel();
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
          if (mounted) setState(() {});
        });
      }
      _isRunning = !_isRunning;
    });
  }

  void _resetTimer() {
    setState(() {
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("독서 타이머", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              // decoration: BoxDecoration(
              //   shape: BoxShape.circle,
              //   color: Colors.white,
              //   boxShadow: [
              //     BoxShadow(
              //       color: Colors.grey.withOpacity(0.2),
              //       blurRadius: 20,
              //       spreadRadius: 5,
              //     )
              //   ],
              //   border: Border.all(color: primaryColor.withOpacity(0.5), width: 2)
              // ),
              child: Text(
                _formatTime(),
                style: TextStyle(
                  fontSize: 45,
                  fontWeight: FontWeight.bold,
                  fontFeatures: [const FontFeature.tabularFigures()],
                  color: _isRunning ? Colors.black : Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 60),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 재생/일시정지 버튼
                ElevatedButton(
                  onPressed: _startOrPauseTimer,
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(24),
                    backgroundColor: _isRunning ? Colors.orange : Colors.green,
                  ),
                  child: Icon(
                    _isRunning ? Icons.pause : Icons.play_arrow,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 30),
                // 리셋 버튼
                ElevatedButton(
                  onPressed: _resetTimer,
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(24),
                    backgroundColor: Colors.grey,
                  ),
                  child: const Icon(
                    Icons.refresh,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              _isRunning ? "집중 모드 ON 🔥" : "타이머를 시작해보세요",
              style: TextStyle(
                fontSize: 16, 
                color: _isRunning ? Colors.orange : Colors.grey
              ),
            )
          ],
        ),
      ),
    );
  }
}