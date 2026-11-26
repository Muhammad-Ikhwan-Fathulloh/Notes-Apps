import 'package:flutter_test/flutter_test.dart';
import 'package:notes/data/local_store.dart';
import 'package:notes/data/memory_local_store.dart';
import 'package:notes/data/sync_notes_repository.dart';
import 'package:notes/models/note_model.dart';
import 'package:notes/models/user_model.dart';
import 'package:notes/services/mock_api_service.dart';

NoteItem _note({
  String id = '',
  String title = 'judul',
  String description = 'deskripsi',
}) {
  return NoteItem(
    id: id,
    userId: '1',
    title: title,
    description: description,
    latitude: '-6.2',
    longitude: '106.8',
    status: 50,
    createdAt: '26-11-2026',
    updatedAt: '26-11-2026',
  );
}

UserModel _user({
  String userId = '1',
  String name = 'tekno',
  String password = 'tekno1234',
}) {
  return UserModel(
    userId: userId,
    name: name,
    avatar: '-',
    password: password,
    createdAt: '26-11-2026',
    updatedAt: '26-11-2026',
  );
}

/// Remote palsu: bisa dimatikan untuk mensimulasikan kondisi offline.
class FakeRemoteApi implements NotesApiClient {
  bool online = true;
  final List<UserModel> users = [];
  final Map<String, List<NoteItem>> notes = {};
  int createCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;
  int _nextNoteId = 100;

  void _requireOnline() {
    if (!online) {
      throw const MockApiException('Tidak ada koneksi internet.');
    }
  }

  @override
  Future<UserModel> login({
    required String name,
    required String password,
  }) async {
    _requireOnline();
    for (final user in users) {
      if (user.name == name && user.password == password) return user;
    }
    throw const MockApiException(
      'Nama pengguna atau kata sandi salah.',
      statusCode: 401,
    );
  }

  @override
  Future<UserModel> register({
    required String name,
    required String password,
    required String avatar,
  }) async {
    _requireOnline();
    final user = UserModel(
      userId: '${users.length + 1}',
      name: name,
      avatar: avatar,
      password: password,
      createdAt: '26-11-2026',
      updatedAt: '26-11-2026',
    );
    users.add(user);
    return user;
  }

  @override
  Future<UserModel> getUserById(String userId) async {
    _requireOnline();
    for (final user in users) {
      if (user.userId == userId) return user;
    }
    throw const MockApiException('User tidak ditemukan.', statusCode: 404);
  }

  @override
  Future<List<NoteItem>> getNotes(String userId) async {
    _requireOnline();
    return List.of(notes[userId] ?? const []);
  }

  @override
  Future<NoteItem> getNoteById({
    required String userId,
    required String noteId,
  }) async {
    _requireOnline();
    for (final note in notes[userId] ?? const <NoteItem>[]) {
      if (note.id == noteId) return note;
    }
    throw const MockApiException('Catatan tidak ditemukan.', statusCode: 404);
  }

  @override
  Future<NoteItem> createNote({
    required String userId,
    required NoteItem note,
  }) async {
    _requireOnline();
    createCalls++;
    final created = note.copyWith(id: '${_nextNoteId++}', userId: userId);
    notes.putIfAbsent(userId, () => []).add(created);
    return created;
  }

  @override
  Future<NoteItem> updateNote({
    required String userId,
    required NoteItem note,
  }) async {
    _requireOnline();
    updateCalls++;
    final list = notes.putIfAbsent(userId, () => []);
    final index = list.indexWhere((item) => item.id == note.id);
    if (index < 0) {
      throw const MockApiException('Catatan tidak ditemukan.', statusCode: 404);
    }
    list[index] = note;
    return note;
  }

  @override
  Future<void> deleteNote({
    required String userId,
    required String noteId,
  }) async {
    _requireOnline();
    deleteCalls++;
    notes[userId]?.removeWhere((item) => item.id == noteId);
  }
}

