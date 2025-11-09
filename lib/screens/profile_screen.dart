import 'package:flutter/material.dart';
import 'package:flutter_app/testdata/book_dummy.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // 감상평 카드 위젯 빌더
  Widget _buildReviewCard(Map<String, dynamic> book) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,  //세로축 기준 중앙정렬
            children: [
              // 책 이미지
              Padding(
                padding: const EdgeInsets.all(10),
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(
                    Radius.circular(8),
                  ),
                  child: Image.network(
                    book['thumbnail'],
                    width: 100,
                    //height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              
              // 책 정보
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book['title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book['author'],
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      const Text('★ 3.5'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsetsGeometry.all(12),
            child: const Text(
              "난 진정, 내 안에서 솟아 나오려는 것. 그것을 살아 보려 했다. 왜 그것이 그토록 어려웠을까. 처음 데미안을 읽었던 때와 지금 다른 게 있다면 고등학교 때는 깨고자 하는 알이 없었다는 점이다. 사실 지금도 내가 깨고자 하는 세계가 확실하지는 않다. 나 스스로에 대해 알아가는 시간이 더 많이 필요하다는 반증이다. 그렇지만 어렴풋이 내가 나아가고자 하는 길이 생겼고, 그 길을 위해 노력하고 있다는 점에서 나는 아브락사스에 도달하고 있는 과정 중에 있지 않을까 하는 생각을 해 본다.[출처] 📚헤르만 헤세 '데미안' 줄거리와 느낀 점 : 내 안의 자아를 찾아라.|작성자 윤콩o0",
              style: TextStyle(
                
              ),
              maxLines: 4,
              overflow: TextOverflow.fade,
            ),
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 246, 243),
      body: CustomScrollView(
        slivers: [
          // 🔹 상단 프로필 SliverAppBar
          SliverAppBar(
            backgroundColor: Colors.grey[300],
            pinned: true,
            expandedHeight: 220, // 확장 높이
            collapsedHeight: 80, // 축소 높이
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.grey,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text("한 줄 바이오 설명글"),
                              SizedBox(height: 3,),
                              Text(
                                "user name",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "@user_id",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(right: 10),
                          child: Row(
                            children: [
                              Text("팔로잉 0"),
                              SizedBox(width: 10),
                              Text("팔로워 0"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 15, top: 15),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(30, 0, 0, 0),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.more_vert, size: 18,),
                  ),
                ),
              ),
            ],
          ),

          // 🔹 본문: 독서 현황 제목
          // TODO: 공개 설정한 감상문만 보이도록 설정해야함
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 25, top: 20, bottom: 10),
              child: Text(
                '작성한 감상문',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // 🔹 책 리스트
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final book = dummyBooks[index];
                return _buildReviewCard(book);
              },
              childCount: dummyBooks.length,
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 25, top: 20, bottom: 10),
              child: Text(
                "모임",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ) 
          )
        ],
      ),
    );
  }
}
