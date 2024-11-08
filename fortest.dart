import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:sqlite3/sqlite3.dart';

/// 모든 일정 조회 핸들러 (테스트 용도)
Future<Response> handleGetAllSchedulesRequest(Database db) async {
  final result = db.select('SELECT * FROM schedules');

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
