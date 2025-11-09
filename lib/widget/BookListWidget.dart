import 'package:flutter/material.dart';

class BookListWidget extends StatelessWidget {
  //tabType -> 탭별 ui 재정을 위한 매개변수
  final List<Map<String, dynamic>> books;
  final String tabType;

  const BookListWidget({
    Key? key,
    required this.books,
    required this.tabType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true, // 내부 높이를 자동으로 계산
      // physics: NeverScrollableScrollPhysics(), // 외부 스크롤과 충돌 방지
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];

        return Card(
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
                // 책표지
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    book['thumbnail'],
                    width: 100,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),

                // 우측 정보 영역
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text(
                        book['title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        book['author'],
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 10),

                      if (tabType == 'reading') ...[
                        const SizedBox(height: 60),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const SizedBox(width: 170),
                            Expanded(
                              child: LinearProgressIndicator(
                                borderRadius: BorderRadius.circular(16),
                                value: 0.65,
                                color: Colors.green,
                                backgroundColor: Colors.grey[200],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "65%",
                              style: TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ] else if (tabType == 'done') ...[
                        const SizedBox(height: 60),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(5, (i) {
                              return Icon(
                                i < 4 ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 18,
                              );
                            }),
                          ),
                        ),
                      ]
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
