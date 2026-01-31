import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

/// Firebase Storage Service
class StorageServiceFirebase {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload profile image
  Future<String?> uploadProfileImage(String uid, File imageFile) async {
    try {
      final extension = path.extension(imageFile.path);
      final ref = _storage.ref().child('users/$uid/profile$extension');

      final uploadTask = await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/${extension.replaceAll('.', '')}'),
      );

      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  /// Upload face image
  Future<String?> uploadFaceImage(
      String uid, String faceId, File imageFile) async {
    try {
      final extension = path.extension(imageFile.path);
      final ref = _storage.ref().child('users/$uid/faces/$faceId$extension');

      final uploadTask = await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/${extension.replaceAll('.', '')}'),
      );

      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  /// Upload OCR image
  Future<String?> uploadOcrImage(
      String uid, String scanId, File imageFile) async {
    try {
      final extension = path.extension(imageFile.path);
      final ref =
          _storage.ref().child('users/$uid/ocr_scans/$scanId$extension');

      final uploadTask = await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/${extension.replaceAll('.', '')}'),
      );

      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  /// Delete file from storage
  Future<void> deleteFile(String filePath) async {
    try {
      await _storage.ref().child(filePath).delete();
    } catch (e) {
      // File may not exist
    }
  }

  /// Delete profile image
  Future<void> deleteProfileImage(String uid) async {
    try {
      // Try common extensions
      for (final ext in ['.jpg', '.jpeg', '.png']) {
        try {
          await _storage.ref().child('users/$uid/profile$ext').delete();
          break;
        } catch (_) {}
      }
    } catch (e) {
      // Ignore
    }
  }

  /// Get download URL for a file
  Future<String?> getDownloadUrl(String filePath) async {
    try {
      return await _storage.ref().child(filePath).getDownloadURL();
    } catch (e) {
      return null;
    }
  }
}
