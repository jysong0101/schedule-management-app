import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final serverUrl = 'http://localhost:8080';

  print('Enter user ID for the schedule:');
  final userId = stdin.readLineSync();
  print('Enter schedule name:');
  final name = stdin.readLineSync();
  print('Enter start date (YYYY-MM-DD):');
  final startDate = stdin.readLineSync();
  print('Enter end date (YYYY-MM-DD):');
  final endDate = stdin.readLineSync();
  print('Enter schedule details:');
  final details = stdin.readLineSync();
  print('Is the schedule completed? (true/false):');
  final completed = stdin.readLineSync()?.toLowerCase() == 'true';

  final url = Uri.parse('$serverUrl/schedule');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'user_id': userId,
      'name': name,
      'start_date': startDate,
      'end_date': endDate,
      'details': details,
      'completed': completed
    }),
  );

  print(response.statusCode == 200
      ? 'Schedule added successfully'
      : 'Failed to add schedule. Status code: ${response.statusCode}');
}
