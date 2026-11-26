import 'package:flutter/material.dart';
import 'data/local_store_factory.dart';
import 'data/sync_notes_repository.dart';
import 'models/note_model.dart';
import 'models/user_model.dart';
import 'screens/auth_screen.dart';
import 'screens/create_note_screen.dart';
import 'screens/note_inspector_screen.dart';
import 'screens/notes_list_screen.dart';
import 'screens/sensor_screen.dart';
import 'services/mock_api_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Penyimpanan lokal (SQLite di Android/desktop, in-memory di web).
  final store = await createLocalStore();
  await store.init();

  runApp(
    NoteSnapApp(
      apiClient: SyncNotesRepository(remote: MockApiService(), store: store),
    ),
  );
}

class NoteSnapApp extends StatelessWidget {
  const NoteSnapApp({super.key, required this.apiClient, this.initialUser});

  final NotesApiClient apiClient;
  final UserModel? initialUser;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NoteSnap',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: _NoteSnapRootShell(apiClient: apiClient, initialUser: initialUser),
    );
  }
}

class _NoteSnapRootShell extends StatefulWidget {
  const _NoteSnapRootShell({
    required this.apiClient,
    required this.initialUser,
  });

  final NotesApiClient apiClient;
  final UserModel? initialUser;

  @override
  State<_NoteSnapRootShell> createState() => _NoteSnapRootShellState();
}

class _NoteSnapRootShellState extends State<_NoteSnapRootShell> {
  UserModel? _currentUser;
  List<NoteItem> _notes = const [];
  bool _isLoadingNotes = false;
  String? _notesError;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.initialUser;
    if (_currentUser != null) {
      _isLoadingNotes = true;
      _loadNotes(notifyBeforeFetch: false);
    }
  }

  Future<void> _loadNotes({bool notifyBeforeFetch = true}) async {
    final user = _currentUser;
    if (user == null) return;

    if (notifyBeforeFetch) {
      setState(() {
        _isLoadingNotes = true;
        _notesError = null;
      });
    }

    try {
      final fetched = await widget.apiClient.getNotes(user.userId);
      if (!mounted) return;
      setState(() {
        _notes = fetched;
      });
    } on MockApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _notesError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _notesError = 'Gagal memuat catatan: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingNotes = false;
        });
      }
    }
  }

  void _handleAuthenticated(UserModel user) {
    setState(() {
      _currentUser = user;
      _notes = const [];
      _notesError = null;
    });
    _loadNotes();
  }

  void _handleSignOut() {
    setState(() {
      _currentUser = null;
      _notes = const [];
      _notesError = null;
    });
  }

  Future<void> _openNoteById(BuildContext context, String noteId) async {
    final user = _currentUser;
    if (user == null) return;

    final fetched = await widget.apiClient.getNoteById(
      userId: user.userId,
      noteId: noteId,
    );
    if (!context.mounted) return;
    _openInspector(context, fetched);
  }

  Future<void> _deleteNote(String noteId) async {
    final user = _currentUser;
    if (user == null) return;

    await widget.apiClient.deleteNote(userId: user.userId, noteId: noteId);
    if (!mounted) return;
    setState(() {
      _notes = _notes.where((n) => n.id != noteId).toList();
    });
  }

  void _openInspector(BuildContext context, NoteItem note) {
    final user = _currentUser;
    if (user == null) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NoteInspectorScreen(
          user: user,
          initialNote: note,
          apiClient: widget.apiClient,
          onNoteUpdated: (updated) {
            setState(() {
              _notes = [
                for (final item in _notes)
                  if (item.id == updated.id) updated else item,
              ];
            });
          },
          onNoteDeleted: (deletedId) {
            setState(() {
              _notes = _notes.where((n) => n.id != deletedId).toList();
            });
          },
        ),
      ),
    );
  }

  void _openCreateNote(BuildContext context) {
    final user = _currentUser;
    if (user == null) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CreateNoteScreen(
          user: user,
          apiClient: widget.apiClient,
          onNoteCreated: (created) {
            setState(() {
              _notes = [created, ..._notes];
            });
          },
        ),
      ),
    );
  }

  void _openSensorScreen(BuildContext context) {
    final user = _currentUser;
    if (user == null) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => SensorScreen(user: user)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;
    if (user == null) {
      return AuthScreen(
        apiClient: widget.apiClient,
        onAuthenticated: _handleAuthenticated,
      );
    }

    return NotesListScreen(
      user: user,
      notes: _notes,
      isLoading: _isLoadingNotes,
      errorMessage: _notesError,
      onRefresh: _loadNotes,
      onOpenNote: (note) => _openInspector(context, note),
      onGetNoteById: (noteId) => _openNoteById(context, noteId),
      onCreateNote: () => _openCreateNote(context),
      onDeleteNote: _deleteNote,
      onOpenSensors: () => _openSensorScreen(context),
      onSignOut: _handleSignOut,
    );
  }
}
