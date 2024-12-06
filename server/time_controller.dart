import 'package:shelf/shelf.dart';

Future<Response> handleTimeRequest(Request request) async {
  final currentTime = DateTime.now().toUtc().toIso8601String();
  return Response.ok('Current UTC time is: $currentTime');
}
