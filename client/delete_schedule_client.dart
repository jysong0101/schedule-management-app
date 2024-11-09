import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final serverUrl = 'http://localhost:8080';

  print('Enter the schedule ID to delete:');
  final scheduleId = stdin.readLineSync();

  final url = Uri.parse('$serverUrl/schedule/$scheduleId');
  final response = await http.delete(url);

  print(response.statusCode == 200
      ? 'Schedule deleted successfully'
      : 'Failed to delete schedule. Status code: ${response.statusCode}');
}
