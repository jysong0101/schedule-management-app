import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';
import 'password_change_screen.dart';
import 'profile_edit_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String baseUrl = 'https://physically-legible-bengal.ngrok-free.app';

class SettingsScreen extends StatefulWidget {
  final String userId;

  SettingsScreen({required this.userId});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _username;
  bool _isLoading = true;
  int selectedPriorityRange = 3;

  @override
  void initState() {
    super.initState();
    _fetchUsername();
    _loadPriorityRange();
  }

  Future<void> _savePriorityRange(int range) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selectedPriorityRange', range);
  }

  Future<void> _loadPriorityRange() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedPriorityRange = prefs.getInt('selectedPriorityRange') ?? 3;
    });
  }

  Future<void> _fetchUsername() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/name?id=${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _username = data['name'];
          _isLoading = false;
        });
      } else if (response.statusCode == 400 || response.statusCode == 404) {
        final data = json.decode(response.body);
        setState(() {
          _username = data['error'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _username = '알 수 없는 오류';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _username = '오류 발생';
        _isLoading = false;
      });
    }
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('로그아웃'),
          content: Text('정말로 로그아웃 하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('아니오'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              },
              child: Text(
                '예',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 프로필 이미지 및 이름
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            child: Icon(Icons.person, size: 50),
                          ),
                          SizedBox(height: 16),
                          Text(
                            _username ?? '알 수 없음',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProfileEditScreen(
                                          userId: widget.userId),
                                    ),
                                  );
                                },
                                child: Text('프로필 편집'),
                              ),
                              SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          PasswordChangeScreen(
                                              userId: widget.userId),
                                    ),
                                  );
                                },
                                child: Text('비밀번호 변경'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 30),
                    SwitchListTile(
                      title: Text('앱 잠금'),
                      value: false,
                      onChanged: (bool value) {
                        // 스위치 상태 변경 처리
                      },
                    ),
                    // 모드 설정
                    ListTile(
                      title: Text('모드 설정'),
                      trailing: DropdownButton<String>(
                        value: '라이트 모드',
                        items: ['라이트 모드', '다크 모드']
                            .map((String value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ))
                            .toList(),
                        onChanged: (String? value) {
                          // 드롭다운 변경 처리
                        },
                      ),
                    ),
                    // 한 주의 시작
                    ListTile(
                      title: Text('한 주의 시작'),
                      trailing: DropdownButton<String>(
                        value: '일요일',
                        items: ['일요일', '월요일']
                            .map((String value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ))
                            .toList(),
                        onChanged: (String? value) {
                          // 드롭다운 변경 처리
                        },
                      ),
                    ),
                    // Priorities 범위 설정
                    ListTile(
                      title: Text('Priorities 범위'),
                      trailing: DropdownButton<int>(
                        value: selectedPriorityRange,
                        items: List.generate(
                          5,
                          (index) => DropdownMenuItem<int>(
                            value: index + 1,
                            child: Text('${index + 1}일'),
                          ),
                        ),
                        onChanged: (int? value) {
                          if (value != null) {
                            setState(() {
                              selectedPriorityRange = value;
                            });
                            _savePriorityRange(value);
                          }
                        },
                      ),
                    ),
                    SizedBox(height: 30),
                    // 로그아웃 버튼
                    Align(
                      alignment: Alignment.center,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 190, 81, 65),
                          padding: EdgeInsets.symmetric(
                              horizontal: 40, vertical: 12),
                        ),
                        onPressed: () {
                          _showLogoutConfirmation(context);
                        },
                        child: Text(
                          'Logout',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
