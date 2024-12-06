import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:sqlite3/sqlite3.dart';

// 오늘 마감되는 일정 조회 함수
Future<Response> handleGetTodayTodos(Request request, Database db) async {
  final userId = request.url.queryParameters['user_id'];

  if (userId == null) {
    return Response.badRequest(body: 'Missing user_id parameter');
  }

  final today = DateTime.now().toIso8601String().split('T').first;

  final result = db.select('''
    SELECT * FROM schedules
    WHERE user_id = ? AND DATE(end_date) = DATE(?)
  ''', [userId, today]);

  final todos = result.map((row) => mapSchedule(row)).toList();

  return Response.ok(jsonEncode(todos),
      headers: {'Content-Type': 'application/json'});
}

// 이번 주 마감되는 일정 조회 함수
Future<Response> handleGetThisWeekTodos(Request request, Database db) async {
  final userId = request.url.queryParameters['user_id'];

  if (userId == null) {
    return Response.badRequest(body: 'Missing user_id parameter');
  }

  final now = DateTime.now();
  final startOfWeek = now
      .subtract(Duration(days: now.weekday - 1))
      .toIso8601String()
      .split('T')
      .first;
  final endOfWeek = now
      .add(Duration(days: 7 - now.weekday))
      .toIso8601String()
      .split('T')
      .first;

  final result = db.select('''
    SELECT * FROM schedules
    WHERE user_id = ? AND DATE(end_date) BETWEEN DATE(?) AND DATE(?)
  ''', [userId, startOfWeek, endOfWeek]);

  final todos = result.map((row) => mapSchedule(row)).toList();

  return Response.ok(jsonEncode(todos),
      headers: {'Content-Type': 'application/json'});
}

// 이번 달 마감되는 일정 조회 함수
Future<Response> handleGetThisMonthTodos(Request request, Database db) async {
  final userId = request.url.queryParameters['user_id'];

  if (userId == null) {
    return Response.badRequest(body: 'Missing user_id parameter');
  }

  final now = DateTime.now();
  final startOfMonth =
      DateTime(now.year, now.month, 1).toIso8601String().split('T').first;
  final endOfMonth =
      DateTime(now.year, now.month + 1, 0).toIso8601String().split('T').first;

  final result = db.select('''
    SELECT * FROM schedules
    WHERE user_id = ? AND DATE(end_date) BETWEEN DATE(?) AND DATE(?)
  ''', [userId, startOfMonth, endOfMonth]);

  final todos = result.map((row) => mapSchedule(row)).toList();

  return Response.ok(jsonEncode(todos),
      headers: {'Content-Type': 'application/json'});
}

Map<String, dynamic> mapSchedule(Row row) {
  return {
    'id': row['id'],
    'user_id': row['user_id'],
    'name': row['name'],
    'start_date': row['start_date'],
    'end_date': row['end_date'],
    'details': row['details'],
    'completed': row['completed'] == 1,
  };
}
