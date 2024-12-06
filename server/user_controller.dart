import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

Future<Response> handleAddUserRequest(Request request, Database db) async {
  final payload = await request.readAsString();
  final data = jsonDecode(payload);

  final id = data['id'];
  final name = data['name'];

  if (id == null || name == null) {
    return Response.badRequest(body: 'Missing id or name');
  }

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
  final password = data['password'];
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
  final password = data['password'];

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

Future<Response> handleUpdateUserInfo(Request request, Database db) async {
  try {
    final payload = await request.readAsString();
    final data = jsonDecode(payload);

    final userId = data['id'];
    final newName = data['name'];
    final newBackupEmail = data['backup_email'];

    if (userId == null || newName == null || newBackupEmail == null) {
      return Response.badRequest(body: 'Missing required fields');
    }

    final existingUser =
        db.select('SELECT id FROM users WHERE id = ?', [userId]);
    if (existingUser.isEmpty) {
      return Response.notFound('User not found');
    }

    db.execute('''
      UPDATE users
      SET name = ?, backup_email = ?
      WHERE id = ?
    ''', [newName, newBackupEmail, userId]);

    return Response.ok('User information updated successfully');
  } catch (e) {
    return Response.internalServerError(body: 'Error updating user info: $e');
  }
}

Future<Response> handleGetUserInfo(Request request, Database db) async {
  try {
    final userId = request.url.queryParameters['id'];
    if (userId == null) {
      return Response.badRequest(body: 'Missing user ID');
    }

    final result = db.select('''
      SELECT id, name, backup_email
      FROM users
      WHERE id = ?
    ''', [userId]);

    if (result.isEmpty) {
      return Response.notFound('User not found');
    }

    final user = result.first;
    return Response.ok(
      jsonEncode({
        'id': user['id'],
        'name': user['name'],
        'backup_email': user['backup_email'],
      }),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(body: 'Error fetching user info: $e');
  }
}

Future<Response> handleUpdatePassword(Request request, Database db) async {
  try {
    final payload = await request.readAsString();
    final data = jsonDecode(payload);

    final userId = data['id'];
    final oldPassword = data['old_password'];
    final newPassword = data['new_password'];

    if (userId == null || oldPassword == null || newPassword == null) {
      return Response.badRequest(body: 'Missing required fields');
    }

    final result =
        db.select('SELECT password FROM users WHERE id = ?', [userId]);
    if (result.isEmpty) {
      return Response.notFound('User not found');
    }

    final existingPassword = result.first['password'];
    if (existingPassword !=
        sha256.convert(utf8.encode(oldPassword)).toString()) {
      return Response.forbidden('Old password is incorrect');
    }

    final hashedNewPassword =
        sha256.convert(utf8.encode(newPassword)).toString();
    db.execute('''
      UPDATE users
      SET password = ?
      WHERE id = ?
    ''', [hashedNewPassword, userId]);

    return Response.ok('Password updated successfully');
  } catch (e) {
    return Response.internalServerError(body: 'Error updating password: $e');
  }
}
