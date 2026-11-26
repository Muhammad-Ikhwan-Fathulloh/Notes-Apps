import '../models/note_model.dart';
import '../models/user_model.dart';

/// Status sinkronisasi sebuah baris lokal terhadap cloud.
enum SyncState {
  synced,
  pending;

  static SyncState fromName(Object? value) =>
      value == pending.name ? pending : synced;
}

/// Jenis operasi tulis catatan yang masih menunggu dikirim ke cloud.
enum PendingOperation { create, update, delete }

/// Satu operasi tulis catatan yang mengantre untuk disinkronkan ke cloud.
class PendingOp {
  const PendingOp({
    this.id,
    required this.userId,
    required this.noteId,
    required this.operation,
    required this.payload,
  });

  final int? id;
  final String userId;

  /// Id lokal catatan (bukan id di cloud).
  final String noteId;
  final PendingOperation operation;
  final Map<String, dynamic> payload;

  static PendingOperation operationFromName(Object? value) {
    for (final op in PendingOperation.values) {
      if (op.name == value) return op;
    }
    return PendingOperation.update;
  }
}

/// Penyimpanan lokal: SQLite di Android/desktop, in-memory di web.
abstract class LocalStore {
  Future<void> init();

  Future<void> close();

  // ---- users ----

  /// Menyimpan atau memperbarui user berdasarkan [UserModel.userId].
  Future<void> saveUser(UserModel user);

  Future<UserModel?> getUserById(String userId);

  /// Pencarian nama tanpa membedakan huruf besar/kecil.
  Future<UserModel?> getUserByName(String name);

  Future<List<UserModel>> listUsers();

  // ---- notes ----

  /// Menyimpan atau memperbarui catatan. [remoteId] diabaikan bila null
  /// sehingga pemetaan id cloud yang sudah ada tidak hilang.
  Future<void> upsertNote(
    NoteItem note, {
    SyncState state = SyncState.synced,
    String? remoteId,
  });

  Future<NoteItem?> getNoteById(String noteId);

  Future<List<NoteItem>> getNotes(String userId);

  Future<void> removeNote(String noteId);

  /// Menandai catatan sebagai tersinkron dan menyimpan id cloud-nya.
  Future<void> markSynced(String noteId, String remoteId);

  Future<String?> remoteIdOf(String noteId);

  Future<SyncState?> syncStateOf(String noteId);

  /// Menimpa seluruh catatan tersinkron milik [userId] dengan data terbaru
  /// dari cloud. Baris yang masih pending tidak pernah dihapus atau ditimpa.
  Future<void> replaceSyncedNotes(String userId, List<NoteItem> remoteNotes);

  // ---- antrian sinkronisasi ----

  Future<void> enqueue(PendingOp op);

  /// Operasi yang menunggu, urut FIFO.
  Future<List<PendingOp>> pendingOps();

  Future<void> dequeue(int id);
}
