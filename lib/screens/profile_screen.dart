import 'package:flutter/material.dart';
import 'package:flutter_app/testdata/book_dummy.dart';

class ProfileScreen extends StatefulWidget {

  const ProfileScreen ({
    Key? key,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Widget _buildReviewCard(BuildContext context, List<Map<String, dynamic>> books) {
    return ListView.builder(
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];

        final reviewCard = Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              //padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //이미지
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    child: Image.network(
                      book['thumbnail'],
                      width: 100,
                      //height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                  //감상평
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book['title'],
                            //maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4,),
                          Text('감상평입니다...'),
                        ],
                      ),
                    )
                  )
                ],
              ),
            ),

        );

        return reviewCard;
      }
    );
  }

  //TODO: 본인, 타사용자 구분
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          //프로필 헤더 영역
          Container(
            color: Colors.grey[300],
            padding: const EdgeInsets.all(20),
            height: 150,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,       //정렬
              children: [
                //우측 추가 작업 아이콘
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(width: 5,)
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      //padding: EdgeInsets.symmetric(horizontal: 1),
                      height: 30,
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.more_vert),
                            iconSize: 15,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end, //하단 정렬
                  children: [
                    //프로필 이미지
                    const CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.grey,
                    ),
                    const SizedBox(width: 16,),
                    //이름, 아이디
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          //이름
                          const Text(
                            "user name",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          //아이디
                          const Text(
                            "@user_id",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      )
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Row(
                        children: [
                          const Text(
                            '팔로잉 0',
                            style: TextStyle(
                              fontSize: 14
                            ),
                          ),
                          SizedBox(width: 10,),
                          const Text(
                            '팔로워 0',
                            style: TextStyle(
                              fontSize: 14
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                )
              ],
            )
          ),

          //하단 본문 영역
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                )
              ),
              child: Padding(
                padding: EdgeInsetsGeometry.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 18,),
                    //독서 현황 전시
                    Text(
                      '독서 현황',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Expanded(
                      child: _buildReviewCard(context, dummyBooks),
                    )
                    
                  ],
                )
              )
              
            )
          )
        ],
      )
    );
  }
}