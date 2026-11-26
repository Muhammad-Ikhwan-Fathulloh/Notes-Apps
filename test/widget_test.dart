import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes/main.dart';
import 'package:notes/models/note_model.dart';
import 'package:notes/models/user_model.dart';
import 'package:notes/services/mock_api_service.dart';

class FakeNotesApiClient implements NotesApiClient {
  final List<UserModel> users = [
    UserModel.fromJson(const {
      'name': 'tekno',
      'avatar': '-',
      'password': 'tekno1234',
      'created_at': '26-11-2026',
      'updated_at': '26-11-2026',
      'user_id': '1',
    }),
  ];

  final List<NoteItem> notes = [
    NoteItem.fromJson(const {
      'id': '1',
      'user_id': '1',
      'title': 'title 1',
      'description': 'description 1',
      'latitude': 'latitude 1',
      'longitude': 'longitude 1',
      'status': 67,
      'created_at': '26-11-2026',
      'updated_at': '26-11-2026',
    }),
  ];

  int _nextNoteId = 2;

  @override
  Future<UserModel> login({
    required String name,
    required String password,
  }) async {
    for (final u in users) {
      if (u.name == name && u.password == password) {
        return u;
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
    if (users.any((u) => u.name.toLowerCase() == name.toLowerCase())) {
      throw const MockApiException('Nama pengguna sudah terdaftar.');
    }
    final user = UserModel(
      userId: '${users.length + 1}',
      name: name,
      avatar: avatar.isEmpty ? '-' : avatar,
      password: password,
      createdAt: '26-11-2026',
      updatedAt: '26-11-2026',
    );
    users.add(user);
    return user;
  }

  @override
  Future<UserModel> getUserById(String userId) async {
    return users.firstWhere(
      (u) => u.userId == userId,
      orElse: () => throw const MockApiException('User tidak ditemukan.'),
    );
  }

  @override
  Future<List<NoteItem>> getNotes(String userId) async {
    return notes.where((n) => n.userId == userId).toList();
  }

  @override
  Future<NoteItem> getNoteById({
    required String userId,
    required String noteId,
  }) async {
    return notes.firstWhere(
      (n) => n.userId == userId && n.id == noteId,
      orElse: () => throw MockApiException('Catatan #$noteId tidak ditemukan.'),
    );
  }

  @override
  Future<NoteItem> createNote({
    required String userId,
    required NoteItem note,
  }) async {
    final created = note.copyWith(id: '${_nextNoteId++}', userId: userId);
    notes.add(created);
    return created;
  }

  @override
  Future<NoteItem> updateNote({
    required String userId,
    required NoteItem note,
  }) async {
    final index = notes.indexWhere(
      (n) => n.userId == userId && n.id == note.id,
    );
    if (index == -1) {
      throw MockApiException('Catatan #${note.id} tidak ditemukan.');
    }
    notes[index] = note;
    return note;
  }

  @override
  Future<void> deleteNote({
    required String userId,
    required String noteId,
  }) async {
    notes.removeWhere((n) => n.userId == userId && n.id == noteId);
  }
}

void main() {
  testWidgets('Auth validation, login, CRUD, Get By ID, and delete flows', (
    WidgetTester tester,
  ) async {
    final api = FakeNotesApiClient();
    await tester.pumpWidget(NoteSnapApp(apiClient: api));

    // Inline validation on empty Auth form
    await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
    await tester.pumpAndSettle();
    expect(find.text('Nama pengguna wajib diisi.'), findsOneWidget);
    expect(find.text('Kata sandi wajib diisi.'), findsOneWidget);

    // Valid login
    await tester.enterText(find.byType(TextFormField).at(0), 'tekno');
    await tester.enterText(find.byType(TextFormField).at(1), 'tekno1234');
    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Masuk'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
    await tester.pumpAndSettle();

    // Notes list loaded from MockAPI /users/1/notes
    expect(find.text('Hai, tekno'), findsOneWidget);
    expect(find.text('NOTE #1'), findsOneWidget);
    expect(find.text('title 1'), findsOneWidget);

    // Empty Get ID validation
    await tester.tap(find.text('Get ID'));
    await tester.pumpAndSettle();
    expect(find.text('Masukkan ID catatan untuk Get By ID.'), findsOneWidget);

    // Valid Get By ID lookup
    await tester.enterText(find.byType(TextField).first, '1');
    await tester.tap(find.text('Get ID'));
    await tester.pumpAndSettle();

    // Note Inspector screen + PUT update
    expect(find.text('Detail Catatan #1'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'title 1 updated');
    await tester.ensureVisible(find.text('Perbarui Catatan'));
    await tester.tap(find.text('Perbarui Catatan'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('title 1 updated'), findsOneWidget);

    // Clear search & Create Note with validation check
    await tester.enterText(find.byType(TextField).first, '');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tambah Catatan'));
    await tester.pumpAndSettle();

    // Trigger Create Note validation errors
    await tester.tap(find.text('Simpan Catatan'));
    await tester.pumpAndSettle();
    expect(find.text('Judul catatan wajib diisi.'), findsOneWidget);
    expect(find.text('Deskripsi catatan wajib diisi.'), findsOneWidget);

    // Fill valid fields including invalid -> valid latitude
    await tester.enterText(find.byType(TextFormField).at(0), 'Catatan MockAPI');
    await tester.enterText(find.byType(TextFormField).at(1), 'Deskripsi baru');
    await tester.enterText(find.byType(TextFormField).at(2), '95');
    await tester.enterText(find.byType(TextFormField).at(3), '106.8456');
    await tester.ensureVisible(find.text('Simpan Catatan'));
    await tester.tap(find.text('Simpan Catatan'));
    await tester.pumpAndSettle();
    expect(find.text('Latitude harus di antara -90 hingga 90.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(2), '-6.2088');
    await tester.ensureVisible(find.text('Simpan Catatan'));
    await tester.tap(find.text('Simpan Catatan'));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('NOTE #2'), findsOneWidget);
    expect(find.text('Catatan MockAPI'), findsOneWidget);

    // Delete Note #2 from Inspector
    await tester.ensureVisible(find.text('Catatan MockAPI'));
    await tester.tap(find.text('Catatan MockAPI'));
    await tester.pumpAndSettle();
    // Tunggu toast simpan menghilang agar tidak menutupi tombol hapus.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Hapus Catatan'));
    await tester.tap(find.text('Hapus Catatan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ya, Hapus'));
    await tester.pumpAndSettle();

    expect(find.text('Catatan MockAPI'), findsNothing);
  });

  testWidgets('Register user flow calls POST /users and loads empty notes', (
    WidgetTester tester,
  ) async {
    final api = FakeNotesApiClient();
    await tester.pumpWidget(NoteSnapApp(apiClient: api));

    await tester.tap(find.text('Daftar'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'budi');
    await tester.enterText(find.byType(TextFormField).at(1), '-');
    await tester.enterText(find.byType(TextFormField).at(2), 'rahasia123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Daftar'));
    await tester.pumpAndSettle();

    expect(find.text('Hai, budi'), findsOneWidget);
    expect(find.text('Belum ada catatan'), findsOneWidget);
  });
}
