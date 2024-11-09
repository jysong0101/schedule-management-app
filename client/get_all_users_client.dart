import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final serverUrl = 'http://localhost:8080';

  final url = Uri.parse('$serverUrl/users');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    print('All users:');
    final users = jsonDecode(response.body);
    for (var user in users) {
      print('ID: ${user['id']}, Name: ${user['name']}');
    }
  } else {
    print('Failed to fetch users. Status code: ${response.statusCode}');
  }
}
