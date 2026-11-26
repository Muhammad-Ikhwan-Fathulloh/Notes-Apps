import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/note_model.dart';
import '../models/user_model.dart';

class MockApiException implements Exception {
  const MockApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Abstract client for NoteSnap MockAPI Auth, CRUD, and Get-by-ID operations.
abstract class NotesApiClient {
  Future<UserModel> login({
    required String name,
    required String password,
  });

  Future<UserModel> register({
    required String name,
    required String password,
    required String avatar,
  });

  Future<UserModel> getUserById(String userId);

  Future<List<NoteItem>> getNotes(String userId);

  Future<NoteItem> getNoteById({
    required String userId,
    required String noteId,
  });

  Future<NoteItem> createNote({
    required String userId,
    required NoteItem note,
  });

  Future<NoteItem> updateNote({
    required String userId,
    required NoteItem note,
  });

  Future<void> deleteNote({
    required String userId,
    required String noteId,
  });
}

/// Live HTTP implementation backed by https://6b07948d58419b87a4385752.mockapi.io.
class MockApiService implements NotesApiClient {
  MockApiService({
    this.baseUrl = 'https://6b07948d58419b87a4385752.mockapi.io',
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _httpClient;

  static String formatTodayDate() {
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year.toString();
    return '$day-$month-$year';
  }

  @override
  Future<UserModel> login({
    required String name,
    required String password,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || password.isEmpty) {
      throw const MockApiException('Nama pengguna dan kata sandi wajib diisi.');
    }

    final raw = await _requestJson('GET', '$baseUrl/users');
    if (raw is! List) {
      throw const MockApiException('Respons daftar user tidak valid.');
    }

    final users = raw
        .whereType<Map<String, dynamic>>()
        .map(UserModel.fromJson)
        .toList();

    for (final user in users) {
      if (user.name.trim().toLowerCase() == trimmedName.toLowerCase() &&
          user.password == password) {
        return user;
      }
    }

    throw const MockApiException('Nama pengguna atau kata sandi salah.');
  }

  @override
  Future<UserModel> register({
    required String name,
    required String password,
    required String avatar,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.length < 3) {
      throw const MockApiException('Nama pengguna minimal 3 karakter.');
    }
    if (password.length < 6) {
      throw const MockApiException('Kata sandi minimal 6 karakter.');
    }

    final existingRaw = await _requestJson('GET', '$baseUrl/users');
    if (existingRaw is List) {
      final exists = existingRaw
          .whereType<Map<String, dynamic>>()
          .map(UserModel.fromJson)
          .any(
            (u) => u.name.trim().toLowerCase() == trimmedName.toLowerCase(),
          );
      if (exists) {
        throw const MockApiException('Nama pengguna sudah terdaftar.');
      }
    }

    final today = formatTodayDate();
    final raw = await _requestJson(
      'POST',
      '$baseUrl/users',
      body: {
        'name': trimmedName,
        'avatar': avatar.trim().isEmpty ? '-' : avatar.trim(),
        'password': password,
        'created_at': today,
        'updated_at': today,
      },
    );

    if (raw is! Map<String, dynamic>) {
      throw const MockApiException('Gagal membaca data user hasil daftar.');
    }
    return UserModel.fromJson(raw);
  }

  @override
  Future<UserModel> getUserById(String userId) async {
    final safeUserId = _requireId(userId, label: 'User ID');
    final raw = await _requestJson('GET', '$baseUrl/users/$safeUserId');
    if (raw is! Map<String, dynamic>) {
      throw const MockApiException('User tidak ditemukan.');
    }
    return UserModel.fromJson(raw);
  }

  @override
  Future<List<NoteItem>> getNotes(String userId) async {
    final safeUserId = _requireId(userId, label: 'User ID');
    try {
      final raw = await _requestJson('GET', '$baseUrl/users/$safeUserId/notes');
      if (raw is! List) {
        throw const MockApiException('Respons daftar catatan tidak valid.');
      }
      return raw
          .whereType<Map<String, dynamic>>()
          .map(NoteItem.fromJson)
          .toList();
    } on MockApiException catch (e) {
      if (e.statusCode == 404) {
        return const [];
      }
      rethrow;
    }
  }

  @override
  Future<NoteItem> getNoteById({
    required String userId,
    required String noteId,
  }) async {
    final safeUserId = _requireId(userId, label: 'User ID');
    final safeNoteId = _requireId(noteId, label: 'ID Catatan');
    final raw = await _requestJson(
      'GET',
      '$baseUrl/users/$safeUserId/notes/$safeNoteId',
    );
    if (raw is! Map<String, dynamic>) {
      throw MockApiException('Catatan #$noteId tidak ditemukan.');
    }
    return NoteItem.fromJson(raw);
  }

  @override
  Future<NoteItem> createNote({
    required String userId,
    required NoteItem note,
  }) async {
    final safeUserId = _requireId(userId, label: 'User ID');
    if (note.title.trim().isEmpty || note.description.trim().isEmpty) {
      throw const MockApiException('Judul dan deskripsi catatan wajib diisi.');
    }

    final today = formatTodayDate();
    final payload = note
        .copyWith(
          userId: userId,
          status: note.status.clamp(0, 100),
          createdAt: note.createdAt.isEmpty ? today : note.createdAt,
          updatedAt: today,
        )
        .toJson();

    final raw = await _requestJson(
      'POST',
      '$baseUrl/users/$safeUserId/notes',
      body: payload,
    );
    if (raw is! Map<String, dynamic>) {
      throw const MockApiException('Gagal membuat catatan baru.');
    }
    return NoteItem.fromJson(raw);
  }

  @override
  Future<NoteItem> updateNote({
    required String userId,
    required NoteItem note,
  }) async {
    final safeUserId = _requireId(userId, label: 'User ID');
    final safeNoteId = _requireId(note.id, label: 'ID Catatan');
    if (note.title.trim().isEmpty || note.description.trim().isEmpty) {
      throw const MockApiException('Judul dan deskripsi catatan wajib diisi.');
    }

    final today = formatTodayDate();
    final payload = note
        .copyWith(
          userId: userId,
          status: note.status.clamp(0, 100),
          updatedAt: today,
        )
        .toJson();

    final raw = await _requestJson(
      'PUT',
      '$baseUrl/users/$safeUserId/notes/$safeNoteId',
      body: payload,
    );
    if (raw is! Map<String, dynamic>) {
      throw const MockApiException('Gagal memperbarui catatan.');
    }
    return NoteItem.fromJson(raw);
  }

  @override
  Future<void> deleteNote({
    required String userId,
    required String noteId,
  }) async {
    final safeUserId = _requireId(userId, label: 'User ID');
    final safeNoteId = _requireId(noteId, label: 'ID Catatan');
    await _requestJson('DELETE', '$baseUrl/users/$safeUserId/notes/$safeNoteId');
  }

  String _requireId(String value, {required String label}) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw MockApiException('$label tidak boleh kosong.');
    }
    return Uri.encodeComponent(trimmed);
  }

