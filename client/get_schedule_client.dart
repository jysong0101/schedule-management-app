import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  // 서버 주소와 포트 설정
  final serverUrl = 'http://localhost:8080';

  // 사용자로부터 user_id 입력받기
  print('Enter the user ID to fetch schedules for:');
  final userId = stdin.readLineSync();

  if (userId == null || userId.isEmpty) {
    print('User ID cannot be empty.');
    return;
  }

  // 사용자로부터 날짜 입력받기
  print('Enter the date to fetch schedules (format: YYYY-MM-DD):');
  final inputDate = stdin.readLineSync();

  if (inputDate != null && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(inputDate)) {
    // 입력한 user_id와 날짜로 일정 조회 요청
    await fetchSchedulesByDate(serverUrl, inputDate, userId);
  } else {
    print('Invalid date format. Please enter a date in the format YYYY-MM-DD.');
  }
}

// user_id와 날짜로 일정 조회하는 함수
Future<void> fetchSchedulesByDate(
    String serverUrl, String date, String userId) async {
  final url = Uri.parse('$serverUrl/schedule?date=$date&user_id=$userId');

  try {
    final response = await http.get(url);

    // 응답 상태 확인
    if (response.statusCode == 200) {
      print('Schedules for $userId on $date:');
      final schedules = jsonDecode(response.body);
      for (var schedule in schedules) {
        printSchedule(schedule);
      }
    } else {
      print('Failed to fetch schedules. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error: $e');
  }
}

// 일정 데이터를 CMD에 출력하는 함수
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
