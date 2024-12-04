import 'package:flutter/material.dart';
import 'schedule_screen.dart';
import 'signup_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // for utf8.encode
import 'package:crypto/crypto.dart'; // for sha256

const String baseUrl = 'https://physically-legible-bengal.ngrok-free.app';

class LoginScreen extends StatelessWidget {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _userIdController,
              decoration: InputDecoration(
                labelText: 'User ID',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true, // 비밀번호 입력 시 텍스트 숨김 처리
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                final userId = _userIdController.text.trim();
                final password = _passwordController.text.trim();

                if (userId.isNotEmpty && password.isNotEmpty) {
                  // 비밀번호 해싱
                  final hashedPassword =
                      sha256.convert(utf8.encode(password)).toString();

                  // 서버로 로그인 요청
                  final response = await http.post(
                    Uri.parse('$baseUrl/login'),
                    headers: {'Content-Type': 'application/json'},
                    body:
                        json.encode({'id': userId, 'password': hashedPassword}),
                  );

                  if (response.statusCode == 200) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ScheduleScreen(userId: userId),
                      ),
                    );
                  } else {
                    // 에러 처리: 팝업으로 알림
                    _showErrorDialog(context, '로그인 실패!',
                        '정확하지 않은 User ID 또는 Password입니다.\n다시 시도해주세요.');
                  }
                } else {
                  // 필드 비어있는 경우 처리
                  _showErrorDialog(
                      context, '입력 오류', 'User ID 와 Password를 입력해주세요.');
                }
              },
              child: Text('Login'),
            ),
            SizedBox(height: 16.0),
            TextButton(
              onPressed: () {
                // 회원가입 화면으로 이동
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SignupScreen(),
                  ),
                );
              },
              child: Text('Create an Account'),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // 팝업 닫기
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
