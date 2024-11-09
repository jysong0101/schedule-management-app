import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final serverUrl = 'http://localhost:8080';

  print('Enter user ID:');
  final userId = stdin.readLineSync();
  print('Enter the number of days for priorities check:');
  final days = stdin.readLineSync();

  final url = Uri.parse('$serverUrl/priorities?x=$days&user_id=$userId');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    print('Priority schedules within $days days for $userId:');
    final priorities = jsonDecode(response.body);
    for (var schedule in priorities) {
      printSchedule(schedule);
    }
  } else {
    print('Failed to fetch priorities. Status code: ${response.statusCode}');
  }
}

// 일정 정보를 보기 좋은 형식으로 출력하는 함수
void printSchedule(Map<String, dynamic> schedule) {
  print('ID: ${schedule['id']}');
  print('User ID: ${schedule['user_id']}');
  print('Name: ${schedule['name']}');
  print('Start Date: ${schedule['start_date']}');
  print('End Date: ${schedule['end_date']}');
  print('Details: ${schedule['details']}');
  print('Completed: ${schedule['completed']}');
  print('-----------------------');
}
