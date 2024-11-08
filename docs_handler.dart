import 'package:shelf/shelf.dart';

Response handleDocsRequest(Request request) {
  const documentation = '''
  <!DOCTYPE html>
  <html>
  <head>
    <title>API Documentation</title>
    <style>
      body { font-family: Arial, sans-serif; }
      h1 { color: #333; }
      .endpoint { margin-bottom: 20px; }
      .endpoint h2 { color: #555; }
      pre { background-color: #f4f4f4; padding: 10px; }
    </style>
  </head>
  <body>
    <h1>API Documentation</h1>
    <div class="endpoint">
      <h2>GET /time</h2>
      <p>Returns the current UTC time.</p>
    </div>
    <div class="endpoint">
      <h2>POST /user</h2>
      <p>Adds a new user.</p>
      <pre>
Request Body:
{
  "name": "string",
  "age": "integer"
}
      </pre>
    </div>
    <div class="endpoint">
      <h2>POST /schedule</h2>
      <p>Adds a new schedule.</p>
      <pre>
Request Body:
{
  "name": "string",
  "start_date": "string (YYYY-MM-DD)",
  "end_date": "string (YYYY-MM-DD)",
  "details": "string",
  "completed": "boolean"
}
      </pre>
    </div>
    <div class="endpoint">
      <h2>PATCH /schedule/{id}/toggle</h2>
      <p>Toggles the completion status of a schedule by its ID.</p>
    </div>
    <div class="endpoint">
      <h2>GET /schedule?date={YYYY-MM-DD}</h2>
      <p>Returns schedules for a specific date range. The date parameter should be in the format YYYY-MM-DD.</p>
      <pre>
Query Parameter:
{
  "date": "string (YYYY-MM-DD)"
}
      </pre>
    </div>
    <div class="endpoint">
      <h2>GET /priorities?x={number}</h2>
      <p>Returns schedules that have an end date within x days from today.</p>
      <pre>
Query Parameter:
{
  "x": "integer"
}
      </pre>
    </div>
    <div class="endpoint">
      <h2>GET /fortest/all-schedules</h2>
      <p>Returns all registered schedules (for testing purposes).</p>
    </div>
  </body>
  </html>
  ''';

  return Response.ok(documentation, headers: {'Content-Type': 'text/html'});
}
