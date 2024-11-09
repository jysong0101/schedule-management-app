import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final serverUrl = 'http://localhost:8080';

  // schedule ID 입력받기
  print('Enter the schedule ID to toggle completion status:');
  final scheduleId = stdin.readLineSync();

  if (scheduleId == null || scheduleId.isEmpty) {
    print('Schedule ID cannot be empty.');
    return;
  }

  // 완료 여부 반전 요청 URL 생성
  final url = Uri.parse('$serverUrl/schedule/$scheduleId/toggle');
  final response = await http.patch(url);

  // 응답 결과 처리
  print(response.statusCode == 200
      ? 'Schedule completion status toggled successfully'
      : 'Failed to toggle schedule completion status. Status code: ${response.statusCode}');
}
