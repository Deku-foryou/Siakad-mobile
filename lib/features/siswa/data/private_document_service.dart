import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../data/keuangan_repository.dart';

/// Menyimpan dokumen privat hasil unduhan ke direktori dokumen aplikasi
/// (BUKAN publik/penyimpanan eksternal terbuka) lalu membukanya dengan
/// viewer bawaan perangkat (open_filex).
class PrivateDocumentService {
  const PrivateDocumentService();

  /// Simpan bytes ke file lokal; mengembalikan path absolut file.
  Future<String> save(DokumenResult dokumen) async {
    final dir = await getApplicationDocumentsDirectory();
    final safeName = _sanitize(dokumen.filename);
    final targetDir = Directory('${dir.path}/dokumen_privat');
    if (!targetDir.existsSync()) {
      await targetDir.create(recursive: true);
    }
    final file = File('${targetDir.path}/$safeName');
    await file.writeAsBytes(dokumen.bytes, flush: true);
    return file.path;
  }

  /// Buka file dengan viewer perangkat. Melempar [FileSystemException]
  /// bila penyimpanan gagal atau [Exception] bila tidak ada aplikasi pembuka.
  Future<bool> open(String path) async {
    final result = await OpenFilex.open(path);
    return result.type == ResultType.done;
  }

  static String _sanitize(String name) {
    final base = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    if (base.isEmpty) return 'dokumen_${DateTime.now().millisecondsSinceEpoch}';
    return base;
  }
}
