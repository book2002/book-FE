import 'package:flutter/material.dart';
import 'package:flutter_app/models/group_post_model.dart';
import 'package:flutter_app/service/group_post_service.dart';

class GroupPostEditPage extends StatefulWidget {
  final GroupPostResponse post;

  const GroupPostEditPage({Key? key, required this.post}) : super(key: key);

  @override
  State<GroupPostEditPage> createState() => _GroupPostEditPageState();
}

class _GroupPostEditPageState extends State<GroupPostEditPage> {
  final GroupPostService _postService = GroupPostService();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // 기존 데이터로 초기화
    _titleController = TextEditingController(text: widget.post.title);
    _contentController = TextEditingController(text: widget.post.content);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _submitUpdate() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("제목과 내용을 모두 입력해주세요.")),
      );
      return;
    }

    setState(() { _isSubmitting = true; });

    bool success = await _postService.updatePost(
      widget.post.postId,
      title,
      content,
    );

    setState(() { _isSubmitting = false; });

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("게시글이 수정되었습니다.")),
      );
      Navigator.pop(context, true); // true 반환 -> 상세 페이지 갱신 트리거
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("게시글 수정에 실패했습니다.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("게시글 수정", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitUpdate,
            child: _isSubmitting 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text("완료", style: TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: "제목을 입력하세요",
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(thickness: 1, height: 30),
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: "내용을 입력하세요",
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