import 'package:flutter/material.dart';

class FileItem {
  final String id;
  final String path;
  final String name;
  final int size;
  final bool isDir;
  final DateTime modified;
  final DateTime created;
  final String sign;
  final String thumb;
  final int type;
  final String hashInfoStr;
  final Map<String, String>? hashInfo;

  FileItem({
    required this.id,
    required this.path,
    required this.name,
    required this.size,
    required this.isDir,
    required this.modified,
    required this.created,
    required this.sign,
    required this.thumb,
    required this.type,
    required this.hashInfoStr,
    this.hashInfo,
  });

  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      id: json['id'] ?? '',
      path: json['path'] ?? '',
      name: json['name'] ?? '',
      size: json['size'] ?? 0,
      isDir: json['is_dir'] ?? false,
      modified: DateTime.parse(json['modified'] ?? DateTime.now().toIso8601String()),
      created: DateTime.parse(json['created'] ?? DateTime.now().toIso8601String()),
      sign: json['sign'] ?? '',
      thumb: json['thumb'] ?? '',
      type: json['type'] ?? 0,
      hashInfoStr: json['hashinfo'] ?? '',
      hashInfo: json['hash_info'] != null ? Map<String, String>.from(json['hash_info']) : null,
    );
  }

  String get formattedSize {
    if (isDir) return '';
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  IconData get icon {
    if (isDir) return Icons.folder;
    
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mkv':
      case 'mov':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
      case 'flac':
        return Icons.audio_file;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }
}

class FileListResponse {
  final List<FileItem> content;
  final int total;
  final String readme;
  final String header;
  final bool write;
  final String provider;

  FileListResponse({
    required this.content,
    required this.total,
    required this.readme,
    required this.header,
    required this.write,
    required this.provider,
  });

  factory FileListResponse.fromJson(Map<String, dynamic> json) {
    final contentList = json['content'] as List? ?? [];
    return FileListResponse(
      content: contentList.map((item) => FileItem.fromJson(item)).toList(),
      total: json['total'] ?? 0,
      readme: json['readme'] ?? '',
      header: json['header'] ?? '',
      write: json['write'] ?? false,
      provider: json['provider'] ?? '',
    );
  }
}