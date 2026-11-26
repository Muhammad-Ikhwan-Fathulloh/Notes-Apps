import '../models/note_model.dart';
import '../models/user_model.dart';
import 'local_store.dart';

/// Penyimpanan lokal berbasis memori, dipakai di web (data bertahan selama
/// sesi berjalan saja) dan sebagai alat bantu pengujian.
class InMemoryLocalStore implements LocalStore {
  final Map<String, UserModel> _users = {};
  final Map<String, _LocalNote> _notes = {};
  final List<PendingOp> _queue = [];
  int _nextOpId = 1;

  @override
  Future<void> init() async {}

  @override
  Future<void> close() async {
    _users.clear();
    _notes.clear();
    _queue.clear();
  }

  @override
  Future<void> saveUser(UserModel user) async {
    _users[user.userId] = user;
  }

  @override
  Future<UserModel?> getUserById(String userId) async => _users[userId];

  @override
  Future<UserModel?> getUserByName(String name) async {
    final target = name.trim().toLowerCase();
    for (final user in _users.values) {
      if (user.name.trim().toLowerCase() == target) return user;
    }
    return null;
  }

  @override
  Future<List<UserModel>> listUsers() async => _users.values.toList();

  @override
  Future<void> upsertNote(
    NoteItem note, {
    SyncState state = SyncState.synced,
    String? remoteId,
  }) async {
    final existing = _notes[note.id];
    _notes[note.id] = _LocalNote(
      note: note,
      state: state,
      remoteId: remoteId ?? existing?.remoteId,
    );
  }

  @override
  Future<NoteItem?> getNoteById(String noteId) async => _notes[noteId]?.note;

  @override
  Future<List<NoteItem>> getNotes(String userId) async => _notes.values
      .where((entry) => entry.note.userId == userId)
      .map((entry) => entry.note)
      .toList();

  @override
  Future<void> removeNote(String noteId) async {
    _notes.remove(noteId);
  }

  @override
  Future<void> markSynced(String noteId, String remoteId) async {
    final existing = _notes[noteId];
    if (existing == null) return;
    _notes[noteId] = _LocalNote(
      note: existing.note,
      state: SyncState.synced,
      remoteId: remoteId,
    );
  }

  @override
  Future<String?> remoteIdOf(String noteId) async => _notes[noteId]?.remoteId;

  @override
  Future<SyncState?> syncStateOf(String noteId) async =>
      _notes[noteId]?.state;

  @override
  Future<void> replaceSyncedNotes(
    String userId,
    List<NoteItem> remoteNotes,
  ) async {
    final keptRemoteIds = <String>{};

    for (final note in remoteNotes) {
      final matchKey = _findKey(note.id);
      if (matchKey == null) {
        _notes[note.id] =
            _LocalNote(note: note, state: SyncState.synced, remoteId: note.id);
        keptRemoteIds.add(note.id);
        continue;
      }

      final existing = _notes[matchKey]!;
      keptRemoteIds.add(note.id);
      // Jangan timpa perubahan lokal yang belum tersinkron.
      if (existing.state == SyncState.pending) continue;

      _notes[matchKey] = _LocalNote(
        note: note.copyWith(id: matchKey),
        state: SyncState.synced,
        remoteId: note.id,
      );
    }

    _notes.removeWhere(
      (key, entry) =>
          entry.note.userId == userId &&
          entry.state == SyncState.synced &&
          !keptRemoteIds.contains(entry.remoteId ?? entry.note.id),
    );
  }

  @override
  Future<void> enqueue(PendingOp op) async {
    _queue.add(
      PendingOp(
        id: _nextOpId++,
        userId: op.userId,
        noteId: op.noteId,
        operation: op.operation,
        payload: op.payload,
      ),
    );
  }

  @override
  Future<List<PendingOp>> pendingOps() async => List.of(_queue);

  @override
  Future<void> dequeue(int id) async {
    _queue.removeWhere((op) => op.id == id);
  }

  /// Mencari id lokal baris yang mewakili [noteId] (id cloud) atau id lokal.
  String? _findKey(String noteId) {
    if (_notes.containsKey(noteId)) return noteId;
    for (final entry in _notes.entries) {
      if (entry.value.remoteId == noteId) return entry.key;
    }
    return null;
  }
}

class _LocalNote {
  const _LocalNote({
    required this.note,
    required this.state,
    this.remoteId,
  });

  final NoteItem note;
  final SyncState state;
  final String? remoteId;
}
