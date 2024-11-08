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

Future<Response> handleToggleScheduleCompletion(
    Request request, Database db, int id) async {
  // 해당 id의 일정 조회
  final result =
      db.select('SELECT completed FROM schedules WHERE id = ?', [id]);

  if (result.isEmpty) {
    return Response.notFound('Schedule not found');
  }

  // 현재 completed 상태 가져오기
  final currentCompleted = result.first['completed'] == 1;
  final newCompleted = !currentCompleted;

  // completed 값을 반전하여 업데이트
  db.execute('UPDATE schedules SET completed = ? WHERE id = ?',
      [newCompleted ? 1 : 0, id]);

  return Response.ok('Schedule completion status toggled successfully');
}

/// 특정 날 수 x일 이내의 일정 조회 핸들러
Future<Response> handleGetPrioritiesRequest(
    Request request, Database db) async {
  final x = int.tryParse(request.url.queryParameters['x'] ?? '');
  if (x == null || x < 0) {
    return Response.badRequest(body: 'Invalid or missing x parameter');
  }

  // 오늘 날짜와 x일 후 날짜 계산
  final today = DateTime.now();
  final endDateLimit = today.add(Duration(days: x));

  // end_date가 오늘부터 x일 이내에 있는 일정 조회
  final result = db.select('''
    SELECT * FROM schedules
    WHERE DATE(end_date) >= DATE(?) AND DATE(end_date) <= DATE(?)
  ''', [
    today.toIso8601String().split('T').first,
    endDateLimit.toIso8601String().split('T').first
  ]);

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
