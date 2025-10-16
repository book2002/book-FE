import 'package:flutter/material.dart';
import 'package:flutter_app/testdata/book_dummy.dart';

class BooklistScreen extends StatefulWidget {

  const BooklistScreen ({
    Key? key,
  }) : super(key: key);

  @override
  State<BooklistScreen> createState() => _BooklistScreenState();
}

class _BooklistScreenState extends State<BooklistScreen> {
  //tabType -> 탭별 ui 재정을 위한 매개변수
  Widget _buildBookList(List<Map<String, dynamic>> books, String tabType) {
    return ListView.builder(
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];

        //공통 ui
        final bookCard = Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Colors.white,
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //책표지
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    book['thumbnail'],
                    width: 100,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12,),

                //우측 텍스트 정보칸
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6,),
                      Text(
                        book['title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6,),
                      Text(
                        book['author'],
                        style: const TextStyle(
                          color: Colors.grey
                        ),
                      ),
                      const SizedBox(height: 10),

                      if (tabType=='reading') ...[
                        const SizedBox(height: 60,),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const SizedBox(width: 170,),
                            Expanded(
                              child: LinearProgressIndicator(
                                borderRadius: BorderRadius.circular(16),
                                value: 0.65,
                                color: Colors.green,
                                backgroundColor: Colors.grey[200],
                              ),
                            ),
                            const SizedBox(width: 8,),
                            const Text(
                              "65%",
                              style: TextStyle(
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ] else if (tabType=='done')...[
                        const SizedBox(height: 60,),
                        Align(
                          alignment: Alignment.bottomRight, //오른쪽 하단에 정렬
                          child: Row(
                            mainAxisSize: MainAxisSize.min, //내부 크기만큼만 차지
                            children: List.generate(5, (i) {
                              return Icon(
                                i < 4 ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 18,
                              );
                            }),
                          ),
                        )
                      ]
                    ],
                  )
                )
              ],
            ),
            
          ),
        );

        return bookCard;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Padding(
        padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0),
        child: Column(
          children: [
            //상단 탭바
            const TabBar(
              labelColor: Colors.black,
              indicatorColor: Colors.green,
              tabs: [
                Tab(text: "읽는 중"),
                Tab(text: "읽기 전"),
                Tab(text: "다 읽은"),
              ]
            ),
            //하단
            Expanded(
              child: TabBarView(
                children: [
                  _buildBookList(dummyBooks, 'reading'),
                  _buildBookList(dummyBooks, 'before'),
                  _buildBookList(dummyBooks, 'done'),
                ]
              ),
            ),
          ],
        ),
      ),
    );
  }
}