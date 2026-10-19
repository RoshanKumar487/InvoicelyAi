import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

Future<String> savePlatformFile(
  Uint8List bytes,
  String filename,
  String mimeType,
) async {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename
    ..style.display = 'none';

  final body = web.document.body;
  if (body != null) {
    body.appendChild(anchor);
    anchor.click();
    anchor.remove();
  } else {
    anchor.click();
  }

  web.window.setTimeout(
    (() {
      web.URL.revokeObjectURL(url);
    }).toJS,
    3000.toJS,
  );
  return filename;
}
