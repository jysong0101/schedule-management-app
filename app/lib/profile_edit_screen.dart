import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String baseUrl = 'https://physically-legible-bengal.ngrok-free.app';

class ProfileEditScreen extends StatefulWidget {
  final String userId;

  ProfileEditScreen({required this.userId});

  @override
  _ProfileEditScreenState createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get-user-info?id=${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          nameController.text = data['name'];
          emailController.text = data['backup_email'];
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to fetch user info');
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateUserInfo() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update-user-info'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id': widget.userId,
          'name': nameController.text.trim(),
          'backup_email': emailController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context, true);
      } else {
        print('Error updating user info: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('프로필 편집'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: '이름',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16.0),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: '이메일',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 32.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('취소'),
                      ),
                      ElevatedButton(
                        onPressed: _updateUserInfo,
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
