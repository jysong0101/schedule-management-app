import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final serverUrl = 'http://localhost:8080';

  print('Enter user ID:');
  final userId = stdin.readLineSync();
  print('Enter user name:');
  final userName = stdin.readLineSync();

  final url = Uri.parse('$serverUrl/user');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'id': userId, 'name': userName}),
  );

  print(response.statusCode == 200
      ? 'User registered successfully'
      : 'Failed to register user. Status code: ${response.statusCode}');
}
