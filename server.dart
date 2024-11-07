import 'dart:async'; // 추가
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'time_controller.dart';

void main() async {
  // 요청 핸들러 생성
  var handler =
      const Pipeline().addMiddleware(logRequests()).addHandler(_router);

  // 서버 실행
  var server = await io.serve(handler, InternetAddress.anyIPv4, 8080);
  print('Server listening on port ${server.port}');
}

// 라우팅 설정
FutureOr<Response> _router(Request request) {
  // 수정
  if (request.url.path == 'time') {
    return handleTimeRequest(request);
  }
  return Response.notFound('Not Found');
}
