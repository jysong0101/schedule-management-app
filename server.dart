import 'dart:async';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:sqlite3/sqlite3.dart';
import 'time_controller.dart';
import 'user_controller.dart';
import 'schedule_controller.dart';
import 'docs_handler.dart';
import 'fortest.dart';

void main() async {
  // SQLite 데이터베이스 초기화
  final database = sqlite3.open('example.db');
  initializeDatabase(database);

  // 요청 핸들러 생성
  var handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler((request) => router(request, database));

  // 서버 실행
  var server = await io.serve(handler, InternetAddress.anyIPv4, 8080);
  print('Server listening on port ${server.port}');
}

void initializeDatabase(Database db) {
  // 기존 테이블이 있으면 삭제
  db.execute('DROP TABLE IF EXISTS users');
  db.execute('DROP TABLE IF EXISTS schedules');

  // 새 테이블 생성
  db.execute('''
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      age INTEGER NOT NULL
    );
  ''');

  db.execute('''
    CREATE TABLE IF NOT EXISTS schedules (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      start_date TEXT NOT NULL,
      end_date TEXT NOT NULL,
      details TEXT,
      completed BOOLEAN NOT NULL DEFAULT 0
    );
  ''');
}

FutureOr<Response> router(Request request, Database database) {
  if (request.url.path == 'time') {
    return handleTimeRequest(request);
  } else if (request.url.path == 'user' && request.method == 'POST') {
    return handleAddUserRequest(request, database);
  } else if (request.url.path == 'users' && request.method == 'GET') {
    return handleGetUsersRequest(database);
  } else if (request.url.path == 'schedule' && request.method == 'POST') {
    return handleAddScheduleRequest(request, database);
  } else if (request.url.path == 'schedule' && request.method == 'GET') {
    return handleGetScheduleByDateRequest(request, database);
  } else if (request.url.pathSegments.length == 3 &&
      request.url.pathSegments[0] == 'schedule' &&
      request.url.pathSegments[2] == 'toggle' &&
      request.method == 'PATCH') {
    final id = int.tryParse(request.url.pathSegments[1]);
    if (id != null) {
      return handleToggleScheduleCompletion(request, database, id);
    }
    return Response.badRequest(body: 'Invalid ID');
  } else if (request.url.path == 'priorities' && request.method == 'GET') {
    return handleGetPrioritiesRequest(request, database);
  } else if (request.url.path == 'fortest/all-schedules' &&
      request.method == 'GET') {
    // 테스트용 모든 일정 조회 경로 추가
    return handleGetAllSchedulesRequest(database);
  } else if (request.url.path == 'openapi.json') {
    return Response.ok(File('openapi.json').readAsStringSync(),
        headers: {'Content-Type': 'application/json'});
  } else if (request.url.path == 'docs') {
    return Response.ok(File('swagger.html').readAsStringSync(),
        headers: {'Content-Type': 'text/html'});
  }
  return Response.notFound('Not Found');
}
