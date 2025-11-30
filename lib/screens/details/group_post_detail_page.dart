import 'package:flutter/material.dart';
import 'package:flutter_app/models/group_post_model.dart';
import 'package:flutter_app/screens/details/group_info_page.dart'; // PostModel 사용을 위해 임포트

class GroupPostDetailPage extends StatefulWidget {
  final GroupPostResponse post;

  const GroupPostDetailPage({Key? key, required this.post}) : super(key: key);

  @override
  State<GroupPostDetailPage> createState() => _GroupPostDetailPageState();
}

class _GroupPostDetailPageState extends State<GroupPostDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  
  // 더미 댓글 데이터
  final List<Map<String, String>> _dummyComments = [
    {'author': '독서왕', 'content': '네 감사합니다!', 'time': '5분 전'},
    {'author': '책벌레', 'content': '확인했습니다.', 'time': '1시간 전'},
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("게시글 상세", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              // TODO: 게시글 신고/삭제 메뉴 등
            },
            icon: const Icon(Icons.more_vert),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. 게시글 헤더 (작성자, 시간, 카테고리)
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.grey,
                        radius: 18,
                        child: Icon(Icons.person, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.post.authorNickname, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 2),
                          Text(widget.post.timeAgo, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(widget.post.category, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 2. 게시글 제목
                  Text(
                    widget.post.title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // 3. 게시글 본문
                  Text(
                    widget.post.content,
                    style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
                  ),
                  const SizedBox(height: 40),

                  const Divider(thickness: 1, color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 10),

                  // 4. 댓글 리스트 (더미)
                  Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text("댓글 ${_dummyComments.length}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _dummyComments.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final comment = _dummyComments[index];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(backgroundColor: Colors.grey, radius: 14, child: Icon(Icons.person, size: 16, color: Colors.white)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50], // 연한 회색 배경
                                borderRadius: BorderRadius.circular(12), // 둥근 모서리
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(comment['author']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      Text(comment['time']!, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(comment['content']!, style: const TextStyle(fontSize: 14)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 5. 댓글 입력창 (하단 고정)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: "댓글을 입력하세요...",
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      // TODO: 댓글 전송 로직 구현
                      if (_commentController.text.isNotEmpty) {
                        _commentController.clear();
                        FocusScope.of(context).unfocus();
                      }
                    },
                    icon: const Icon(Icons.send, color: Colors.green),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}