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
import 'todo_controller.dart';

void main() async {
  // 로그 파일 생성
  final DateTime now = DateTime.now();
  final logFileName =
      'server_logs/${now.toIso8601String().replaceAll(':', '-')}.txt';
  final logFile = await initializeLogFile(logFileName);

  // SQLite 데이터베이스 초기화
  final database = sqlite3.open('example.db');
  initializeDatabase(database);

  // 요청 핸들러 생성
  var handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware((innerHandler) => (request) async {
            // 요청 로그 작성
            final logEntry =
                '[${DateTime.now()}] ${request.method} ${request.requestedUri}\n';
            await logFile.writeAsString(logEntry, mode: FileMode.append);
            final response = await innerHandler(request);

            // 응답 로그 작성
            final responseLog =
                '[${DateTime.now()}] Response: ${response.statusCode}\n\n';
            await logFile.writeAsString(responseLog, mode: FileMode.append);
            return response;
          })
      .addHandler((request) => router(request, database));

  // 서버 실행
  var server = await io.serve(handler, InternetAddress.anyIPv4, 8080);
  print('Server listening on port ${server.port}');
}

Future<File> initializeLogFile(String logFileName) async {
  final logDirectory = Directory('server_logs');
  if (!await logDirectory.exists()) {
    await logDirectory.create();
  }
  final logFile = File(logFileName);
  return await logFile.create();
}

void initializeDatabase(Database db) {
  // 기존 테이블이 존재하면 유지 (삭제하지 않음)
  db.execute('''
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL
    );
  ''');

  db.execute('''
    CREATE TABLE IF NOT EXISTS schedules (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id TEXT NOT NULL,
      name TEXT NOT NULL,
      start_date TEXT NOT NULL,
      end_date TEXT NOT NULL,
      details TEXT,
      completed BOOLEAN NOT NULL DEFAULT 0,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    );
  ''');

  // 초기 데이터 삽입
  insertInitialData(db);
}

void insertInitialData(Database db) {
  // 사용자 데이터가 이미 있는지 확인
  final existingUsers = db.select('SELECT COUNT(*) AS count FROM users');
  if (existingUsers.first['count'] == 0) {
    // 사용자 추가
    final users = [
      {'id': 'user1', 'name': 'Alice'},
      {'id': 'user2', 'name': 'Bob'}
    ];

    for (var user in users) {
      db.execute('INSERT INTO users (id, name) VALUES (?, ?)',
          [user['id'], user['name']]);
    }
  }

  // 일정 데이터가 이미 있는지 확인
  final existingSchedules =
      db.select('SELECT COUNT(*) AS count FROM schedules');
  if (existingSchedules.first['count'] == 0) {
    // 일정 데이터 추가
    final startDate = DateTime(2024, 11, 1);
    final endDate = DateTime(2024, 11, 30);

    for (var date = startDate;
        date.isBefore(endDate) || date.isAtSameMomentAs(endDate);
        date = date.add(Duration(days: 1))) {
      for (var i = 1; i <= 2; i++) {
        final formattedDate =
            '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final name = '$formattedDate example$i';
        final details = '$name for test';
        final dateString = date.toIso8601String().split('T').first;

        // 각 사용자마다 동일한 일정을 생성
        for (var userId in ['user1', 'user2']) {
          db.execute('''
            INSERT INTO schedules (user_id, name, start_date, end_date, details, completed)
            VALUES (?, ?, ?, ?, ?, 0)
          ''', [userId, name, dateString, dateString, details]);
        }
      }
    }
  }
}

FutureOr<Response> router(Request request, Database database) {
  if (request.url.path == 'time') {
    return handleTimeRequest(request);
  } else if (request.url.path == 'user' && request.method == 'POST') {
    return handleAddUserRequest(request, database);
  } else if (request.url.path == 'users' && request.method == 'GET') {
    return handleGetUsersRequest(database);
  } else if (request.url.path == 'user/name' && request.method == 'GET') {
    return handleGetUserNameByIdRequest(request, database);
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
  } else if (request.url.pathSegments.length == 2 &&
      request.url.pathSegments[0] == 'schedule' &&
      request.method == 'DELETE') {
    final id = int.tryParse(request.url.pathSegments[1]);
    if (id != null) {
      return handleDeleteScheduleRequest(request, database, id);
    }
    return Response.badRequest(body: 'Invalid ID');
  } else if (request.url.path == 'priorities' && request.method == 'GET') {
    return handleGetPrioritiesRequest(request, database);
  } else if (request.url.path == 'fortest/all-schedules' &&
      request.method == 'GET') {
    return handleGetAllSchedulesRequest(database);
  } else if (request.url.path == 'openapi.json') {
    return Response.ok(File('openapi.json').readAsStringSync(),
        headers: {'Content-Type': 'application/json'});
  } else if (request.url.path == 'docs') {
    return Response.ok(File('swagger.html').readAsStringSync(),
        headers: {'Content-Type': 'text/html'});
  }
  // 추가된 todo API 경로
  else if (request.url.path == 'todo/today' && request.method == 'GET') {
    return handleGetTodayTodos(request, database);
  } else if (request.url.path == 'todo/week' && request.method == 'GET') {
    return handleGetThisWeekTodos(request, database);
  } else if (request.url.path == 'todo/month' && request.method == 'GET') {
    return handleGetThisMonthTodos(request, database);
  }

  return Response.notFound('Not Found');
}
