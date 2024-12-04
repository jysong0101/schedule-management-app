// password_change_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String baseUrl = 'https://physically-legible-bengal.ngrok-free.app';

class PasswordChangeScreen extends StatefulWidget {
  final String userId;

  PasswordChangeScreen({required this.userId});

  @override
  _PasswordChangeScreenState createState() => _PasswordChangeScreenState();
}

class _PasswordChangeScreenState extends State<PasswordChangeScreen> {
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmNewPasswordController =
      TextEditingController();

  Future<void> _updatePassword() async {
    if (newPasswordController.text.trim() !=
        confirmNewPasswordController.text.trim()) {
      _showErrorDialog('비밀번호 불일치', '새 비밀번호가 일치하지 않습니다.');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id': widget.userId,
          'old_password': currentPasswordController.text.trim(),
          'new_password': newPasswordController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context, true); // 성공 시 이전 화면으로 돌아가기
      } else {
        final data = json.decode(response.body);
        if (response.statusCode == 400 &&
            (data['error']?.contains('invalid current password') ?? false)) {
          _showErrorDialog('현재 비밀번호 오류', '현재 비밀번호가 올바르지 않습니다.');
        } else {
          _showErrorDialog('오류', data['error'] ?? '비밀번호 변경 실패');
        }
      }
    } catch (e) {
      print('Error: $e');
      _showErrorDialog('오류', '비밀번호 변경 실패');
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('비밀번호 변경'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: currentPasswordController,
              decoration: InputDecoration(
                labelText: '현재 비밀번호',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: newPasswordController,
              decoration: InputDecoration(
                labelText: '새 비밀번호',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: confirmNewPasswordController,
              decoration: InputDecoration(
                labelText: '새 비밀번호 확인',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 32.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // 취소 버튼
                  },
                  child: Text('취소'),
                ),
                ElevatedButton(
                  onPressed: _updatePassword, // 저장 버튼
                  child: Text('저장'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
