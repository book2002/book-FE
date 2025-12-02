import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_app/constants.dart';
import 'package:flutter_app/service/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ProfileEditPage extends StatefulWidget {
  final String currentNickname;
  final String currentBio;
  final String? currentImageUrl;

  const ProfileEditPage({
    Key? key,
    required this.currentNickname,
    required this.currentBio,
    this.currentImageUrl,
  }) : super(key: key);

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _nicknameController = TextEditingController();
  final _bioController = TextEditingController();
  final AuthService _authService = AuthService();
  
  XFile? _imageXFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nicknameController.text = widget.currentNickname;
    _bioController.text = widget.currentBio;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageXFile = pickedFile;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (_nicknameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("닉네임을 입력해주세요.")));
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final String? accessToken = await _authService.getAccessToken();
      if (accessToken == null) return;

      final url = Uri.parse(profileEditApiUrl);
      var request = http.MultipartRequest('PUT', url);
      request.headers['Authorization'] = "Bearer $accessToken";

      Map<String, String?> dtoMap = {
        "nickname": _nicknameController.text,
        "bio": _bioController.text,
      };

      request.files.add(
        http.MultipartFile.fromString(
          'request',
          jsonEncode(dtoMap),
          contentType: MediaType('application', 'json'),
        ),
      );

      if (_imageXFile != null) {
        final bytes = await _imageXFile!.readAsBytes();
        String extension = _imageXFile!.path.split('.').last.toLowerCase();
        request.files.add(
          await http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: _imageXFile!.name,
            contentType: MediaType('image', extension == 'png' ? 'png' : 'jpeg'),
          ),
        );
      }

      var response = await request.send();
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("프로필이 수정되었습니다.")));
        Navigator.pop(context, true); // 수정 성공 시 true 반환
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("수정 실패")));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("오류: $e")));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("프로필 수정", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _updateProfile,
            child: const Text("저장", style: TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: _imageXFile != null 
                  ? (kIsWeb ? NetworkImage(_imageXFile!.path) : FileImage(File(_imageXFile!.path)) as ImageProvider)
                  : (widget.currentImageUrl != null ? NetworkImage(widget.currentImageUrl!) : null),
                child: (_imageXFile == null && widget.currentImageUrl == null) 
                  ? Icon(Icons.camera_alt, color: Colors.grey.shade700, size: 40) 
                  : null,
              ),
            ),
            const SizedBox(height: 10),
            const Text("사진 변경", style: TextStyle(color: Colors.blue)),
            const SizedBox(height: 30),
            
            TextField(
              controller: _nicknameController,
              decoration: const InputDecoration(labelText: "닉네임", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            
            TextField(
              controller: _bioController,
              decoration: const InputDecoration(labelText: "자기소개", border: OutlineInputBorder()),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}