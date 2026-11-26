import 'package:flutter/material.dart';
import '../models/note_model.dart';
import '../models/user_model.dart';
import '../services/mock_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/notesnap_widgets.dart';

class NotesListScreen extends StatefulWidget {
  const NotesListScreen({
    super.key,
    required this.user,
    required this.notes,
    required this.isLoading,
    required this.errorMessage,
    required this.onRefresh,
    required this.onOpenNote,
    required this.onGetNoteById,
    required this.onCreateNote,
    required this.onDeleteNote,
    required this.onOpenSensors,
    required this.onSignOut,
  });

  final UserModel user;
  final List<NoteItem> notes;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRefresh;
  final ValueChanged<NoteItem> onOpenNote;
  final Future<void> Function(String noteId) onGetNoteById;
  final VoidCallback onCreateNote;
  final Future<void> Function(String noteId) onDeleteNote;
  final VoidCallback onOpenSensors;
  final VoidCallback onSignOut;

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  final TextEditingController _searchController = TextEditingController();
  NoteItem? _pendingDeleteNote;
  bool _isDeleting = false;
  bool _isFetchingById = false;
  String? _lookupError;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<NoteItem> get _filteredNotes {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return widget.notes;
    return widget.notes.where((note) {
      return note.id.toLowerCase().contains(query) ||
          note.title.toLowerCase().contains(query) ||
          note.description.toLowerCase().contains(query) ||
          note.latitude.toLowerCase().contains(query) ||
          note.longitude.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _lookupById() async {
    final rawId = _searchController.text.trim();
    if (rawId.isEmpty) {
      setState(() => _lookupError = 'Masukkan ID catatan untuk Get By ID.');
      return;
    }
    if (rawId.contains(' ')) {
      setState(() => _lookupError = 'ID catatan tidak boleh mengandung spasi.');
      return;
    }

    setState(() {
      _isFetchingById = true;
      _lookupError = null;
    });

    try {
      await widget.onGetNoteById(rawId);
    } on MockApiException catch (e) {
      if (!mounted) return;
      setState(() => _lookupError = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _lookupError = 'Gagal mengambil catatan #$rawId: $e');
    } finally {
      if (mounted) {
        setState(() => _isFetchingById = false);
      }
    }
  }

  Future<void> _confirmDelete() async {
    final target = _pendingDeleteNote;
    if (target == null) return;
    setState(() => _isDeleting = true);
    try {
      await widget.onDeleteNote(target.id);
      if (!mounted) return;
      setState(() => _pendingDeleteNote = null);
      showNoteSnapToast(context, 'Catatan #${target.id} dihapus.');
    } on MockApiException catch (e) {
      if (!mounted) return;
      showNoteSnapToast(context, e.message);
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleNotes = _filteredNotes;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: widget.onRefresh,
                    color: AppColors.primary,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.margin,
                        AppSpacing.sm,
                        AppSpacing.margin,
                        108,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildGreetingHeader(),
                              const SizedBox(height: AppSpacing.md),
                              _buildSearchAndGetByIdBar(),
                              if (_lookupError != null) ...[
                                const SizedBox(height: 6),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    _lookupError!,
                                    style: AppTypography.bodySm.copyWith(
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: AppSpacing.md),
                              if (widget.errorMessage != null &&
                                  widget.notes.isNotEmpty) ...[
                                _buildInlineErrorBanner(widget.errorMessage!),
                                const SizedBox(height: AppSpacing.md),
                              ],
                              if (widget.isLoading && widget.notes.isEmpty)
                                _buildLoadingState()
                              else if (widget.errorMessage != null &&
                                  widget.notes.isEmpty)
                                _buildErrorState(widget.errorMessage!)
                              else if (visibleNotes.isEmpty)
                                _buildEmptyState()
                              else
                                Column(
                                  children: [
                                    for (
                                      int i = 0;
                                      i < visibleNotes.length;
                                      i++
                                    )
                                      Padding(
                                        padding: EdgeInsets.only(
                                          bottom: i == visibleNotes.length - 1
                                              ? 0
                                              : AppSpacing.md,
                                        ),
                                        child: _NoteBentoCard(
                                          note: visibleNotes[i],
                                          onTap: () => widget.onOpenNote(
                                            visibleNotes[i],
                                          ),
                                          onDeleteRequest: () => setState(
                                            () => _pendingDeleteNote =
                                                visibleNotes[i],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_pendingDeleteNote != null)
              Positioned(
                left: AppSpacing.margin,
                right: AppSpacing.margin,
                bottom: 24,
                child: SafeArea(
                  top: false,
                  child: _DeleteBanner(
                    noteId: _pendingDeleteNote!.id,
                    isDeleting: _isDeleting,
                    onCancel: () => setState(() => _pendingDeleteNote = null),
                    onConfirm: _confirmDelete,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: _pendingDeleteNote == null
          ? FloatingActionButton.extended(
              onPressed: widget.onCreateNote,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              shape: const StadiumBorder(),
              icon: const Icon(Icons.add_rounded),
              label: Text(
                'Tambah Catatan',
                style: AppTypography.labelMd.copyWith(
                  color: AppColors.onPrimary,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margin),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.92),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Di layar sempit (mis. 320dp) pil nama disembunyikan agar ikon
          // kompas dan tombol keluar tetap tampil utuh.
          final showNamePill = constraints.maxWidth >= 300;
          return Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const NoteSnapLogoMark(size: 32),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        'NoteSnap',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.headlineSm.copyWith(
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: UserProfileActionCluster(
                        username:
                            '${widget.user.name} • #${widget.user.userId}',
                        avatarUrl: widget.user.avatar,
                        showNamePill: showNamePill,
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: widget.onOpenSensors,
                      tooltip: 'Guncangan & Kompas',
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surfaceContainerHigh,
                        fixedSize: const Size(34, 34),
                        padding: EdgeInsets.zero,
                      ),
                      icon: const Icon(
                        Icons.explore_rounded,
                        size: 16,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: widget.onSignOut,
                      tooltip: 'Keluar',
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surfaceContainerHigh,
                        fixedSize: const Size(34, 34),
                        padding: EdgeInsets.zero,
                      ),
                      icon: const Icon(
                        Icons.logout_rounded,
                        size: 16,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGreetingHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'USER ID: ${widget.user.userId}',
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 0.9,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Hai, ${widget.user.name}',
                overflow: TextOverflow.ellipsis,
                style: AppTypography.headlineLg.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: widget.isLoading ? null : widget.onRefresh,
          tooltip: 'Muat ulang catatan',
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surfaceContainerHigh,
            fixedSize: const Size(44, 44),
          ),
          icon: widget.isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.onSurface,
                  ),
                )
              : const Icon(
                  Icons.refresh_rounded,
                  size: 22,
                  color: AppColors.onSurface,
                ),
        ),
      ],
    );
  }

  Widget _buildSearchAndGetByIdBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 5, 6, 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: _lookupError != null ? AppColors.error : Colors.transparent,
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 20, color: AppColors.outline),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() => _lookupError = null),
              onSubmitted: (_) => _lookupById(),
              style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Cari catatan atau masukkan ID...',
                hintStyle: AppTypography.bodyMd.copyWith(
                  color: AppColors.outline.withValues(alpha: 0.75),
                ),
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              onPressed: () {
                _searchController.clear();
                setState(() => _lookupError = null);
              },
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.close_rounded,
                size: 18,
                color: AppColors.outline,
              ),
            ),
          const SizedBox(width: 4),
          ElevatedButton(
            onPressed: _isFetchingById ? null : _lookupById,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              shape: const StadiumBorder(),
              elevation: 0,
            ),
            child: _isFetchingById
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.onPrimary,
                    ),
                  )
                : Text(
                    'Get ID',
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.onPrimary,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.standard),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: AppColors.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySm.copyWith(
                color: AppColors.onErrorContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: widget.onRefresh,
            child: const Text('Muat Ulang'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 12),
          Text('Memuat catatan dari MockAPI...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onErrorContainer,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: widget.onRefresh,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              shape: const StadiumBorder(),
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.note_add_outlined,
              size: 32,
              color: AppColors.outline,
            ),
          ),
          const SizedBox(height: 12),
          Text('Belum ada catatan', style: AppTypography.headlineSm),
          const SizedBox(height: 4),
          Text(
            'Tambahkan catatan baru atau sesuaikan kata kunci pencarian.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySm,
          ),
        ],
      ),
    );
  }
}

