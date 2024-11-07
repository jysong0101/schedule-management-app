import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:sqlite3/sqlite3.dart';

/// 일정 추가 핸들러
Future<Response> handleAddScheduleRequest(Request request, Database db) async {
  final payload = await request.readAsString();
  final data = jsonDecode(payload);

  final name = data['name'];
  final startDate = data['start_date'];
  final endDate = data['end_date'];
  final details = data['details'];
  final completed = data['completed'] ?? false;

  if (name == null || startDate == null || endDate == null) {
    return Response.badRequest(body: 'Missing required fields');
  }

  db.execute('''
    INSERT INTO schedules (name, start_date, end_date, details, completed)
    VALUES (?, ?, ?, ?, ?)
  ''', [name, startDate, endDate, details, completed ? 1 : 0]);

  return Response.ok('Schedule added successfully');
}

/// 특정 날짜로 일정 조회 핸들러
Future<Response> handleGetScheduleByDateRequest(
    Request request, Database db) async {
  final date = request.url.queryParameters['date'];
  if (date == null) {
    return Response.badRequest(body: 'Missing date parameter');
  }

  final result = db.select('''
    SELECT * FROM schedules
    WHERE start_date <= ? AND end_date >= ?
  ''', [date, date]);

  final schedules = result
      .map((row) => {
            'id': row['id'],
            'name': row['name'],
            'start_date': row['start_date'],
            'end_date': row['end_date'],
            'details': row['details'],
            'completed': row['completed'] == 1
          })
      .toList();

  return Response.ok(jsonEncode(schedules),
      headers: {'Content-Type': 'application/json'});
}
