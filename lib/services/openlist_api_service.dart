import 'package:dio/dio.dart';
import '../models/file_item.dart';

class OpenListApiService {
  late Dio _dio;
  String? _token;
  String? _baseUrl;
  
  static final OpenListApiService _instance = OpenListApiService._internal();
  factory OpenListApiService() => _instance;
  OpenListApiService._internal() {
    _dio = Dio();
  }

  void init(String baseUrl) {
    _baseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    _dio.options.baseUrl = _baseUrl!;
    _dio.options.headers['Content-Type'] = 'application/json';
  }

  void setToken(String token) {
    _token = token;
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  Future<bool> login(String username, String password) async {
    try {
      final response = await _dio.post('/api/auth/login', data: {
        'username': username,
        'password': password,
      });
      
      if (response.statusCode == 200 && response.data['code'] == 200) {
        _token = response.data['data']['token'];
        setToken(_token!);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<FileListResponse?> listFiles(String path, {int page = 1, int perPage = 0, bool refresh = false}) async {
    if (_token == null) return null;
    
    try {
      final response = await _dio.post('/api/fs/list', data: {
        'path': path,
        'page': page,
        'per_page': perPage,
        'refresh': refresh,
      });
      
      if (response.statusCode == 200 && response.data['code'] == 200) {
        return FileListResponse.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> createFolder(String path) async {
    if (_token == null) return false;
    
    try {
      final response = await _dio.post('/api/fs/mkdir', data: {
        'path': path,
      });
      
      return response.statusCode == 200 && response.data['code'] == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> rename(String path, String newName) async {
    if (_token == null) return false;
    
    try {
      final response = await _dio.post('/api/fs/rename', data: {
        'path': path,
        'name': newName,
      });
      
      return response.statusCode == 200 && response.data['code'] == 200;
    } catch (e) {
      return false;
    }
  }

  Future<String?> getDownloadUrl(String path) async {
    if (_token == null) return null;
    
    try {
      final response = await _dio.post('/api/fs/get', data: {
        'path': path,
      });
      
      if (response.statusCode == 200 && response.data['code'] == 200) {
        return response.data['data']['raw_url'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}