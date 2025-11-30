import 'package:flutter/material.dart';
import 'package:flutter_app/models/discussion_model.dart';
import 'package:flutter_app/screens/details/discussion_edit_page.dart'; // [신규] 수정 페이지
import 'package:flutter_app/service/discussion_service.dart';
import 'package:flutter_app/service/auth_service.dart';

class DiscussionDetailPage extends StatefulWidget {
  final int discussionId;
  final DiscussionResponse? previewDiscussion;
  final bool isLeader; // 모임장 여부

  const DiscussionDetailPage({
    Key? key,
    required this.discussionId,
    this.previewDiscussion,
    this.isLeader = false,
  }) : super(key: key);

  @override
  State<DiscussionDetailPage> createState() => _DiscussionDetailPageState();
}

class _DiscussionDetailPageState extends State<DiscussionDetailPage> {
  final DiscussionService _discussionService = DiscussionService();
  final AuthService _authService = AuthService();

  DiscussionResponse? _discussion;
  List<DiscussionCommentResponse> _comments = [];
  
  bool _isLoading = true;
  bool _isLoadingComments = true;
  String? _errorMessage;
  String? _myNickname; // 작성자 판단용
  bool _isContentChanged = false; // 목록 갱신 트리거

  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.previewDiscussion != null) {
      _discussion = widget.previewDiscussion;
    }
    _fetchDetail();
    _fetchComments();
    _fetchMyNickname();
  }

  Future<void> _fetchMyNickname() async {
    // 닉네임 조회 로직 (임시 생략)
  }

  Future<void> _fetchDetail() async {
    try {
      final data = await _discussionService.getDiscussionDetail(widget.discussionId);
      if (mounted) {
        setState(() {
          if (data != null) {
            _discussion = data;
          } else {
            _errorMessage = "토론 정보를 불러올 수 없습니다.";
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _errorMessage = "오류: $e"; });
    }
  }

  Future<void> _fetchComments() async {
    setState(() { _isLoadingComments = true; });
    try {
      final comments = await _discussionService.getComments(widget.discussionId);
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoadingComments = false; });
    }
  }

  // 토론 상태 변경 (마감/진행)
  void _toggleStatus() async {
    if (_discussion == null) return;
    bool newStatus = !_discussion!.isClosed; // 상태 반전

    bool success = await _discussionService.updateDiscussionStatus(widget.discussionId, newStatus);
    if (success) {
      setState(() { _isContentChanged = true; });
      _fetchDetail(); // 상태 갱신
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(newStatus ? "토론이 마감되었습니다." : "토론이 다시 시작되었습니다.")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("상태 변경 실패")));
    }
  }

  // 토론 삭제
  void _deleteDiscussion() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("토론 삭제"),
        content: const Text("정말로 이 토론을 삭제하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("삭제", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      bool success = await _discussionService.deleteDiscussion(widget.discussionId);
      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("삭제되었습니다.")));
        Navigator.pop(context, true);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("삭제 실패")));
      }
    }
  }

  // 토론 수정
  void _editDiscussion() async {
    if (_discussion == null) return;
    final bool? updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DiscussionEditPage(discussion: _discussion!)),
    );

    if (updated == true) {
      setState(() { _isContentChanged = true; });
      _fetchDetail();
    }
  }

  // 댓글 작성
  void _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;
    FocusScope.of(context).unfocus();

    bool success = await _discussionService.createComment(widget.discussionId, content);
    if (success) {
      _commentController.clear();
      _fetchComments();
      _fetchDetail(); // 댓글 수 갱신
      setState(() { _isContentChanged = true; });
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
        content: const Text("삭제하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("삭제", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      bool success = await _discussionService.deleteComment(commentId);
      if (success) {
        _fetchComments();
        _fetchDetail();
        setState(() { _isContentChanged = true; });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("삭제되었습니다.")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("삭제 실패")));
      }
    }
  }

  // 댓글 수정 다이얼로그
  void _showEditCommentDialog(DiscussionCommentResponse comment) {
    final controller = TextEditingController(text: comment.content);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("댓글 수정"),
        content: TextField(controller: controller, maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("취소")),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(ctx);
                bool success = await _discussionService.updateComment(comment.commentId, controller.text.trim());
                if (success) {
                  _fetchComments();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("수정되었습니다.")));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("수정 실패")));
                }
              }
            },
            child: const Text("수정", style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _discussion == null) {
      return Scaffold(appBar: AppBar(backgroundColor: Colors.white, elevation: 0), body: const Center(child: CircularProgressIndicator()));
    }
    if (_errorMessage != null && _discussion == null) {
      return Scaffold(appBar: AppBar(backgroundColor: Colors.white, elevation: 0, foregroundColor: Colors.black), body: Center(child: Text(_errorMessage!)));
    }

    final discussion = _discussion!;
    // 권한 판단 (임시 로직: 작성자이거나 모임장이면 관리 가능)
    bool isAuthor = _myNickname != null && discussion.authorNickname == _myNickname;
    bool canManage = isAuthor || widget.isLeader;
    // 임시로 권한 열어둠
    canManage = true; 

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) { if (!didPop) Navigator.pop(context, _isContentChanged); },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'edit') _editDiscussion();
                else if (value == 'delete') _deleteDiscussion();
                else if (value == 'status') _toggleStatus(); // 상태 변경
              },
              itemBuilder: (context) {
                if (canManage) {
                  return [
                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text("수정")])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 20, color: Colors.red), SizedBox(width: 8), Text("삭제", style: TextStyle(color: Colors.red))])),
                    PopupMenuItem(
                      value: 'status', 
                      child: Row(
                        children: [
                          Icon(discussion.isClosed ? Icons.lock_open : Icons.lock, size: 20, color: Colors.blue), 
                          SizedBox(width: 8), 
                          Text(discussion.isClosed ? "토론 다시 열기" : "토론 마감하기", style: const TextStyle(color: Colors.blue))
                        ]
                      )
                    ),
                  ];
                } else {
                  return [const PopupMenuItem(value: 'report', child: Text("신고"))];
                }
              },
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
                    // 헤더
                    Row(
                      children: [
                        const CircleAvatar(backgroundColor: Colors.grey, radius: 18, child: Icon(Icons.person, color: Colors.white, size: 20)),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(discussion.authorNickname, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(discussion.timeAgo, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                        const Spacer(),
                        // 상태 뱃지
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: discussion.isClosed ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(discussion.isClosed ? "마감됨" : "진행중", style: TextStyle(color: discussion.isClosed ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(discussion.topicTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Text(discussion.topicContent, style: const TextStyle(fontSize: 16, height: 1.6)),
                    const SizedBox(height: 40),
                    const Divider(),
                    
                    // 댓글 헤더
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text("댓글 ${_comments.length}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),

                    // 댓글 리스트
                    if (_isLoadingComments)
                      const Center(child: CircularProgressIndicator())
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _comments.length,
                        separatorBuilder: (ctx, i) => const SizedBox(height: 16),
                        itemBuilder: (ctx, i) {
                          final comment = _comments[i];
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const CircleAvatar(backgroundColor: Colors.grey, radius: 14, child: Icon(Icons.person, size: 16, color: Colors.white)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(comment.authorNickname, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          Row(
                                            children: [
                                              Text(comment.timeAgo, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                              if (comment.isMyComment)
                                                SizedBox(
                                                  height: 20, width: 20,
                                                  child: PopupMenuButton<String>(
                                                    padding: EdgeInsets.zero,
                                                    icon: const Icon(Icons.more_vert, size: 16, color: Colors.grey),
                                                    onSelected: (val) {
                                                      if (val == 'edit') _showEditCommentDialog(comment);
                                                      else if (val == 'delete') _deleteComment(comment.commentId);
                                                    },
                                                    itemBuilder: (ctx) => [
                                                      const PopupMenuItem(value: 'edit', height: 32, child: Text("수정", style: TextStyle(fontSize: 13))),
                                                      const PopupMenuItem(value: 'delete', height: 32, child: Text("삭제", style: TextStyle(fontSize: 13, color: Colors.red))),
                                                    ]
                                                  ),
                                                )
                                            ],
                                          )
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(comment.content),
                                    ],
                                  ),
                                ),
                              )
                            ],
                          );
                        },
                      )
                  ],
                ),
              ),
            ),
            // 댓글 입력창 (마감 시 비활성화 가능, 여기선 항상 활성)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        enabled: !discussion.isClosed, // 마감 시 입력 불가
                        decoration: InputDecoration(
                          hintText: discussion.isClosed ? "마감된 토론입니다." : "의견을 남겨주세요...",
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: discussion.isClosed ? null : _submitComment,
                      icon: Icon(Icons.send, color: discussion.isClosed ? Colors.grey : Colors.green),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}