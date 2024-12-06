import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:sqlite3/sqlite3.dart';

/// 일정 추가 핸들러
Future<Response> handleAddScheduleRequest(Request request, Database db) async {
  final payload = await request.readAsString();
  final data = jsonDecode(payload);

  final userId = data['user_id'];
  final name = data['name'];
  final startDate = data['start_date'];
  final endDate = data['end_date'];
  final details = data['details'];
  final completed = data['completed'] ?? false;

  if (userId == null || name == null || startDate == null || endDate == null) {
    return Response.badRequest(body: 'Missing required fields');
  }

  final userExists = db.select('SELECT id FROM users WHERE id = ?', [userId]);
  if (userExists.isEmpty) {
    return Response.notFound('User not found');
  }

  db.execute('''
    INSERT INTO schedules (user_id, name, start_date, end_date, details, completed)
    VALUES (?, ?, ?, ?, ?, ?)
  ''', [userId, name, startDate, endDate, details, completed ? 1 : 0]);

  return Response.ok('Schedule added successfully');
}

/// 특정 날짜의 일정 조회 핸들러
Future<Response> handleGetScheduleByDateRequest(
    Request request, Database db) async {
  final date = request.url.queryParameters['date'];
  final userId = request.url.queryParameters['user_id'];

  if (date == null || userId == null) {
    return Response.badRequest(body: 'Missing date or user_id parameter');
  }

  final result = db.select('''
    SELECT id, user_id, name, start_date, end_date, details, completed 
    FROM schedules
    WHERE user_id = ? AND DATE(start_date) <= DATE(?) AND DATE(end_date) >= DATE(?)
  ''', [userId, date, date]);

  final schedules = result
      .map((row) => {
            'id': row['id'],
            'user_id': row['user_id'],
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

/// 일정 완료 상태 토글 핸들러
Future<Response> handleToggleScheduleCompletion(
    Request request, Database db, int id) async {
  final result =
      db.select('SELECT completed FROM schedules WHERE id = ?', [id]);

  if (result.isEmpty) {
    return Response.notFound('Schedule not found');
  }

  final currentCompleted = result.first['completed'] == 1;
  final newCompleted = !currentCompleted;

  db.execute('UPDATE schedules SET completed = ? WHERE id = ?',
      [newCompleted ? 1 : 0, id]);

  return Response.ok('Schedule completion status toggled successfully');
}

/// 특정 날 수 이내의 일정 조회 핸들러
Future<Response> handleGetPrioritiesRequest(
    Request request, Database db) async {
  final x = int.tryParse(request.url.queryParameters['x'] ?? '');
  final userId = request.url.queryParameters['user_id'];
  if (x == null || x < 0 || userId == null) {
    return Response.badRequest(
        body: 'Invalid or missing x or user_id parameter');
  }

  final today = DateTime.now();
  final endDateLimit = today.add(Duration(days: x));

  final result = db.select('''
    SELECT id, user_id, name, start_date, end_date, details, completed 
    FROM schedules
    WHERE user_id = ? AND DATE(end_date) >= DATE(?) AND DATE(end_date) <= DATE(?)
  ''', [
    userId,
    today.toIso8601String().split('T').first,
    endDateLimit.toIso8601String().split('T').first
  ]);

  final schedules = result
      .map((row) => {
            'id': row['id'],
            'user_id': row['user_id'],
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

/// 일정 삭제 핸들러
Future<Response> handleDeleteScheduleRequest(
    Request request, Database db, int id) async {
  final result = db.select('SELECT * FROM schedules WHERE id = ?', [id]);

  if (result.isEmpty) {
    return Response.notFound('Schedule not found');
  }

  db.execute('DELETE FROM schedules WHERE id = ?', [id]);

  return Response.ok('Schedule deleted successfully');
}