void main() {
  late FakeRemoteApi remote;
  late LocalStore store;
  late SyncNotesRepository repository;

  setUp(() async {
    remote = FakeRemoteApi();
    store = InMemoryLocalStore();
    await store.init();
    repository = SyncNotesRepository(remote: remote, store: store);
  });

  test('login menyimpan user ke cache lokal', () async {
    remote.users.add(_user());

    final user = await repository.login(name: 'tekno', password: 'tekno1234');

    expect(user.userId, '1');
    expect((await store.getUserByName('tekno'))?.password, 'tekno1234');
  });

  test('login saat offline memakai cache lokal', () async {
    remote.users.add(_user());
    await repository.login(name: 'tekno', password: 'tekno1234');

    remote.online = false;
    final user = await repository.login(name: 'tekno', password: 'tekno1234');

    expect(user.userId, '1');
  });

  test('login dengan password salah tetap ditolak walau ada cache', () async {
    remote.users.add(_user());
    await repository.login(name: 'tekno', password: 'tekno1234');

    expect(
      () => repository.login(name: 'tekno', password: 'salah-sekali'),
      throwsA(isA<MockApiException>()),
    );
  });

  test('getNotes menarik data cloud dan menyimpannya ke lokal', () async {
    remote.notes['1'] = [_note(id: 'r1', title: 'dari cloud')];

    final notes = await repository.getNotes('1');

    expect(notes.single.title, 'dari cloud');
    expect((await store.getNotes('1')).single.id, 'r1');
    expect(await store.syncStateOf('r1'), SyncState.synced);
  });

  test('getNotes saat offline memakai data lokal', () async {
    remote.notes['1'] = [_note(id: 'r1', title: 'dari cloud')];
    await repository.getNotes('1');

    remote.online = false;
    final notes = await repository.getNotes('1');

    expect(notes.single.title, 'dari cloud');
  });

  test('createNote saat online langsung mendapat id cloud', () async {
    final created = await repository.createNote(userId: '1', note: _note());

    expect(created.id, isNotEmpty);
    expect(remote.notes['1'], hasLength(1));
    expect(await store.pendingOps(), isEmpty);
    expect(await store.syncStateOf(created.id), SyncState.synced);
  });

  test('createNote saat offline tersimpan lokal dan masuk antrian', () async {
    remote.online = false;

    final created = await repository.createNote(userId: '1', note: _note());

    expect(await store.getNoteById(created.id), isNotNull);
    expect(await store.syncStateOf(created.id), SyncState.pending);
    expect(await store.pendingOps(), hasLength(1));
    expect(remote.notes['1'] ?? const [], isEmpty);
  });

  test('sync mengirim catatan yang dibuat offline ke cloud', () async {
    remote.online = false;
    final created = await repository.createNote(userId: '1', note: _note());

    remote.online = true;
    await repository.sync('1');

    expect(remote.notes['1'], hasLength(1));
    expect(remote.notes['1']!.single.title, 'judul');
    expect(await store.remoteIdOf(created.id), remote.notes['1']!.single.id);
    expect(await store.syncStateOf(created.id), SyncState.synced);
    expect(await store.pendingOps(), isEmpty);
  });

  test('updateNote saat offline tersimpan lokal lalu tersinkron', () async {
    final created = await repository.createNote(userId: '1', note: _note());

    remote.online = false;
    final updated = await repository.updateNote(
      userId: '1',
      note: created.copyWith(title: 'judul baru'),
    );

    expect(updated.title, 'judul baru');
    expect(await store.syncStateOf(created.id), SyncState.pending);

    remote.online = true;
    await repository.sync('1');

    expect(remote.notes['1']!.single.title, 'judul baru');
    expect(await store.syncStateOf(created.id), SyncState.synced);
  });

  test('deleteNote saat offline terhapus lokal lalu tersinkron', () async {
    final created = await repository.createNote(userId: '1', note: _note());

    remote.online = false;
    await repository.deleteNote(userId: '1', noteId: created.id);

    expect(await store.getNoteById(created.id), isNull);

    remote.online = true;
    await repository.sync('1');

    expect(remote.notes['1'] ?? const [], isEmpty);
    expect(remote.deleteCalls, 1);
  });

  test('antrian dikirim berurutan saat kembali online', () async {
    remote.online = false;
    final created = await repository.createNote(userId: '1', note: _note());
    await repository.updateNote(
      userId: '1',
      note: created.copyWith(title: 'judul baru'),
    );

    expect(
      (await store.pendingOps()).map((op) => op.operation),
      [PendingOperation.create, PendingOperation.update],
    );

    remote.online = true;
    await repository.sync('1');

    expect(remote.createCalls, 1);
    expect(remote.updateCalls, 1);
    expect(remote.notes['1']!.single.title, 'judul baru');
  });

  test('getNoteById mengutamakan catatan lokal yang belum tersinkron',
      () async {
    remote.online = false;
    final created = await repository.createNote(userId: '1', note: _note());

    final fetched = await repository.getNoteById(
      userId: '1',
      noteId: created.id,
    );

    expect(fetched.title, 'judul');
  });
}
