import 'package:flutter/material.dart';
import 'package:Readly/models/group_model.dart';
import 'package:Readly/service/group_service.dart';

class GroupCreatePage extends StatefulWidget {
  const GroupCreatePage({Key? key}) : super(key: key);

  @override
  State<GroupCreatePage> createState() => _GroupCreatePageState();
}

class _GroupCreatePageState extends State<GroupCreatePage> {
  final GroupService _groupService = GroupService();
  
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _goalController = TextEditingController();
  final _maxMemberController = TextEditingController(text: "10");

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _goalController.dispose();
    _maxMemberController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    // 유효성 검사
    if (_nameController.text.isEmpty || _descController.text.isEmpty || _goalController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("모든 항목을 입력해주세요.")));
      return;
    }
    int max = int.tryParse(_maxMemberController.text) ?? 0;
    if (max < 2 || max > 30) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("정원은 2명 이상 30명 이하여야 합니다.")));
      return;
    }

    setState(() { _isLoading = true; });

    try {
      // 비동기 작업 전에 context를 사용하는 객체들을 미리 변수에 저장
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      // 생성 요청
      bool success = await _groupService.createGroup(GroupCreateRequest(
        name: _nameController.text,
        description: _descController.text,
        goal: _goalController.text,
        maxMembers: max,
      ));

      if (!mounted) return;

      if (success) {
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text("모임이 생성되었습니다!")));
        navigator.pop(true); // 성공 시 true 반환하며 뒤로가기
      } else {
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text("모임 생성 실패")));
      }
    } catch (e) {
      if (mounted) {
        // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("오류 발생: $e")));
        print("오류 발생: $e");
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("모임 생성하기", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "모임 이름",
                border: OutlineInputBorder(),
                hintText: "예: 독서왕 모임",
              ),
            ),
            const SizedBox(height: 20),
            
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: "모임 설명",
                border: OutlineInputBorder(),
                hintText: "모임의 성격이나 규칙 등을 자유롭게 적어주세요.",
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _goalController,
              decoration: const InputDecoration(
                labelText: "모임 목표",
                border: OutlineInputBorder(),
                hintText: "예: 한 달에 책 한 권 읽기",
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _maxMemberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "정원 (2~30명)",
                border: OutlineInputBorder(),
                helperText: "최대 30명까지 설정 가능합니다.",
              ),
            ),
            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: _isLoading ? null : _createGroup,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("생성하기", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}