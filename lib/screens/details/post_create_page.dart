import 'package:flutter/material.dart';
import 'package:flutter_app/service/group_post_service.dart';

class GroupPostCreatePage extends StatefulWidget {
  final int groupId;

  const GroupPostCreatePage({Key? key, required this.groupId}) : super(key: key);

  @override
  State<GroupPostCreatePage> createState() => _GroupPostCreatePageState();
}

class _GroupPostCreatePageState extends State<GroupPostCreatePage> {
  final GroupPostService _postService = GroupPostService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _isSubmitting = false;

  void _submitPost() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("제목과 내용을 모두 입력해주세요.")),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // 게시글 작성 요청
    bool success = await _postService.createPost(
      widget.groupId,
      title,
      content,
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("게시글이 등록되었습니다.")),
      );
      Navigator.pop(context, true); // true 반환 -> 목록 새로고침 트리거
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("게시글 등록에 실패했습니다.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("글 쓰기", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitPost,
            child: _isSubmitting 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text("등록", style: TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // 제목 입력
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: "제목을 입력하세요",
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(thickness: 1, height: 30),
            // 내용 입력
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null, // 무제한 줄
                expands: true,
                decoration: const InputDecoration(
                  hintText: "내용을 자유롭게 작성해주세요.\n(모임과 관련 없는 내용은 삭제될 수 있습니다.)",
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}