import 'package:flutter/material.dart';
import 'package:flutter_app/screens/details/loan_info_page.dart';
import 'package:flutter_app/widget/HabitTrackerWidget.dart';
import 'package:flutter_app/widget/StopWatchWidget.dart';

class HelperScreen extends StatefulWidget {
  const HelperScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _HelperScreenState();
}

class _HelperScreenState extends State<HelperScreen> {
    // [추가] 사용하신 Base64 이미지 문자열을 변수로 분리 (코드 가독성 위함)
  final String _bookImageBase64 = "https://contents.kyobobook.co.kr/sih/fit-in/400x0/pdt/9788966260959.jpg";

  @override
  Widget build(BuildContext context) {
    return SafeArea(    // 노치나 하단 홈 바 영역을 침범하지 않도록 보호
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text.rich(
                TextSpan(
                  // 전체 텍스트에 공통으로 적용될 기본 스타일 유지
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                    // 기본 색상이 필요하다면 여기에 color: Colors.black 등을 명시 가능
                  ),
                  children: [
                    // [변경] 텍스트를 쪼개서 입력
                    const TextSpan(text: "목표까지 "), // 앞부분 텍스트
                    TextSpan(
                      text: "2", // 색상을 바꿀 숫자
                      // [변경] 숫자 '2'에만 적용할 특정 색상 지정 (예: primary color 또는 특정 색)
                      style: TextStyle(color: Colors.green), 
                    ),
                    const TextSpan(text: "권 남았어요!"), // 뒷부분 텍스트 (\n 포함)
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            // [변경] 고정된 SizedBox(height) 대신 Spacer를 사용하여 남는 공간을 유연하게 배분
            //const Spacer(flex: 1),

            // [변경] Expanded 사용: 해빗트래커가 남은 공간의 일부를 차지하도록 변경 (비율 조정 가능)
            const Expanded(
              flex: 2, // 필요에 따라 flex 값 조절 (예: 트래커가 스톱워치보다 더 많은 공간 차지)
              child: HabitTracker(), 
            ),

            //const Spacer(flex: 1),
            
            //const SizedBox(height: 24,),
            Expanded(
              child: Padding(
                //타이머 주변 여백 설정
                padding: EdgeInsetsGeometry.symmetric(horizontal: 10,),
                child: const StopwatchWidget(),  //스톱워치 연결
              ),
            ),

            //const Spacer(flex: 1,),
            //const SizedBox(height: 10,),
            
            Padding(
              padding: EdgeInsetsGeometry.symmetric(horizontal: 10, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        //fontSize: 30,
                      ),
                      children: [
                        const TextSpan(text: "  클린 코드 및 1권의 반납일이 "),
                        const TextSpan(
                          text: "D-2",
                          style: TextStyle(color: Colors.orange)
                        ),
                        const TextSpan(text: "에요."),
                      ]
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10,),
                  Container(
                    width: double.infinity,   // 부모 위젯이 허락하는 최대 너비를 가짐
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(width: 1, color: const Color(0xFFE1E1E1)),
                    ),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "📍 부경대학교 중앙도서관",
                                style: TextStyle(
                                  fontSize: 10
                                ),
                              ),
                              SizedBox(height: 6,),
                              Row(
                                children: [
                                  SizedBox(width: 6,),
                                  // [수정] Image 위젯을 SizedBox로 감싸서 명확한 크기 제약을 제공
                                  // Image.memory 내부의 width/height 속성 대신 SizedBox를 사용하면
                                  // 'Infinity or NaN toInt' 오류를 방지할 수 있습니다.
                                  SizedBox(
                                    width: 50,
                                    height: 75,
                                    child: Image.network(
                                      "https://contents.kyobobook.co.kr/sih/fit-in/400x0/pdt/9788966260959.jpg",
                                      fit: BoxFit.cover, // 이미지가 영역을 벗어나지 않도록 fit 설정
                                    ),
                                  ),
                                  
                                  const SizedBox(width: 12,),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "클린 코드",
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      ),
                                      Text("반납일 : 2025-11-24")
                                    ],
                                  )
                                ],
                              )
                              
                            ],
                          ),
                          InkWell(
                            onTap: () {
                              // [신규 추가] 클릭 시 LoanInfoPage로 화면 이동
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const LoanInfoPage()),
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Icon(
                              Icons.keyboard_arrow_right_rounded,
                              size: 30,
                              color: Colors.grey,
                            ),
                          ),
                        ],                    
                    )
                  ),
                ],
              )
              
            ),
          ],
        ),
      )
    );
    
  }
}