import 'package:flutter/material.dart';
import 'package:flutter_app/widget/HabitTrackerWidget.dart';
import 'package:flutter_app/widget/StopWatchWidget.dart';

class HelperScreen extends StatefulWidget {
  const HelperScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _HelperScreenState();
}

class _HelperScreenState extends State<HelperScreen> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              "목표까지 N권 \n남았어요!",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 50,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const HabitTracker(),     //해빗트래커 연결 
          
          const SizedBox(height: 20,),
          Padding(
            //타이머 주변 여백 설정
            padding: EdgeInsetsGeometry.symmetric(horizontal: 26, vertical: 10),
            child: const StopwatchWidget(),  //스톱워치 연결
          ),
          
        ],
      ),
    );
  }
}