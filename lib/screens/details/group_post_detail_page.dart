import 'package:flutter/material.dart';
import 'package:flutter_app/models/group_post_model.dart';
import 'package:flutter_app/screens/details/post_edit_page.dart';
import 'package:flutter_app/service/group_post_service.dart'; // PostModel 사용을 위해 임포트

class GroupPostDetailPage extends StatefulWidget {
  final int postId;
  final GroupPostResponse? previewPost;
  final bool canModify;    // 상위 페이지에서 모임장 여부 받아옴

  const GroupPostDetailPage({
    Key? key, 
    required this.postId,
    this.previewPost,
    this.canModify = false,  // 기본값, 넘겨주는 값으로 권한 판단
  }) : super(key: key);

  @override
  State<GroupPostDetailPage> createState() => _GroupPostDetailPageState();
}

class _GroupPostDetailPageState extends State<GroupPostDetailPage> {
  final GroupPostService _postService = GroupPostService();

  GroupPostResponse? _post;
  bool _isLoading = true;
  String? _errorMessage;

  bool _isContentChanged = false;   // 컨텐츠 변경 여부 추적 변수 

  List<GroupCommentResponse> _comments = [];    // 댓글 데이터 상태 변수
  bool _isLoadingComments = true;

  final TextEditingController _commentController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    if (widget.previewPost != null) {
      _post = widget.previewPost;
    }
    _fetchPostDetail();
    _fetchComments();
    _fetchMyNickname();
  }

  Future<void> _fetchPostDetail() async {
    try {
      final post = await _postService.getPostDetail(widget.postId);
      if (mounted) {
        setState(() {
          if (post != null) {
            _post = post;
          } else {
            _errorMessage = "게시글을 불러올 수 없습니다.";
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "오류가 발생했습니다: $e";
          _isLoading = false;
        });
      }
    }
  }

  // 댓글 목록 조회
  Future<void> _fetchComments() async {
    setState(() { _isLoadingComments = true; });
    try {
      final comments = await _postService.getComments(widget.postId);
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      print("댓글 조회 실패: $e");
      if (mounted) {
        setState(() { _isLoadingComments = false; });
      }
    }
  }

  // 댓글 작성
  void _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    FocusScope.of(context).unfocus(); // 키보드 내리기

    bool success = await _postService.createComment(widget.postId, content);
    if (success) {
      _commentController.clear();
      // 댓글 작성 후 목록과 게시글 정보(댓글 수) 갱신
      _fetchComments();
      _fetchPostDetail();
      setState(() { _isContentChanged = true; }); // 댓글 수 변경도 변경 사항으로 간주
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("댓글 작성 실패")));
    }
  }

  // 댓글 삭제
  void _deleteComment(int commentId) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("댓글 삭제"),
        content: const Text("정말로 삭제하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("삭제", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      bool success = await _postService.deleteComment(commentId);
      if (success) {
        _fetchComments();
        _fetchPostDetail(); // 댓글 수 갱신을 위해
        setState(() { _isContentChanged = true; });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("댓글이 삭제되었습니다.")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("댓글 삭제 실패")));
      }
    }
  }

  // 댓글 수정 다이얼로그
  void _showEditCommentDialog(GroupCommentResponse comment) {
    final editController = TextEditingController(text: comment.content);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("댓글 수정"),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(hintText: "수정할 내용을 입력하세요"),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("취소")),
          TextButton(
            onPressed: () async {
              final newContent = editController.text.trim();
              if (newContent.isNotEmpty) {
                Navigator.pop(ctx);
                bool success = await _postService.updateComment(comment.commentId, newContent);
                if (success) {
                  _fetchComments();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("댓글이 수정되었습니다.")));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("댓글 수정 실패")));
                }
              }
            },
            child: const Text("수정", style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  // 작성자 판단용
  Future<void> _fetchMyNickname() async {
    // TODO: 백엔드 명세에 따라 실제 내 프로필/닉네임을 가져오는 API 호출로 대체해야 합니다.
    // 현재는 AuthService 등에 닉네임 저장소가 있다고 가정하거나, 
    // 프로필 조회 API를 호출하여 _myNickname 변수에 할당해야 합니다.
    
    // 예시: String? nick = await _authService.getNickname();
    // setState(() { _myNickname = nick; });
    
    // [임시] 테스트를 위해 비워두거나 하드코딩된 값으로 테스트 가능
    // setState(() { _myNickname = "작성자닉네임"; }); 
  }

  // 게시글 삭제 로직
  void _deletePost() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("게시글 삭제"),
        content: const Text("정말로 이 게시글을 삭제하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("삭제", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      bool success = await _postService.deletePost(widget.postId);
      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("게시글이 삭제되었습니다.")));
        Navigator.pop(context, true); // 상세 페이지 닫기 (목록으로 이동)
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("삭제 실패")));
      }
    }
  }

  // 게시글 수정 페이지 이동 로직
  void _editPost() async {
    if (_post == null) return;
    
    final bool? updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupPostEditPage(post: _post!),
      ),
    );

    // 수정 후 돌아왔을 때 데이터 갱신
    if (updated == true) {
      setState(() {
        _isContentChanged = true;
      });
      _fetchPostDetail();
    }
  }

  // 게시글 신고 로직 (UI만 구현)
  void _reportPost() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("신고하기"),
        content: const Text("이 게시글을 신고하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("취소")),
          TextButton(onPressed: () {
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("신고가 접수되었습니다.")),
            );
          }, child: const Text("신고", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 로딩 중이고 미리보기 데이터도 없는 경우
    if (_isLoading && _post == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // 에러 발생 시
    if (_errorMessage != null && _post == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0, foregroundColor: Colors.black),
        body: Center(child: Text(_errorMessage!)),
      );
    }

    // 데이터가 있는 경우 (로딩 완료 or 미리보기)
    final post = _post!;
    // 관리 권한: 작성자이거나 모임장인 경우
    bool canManage = widget.canModify;

    return PopScope(
      canPop: false,    // 뒤로가기 동작 수동 제어
      onPopInvoked: (bool didPop) {
        if (didPop) return;
        Navigator.pop(context, _isContentChanged);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          //title: const Text("게시글 상세", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          actions: [
            // 작성자 여부에 따라 다른 메뉴 노출
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (String value) {
                if (value == 'edit') _editPost();
                else if (value == 'delete') _deletePost();
                else if (value == 'report') _reportPost();
              },
              itemBuilder: (BuildContext context) {
                // 작성자인 경우: 수정, 삭제
                if (canManage) {
                  return [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text("수정")],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [Icon(Icons.delete, size: 20, color: Colors.red), SizedBox(width: 8), Text("삭제", style: TextStyle(color: Colors.red))],
                      ),
                    ),
                  ];
                } 
                // 작성자가 아닌 경우: 신고
                else {
                  return [
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [Icon(Icons.report_problem, size: 20, color: Colors.red), SizedBox(width: 8), Text("신고", style: TextStyle(color: Colors.red))],
                      ),
                    ),
                  ];
                }
              },
            ),
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
                            Text(post.authorNickname, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(post.timeAgo, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(post.category, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 2. 게시글 제목
                    Text(
                      post.title,
                      style: const TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. 게시글 본문
                    Text(
                      post.content,
                      style: const TextStyle(
                        fontSize: 16, height: 1.6, 
                        color: Colors.black87
                      ),
                    ),
                    const SizedBox(height: 40),

                    const Divider(thickness: 1, color: Color(0xFFEEEEEE)),
                    const SizedBox(height: 10),

                    // 4. 댓글 리스트
                    Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          "댓글 ${_comments.length}", 
                          style: const TextStyle(fontWeight: FontWeight.bold)
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 댓글 리스트 Placeholder
                    if (_isLoadingComments)
                      const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                    else if (_comments.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(30),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            "아직 작성된 댓글이 없습니다.\n첫 댓글을 남겨보세요!",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _comments.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
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
                                          Text(comment.authorNickname, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                          Row(
                                            children: [
                                              Text(comment.timeAgo, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                              if (comment.isMyComment)  // 본인 댓글일 경우 메뉴 버튼 표시
                                                SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child: PopupMenuButton<String>(
                                                    padding: EdgeInsets.zero,
                                                    icon: const Icon(Icons.more_vert, size: 16, color: Colors.grey),
                                                    onSelected: (value) {
                                                      if (value == 'edit') _showEditCommentDialog(comment);
                                                      else if (value == 'delete') _deleteComment(comment.commentId);
                                                    },
                                                    itemBuilder: (context) => [
                                                      const PopupMenuItem(value: 'edit', height: 32, child: Text("수정", style: TextStyle(fontSize: 13))),
                                                      const PopupMenuItem(value: 'delete', height: 32, child: Text("삭제", style: TextStyle(fontSize: 13, color: Colors.red))),
                                                    ],
                                                  ),
                                                ),
                                            ]
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(comment.content, style: const TextStyle(fontSize: 14)),
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
                      onPressed: _submitComment,
                      icon: const Icon(Icons.send, color: Colors.green),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      )
    )
    ;
  }
}