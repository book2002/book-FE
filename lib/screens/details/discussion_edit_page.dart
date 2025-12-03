import 'package:flutter/material.dart';
import 'package:Readly/models/discussion_model.dart';
import 'package:Readly/service/discussion_service.dart';

class DiscussionEditPage extends StatefulWidget {
  final DiscussionResponse discussion;

  const DiscussionEditPage({Key? key, required this.discussion}) : super(key: key);

  @override
  State<DiscussionEditPage> createState() => _DiscussionEditPageState();
}

class _DiscussionEditPageState extends State<DiscussionEditPage> {
  final DiscussionService _discussionService = DiscussionService();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.discussion.topicTitle);
    _contentController = TextEditingController(text: widget.discussion.topicContent);
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("내용을 입력해주세요.")));
      return;
    }

    setState(() { _isSubmitting = true; });

    bool success = await _discussionService.updateDiscussion(widget.discussion.discussionId, title, content);

    setState(() { _isSubmitting = false; });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("수정되었습니다.")));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("수정 실패")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("토론 수정", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitUpdate,
            child: const Text("완료", style: TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: "주제", border: InputBorder.none),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(hintText: "내용", border: InputBorder.none),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}