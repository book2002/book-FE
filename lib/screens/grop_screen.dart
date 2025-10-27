import 'package:flutter/material.dart';
import 'package:flutter_app/testdata/group_dummy.dart';

class GroupScreen extends StatefulWidget {
  const GroupScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  final TextEditingController _searchController = TextEditingController();

  void _onSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('검색어: $query')),
    );

    // TODO: 실제 도서 검색 로직 추가
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //모임 검색창
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '원하는 모임을 찾아보세요',
              //prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSubmitted: (_) => _onSearch(),
          ),

          // TODO: 로그인 상태 확인 후 로그인한 경우에만 내 모임 출력되도록
          const SizedBox(height: 16,),
          const Text('내 모임'),
          const SizedBox(height: 8,),

          //내 모임 칸
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,   //가로 스크롤
              itemCount: dummyGroups.length,
              physics: const AlwaysScrollableScrollPhysics(),   //스크롤 허용
              itemBuilder: (context, index) {
                final group = dummyGroups[index];
                final screenWidth = MediaQuery.of(context).size.width;  //화면 width 크기 불러옴
                final cardWidth = screenWidth-40;

                return Container(
                  width: cardWidth,
                  margin: const EdgeInsets.only(right: 12),
                  child: Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      child: Padding(
                        padding: EdgeInsetsGeometry.all(10),
                        child: Column(
                          //crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group['name'],
                              maxLines: 1,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              group['description'],
                              maxLines: 3,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            )
                          ],
                        ),
                      ),
                      onTap: () {
                        // TODO: 모임 페이지로 이동
                        
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10,),
          const Text("추천하는 모임이에요!"),
        ],
      ),
    );
  }
}