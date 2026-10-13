import 'dart:io';

const Map<String, String> mimeTypes = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.mjs': 'application/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.wasm': 'application/wasm',
  '.css': 'text/css; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.map': 'application/json',
};

void main(List<String> args) async {
  final port = args.isNotEmpty ? int.tryParse(args[0]) ?? 3000 : 3000;
  final webDir = Directory('build/web');

  if (!await webDir.exists()) {
    stderr.writeln('Error: build/web directory does not exist.');
    exit(1);
  }

  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  stdout.writeln('Invoicely AI Web Server listening on http://localhost:$port (0.0.0.0:$port)');

  await for (final request in server) {
    try {
      final reqPath = request.uri.path == '/' ? '/index.html' : request.uri.path;
      var file = File('${webDir.path}$reqPath');

      // SPA fallback to index.html if file does not exist and no extension
      if (!await file.exists()) {
        if (!reqPath.contains('.')) {
          file = File('${webDir.path}/index.html');
        } else {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
          continue;
        }
      }

      final ext = file.path.contains('.') ? '.${file.path.split('.').last.toLowerCase()}' : '';
      final contentType = mimeTypes[ext] ?? 'application/octet-stream';

      // Disallow caching on entry points to ensure latest build updates load immediately
      final isEntryPoint = file.path.endsWith('index.html') ||
          file.path.endsWith('flutter_service_worker.js') ||
          file.path.endsWith('version.json') ||
          file.path.endsWith('main.dart.js');

      request.response.headers.set('Content-Type', contentType);
      request.response.headers.set('Access-Control-Allow-Origin', '*');
      request.response.headers.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
      request.response.headers.set('Access-Control-Allow-Headers', '*');

      if (isEntryPoint) {
        request.response.headers.set('Cache-Control', 'no-cache, no-store, must-revalidate');
        request.response.headers.set('Pragma', 'no-cache');
        request.response.headers.set('Expires', '0');
      } else {
        request.response.headers.set('Cache-Control', 'public, max-age=3600');
      }

      await request.response.addStream(file.openRead());
      await request.response.close();
    } catch (e) {
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        await request.response.close();
      } catch (_) {}
    }
  }
}
