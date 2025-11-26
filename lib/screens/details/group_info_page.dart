import 'package:flutter/material.dart';

// [신규 추가] 게시글 데이터 모델 클래스
class PostModel {
  final String authorName;
  final String timeAgo;
  final String title;
  final String content;
  final String category; // '토론' or '일반'

  PostModel({
    required this.authorName,
    required this.timeAgo,
    required this.title,
    required this.content,
    required this.category,
  });
}

class GroupInfoPage extends StatefulWidget {
  const GroupInfoPage({
    Key? key,
  }) : super(key: key);

  @override
  State<GroupInfoPage> createState() => _GroupInfoPageState();
}


class _GroupInfoPageState extends State<GroupInfoPage> {
  // [신규 추가] 더미 데이터 리스트 생성
  final List<PostModel> _dummyPosts = [
    PostModel(
      authorName: "책벌레",
      timeAgo: "10분 전",
      title: "이번 주 모임 장소 변경 공지입니다.",
      content: "안녕하세요. 이번 주 모임 장소가 강남역 11번 출구 앞 스타벅스로 변경되었습니다. 착오 없으시길 바랍니다.",
      category: "일반",
    ),
    PostModel(
      authorName: "독서왕",
      timeAgo: "1시간 전",
      title: "3장 '마음의 소리' 발제문 공유합니다.",
      content: "이번 챕터에서 주인공의 심리 변화가 가장 인상 깊었습니다. 특히 154페이지의 독백 부분에 대해 함께 이야기 나누고 싶어요.",
      category: "토론",
    ),
    PostModel(
      authorName: "김철수",
      timeAgo: "3시간 전",
      title: "다음 달 읽을 책 투표 결과",
      content: "투표 결과 '지적 대화를 위한 넓고 얕은 지식'이 선정되었습니다. 다음 주까지 1부 읽어오시면 됩니다!",
      category: "일반",
    ),
    PostModel(
      authorName: "이영희",
      timeAgo: "어제",
      title: "혹시 이 문장 이해되시는 분?",
      content: "p.89 '그는 침묵 속에서 비명을 질렀다'라는 표현이 역설적인데, 작가가 의도한 바가 무엇일까요?",
      category: "토론",
    ),
    PostModel(
      authorName: "신입회원",
      timeAgo: "2일 전",
      title: "가입 인사 드립니다! 잘 부탁드려요.",
      content: "평소에 책 읽기를 좋아해서 가입하게 되었습니다. 주로 소설을 읽지만 다양한 장르에 도전해보고 싶습니다.",
      category: "일반",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // [유지] 배경색 흰색 고정
      backgroundColor: Colors.white,
      
      // [유지] 앱바 디자인 및 우측 멤버 아이콘/인원수
      appBar: AppBar(
        title: const Text("책책책", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: const [
                Icon(Icons.people, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  "23명",
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. [유지] 상단 모임 소개 구역
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "모임 소개",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "바쁜 일상 속, 잠시 멈춰 책과 함께 쉬어가세요. 따뜻한 문장을 나누며 마음에 쉼표를 찍는 공간입니다.",
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. [유지] 필터 및 정렬 구역
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildTagChip("토론", isSelected: true),
                    const SizedBox(width: 8),
                    _buildTagChip("일반", isSelected: true),
                  ],
                ),
                Row(
                  children: const [
                    Text("최신순", style: TextStyle(fontSize: 14)),
                    Icon(Icons.keyboard_arrow_down, size: 18),
                  ],
                )
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1),

          // 3. [수정] 하단 게시글 리스트 (더미 데이터 연결)
          Expanded(
            child: ListView.separated(
              itemCount: _dummyPosts.length, // 데이터 개수만큼 생성
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                // 해당 인덱스의 데이터 모델 가져오기
                final post = _dummyPosts[index];
                return _buildPostItem(post); // 모델 전달
              },
            ),
          ),
        ],
      ),
    );
  }

  // [유지] 태그 칩 위젯
  Widget _buildTagChip(String label, {required bool isSelected}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? Colors.green : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // [수정] 게시글 아이템 위젯 - PostModel 데이터를 받아 출력하도록 변경
  Widget _buildPostItem(PostModel post) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey[200],
                radius: 12,
                child: const Icon(Icons.person, size: 16, color: Colors.grey),
              ),
              const SizedBox(width: 8),
              // [수정] 작성자 이름 데이터 바인딩
              Text(post.authorName,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(width: 8),
              // [신규] 카테고리 표시 (선택 사항)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(post.category, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ),
              const Spacer(),
              // [수정] 시간 데이터 바인딩
              Text(post.timeAgo,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          // [수정] 제목 데이터 바인딩
          Text(
            post.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          // [수정] 내용 데이터 바인딩
          Text(
            post.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}