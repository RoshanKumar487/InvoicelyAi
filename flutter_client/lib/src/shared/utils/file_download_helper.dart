import 'dart:typed_data';

import 'file_download_helper_io.dart'
    if (dart.library.html) 'file_download_helper_web.dart'
    if (dart.library.js_interop) 'file_download_helper_web.dart' as platform;

class FileDownloadHelper {
  FileDownloadHelper._();

  /// Direct file download/save function.
  /// Saves directly to the user's Downloads directory (or triggers browser download on web)
  /// without opening any share sheet or share options.
  static Future<String> downloadFile({
    required Uint8List bytes,
    required String filename,
    required String mimeType,
    String? subject,
    String? text,
  }) async {
    return await platform.savePlatformFile(bytes, filename, mimeType);
  }

  /// Backward-compatible alias for existing callers.
  static Future<void> downloadOrShare({
    required Uint8List bytes,
    required String filename,
    required String mimeType,
    String? subject,
    String? text,
  }) async {
    await downloadFile(
      bytes: bytes,
      filename: filename,
      mimeType: mimeType,
      subject: subject,
      text: text,
    );
  }
}
