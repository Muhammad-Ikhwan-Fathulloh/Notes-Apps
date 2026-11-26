import '../models/note_model.dart';
import '../models/user_model.dart';
import '../services/mock_api_service.dart';
import 'local_store.dart';

/// Jembatan antara cloud (MockAPI) dan penyimpanan lokal SQLite.
///
/// Pola "offline-first": setiap perubahan ditulis ke lokal lebih dulu lalu
/// dimasukkan ke antrian [PendingOp]. Saat jaringan tersedia, antrean dikirim
/// ke cloud secara berurutan (FIFO), kemudian data terbaru ditarik kembali.
class SyncNotesRepository implements NotesApiClient {
  SyncNotesRepository({required this.remote, required this.store});

  /// Sumber data cloud (MockAPI).
  final NotesApiClient remote;

  /// Penyimpanan lokal (SQLite / in-memory).
  final LocalStore store;

  int _localIdCounter = 0;

  String _newLocalId() {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    return 'local-$stamp-${_localIdCounter++}';
  }

  // ---- autentikasi ----

  @override
  Future<UserModel> login({
    required String name,
    required String password,
  }) async {
    try {
      final user = await remote.login(name: name, password: password);
      await store.saveUser(user);
      return user;
    } on MockApiException catch (e) {
      // Server menjawab (mis. kata sandi salah) → jangan pakai cache.
      if (e.statusCode != null) rethrow;

      final cached = await store.getUserByName(name);
      if (cached != null && cached.password == password) return cached;
      rethrow;
    }
  }

  @override
  Future<UserModel> register({
    required String name,
    required String password,
    required String avatar,
  }) async {
    // Pendaftaran butuh jaringan karena id user ditentukan oleh cloud.
    final user = await remote.register(
      name: name,
      password: password,
      avatar: avatar,
    );
    await store.saveUser(user);
    return user;
  }

  @override
  Future<UserModel> getUserById(String userId) async {
    try {
      final user = await remote.getUserById(userId);
      await store.saveUser(user);
      return user;
    } on MockApiException catch (e) {
      if (e.statusCode != null) rethrow;
      final cached = await store.getUserById(userId);
      if (cached != null) return cached;
      rethrow;
    }
  }

  // ---- catatan ----

  @override
  Future<List<NoteItem>> getNotes(String userId) async {
    try {
      await sync(userId);
    } on MockApiException {
      final cached = await store.getNotes(userId);
      if (cached.isEmpty) rethrow;
      return cached;
    }
    return store.getNotes(userId);
  }

  @override
  Future<NoteItem> getNoteById({
    required String userId,
    required String noteId,
  }) async {
    final local = await store.getNoteById(noteId);
    final state = await store.syncStateOf(noteId);

    // Catatan yang belum pernah terkirim ke cloud hanya ada di lokal.
    if (local != null && state == SyncState.pending) return local;

    try {
      final fresh = await remote.getNoteById(userId: userId, noteId: noteId);
      await store.upsertNote(fresh, remoteId: fresh.id);
      return fresh;
    } on MockApiException {
      if (local != null) return local;
      rethrow;
    }
  }

  @override
  Future<NoteItem> createNote({
    required String userId,
    required NoteItem note,
  }) async {
    final localId = note.id.trim().isEmpty ? _newLocalId() : note.id;
    final local = note.copyWith(id: localId, userId: userId);

    await store.upsertNote(local, state: SyncState.pending);
    await store.enqueue(
      PendingOp(
        userId: userId,
        noteId: localId,
        operation: PendingOperation.create,
        payload: local.toJson(),
      ),
    );

    await _flushPending(userId);
    return await store.getNoteById(localId) ?? local;
  }

  @override
  Future<NoteItem> updateNote({
    required String userId,
    required NoteItem note,
  }) async {
    final local = note.copyWith(userId: userId);

    await store.upsertNote(local, state: SyncState.pending);
    await store.enqueue(
      PendingOp(
        userId: userId,
        noteId: local.id,
        operation: PendingOperation.update,
        payload: local.toJson(),
      ),
    );

    await _flushPending(userId);
    return await store.getNoteById(local.id) ?? local;
  }

  @override
  Future<void> deleteNote({
    required String userId,
    required String noteId,
  }) async {
    // Id cloud dibaca sebelum baris lokal dihapus, agar penghapusan di cloud
    // tetap bisa dikirim saat perangkat sedang offline.
    final remoteId = await store.remoteIdOf(noteId);
    await store.removeNote(noteId);

    final payload = <String, dynamic>{};
    if (remoteId != null) payload['remote_id'] = remoteId;

    await store.enqueue(
      PendingOp(
        userId: userId,
        noteId: noteId,
        operation: PendingOperation.delete,
        payload: payload,
      ),
    );

    await _flushPending(userId);
  }

  /// Mengirim antrean lokal ke cloud lalu menarik data terbaru.
  ///
  /// Melempar [MockApiException] bila cloud tidak terjangkau.
  Future<void> sync(String userId) async {
    await _flushPending(userId);
    final remoteNotes = await remote.getNotes(userId);
    await store.replaceSyncedNotes(userId, remoteNotes);
  }

  /// Mengirim operasi yang mengantre secara berurutan. Berhenti pada kegagalan
  /// pertama (mis. offline) agar urutan create → update → delete tetap utuh.
  Future<void> _flushPending(String userId) async {
    for (final op in await store.pendingOps()) {
      if (op.userId != userId) continue;
      try {
        await _push(op);
      } on MockApiException {
        return;
      }
      if (op.id != null) await store.dequeue(op.id!);
    }
  }

  Future<void> _push(PendingOp op) async {
    if (op.operation == PendingOperation.delete) {
      final remoteId = op.payload['remote_id'] as String?;
      if (remoteId != null) {
        try {
          await remote.deleteNote(userId: op.userId, noteId: remoteId);
        } on MockApiException catch (e) {
          // 404 berarti catatan sudah tidak ada di cloud.
          if (e.statusCode != 404) rethrow;
        }
      }
      return;
    }

    // Baris lokal terkini dipakai sebagai sumber data, sehingga perubahan
    // terbaru selalu ikut terkirim walau operasinya dibuat sebelumnya.
    final local = await store.getNoteById(op.noteId);
    if (local == null) return;

    final remoteId = await store.remoteIdOf(op.noteId);
    if (remoteId == null) {
      final created = await remote.createNote(userId: op.userId, note: local);
      await store.upsertNote(
        created.copyWith(id: op.noteId),
        remoteId: created.id,
      );
    } else {
      final updated = await remote.updateNote(
        userId: op.userId,
        note: local.copyWith(id: remoteId),
      );
      await store.upsertNote(
        updated.copyWith(id: op.noteId),
        remoteId: remoteId,
      );
    }
  }
}