  Future<dynamic> _requestJson(
    String method,
    String url, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse(url);
      final request = http.Request(method, uri);
      request.headers['Accept'] = 'application/json';

      if (body != null) {
        request.headers['Content-Type'] = 'application/json; charset=utf-8';
        request.body = jsonEncode(body);
      }

      final streamed = await _httpClient
          .send(request)
          .timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(
        streamed,
      ).timeout(const Duration(seconds: 15));

      // Decode explicitly as UTF-8 so non-ASCII payloads stay intact on web.
      final responseBody = utf8.decode(response.bodyBytes);

      if (response.statusCode == 404) {
        throw const MockApiException(
          'Data tidak ditemukan (404).',
          statusCode: 404,
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw MockApiException(
          'Permintaan gagal (${response.statusCode}): '
          '${responseBody.isEmpty ? 'Server error' : responseBody}',
          statusCode: response.statusCode,
        );
      }

      if (responseBody.trim().isEmpty) return null;
      return jsonDecode(responseBody);
    } on MockApiException {
      rethrow;
    } on TimeoutException {
      throw const MockApiException(
        'Koneksi ke MockAPI melebihi batas waktu (timeout).',
      );
    } on http.ClientException {
      throw const MockApiException(
        'Tidak ada koneksi internet atau server MockAPI tidak terjangkau.',
      );
    } on FormatException {
      throw const MockApiException(
        'Format respons JSON dari server tidak valid.',
      );
    } catch (e) {
      throw MockApiException('Koneksi ke MockAPI gagal: $e');
    }
  }
}
