// Small local-only release preview server. Run from the project root.
import 'dart:io';

Future<void> main() async {
  final root = Directory('build/web').absolute;
  if (!root.existsSync()) {
    stderr.writeln('Run flutter build web first.');
    exitCode = 1;
    return;
  }
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 5180);
  stdout.writeln('FINPATH release preview: http://127.0.0.1:5180');
  const mime = {
    'html': 'text/html',
    'js': 'application/javascript',
    'css': 'text/css',
    'json': 'application/json',
    'wasm': 'application/wasm',
    'png': 'image/png',
    'ttf': 'font/ttf',
    'otf': 'font/otf',
    'svg': 'image/svg+xml',
  };
  await for (final request in server) {
    try {
      if (request.uri.pathSegments.any((p) => p == '..' || p.contains('\\'))) {
        request.response.statusCode = 400;
        await request.response.close();
        continue;
      }
      final relative = request.uri.path == '/'
          ? 'index.html'
          : request.uri.pathSegments.join('/');
      final file = File('${root.path}/$relative');
      if (!await file.exists()) {
        request.response.statusCode = 404;
      } else {
        request.response.headers.set(
          'Content-Type',
          mime[relative.split('.').last] ?? 'application/octet-stream',
        );
        request.response.headers.set('Cache-Control', 'no-store');
        await request.response.addStream(file.openRead());
      }
    } catch (_) {
      request.response.statusCode = 500;
    }
    await request.response.close();
  }
}
