import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  //책 더미 데이터
  final List<Map<String, dynamic>> _books = [
    {
      'title': '데미안',
      'author': '헤르만 헤세',
      'thumbnail': 'https://covers.openlibrary.org/b/id/8231856-L.jpg',
    },
    {
      'title': '1984',
      'author': '조지 오웰',
      'thumbnail': 'https://covers.openlibrary.org/b/id/7222246-L.jpg',
    },
    {
      'title': '어린 왕자',
      'author': '앙투안 드 생텍쥐페리',
      'thumbnail': 'https://covers.openlibrary.org/b/id/8101341-L.jpg',
    },
  ];

  void _onSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('검색어: $query')),
    );

    // TODO: 실제 도서 검색 로직 추가 (API 연결 등)
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Padding(
      padding: const EdgeInsets.all(20.0),  //margin 설정
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          //도서 검색창
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '도서명을 입력하세요',
              //prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSubmitted: (_) => _onSearch(),
          ),
          const SizedBox(height: 16,),
          const Text('현재 읽고 있는 책이에요.'),
          const SizedBox(height: 8,),
          //카드뷰
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal, //가로 스크롤
              itemCount: _books.length,
              shrinkWrap: true,         //내부 높이 내용에 맞게 계산
              physics: const AlwaysScrollableScrollPhysics(), //스크롤 허용
              itemBuilder: (context, index) {
                final book = _books[index];
                final screenWidth = MediaQuery.of(context).size.width;
                final cardWidth = screenWidth/2-30;   //화면 절반, 여백 보정
                
                return Container(
                  width: cardWidth,
                  margin: const EdgeInsets.only(right: 12),
                  child: Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  //margin: const EdgeInsets.symmetric(vertical: 8),
                  child: InkWell(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        //왼편: 이미지
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                          child: Image.network(
                            book['thumbnail'],
                            width: cardWidth*0.3, //카드 너비 약 40% 사용
                            height: 120,
                            fit: BoxFit.cover,    //이미지를 영역에 가득 채움
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  book['title'],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  book['author'],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12
                                  ),
                                ),
                              ],
                            ),
                          )
                        )
                        
                      ],
                    ),
                    onTap: () {
                      // TODO: 책 상세 페이지로 이동
                    },
                  ),
                ) 
                  
                );
              },
            ),
          ),
          const SizedBox(height: 10,),
          const Text("추천 도서")
        ],
      ),
    );
  }
}