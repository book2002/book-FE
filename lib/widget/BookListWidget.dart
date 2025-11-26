import 'package:flutter/material.dart';
import 'package:flutter_app/bookpage/book_detail.dart';
import 'package:flutter_app/models/book_model.dart';

class BookListWidget extends StatelessWidget {
  //tabType -> 탭별 ui 재정을 위한 매개변수
  final List<dynamic> books;  // dynamic 설정으로 BookDto(검색)와 BookShelfItemDto(내 서재) 모두 사용

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
      physics: const NeverScrollableScrollPhysics(), // 외부 스크롤과 충돌 방지
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index] ?? [];

        // 타입에 따라 필드 값을 추출
        String title = '';
        String author = '';
        String thumbnail = '';
        String isbn = '';
        String description = '';
        String publisher = '';
        String publishedDate = '';

        // 진행률 관련 (BookShelfItemDto에만 존재)
        double progressValue = 0.0;
        String progressPercent = '';

        if (book is BookDto) {    // 검색 결과 / 베스트셀러 모델
          title = book.title;
          author = book.authorsString;
          thumbnail = book.thumbnail;
          isbn = book.isbn;
          description = book.contents;
          publisher = book.publisher;
          publishedDate = book.datetime;
        } else if (book is BookShelfItemDto) {  // 내 책장 아이템 모델
          title = book.title;
          author = book.author; // DTO 필드명이 다름 (author vs authors)
          thumbnail = book.thumbnail ?? '';
          isbn = book.isbn;
          // 책장 목록 API에는 보통 상세 줄거리가 포함되지 않으므로 빈값 처리
          description = ''; 
          
          // 진행률 계산
          progressValue = book.progressValue;
          progressPercent = book.progressPercent;
        }

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Colors.white,
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: InkWell( // 클릭 이벤트를 위해 InkWell 추가
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              // 클릭 시 BookDetailPage로 이동하며 상세 데이터 전달
              Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (context) => BookDetailPage(
                    isbn: isbn,
                    title: title,
                    author: author,
                    thumbnail: thumbnail.isNotEmpty ? thumbnail : "",
                    description: description, // 줄거리 전달
                    publisher: publisher,  // 출판사 전달
                    publishedDate: publishedDate, // 출판일 전달
                  )
                )
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 책표지
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      book.thumbnail.isNotEmpty ? book.thumbnail : 'https://via.placeholder.com/100x150',   // 이미지 없을 경우 임의 이미지
                      width: 100,
                      height: 150,
                      fit: BoxFit.cover,
                      // 이미지 로드 에러 처리
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 100, height: 150, color: Colors.grey[300], child: const Icon(Icons.broken_image),
                      ),
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
                          book.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          author,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 10),

                        // [변경 사항] 탭 타입에 따른 UI 분기 로직
                        if (tabType == 'reading' && book is BookShelfItemDto) ...[
                          const SizedBox(height: 60),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const SizedBox(width: 170),
                              Expanded(
                                child: LinearProgressIndicator(
                                  borderRadius: BorderRadius.circular(16),
                                  value: progressValue,   // 실제 진행률
                                  color: Colors.green,
                                  backgroundColor: Colors.grey[200],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                progressPercent,    // 실제 퍼센트
                                style: TextStyle(fontSize: 12),
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
          ),
        );
      },
    );
  }
}
