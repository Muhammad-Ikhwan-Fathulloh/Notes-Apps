import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/note_model.dart';
import '../models/user_model.dart';
import 'local_store.dart';

/// Penyimpanan lokal berbasis SQLite untuk Android dan desktop.
class SqliteLocalStore implements LocalStore {
  SqliteLocalStore({this.factory, this.path});

  static const String _fileName = 'notesnap.db';

  /// Factory SQLite khusus (desktop/pengujian); null berarti sqflite bawaan.
  final DatabaseFactory? factory;

  /// Lokasi berkas database; null berarti direktori database default.
  final String? path;

  Database? _db;

  Database get _database {
    final db = _db;
    if (db == null) {
      throw StateError('SqliteLocalStore belum diinisialisasi (panggil init).');
    }
    return db;
  }

  @override
  Future<void> init() async {
    if (_db != null) return;
    final resolvedFactory = factory ?? databaseFactory;
    final resolvedPath = path ??
        p.join(await resolvedFactory.getDatabasesPath(), _fileName);
    _db = await resolvedFactory.openDatabase(
      resolvedPath,
      options: OpenDatabaseOptions(version: 1, onCreate: _onCreate),
    );
  }

  @override
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        user_id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        avatar TEXT,
        password TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        remote_id TEXT,
        user_id TEXT NOT NULL,
        title TEXT,
        description TEXT,
        latitude TEXT,
        longitude TEXT,
        status INTEGER,
        created_at TEXT,
        updated_at TEXT,
        sync_state TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE pending_ops (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        note_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload TEXT NOT NULL
      )
    ''');
  }

  // ---- users ----

  @override
  Future<void> saveUser(UserModel user) async {
    final values = {
      'user_id': user.userId,
      'name': user.name,
      'avatar': user.avatar,
      'password': user.password,
      'created_at': user.createdAt,
      'updated_at': user.updatedAt,
    };
    final updated = await _database.update(
      'users',
      values,
      where: 'user_id = ?',
      whereArgs: [user.userId],
    );
    if (updated == 0) {
      await _database.insert('users', values);
    }
  }

  @override
  Future<UserModel?> getUserById(String userId) async {
    final rows = await _database.query(
      'users',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    return rows.isEmpty ? null : UserModel.fromJson(rows.first);
  }

  @override
  Future<UserModel?> getUserByName(String name) async {
    final rows = await _database.query(
      'users',
      where: 'lower(name) = lower(?)',
      whereArgs: [name.trim()],
      limit: 1,
    );
    return rows.isEmpty ? null : UserModel.fromJson(rows.first);
  }

  @override
  Future<List<UserModel>> listUsers() async {
    final rows = await _database.query('users');
    return rows.map(UserModel.fromJson).toList();
  }

  // ---- notes ----

  @override
  Future<void> upsertNote(
    NoteItem note, {
    SyncState state = SyncState.synced,
    String? remoteId,
  }) async {
    final db = _database;
    final existing = await db.query(
      'notes',
      columns: ['remote_id'],
      where: 'id = ?',
      whereArgs: [note.id],
      limit: 1,
    );
    final values = _noteValues(note)
      ..['remote_id'] =
          remoteId ?? (existing.isEmpty ? null : existing.first['remote_id'])
      ..['sync_state'] = state.name;

    if (existing.isEmpty) {
      await db.insert('notes', values);
    } else {
      await db.update('notes', values, where: 'id = ?', whereArgs: [note.id]);
    }
  }

  @override
  Future<NoteItem?> getNoteById(String noteId) async {
    final rows = await _database.query(
      'notes',
      where: 'id = ?',
      whereArgs: [noteId],
      limit: 1,
    );
    return rows.isEmpty ? null : NoteItem.fromJson(rows.first);
  }

  @override
  Future<List<NoteItem>> getNotes(String userId) async {
    final rows = await _database.query(
      'notes',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'rowid ASC',
    );
    return rows.map(NoteItem.fromJson).toList();
  }

  @override
  Future<void> removeNote(String noteId) async {
    await _database.delete('notes', where: 'id = ?', whereArgs: [noteId]);
  }

  @override
  Future<void> markSynced(String noteId, String remoteId) async {
    await _database.update(
      'notes',
      {'remote_id': remoteId, 'sync_state': SyncState.synced.name},
      where: 'id = ?',
      whereArgs: [noteId],
    );
  }

  @override
  Future<String?> remoteIdOf(String noteId) async {
    final rows = await _database.query(
      'notes',
      columns: ['remote_id'],
      where: 'id = ?',
      whereArgs: [noteId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['remote_id'] as String?;
  }

  @override
  Future<SyncState?> syncStateOf(String noteId) async {
    final rows = await _database.query(
      'notes',
      columns: ['sync_state'],
      where: 'id = ?',
      whereArgs: [noteId],
      limit: 1,
    );
    return rows.isEmpty ? null : SyncState.fromName(rows.first['sync_state']);
  }

  @override
  Future<void> replaceSyncedNotes(
    String userId,
    List<NoteItem> remoteNotes,
  ) async {
    await _database.transaction((txn) async {
      final keptRemoteIds = <String>[];

      for (final note in remoteNotes) {
        final existing = await txn.query(
          'notes',
          columns: ['id', 'sync_state'],
          where: 'remote_id = ? OR id = ?',
          whereArgs: [note.id, note.id],
          limit: 1,
        );

        if (existing.isEmpty) {
          final values = _noteValues(note)
            ..['remote_id'] = note.id
            ..['sync_state'] = SyncState.synced.name;
          await txn.insert('notes', values);
          keptRemoteIds.add(note.id);
          continue;
        }

        keptRemoteIds.add(note.id);
        final localId = existing.first['id'] as String;
        // Jangan timpa perubahan lokal yang belum tersinkron.
        if (SyncState.fromName(existing.first['sync_state']) ==
            SyncState.pending) {
          continue;
        }

        // Id lokal dipertahankan agar id cloud tidak menggantikan identitas
        // baris yang sudah dipakai antrean dan layar.
        final values = _noteValues(note.copyWith(id: localId))
          ..['remote_id'] = note.id
          ..['sync_state'] = SyncState.synced.name;
        await txn.update('notes', values, where: 'id = ?', whereArgs: [localId]);
      }

      if (keptRemoteIds.isEmpty) {
        await txn.delete(
          'notes',
          where: 'user_id = ? AND sync_state = ?',
          whereArgs: [userId, SyncState.synced.name],
        );
      } else {
        final placeholders = List.filled(keptRemoteIds.length, '?').join(', ');
        await txn.delete(
          'notes',
          where: 'user_id = ? AND sync_state = ? '
              'AND COALESCE(remote_id, id) NOT IN ($placeholders)',
          whereArgs: [userId, SyncState.synced.name, ...keptRemoteIds],
        );
      }
    });
  }

  // ---- antrian sinkronisasi ----

  @override
  Future<void> enqueue(PendingOp op) async {
    await _database.insert('pending_ops', {
      'user_id': op.userId,
      'note_id': op.noteId,
      'operation': op.operation.name,
      'payload': jsonEncode(op.payload),
    });
  }

  @override
  Future<List<PendingOp>> pendingOps() async {
    final rows = await _database.query('pending_ops', orderBy: 'id ASC');
    return rows.map((row) {
      return PendingOp(
        id: row['id'] as int?,
        userId: (row['user_id'] ?? '').toString(),
        noteId: (row['note_id'] ?? '').toString(),
        operation: PendingOp.operationFromName(row['operation']),
        payload: _decodePayload(row['payload']),
      );
    }).toList();
  }

  @override
  Future<void> dequeue(int id) async {
    await _database.delete('pending_ops', where: 'id = ?', whereArgs: [id]);
  }

  Map<String, dynamic> _noteValues(NoteItem note) => {
        'id': note.id,
        'user_id': note.userId,
        'title': note.title,
        'description': note.description,
        'latitude': note.latitude,
        'longitude': note.longitude,
        'status': note.status,
        'created_at': note.createdAt,
        'updated_at': note.updatedAt,
      };

  Map<String, dynamic> _decodePayload(Object? raw) {
    if (raw is! String || raw.trim().isEmpty) return const {};
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : const {};
  }
}
