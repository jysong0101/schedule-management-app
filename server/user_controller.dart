import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:sqlite3/sqlite3.dart';

Future<Response> handleAddUserRequest(Request request, Database db) async {
  final payload = await request.readAsString();
  final data = jsonDecode(payload);

  final id = data['id'];
  final name = data['name'];

  if (id == null || name == null) {
    return Response.badRequest(body: 'Missing id or name');
  }

  // 데이터베이스에 사용자 추가
  try {
    db.execute('INSERT INTO users (id, name) VALUES (?, ?)', [id, name]);
  } catch (e) {
    return Response.badRequest(body: 'User ID must be unique');
  }

  return Response.ok('User added successfully');
}

Future<Response> handleGetUsersRequest(Database db) async {
  final result = db.select('SELECT * FROM users');
  final users = result
      .map((row) => {
            'id': row['id'],
            'name': row['name'],
            'age': row['age'],
          })
      .toList();

  return Response.ok(jsonEncode(users),
      headers: {'Content-Type': 'application/json'});
}

Future<Response> handleGetUserNameByIdRequest(
    Request request, Database db) async {
  final userId = request.url.queryParameters['id'];

  if (userId == null || userId.isEmpty) {
    return Response.badRequest(body: 'Missing or invalid user ID');
  }

  // 데이터베이스에서 사용자 이름 조회
  try {
    final result = db.select(
      'SELECT name FROM users WHERE id = ?',
      [userId],
    );

    if (result.isEmpty) {
      return Response.notFound('User not found');
    }

    final userName = result.first['name'];
    return Response.ok(jsonEncode({'id': userId, 'name': userName}),
        headers: {'Content-Type': 'application/json'});
  } catch (e) {
    return Response.internalServerError(body: 'Database error: $e');
  }
}

/// 계정 생성 API
Future<Response> handleCreateAccount(Request request, Database db) async {
  final payload = await request.readAsString();
  final data = jsonDecode(payload);

  final userId = data['id'];
  final name = data['name'];
  final password = data['password']; // 해싱된 비밀번호
  final backupEmail = data['backup_email'];

  if (userId == null ||
      name == null ||
      password == null ||
      backupEmail == null) {
    return Response.badRequest(body: 'Missing required fields');
  }

  try {
    db.execute('''
      INSERT INTO users (id, name, password, backup_email)
      VALUES (?, ?, ?, ?)
    ''', [userId, name, password, backupEmail]);

    return Response.ok('Account created successfully');
  } catch (e) {
    return Response.badRequest(body: 'User ID already exists');
  }
}

/// 로그인 API
Future<Response> handleLogin(Request request, Database db) async {
  final payload = await request.readAsString();
  final data = jsonDecode(payload);

  final userId = data['id'];
  final password = data['password']; // 클라이언트에서 해싱된 비밀번호 제공

  if (userId == null || password == null) {
    return Response.badRequest(body: 'Missing user ID or password');
  }

  final result = db.select('''
    SELECT password FROM users WHERE id = ?
  ''', [userId]);

  if (result.isEmpty) {
    return Response.notFound('User not found');
  }

  final storedPassword = result.first['password'];
  if (storedPassword != password) {
    return Response.forbidden('Invalid password');
  }

  return Response.ok('Login successful');
}
