import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'api_client.dart';

/// Cloud storage service for Google Drive backend integration
/// Handles file upload, download, list, and delete operations
class CloudStorageService {
  final ApiClient _apiClient;
  static const String baseUrl = 'http://localhost:3000';

  CloudStorageService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Upload a single file to a project
  Future<CloudFile> uploadFile({
    required String projectId,
    required String fileName,
    required Uint8List fileBytes,
  }) async {
    final uri = Uri.parse('$baseUrl/storage/projects/$projectId/files');
    final token = await _apiClient.getToken();

    if (token == null) {
      throw Exception('No authentication token found');
    }

    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 201) {
      throw Exception('Upload failed: ${response.body}');
    }

    final data = json.decode(response.body);
    return CloudFile.fromJson(data['file']);
  }

  /// List all files in a project
  Future<List<CloudFile>> listFiles(String projectId) async {
    final response = await _apiClient.get('/storage/projects/$projectId/files');

    if (response == null) {
      return [];
    }

    final files = (response['files'] as List)
        .map((f) => CloudFile.fromJson(f))
        .toList();

    return files;
  }

  /// Download a file by its ID
  Future<Uint8List> downloadFile(String fileId) async {
    final token = await _apiClient.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/storage/files/$fileId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Download failed: ${response.body}');
    }

    return response.bodyBytes;
  }

  /// Delete a file by its ID
  Future<void> deleteFile(String fileId) async {
    await _apiClient.delete('/storage/files/$fileId');
  }

  /// Create a backup of the entire project
  Future<CloudFile> exportBackup(String projectId) async {
    final response = await _apiClient.post(
      '/storage/projects/$projectId/backup',
      {},
    );

    if (response == null || response['backup'] == null) {
      throw Exception('Backup failed');
    }

    return CloudFile.fromJson(response['backup']);
  }

  /// Upload chapter content as a file
  Future<CloudFile> uploadChapter({
    required String projectId,
    required String chapterId,
    required String title,
    required String content,
  }) async {
    final fileName = 'chapter_$chapterId.txt';
    final fileBytes = Uint8List.fromList(utf8.encode(content));

    return uploadFile(
      projectId: projectId,
      fileName: fileName,
      fileBytes: fileBytes,
    );
  }

  /// Download chapter content
  Future<String> downloadChapter(String fileId) async {
    final bytes = await downloadFile(fileId);
    return utf8.decode(bytes);
  }
}

/// Model for cloud-stored file
class CloudFile {
  final String id;
  final String fileId;
  final String fileName;
  final String mimeType;
  final int fileSize;
  final String webViewLink;
  final DateTime createdAt;
  final DateTime updatedAt;

  CloudFile({
    required this.id,
    required this.fileId,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
    required this.webViewLink,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CloudFile.fromJson(Map<String, dynamic> json) {
    return CloudFile(
      id: json['id'] ?? json['fileId'] ?? '',
      fileId: json['file_id'] ?? json['fileId'] ?? '',
      fileName: json['file_name'] ?? json['fileName'] ?? '',
      mimeType: json['mime_type'] ?? json['mimeType'] ?? '',
      fileSize: json['file_size'] ?? json['size'] ?? 0,
      webViewLink: json['web_view_link'] ?? json['webViewLink'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : (json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now()),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : (json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'])
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileId': fileId,
      'fileName': fileName,
      'mimeType': mimeType,
      'fileSize': fileSize,
      'webViewLink': webViewLink,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
