// Standalone checks: no Gemini key or external API calls needed.
import 'dart:convert';
import 'dart:io';
import '../bin/server.dart' as api;

Future<void> main() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final subscription = server.listen((request) {
    api.handle(request, {
      'GEMINI_API_KEY': request.uri.queryParameters['configured'] == '1'
          ? 'test-only-placeholder'
          : '',
    });
  });
  final client = HttpClient();
  var passed = 0;
  Future<void> check(
    String path,
    int expected, {
    String method = 'GET',
    String? body,
    String? origin,
  }) async {
    final request = await client.openUrl(
      method,
      Uri.parse('http://127.0.0.1:${server.port}$path'),
    );
    if (origin != null) request.headers.set('Origin', origin);
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(body);
    }
    final response = await request.close();
    final text = await response.transform(utf8.decoder).join();
    if (response.statusCode != expected) {
      throw StateError(
        '$path: expected $expected, got ${response.statusCode}: $text',
      );
    }
    if (path == '/health' && jsonDecode(text)['configured'] != false) {
      throw StateError('No-key health status incorrect');
    }
    passed++;
  }

  try {
    await check('/health', 200);
    await check('/unknown', 404);
    await check('/api/chat', 503, method: 'POST', body: '{"consent":true}');
    await check(
      '/api/chat',
      403,
      method: 'POST',
      origin: 'https://untrusted.example',
    );
    await check(
      '/api/chat?configured=1',
      403,
      method: 'POST',
      body: '{"consent":false}',
    );
    await check('/api/chat?configured=1', 400, method: 'POST', body: '[]');
    await check(
      '/api/extract?configured=1',
      400,
      method: 'POST',
      body:
          '{"consent":true,"attachment":{"mimeType":"application/x-executable","data":"AA=="}}',
    );
    await check(
      '/api/chat',
      204,
      method: 'OPTIONS',
      origin: 'http://localhost:5173',
    );
    stdout.writeln(
      '$passed backend checks passed. No external API calls made.',
    );
  } finally {
    client.close(force: true);
    await server.close(force: true);
    await subscription.cancel();
  }
}
