import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final serverUrl = 'http://localhost:8080';

  // 사용자로부터 user_id 입력받기
  print('Enter user ID to fetch to-dos for:');
  final userId = stdin.readLineSync();

  if (userId == null || userId.isEmpty) {
    print('User ID cannot be empty.');
    return;
  }

  // 사용자로부터 to-do 타입 선택받기
  print('Select to-do type to fetch:\n1. Today\n2. This week\n3. This month');
  final choice = stdin.readLineSync();

  final endpoint =
      {'1': 'todo/today', '2': 'todo/week', '3': 'todo/month'}[choice];

  if (endpoint == null) {
    print('Invalid choice.');
    return;
  }

  final url = Uri.parse('$serverUrl/$endpoint?user_id=$userId');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    print('To-dos for $userId on $endpoint:');
    final todos = jsonDecode(response.body);
    for (var todo in todos) {
      printTodoDetails(todo);
    }
  } else {
    print('Failed to fetch to-dos. Status code: ${response.statusCode}');
  }
}

// 일정 데이터를 보기 좋은 형식으로 출력하는 함수
void printTodoDetails(Map<String, dynamic> todo) {
  print('ID: ${todo['id']}');
  print('User ID: ${todo['user_id']}');
  print('Name: ${todo['name']}');
  print('Start Date: ${todo['start_date']}');
  print('End Date: ${todo['end_date']}');
  print('Details: ${todo['details']}');
  print('Completed: ${todo['completed']}');
  print('-----------------------');
}
