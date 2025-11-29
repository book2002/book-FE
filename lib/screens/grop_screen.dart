import 'package:flutter/material.dart';
import 'package:flutter_app/models/group_model.dart';
import 'package:flutter_app/screens/details/group_create_page.dart';
import 'package:flutter_app/screens/details/group_info_page.dart';
import 'package:flutter_app/service/auth_service.dart';
import 'package:flutter_app/service/group_service.dart';
import 'package:flutter_app/testdata/group_dummy.dart';

class GroupScreen extends StatefulWidget {
  const GroupScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  final GroupService _groupService = GroupService();
  final AuthService _authService = AuthService();

  final TextEditingController _searchController = TextEditingController();

  // 데이터 상태 변수
  List<GroupResponse> _myGroups = [];
  List<GroupResponse> _allGroups = []; // 최신순
  List<GroupResponse> _popularGroups = []; // 인기순

  bool _isLoading = true;
  String _sortMode = '인기순';    // 정렬 모드 텍스트 변수 (기본값: 인기순)

  @override
  void initState() {
    super.initState();
    _fetchGroupData();
  }

  Future<void> _fetchGroupData() async {
    setState(() { _isLoading = true; });
    try {
      final results = await Future.wait([
        _groupService.getMyGroups(),
        _groupService.getGroups(),
        _groupService.getPopularGroups(),
      ]);

      if (mounted) {
        // _allGroups를 groupId 내림차순으로 정렬
        List<GroupResponse> sortedAllGroups = results[1];
        sortedAllGroups.sort((a, b) => b.groupId.compareTo(a.groupId));
        setState(() {
          _myGroups = results[0];
          _allGroups = sortedAllGroups;   // 정렬된 리스트 할당
          _popularGroups = results[2];
          _isLoading = false;
        });
      }
    } catch (e) {
      print("모임 데이터 로드 오류: $e");
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  // 모임 생성 페이지 이동 함수
  void _goToCreateGroupPage() async {
    if (!_authService.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("로그인이 필요합니다.")));
      return;
    }

    // 페이지 이동 후 결과를 기다림 (true면 생성 성공)
    final bool? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GroupCreatePage()),
    );

    // 생성 성공 시 목록 갱신
    if (result == true) {
      _fetchGroupData();
    }
  }

  // 모임 상세 페이지 이동 함수 (가입 여부 확인)
  void _goToGroupInfo(GroupResponse group) {
    // 1. 로그인이 안되어 있거나
    // 2. 가입하지 않은 그룹인 경우 접근 제한
    if (!group.isJoined) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("모임에 가입해야 게시글을 확인할 수 있습니다."),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 가입된 경우 상세 페이지로 이동하며 그룹 데이터 전달
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context)=> GroupInfoPage(group: group),
      ),
    );
  }

  // 모임 가입 함수
  void _joinGroup(int groupId) async {
    // 로그인 체크
    if (!_authService.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("로그인이 필요한 서비스입니다.")));
      return;
    }

    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("가입 확인"),
        content: const Text("이 모임에 가입하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("가입", style: TextStyle(color: Colors.green))),
        ],
      )
    );

    if (confirm == true) {
      bool success = await _groupService.joinGroup(groupId);
      if (success) {
        _fetchGroupData(); // 목록 갱신
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("가입되었습니다!")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("가입 실패 (정원 초과 등)")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 현재 탭에 따라 표시할 리스트 선택
    final displayList = _sortMode == '인기순' ? _popularGroups : _allGroups;  // 정렬 모드에 따라 표시할 리스트 선택

    return RefreshIndicator(
      onRefresh: _fetchGroupData, // 새로고침 함수 연결
      color: Colors.green,
      child: SingleChildScrollView(   // 전체 화면 스크롤
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 생성 유도 섹션
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("원하는 모임을 생성해보세요!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                    IconButton(
                      onPressed: _goToCreateGroupPage,    // 페이지 이동 함수 연결
                      icon: const Icon(Icons.add_circle, color: Colors.green, size: 30),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 내 모임 섹션
              Text('내 모임', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              
              if (!_authService.isLoggedIn)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("로그인 후 내 모임을 확인하세요.", style: TextStyle(color: Colors.grey))))
              else if (_myGroups.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                  child: const Column(
                    children: [
                      Icon(Icons.group_off, size: 40, color: Colors.grey),
                      SizedBox(height: 10),
                      Text("참여한 모임이 없어요.\n다양한 모임에 참여해보세요!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              else
                SizedBox(
                  height: 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _myGroups.length,
                    itemBuilder: (context, index) {
                      final group = _myGroups[index];
                      return Container(
                        width: 250,
                        margin: const EdgeInsets.only(right: 12),
                        child: Card(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: InkWell(
                            onTap: () => _goToGroupInfo(group),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 커버 이미지 영역 (상단 절반)
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                  child: Container(
                                    height: 70,
                                    width: double.infinity,
                                    color: Colors.primaries[index % Colors.primaries.length].withOpacity(0.3), // 랜덤 파스텔톤 배경
                                    child: group.groupImageUrl != null 
                                      ? Image.network(group.groupImageUrl!, fit: BoxFit.cover)
                                      : Icon(Icons.menu_book, color: Colors.primaries[index % Colors.primaries.length]),
                                  ),
                                ),
                                const Spacer(),
                                // 정보 영역
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(group.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          const Spacer(),
                                          Text("${group.currentMembers}명 참여 중", style: const TextStyle(color: Colors.grey, fontSize: 12))
                                        ],
                                      )
                                      ,
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              
              const SizedBox(height: 30),

              // 모임 목록 조회 헤더 (드롭다운 정렬)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 왼쪽: 타이틀 (선택 사항, 공백으로 둘 수도 있음)
                  Text("모임 둘러보기", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(), // 우측 정렬을 위해 Spacer 사용

                  // 오른쪽: 정렬 선택기 (PopupMenuButton)
                  PopupMenuButton<String>(
                    onSelected: (String value) {
                      setState(() {
                        _sortMode = value;
                      });
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: '인기순',
                        child: Text('인기순'),
                      ),
                      const PopupMenuItem<String>(
                        value: '최신순',
                        child: Text('최신순'),
                      ),
                    ],
                    child: Row(
                      children: [
                        Text(
                          _sortMode,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.black87),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              _isLoading 
                ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(), 
                    itemCount: displayList.length,
                    itemBuilder: (context, index) {
                      final group = displayList[index];
                      return InkWell(
                        onTap: () => _goToGroupInfo(group),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
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
                                    ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(group.groupImageUrl!, fit: BoxFit.cover))
                                    : const Icon(Icons.group, color: Colors.grey),
                                ),
                                const SizedBox(width: 12),
                                // 정보
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(height: 4),
                                      Text(group.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey)),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.person, size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text("${group.currentMembers}/${group.maxMembers}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                                // 가입 버튼
                                if (!group.isJoined)
                                  ElevatedButton(
                                    onPressed: group.currentMembers >= group.maxMembers ? null : () => _joinGroup(group.groupId),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      minimumSize: Size.zero, 
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap, 
                                    ),
                                    child: Text(
                                      group.currentMembers >= group.maxMembers ? "마감" : "가입", 
                                      style: const TextStyle(color: Colors.white, fontSize: 12)
                                    ),
                                  )
                                else
                                  const Text("참여중", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

            ],
          ),
        )
      )
    );
    
  }
}