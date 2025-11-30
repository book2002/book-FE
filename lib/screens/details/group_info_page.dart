import 'package:flutter/material.dart';
import 'package:flutter_app/models/group_model.dart';
import 'package:flutter_app/models/group_post_model.dart';
import 'package:flutter_app/screens/details/group_post_detail_page.dart';
import 'package:flutter_app/screens/details/post_create_page.dart';
import 'package:flutter_app/service/group_post_service.dart';
import 'package:flutter_app/service/group_service.dart';

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
  final GroupResponse group;

  const GroupInfoPage({
    Key? key,
    required this.group,
  }) : super(key: key);

  @override
  State<GroupInfoPage> createState() => _GroupInfoPageState();
}


class _GroupInfoPageState extends State<GroupInfoPage> {
  // 그룹 서비스 인스턴스
  final GroupService _groupService = GroupService();
  final GroupPostService _postService = GroupPostService();

  // [데이터 상태]
  List<GroupPostResponse> _allPosts = [];
  List<GroupPostResponse> _filteredPosts = [];
  bool _isLoadingPosts = true;

  // [필터 상태] 기본값: 모두 선택
  bool _showDiscussion = true;
  bool _showGeneral = true;

  // 더미 데이터 리스트
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
  void initState() {
    super.initState();
    _fetchPosts();
  }

  // 게시글 목록 조회
  Future<void> _fetchPosts() async {
    setState(() { _isLoadingPosts = true; });
    
    // 페이지네이션은 현재 넉넉하게 50개로 설정
    List<GroupPostResponse> posts = await _postService.getGroupPosts(widget.group.groupId, size: 50);

    if (mounted) {
      setState(() {
        _allPosts = posts;
        _isLoadingPosts = false;
        _applyFilter(); // 데이터 로드 후 필터 적용
      });
    }
  }

  // 필터링 로직
  void _applyFilter() {
    setState(() {
      _filteredPosts = _allPosts.where((post) {
        if (post.category == '토론' && !_showDiscussion) return false;
        if (post.category == '일반' && !_showGeneral) return false;
        return true;
      }).toList();
    });
  }

  // 글 작성 페이지 이동
  void _goToCreatePost() async {
    final bool? created = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupPostCreatePage(groupId: widget.group.groupId),
      ),
    );

    // 작성이 완료되어 true가 반환되면 목록 갱신
    if (created == true) {
      _fetchPosts();
    }
  }

  // 탈퇴 로직
  void _handleLeaveGroup() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("모임 탈퇴"),
        content: const Text("정말로 이 모임에서 나가시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("나가기", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      bool success = await _groupService.leaveGroup(widget.group.groupId);
      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("모임에서 탈퇴했습니다.")),
        );
        // true를 반환하여 이전 화면(목록)에서 갱신하도록 함
        Navigator.pop(context, true);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("탈퇴에 실패했습니다. 다시 시도해주세요.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 배경색 흰색 고정
      backgroundColor: Colors.white,

      // 글 작성 플로팅 버튼
      floatingActionButton: FloatingActionButton(
        onPressed: _goToCreatePost,
        backgroundColor: Colors.green,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      
      // 앱바 디자인 및 우측 멤버 아이콘/인원수
      appBar: AppBar(
        title: Text(widget.group.name, style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                const Icon(Icons.people, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  "${widget.group.currentMembers}명",
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.grey), // 나가는 문 아이콘
            tooltip: "모임 나가기",
            onPressed: _handleLeaveGroup,
          ),
          const SizedBox(width: 16,)
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
                children: [
                  const Text(
                    "모임 소개",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.group.description.isNotEmpty
                    ? widget.group.description
                    : "모임 소개글이 없습니다.",
                    style: const TextStyle(
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
                    _buildTagChip("토론", isSelected: _showDiscussion, onTap: () {
                      setState(() {
                        _showDiscussion = !_showDiscussion;
                        _applyFilter();
                      });
                    },),
                    const SizedBox(width: 8),
                    _buildTagChip("일반", isSelected: _showGeneral, onTap: () {
                      setState(() {
                        _showGeneral = !_showGeneral;
                        _applyFilter();
                      });
                    },),
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

          // 하단 게시글 리스트
          Expanded(
            child: _isLoadingPosts
              ? const Center(child: CircularProgressIndicator(),)
              : _filteredPosts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.article_outlined, size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "게시글이 존재하지 않아요.\n첫 게시글을 작성해보세요!",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _filteredPosts.length, // 데이터 개수만큼 생성
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      // 해당 인덱스의 데이터 모델 가져오기
                      final post = _filteredPosts[index];
                      return _buildPostItem(post); // 모델 전달
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // 태그 칩 위젯
  Widget _buildTagChip(String label, {required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
      ),
    );
  }

  // 게시글 아이템 빌더
  Widget _buildPostItem(GroupPostResponse post) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GroupPostDetailPage(post: post),
          ),
        );
      },
      child: Padding(
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
                Text(post.authorNickname,
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
            // 제목 데이터 바인딩
            Text(
              post.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            // 내용 데이터 바인딩
            Text(
              post.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            if (post.commentCount > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.comment, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text("${post.commentCount}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              )
            ]
          ],
        ),
      )
    );
    
  }
}