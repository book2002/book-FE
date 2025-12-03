import 'package:flutter/material.dart';
import 'package:Readly/service/discussion_service.dart';
import 'package:Readly/service/group_post_service.dart';

class GroupPostCreatePage extends StatefulWidget {
  final int groupId;

  const GroupPostCreatePage({Key? key, required this.groupId}) : super(key: key);

  @override
  State<GroupPostCreatePage> createState() => _GroupPostCreatePageState();
}

class _GroupPostCreatePageState extends State<GroupPostCreatePage> {
  final GroupPostService _postService = GroupPostService();
  final DiscussionService _discussionService = DiscussionService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _isSubmitting = false;
  String _selectedCategory = '일반';    // '일반' or '토론'

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

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

    bool success = false;

    // 카테고리에 따라 다른 API 호출
    if (_selectedCategory == '일반') {
      success = await _postService.createPost(widget.groupId, title, content);
    } else {
      success = await _discussionService.createDiscussion(widget.groupId, title, content);
    }

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
            // 카테고리 선택 칩
            Row(
              children: [
                _buildCategoryChip('일반'),
                const SizedBox(width: 10),
                _buildCategoryChip('토론'),
              ],
            ),
            const SizedBox(height: 20),

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
                decoration: InputDecoration(
                  hintText: _selectedCategory == '토론' 
                      ? "토론 주제에 대해 자유롭게 이야기해보세요."
                      : "내용을 자유롭게 작성해주세요.\n(모임과 관련 없는 내용은 삭제될 수 있습니다.)",
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

  Widget _buildCategoryChip(String label) {
    bool isSelected = _selectedCategory == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedCategory = label;
          });
        }
      },
      selectedColor: Colors.green,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: FontWeight.bold,
      ),
      backgroundColor: Colors.grey[200],
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}