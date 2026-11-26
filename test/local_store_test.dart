import 'package:flutter_test/flutter_test.dart';
import 'package:notes/data/local_store.dart';
import 'package:notes/data/memory_local_store.dart';
import 'package:notes/data/sqlite_local_store.dart';
import 'package:notes/models/note_model.dart';
import 'package:notes/models/user_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

UserModel _user({
  String userId = '1',
  String name = 'tekno',
  String avatar = '-',
  String password = 'tekno1234',
}) {
  return UserModel(
    userId: userId,
    name: name,
    avatar: avatar,
    password: password,
    createdAt: '26-11-2026',
    updatedAt: '26-11-2026',
  );
}

NoteItem _note({
  String id = '1',
  String userId = '1',
  String title = 'judul',
  String description = 'deskripsi',
  int status = 50,
}) {
  return NoteItem(
    id: id,
    userId: userId,
    title: title,
    description: description,
    latitude: '-6.2',
    longitude: '106.8',
    status: status,
    createdAt: '26-11-2026',
    updatedAt: '26-11-2026',
  );
}

void main() {
  group('InMemoryLocalStore', () {
    _runLocalStoreTests(() async => InMemoryLocalStore());
  });

  group('SqliteLocalStore', () {
    setUpAll(sqfliteFfiInit);

    _runLocalStoreTests(
      () async => SqliteLocalStore(
        factory: databaseFactoryFfi,
        path: inMemoryDatabasePath,
      ),
    );
  });
}

void _runLocalStoreTests(Future<LocalStore> Function() create) {
  late LocalStore store;

  setUp(() async {
    store = await create();
    await store.init();
  });

  tearDown(() async {
    await store.close();
  });

  test('menyimpan user lalu membacanya lewat nama dan id', () async {
    await store.saveUser(_user());

    expect((await store.getUserByName('tekno'))?.userId, '1');
    expect((await store.getUserByName('TEKNO'))?.password, 'tekno1234');
    expect((await store.getUserById('1'))?.name, 'tekno');
    expect(await store.getUserByName('tidak-ada'), isNull);
  });

  test('saveUser bersifat upsert (tidak menggandakan baris)', () async {
    await store.saveUser(_user());
    await store.saveUser(_user(password: 'baru1234'));

    final all = await store.listUsers();
    expect(all, hasLength(1));
    expect(all.single.password, 'baru1234');
  });

  test('menyimpan catatan pending lalu membacanya kembali', () async {
    await store.upsertNote(_note(id: 'local-1'), state: SyncState.pending);

    final fetched = await store.getNoteById('local-1');
    expect(fetched?.title, 'judul');
    expect(await store.getNotes('1'), hasLength(1));
    expect(await store.remoteIdOf('local-1'), isNull);
    expect(await store.syncStateOf('local-1'), SyncState.pending);
  });

  test('getNotes hanya mengembalikan catatan milik user terkait', () async {
    await store.upsertNote(_note(id: '1', userId: '1'));
    await store.upsertNote(_note(id: '2', userId: '2'));

    final notes = await store.getNotes('1');
    expect(notes.map((n) => n.id), ['1']);
  });

  test('antrian operasi bersifat FIFO dan bisa dikuras', () async {
    await store.enqueue(
      PendingOp(
        userId: '1',
        noteId: 'local-1',
        operation: PendingOperation.create,
        payload: {'title': 'a'},
      ),
    );
    await store.enqueue(
      PendingOp(
        userId: '1',
        noteId: 'local-1',
        operation: PendingOperation.update,
        payload: {'title': 'b'},
      ),
    );

    final queued = await store.pendingOps();
    expect(queued.map((op) => op.operation), [
      PendingOperation.create,
      PendingOperation.update,
    ]);

    await store.dequeue(queued.first.id!);
    expect((await store.pendingOps()).single.operation,
        PendingOperation.update);
  });

  test('markSynced menyimpan remote id dan menandai baris tersinkron',
      () async {
    await store.upsertNote(_note(id: 'local-1'), state: SyncState.pending);
    await store.markSynced('local-1', '77');

    expect(await store.remoteIdOf('local-1'), '77');
    expect(await store.syncStateOf('local-1'), SyncState.synced);
  });

  test('replaceSyncedNotes menambah, memperbarui, dan menghapus baris',
      () async {
    await store.upsertNote(
      _note(id: 'r1', title: 'lama'),
      state: SyncState.synced,
      remoteId: 'r1',
    );
    await store.upsertNote(
      _note(id: 'r3', title: 'terhapus di cloud'),
      state: SyncState.synced,
      remoteId: 'r3',
    );

    await store.replaceSyncedNotes('1', [
      _note(id: 'r1', title: 'baru'),
      _note(id: 'r9', title: 'tambahan'),
    ]);

    final notes = await store.getNotes('1');
    expect(notes.map((n) => n.id).toList()..sort(), ['r1', 'r9']);
    expect(
      notes.firstWhere((n) => n.id == 'r1').title,
      'baru',
    );
  });

  test('replaceSyncedNotes tidak menghapus catatan yang masih pending',
      () async {
    await store.upsertNote(_note(id: 'local-1'), state: SyncState.pending);

    await store.replaceSyncedNotes('1', const []);

    expect(await store.getNoteById('local-1'), isNotNull);
  });

  test('catatan lokal yang sudah punya remote id dikenali saat tarik cloud',
      () async {
    await store.upsertNote(_note(id: 'local-1'), state: SyncState.pending);
    await store.markSynced('local-1', 'r7');

    await store.replaceSyncedNotes('1', [_note(id: 'r7', title: 'dari cloud')]);

    final notes = await store.getNotes('1');
    expect(notes, hasLength(1));
    expect(notes.single.id, 'local-1');
    expect(notes.single.title, 'dari cloud');
  });
}
