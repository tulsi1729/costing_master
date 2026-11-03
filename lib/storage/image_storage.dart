import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

final imageStorageProvider = Provider((ref) => ImageStorage(
      storage: FirebaseStorage.instance,
      picker: ImagePicker(),
    ));

/// Picks photos (downscaled natively, so no Dart-side image codec is needed)
/// and uploads them to Firebase Storage under a unique name.
class ImageStorage {
  final FirebaseStorage _storage;
  final ImagePicker _picker;

  ImageStorage({required FirebaseStorage storage, required ImagePicker picker})
      : _storage = storage,
        _picker = picker;

  Future<File?> pick({required bool fromCamera, double maxWidth = 1600}) async {
    final picked = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: maxWidth,
      imageQuality: 75,
    );
    return picked == null ? null : File(picked.path);
  }

  /// Uploads [file] as `costings/<fileName>.jpg` and returns its download URL.
  ///
  /// Files stay directly under `costings/` (one path segment) so they are
  /// covered by the same storage rules as images uploaded by v1 of the app.
  Future<String> upload(
    File file, {
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    final ref = _storage.ref('costings/$fileName.jpg');
    final task = ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    final subscription = task.snapshotEvents.listen((snapshot) {
      if (snapshot.totalBytes > 0) {
        onProgress?.call(snapshot.bytesTransferred / snapshot.totalBytes);
      }
    });
    try {
      final snapshot = await task;
      return await snapshot.ref.getDownloadURL();
    } finally {
      await subscription.cancel();
    }
  }
}

/// Photos kept on the phone until they are backed up. They are referenced as
/// `local:<file name>` (not a full path, which can change between app
/// updates on iOS) wherever a download URL would otherwise be stored.
abstract final class LocalImages {
  static const _scheme = 'local:';
  static late Directory _dir;

  static Future<void> init() async {
    final docs = await getApplicationDocumentsDirectory();
    _dir = await Directory('${docs.path}/images').create(recursive: true);
  }

  static bool isLocal(String ref) => ref.startsWith(_scheme);

  static File file(String ref) =>
      File('${_dir.path}/${ref.substring(_scheme.length)}');

  /// Copies [source] into app storage and returns its `local:` reference.
  static Future<String> save(File source, String name) async {
    await source.copy('${_dir.path}/$name.jpg');
    return '$_scheme$name.jpg';
  }

  static Future<void> clear() async {
    await _dir.delete(recursive: true);
    await _dir.create();
  }
}
