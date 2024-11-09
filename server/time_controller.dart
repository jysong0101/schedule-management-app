import 'package:shelf/shelf.dart';

Future<Response> handleTimeRequest(Request request) async {
  // 수정
  final currentTime = DateTime.now().toUtc().toIso8601String();
  return Response.ok('Current UTC time is: $currentTime');
}
