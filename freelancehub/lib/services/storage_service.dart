import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import '../core/errors/app_exception.dart';
import '../core/firebase/firebase_config.dart';

/// Metadata result returned after a file upload to Firebase Storage.
class StorageUploadResult {
  final String downloadUrl;
  final String storagePath;
  final String fileName;
  final int sizeBytes;
  final String? contentType;

  const StorageUploadResult({
    required this.downloadUrl,
    required this.storagePath,
    required this.fileName,
    required this.sizeBytes,
    this.contentType,
  });
}

/// Dedicated service managing Firebase Storage uploads and downloads for FreelanceHub.
/// Handles profile photos, portfolio items, task attachments, and deliverables.
class StorageService {
  final FirebaseStorage? _injectedStorage;

  StorageService({FirebaseStorage? storage})
      : _injectedStorage = storage;

  static final StorageService instance = StorageService();

  FirebaseStorage get _storage =>
      _injectedStorage ?? FirebaseConfig.instance.storage;

  /// Upload User Profile Photo
  Future<StorageUploadResult> uploadProfilePhoto({
    required String userId,
    required Uint8List bytes,
    required String fileName,
    String contentType = 'image/jpeg',
  }) async {
    final cleanFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path = 'users/$userId/profile/$cleanFileName';
    return _uploadData(
      path: path,
      bytes: bytes,
      fileName: fileName,
      contentType: contentType,
    );
  }

  /// Upload Freelancer Portfolio Image
  Future<StorageUploadResult> uploadPortfolioImage({
    required String userId,
    required Uint8List bytes,
    required String fileName,
    String contentType = 'image/jpeg',
  }) async {
    final cleanFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path = 'freelancers/$userId/portfolio/$cleanFileName';
    return _uploadData(
      path: path,
      bytes: bytes,
      fileName: fileName,
      contentType: contentType,
    );
  }

  /// Upload Task Attachment
  Future<StorageUploadResult> uploadTaskAttachment({
    required String taskId,
    required Uint8List bytes,
    required String fileName,
    String? contentType,
  }) async {
    final cleanFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path = 'tasks/$taskId/attachments/$cleanFileName';
    return _uploadData(
      path: path,
      bytes: bytes,
      fileName: fileName,
      contentType: contentType,
    );
  }

  /// Upload Project Completed Deliverable
  Future<StorageUploadResult> uploadProjectDeliverable({
    required String projectId,
    required Uint8List bytes,
    required String fileName,
    String? contentType,
  }) async {
    final cleanFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'projects/$projectId/deliverables/${timestamp}_$cleanFileName';
    return _uploadData(
      path: path,
      bytes: bytes,
      fileName: fileName,
      contentType: contentType,
    );
  }

  /// Helper uploading raw bytes and obtaining download URL
  Future<StorageUploadResult> _uploadData({
    required String path,
    required Uint8List bytes,
    required String fileName,
    String? contentType,
  }) async {
    try {
      final ref = _storage.ref().child(path);
      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {'originalName': fileName},
      );

      final uploadTask = await ref.putData(bytes, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return StorageUploadResult(
        downloadUrl: downloadUrl,
        storagePath: path,
        fileName: fileName,
        sizeBytes: bytes.length,
        contentType: contentType,
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Delete a file by its storage path
  Future<void> deleteFile(String path) async {
    try {
      await _storage.ref().child(path).delete();
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
