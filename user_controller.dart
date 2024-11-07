import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:sqlite3/sqlite3.dart';

Future<Response> handleAddUserRequest(Request request, Database db) async {
  final payload = await request.readAsString();
  final data = jsonDecode(payload);

  final name = data['name'];
  final age = data['age'];

  if (name == null || age == null) {
    return Response.badRequest(body: 'Missing name or age');
  }

  // 데이터베이스에 사용자 추가
  db.execute('INSERT INTO users (name, age) VALUES (?, ?)', [name, age]);

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
