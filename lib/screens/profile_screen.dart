import 'package:flutter/material.dart';
import 'package:flutter_app/models/book_model.dart';
import 'package:flutter_app/models/group_model.dart';
import 'package:flutter_app/models/record_model.dart';
import 'package:flutter_app/screens/details/group_info_page.dart';
import 'package:flutter_app/screens/profile/password_change_page.dart';
import 'package:flutter_app/screens/profile/profile_edit_page.dart';
import 'package:flutter_app/service/book_service.dart';
import 'package:flutter_app/service/group_service.dart';
import 'package:flutter_app/service/record_service.dart';
import 'package:flutter_app/service/refresh_service.dart';
import 'package:flutter_app/testdata/book_dummy.dart';
import 'package:flutter_app/service/auth_service.dart'; // AuthService
import 'package:flutter_app/constants.dart'; // URL 상수
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final RecordService _recordService = RecordService();
  final BookService _bookService = BookService();
  final GroupService _groupService = GroupService();

  // 프로필 데이터를 저장할 변수
  Map<String, dynamic>? _profileData;
  List<ReviewResponse> _publicReviews = [];   // 공개 감상문 리스트
  List<GroupResponse> _myGroups = [];          // 가입한 모임 목록
  bool _isLoading = true;
  bool _hasError = false;

  // 스크롤 감지 컨트롤러 및 상태 변수
  late ScrollController _scrollController;
  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    _fetchProfileAndReviews();
    RefreshService().reviewNotifier.addListener(_onReviewUpdated);

    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    RefreshService().reviewNotifier.removeListener(_onReviewUpdated);
    _scrollController.dispose();
    super.dispose();
  }

  // 스크롤 위치에 따라 앱바 상태 감지
  void _onScroll() {
    // expandedHeight(220) - collapsedHeight(60) = 160
    // 스크롤이 160 이상 되면 앱바가 접힌 상태로 간주
    if (_scrollController.hasClients && _scrollController.offset > (220 - 60)) {
      if (!_isCollapsed) {
        setState(() => _isCollapsed = true);
      }
    } else {
      if (_isCollapsed) {
        setState(() => _isCollapsed = false);
      }
    }
  }

  void _onReviewUpdated() {
    print("프로필 화면: 리뷰 변경 감지 -> 갱신");
    _fetchProfileAndReviews();
  }

  // 프로필 데이터 가져오는 함수
  Future<void> _fetchProfileAndReviews() async {
    try {
      // accessToken으로 연결된 회원 정보 파악
      final accessToken = await _authService.getAccessToken();
      final profileIdStr = await _authService.getProfileIdFromToken();

      if (accessToken == null || profileIdStr == null) {
        print("토큰이 없거나 ID를 추출할 수 없습니다.");
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        return;
      }

      int profileId = int.parse(profileIdStr);

      final url = Uri.parse('$baseUrl/api/v1/profile/$profileId');
      print("요청 URL: $url"); 
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken', // ✅ 서버는 이 토큰을 보고 누군지 압니다.
          'Content-Type': 'application/json',
        },
      );

      final reviews = await _recordService.getReviewsByProfileId();
      final groups = await _groupService.getMyGroups();

      if (response.statusCode == 200) {
        setState(() {
          _profileData = jsonDecode(utf8.decode(response.bodyBytes));   // utf-8 디코딩 -> 한글 깨짐 방지
          _publicReviews = reviews.where((r) => r.isPublic).toList();   // 공개된 감상문만 필터링
          _myGroups = groups;   // 모임 목록 저장
          _isLoading = false;
        });
      } else {
        print("프로필 로드 실패: ${response.statusCode} - ${response.body}");
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (e) {
      print("프로필 로드 중 오류: $e");
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  // 책 정보를 가져오기 위한 Helper (이미지, 저자 등)
  Future<BookDto?> _fetchBookInfo(String title) async {
    try {
      final results = await _bookService.getSearchBooks(title);
      if (results.isNotEmpty) {
        return results.first;
      }
    } catch (e) {
      print("책 정보 검색 실패: $e");
    }
    return null;
  }

  // 프로필 수정 페이지 이동
  void _goToProfileEdit() async {
    if (_profileData == null) return;
    final bool? updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileEditPage(
          currentNickname: _profileData!['nickname'],
          currentBio: _profileData!['bio'] ?? '',
          currentImageUrl: _profileData!['profileImageUrl'],
        ),
      ),
    );

    if (updated == true) {
      _fetchProfileAndReviews(); // 갱신
    }
  }

  // 비밀번호 변경 페이지 이동
  void _goToPasswordChange() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PasswordChangePage()),
    );
  }

  // 로그아웃
  void _logout() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("로그아웃"),
        content: const Text("정말 로그아웃 하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("로그아웃", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      // AuthGate에 의해 로그인 화면으로 자동 전환됨
    }
  }

  // 계정 탈퇴/비활성화 처리
  void _manageAccount(String type) async {
    bool isDelete = type == 'delete';
    String title = isDelete ? "회원 탈퇴" : "계정 비활성화";
    String content = isDelete 
        ? "정말로 탈퇴하시겠습니까? 모든 데이터가 삭제되며 복구할 수 없습니다."
        : "계정을 비활성화하시겠습니까? 언제든 다시 로그인하여 활성화할 수 있습니다.";

    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: Text(isDelete ? "탈퇴" : "비활성화", style: const TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirm == true) {
      bool success = isDelete 
          ? await _authService.deleteAccount()
          : await _authService.inactivateAccount();
      
      if (!success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$title 실패")));
      }
      // 성공 시 logout()이 호출되어 자동으로 로그인 화면으로 이동됨
    }
  }

  // 감상평 카드 위젯 빌더
  Widget _buildReviewCard(ReviewResponse review) {
    return FutureBuilder<BookDto?>(
      future: _fetchBookInfo(review.bookTitle), // 책 제목으로 정보 검색
      builder: (context, snapshot) {
        final bookInfo = snapshot.data;
        final String thumbnail = bookInfo?.thumbnail ?? "https://via.placeholder.com/100x150";
        final String author = bookInfo?.authorsString ?? "저자 미상";

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,  //세로축 기준 중앙정렬
                children: [
                  // 책 이미지
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(
                        Radius.circular(8),
                      ),
                      child: Image.network(
                        thumbnail,
                        width: 80,
                        height: 110,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Container(width: 80, height: 110, color: Colors.grey[200], child: const Icon(Icons.book, color: Colors.grey)),
                      ),
                    ),
                  ),
                  
                  // 책 정보
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            review.bookTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            author,
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.star, size: 14, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text('${review.rating}', style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // 리뷰 내용
              Padding(
                padding: EdgeInsetsGeometry.all(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    review.content,
                    style: const TextStyle(height: 1.5, fontSize: 14),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
            ],
          )
        );
      }
    );
  }

  // 모임 아이템 빌더
  Widget _buildGroupItem(GroupResponse group) {
    return InkWell(
      onTap: () {
        // 모임 상세 페이지 이동
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => GroupInfoPage(group: group)),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          // side: BorderSide(color: Colors.grey.shade200) // 테두리 선택사항
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // 모임 이미지
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: group.groupImageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(group.groupImageUrl!, fit: BoxFit.cover)
                    )
                  : const Icon(Icons.group, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              // 정보 영역
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name, 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                    ),
                    const SizedBox(height: 4),
                    Text(
                      group.description, 
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis, 
                      style: const TextStyle(color: Colors.grey)
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          "${group.currentMembers}/${group.maxMembers}", 
                          style: const TextStyle(fontSize: 12, color: Colors.grey)
                        ),
                      ],
                    )
                  ],
                ),
              ),
              // 참여중 표시
              const Text(
                "참여중", 
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    if (_hasError || _profileData == null) {
      return const Scaffold(
        body: Center(child: Text("프로필 정보를 불러오는데 실패했습니다.")),
      );
    }

    // 데이터 바인딩
    final String nickname = _profileData?['nickname'] ?? "알 수 없음";
    final String bio = _profileData?['bio'] ?? "소개가 없습니다.";
    final String? profileImageUrl = _profileData?['profileImageUrl']; 
    final int followerCount = _profileData?['followerCount'] ?? 0;
    final int followingCount = _profileData?['followingCount'] ?? 0;

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // 상단 프로필 SliverAppBar
          SliverAppBar(
            backgroundColor: Colors.grey[300],
            pinned: true,
            expandedHeight: 220, // 확장 높이
            collapsedHeight: 60, // 축소 높이
            title: _isCollapsed   // 접혔을 때만 닉네임 표시
                ? Text(nickname, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))
                : null,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.grey,
                          backgroundImage: profileImageUrl != null
                            ? NetworkImage(profileImageUrl)
                            : null,
                          child: profileImageUrl==null
                            ? const Icon(Icons.person, size: 40, color: Colors.white,)
                            : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nickname,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                bio,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(right: 10),
                          child: Row(
                            children: [
                              Text("팔로잉 $followingCount"),
                              SizedBox(width: 10),
                              Text("팔로워 $followerCount"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 15, top: 10, bottom: 10),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(30, 0, 0, 0),
                    shape: BoxShape.circle,
                  ),
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18),
                    onSelected: (String value) {
                      // 선택된 값에 따라 분기 처리
                      switch (value) {
                        case 'edit_profile':
                          _goToProfileEdit();
                          break;
                        case 'change_password':
                          _goToPasswordChange();
                          break;
                        case 'logout':
                          _logout();
                          break;
                        case 'inactivate_account':
                          _manageAccount('inactivate');
                          break;
                        case 'delete_account':
                          _manageAccount('delete');
                          break;
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'edit_profile',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('프로필 수정'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(), // 구분선
                      const PopupMenuItem<String>(
                        value: 'change_password',
                        child: Row(
                          children: [
                            Icon(Icons.lock_outline, size: 20),
                            SizedBox(width: 8),
                            Text('비밀번호 변경'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, size: 20),
                            SizedBox(width: 8),
                            Text('로그아웃'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                      value: 'inactivate_account',
                      child: Row(
                        children: [
                          Icon(Icons.pause_circle_outline, size: 20), 
                          SizedBox(width: 8), Text('계정 비활성화')
                        ]
                      ),
                    ),
                      const PopupMenuItem<String>(
                        value: 'delete_account',
                        child: Row(
                          children: [
                            Icon(Icons.delete_forever, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('회원 탈퇴', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ]
                  ),
                ),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 25, top: 20, bottom: 10),
              child: Text(
                '작성한 감상문',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // 🔹 책 리스트
          if (_publicReviews.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(30.0),
                child: Center(child: Text("작성된 공개 감상문이 없습니다.", style: TextStyle(color: Colors.grey))),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final review = _publicReviews[index];
                  return _buildReviewCard(review);
                },
                childCount: _publicReviews.length,
              ),
            ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 25, top: 20, bottom: 10),
              child: Text(
                "참여 모임",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ) 
          ),
          // [신규] 내 모임 리스트 출력
          if (_myGroups.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(30.0),
                child: Center(child: Text("가입한 모임이 없습니다.", style: TextStyle(color: Colors.grey))),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final group = _myGroups[index];
                  return _buildGroupItem(group);
                },
                childCount: _myGroups.length,
              ),
            ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 100), 
          ),
        ],
      ),
    );
  }
}
