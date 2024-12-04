import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart'; // for sha256
import 'dart:convert';

const String baseUrl = 'https://physically-legible-bengal.ngrok-free.app';

class SignupScreen extends StatelessWidget {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
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
              controller: _userNameController,
              decoration: InputDecoration(
                labelText: 'User Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                final userId = _userIdController.text.trim();
                final userName = _userNameController.text.trim();
                final email = _emailController.text.trim();
                final password = _passwordController.text.trim();
                final confirmPassword = _confirmPasswordController.text.trim();

                if (userId.isNotEmpty &&
                    userName.isNotEmpty &&
                    email.isNotEmpty &&
                    password.isNotEmpty &&
                    password == confirmPassword) {
                  // 비밀번호 해싱
                  final hashedPassword =
                      sha256.convert(utf8.encode(password)).toString();

                  // 서버로 회원가입 요청
                  final response = await http.post(
                    Uri.parse('$baseUrl/create-account'),
                    headers: {'Content-Type': 'application/json'},
                    body: json.encode({
                      'id': userId,
                      'name': userName,
                      'password': hashedPassword,
                      'backup_email': email,
                    }),
                  );

                  if (response.statusCode == 200) {
                    Navigator.pop(context); // 성공 시 로그인 화면으로 돌아가기
                  } else {
                    print('Signup failed: ${response.body}');
                  }
                } else {
                  // 에러 처리: 입력값 검증 실패
                  if (password != confirmPassword) {
                    print('Passwords do not match');
                  } else {
                    print('All fields are required');
                  }
                }
              },
              child: Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
