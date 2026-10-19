import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

Future<String> savePlatformFile(
  Uint8List bytes,
  String filename,
  String mimeType,
) async {
  Directory? targetDir;
  try {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      targetDir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    } else if (Platform.isAndroid) {
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (await downloadDir.exists()) {
        targetDir = downloadDir;
      } else {
        targetDir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      }
    } else {
      targetDir = await getApplicationDocumentsDirectory();
    }
  } catch (_) {
    targetDir = await getApplicationDocumentsDirectory();
  }

  final targetFile = File('${targetDir.path}${Platform.pathSeparator}$filename');
  await targetFile.writeAsBytes(bytes, flush: true);
  return targetFile.path;
}
