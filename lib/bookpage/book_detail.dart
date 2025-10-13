import 'package:flutter/material.dart';

class BookDetailPage extends StatefulWidget {
  final String title;
  final String author;
  final String thumbnail;

  const BookDetailPage ({
    Key? key,
    required this.title,
    required this.author,
    required this.thumbnail,
  }) : super(key: key);

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,        //탭 개수
      child:  Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
          actions: [],
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              //상단
              Container(
                height: 300,
                padding: const EdgeInsets.only(left: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //책 표지
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.thumbnail,
                        height: 250,
                        fit: BoxFit.cover,
                      ),
                    ),
                    //책 정보
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            //제목
                            Text(
                              widget.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              //textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10,),
                            //저자
                            Text(
                              widget.author,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 10,),
                            //추가 버튼
                            ElevatedButton.icon(
                              onPressed: () {
                                //TODO: 책장 추가 로직 구현
                              }, 
                              icon: const Icon(Icons.bookmark_outline),
                              label: const Text("책장에 추가"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                )
                              )
                            )
                          ],
                        ),
                      )
                    ),
                  ],
                ),
              ),
              
              //const SizedBox(height: 10,),
              
              //하단 탭 윈도우
              const TabBar(
                labelColor: Colors.black,
                indicatorColor: Colors.green,
                tabs:[
                  Tab(text: "책 정보",),
                  Tab(text: "독서 노트",),
                ] 
              ),

              Expanded(
                child: TabBarView(
                  children: [
                    //책 정보
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: const Text(
                        '이 책에 대한 상세 설명이 여기에 표시됩니다.\n\n'
                        '이 부분은 스크롤이 가능하며, 나중에 API 데이터를 불러와서 '
                        '책 줄거리나 저자 설명 등을 표시할 수 있습니다.',
                        style: TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    //독서 노트
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      //TODO: 가운데 정렬 구현
                      child: const Text(
                        '작성한 독서 노트가 없어요. 노트를 추가해보세요!',
                        style: TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ]
                ),
              ),

            ],
          ),
        ),
        //독서노트 탭을 클릭했을 때만 해당 버튼이 출력되도록 변경
        floatingActionButton: FloatingActionButton(
          onPressed: () {

          },
          child: Icon(Icons.add, color: Colors.white,),
          backgroundColor: Colors.green,
          elevation: 0,
          shape: CircleBorder(),
        ),
      )

    );
  }
}