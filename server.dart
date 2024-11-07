import 'dart:async';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:sqlite3/sqlite3.dart';
import 'time_controller.dart';
import 'user_controller.dart';
import 'schedule_controller.dart'; // 새로 추가

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

// 라우팅 설정
FutureOr<Response> router(Request request, Database database) {
  if (request.url.path == 'time') {
    return handleTimeRequest(request);
  } else if (request.url.path == 'user' && request.method == 'POST') {
    return handleAddUserRequest(request, database);
  } else if (request.url.path == 'users' && request.method == 'GET') {
    return handleGetUsersRequest(database);
  } else if (request.url.path == 'schedule' && request.method == 'POST') {
    return handleAddScheduleRequest(request, database); // 일정 추가
  } else if (request.url.path.startsWith('schedule') &&
      request.method == 'GET') {
    return handleGetScheduleByDateRequest(request, database); // 날짜로 일정 조회
  }
  return Response.notFound('Not Found');
}