class _NoteBentoCard extends StatelessWidget {
  const _NoteBentoCard({
    required this.note,
    required this.onTap,
    required this.onDeleteRequest,
  });

  final NoteItem note;
  final VoidCallback onTap;
  final VoidCallback onDeleteRequest;

  @override
  Widget build(BuildContext context) {
    final bg = note.palette.backgroundColor;
    final fg = note.palette.foregroundColor;
    final dateDisplay = note.updatedAt.isNotEmpty
        ? note.updatedAt
        : note.createdAt;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              right: -22,
              bottom: -22,
              width: 128,
              height: 128,
              child: IgnorePointer(
                child: CustomPaint(painter: NoteStampPainter(color: fg)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.margin),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: fg.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.full,
                                ),
                              ),
                              child: Text(
                                'NOTE #${note.id}',
                                style: AppTypography.labelSm.copyWith(
                                  color: fg,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.7,
                                ),
                              ),
                            ),
                            if (dateDisplay.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 13,
                                    color: fg.withValues(alpha: 0.75),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    dateDisplay,
                                    style: AppTypography.labelSm.copyWith(
                                      color: fg.withValues(alpha: 0.75),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        color: AppColors.surfaceContainerLowest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppRadius.standard,
                          ),
                        ),
                        onSelected: (value) {
                          if (value == 'edit') onTap();
                          if (value == 'delete') onDeleteRequest();
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(Icons.edit_outlined, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Detail / Edit',
                                  style: AppTypography.bodyMd,
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: AppColors.error,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Hapus',
                                  style: AppTypography.bodyMd.copyWith(
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: fg.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.more_vert_rounded,
                            size: 18,
                            color: fg,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    note.title,
                    style: AppTypography.headlineMd.copyWith(
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    note.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyLg.copyWith(
                      color: fg.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: fg.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 15,
                              color: fg,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${note.latitude}, ${note.longitude}',
                              style: AppTypography.labelSm.copyWith(color: fg),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: fg,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Status: ${note.status}%',
                              style: AppTypography.labelSm.copyWith(
                                color: bg,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 48,
                              height: 6,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.full,
                                ),
                                child: LinearProgressIndicator(
                                  value: (note.status / 100).clamp(0.0, 1.0),
                                  backgroundColor: bg.withValues(alpha: 0.4),
                                  valueColor: AlwaysStoppedAnimation<Color>(bg),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteBanner extends StatelessWidget {
  const _DeleteBanner({
    required this.noteId,
    required this.isDeleting,
    required this.onCancel,
    required this.onConfirm,
  });

  final String noteId;
  final bool isDeleting;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.inverseSurface,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: AppColors.secondaryFixed,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Hapus Catatan #$noteId?',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.inverseOnSurface,
              ),
            ),
          ),
          TextButton(
            onPressed: isDeleting ? null : onCancel,
            child: Text(
              'Batal',
              style: AppTypography.labelMd.copyWith(
                color: AppColors.inverseOnSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: isDeleting ? null : onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.onError,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
            ),
            child: isDeleting
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.onError,
                    ),
                  )
                : Text(
                    'Hapus',
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.onError,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
