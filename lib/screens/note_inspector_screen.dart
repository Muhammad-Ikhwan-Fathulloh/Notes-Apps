import 'package:flutter/material.dart';
import '../models/note_model.dart';
import '../models/user_model.dart';
import '../services/mock_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/notesnap_widgets.dart';

class NoteInspectorScreen extends StatefulWidget {
  const NoteInspectorScreen({
    super.key,
    required this.user,
    required this.initialNote,
    required this.apiClient,
    required this.onNoteUpdated,
    required this.onNoteDeleted,
  });

  final UserModel user;
  final NoteItem initialNote;
  final NotesApiClient apiClient;
  final ValueChanged<NoteItem> onNoteUpdated;
  final ValueChanged<String> onNoteDeleted;

  @override
  State<NoteInspectorScreen> createState() => _NoteInspectorScreenState();
}

class _NoteInspectorScreenState extends State<NoteInspectorScreen> {
  final _formKey = GlobalKey<FormState>();

  late NoteItem _note;
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;

  late double _statusValue;
  bool _isRefreshing = true;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _autoValidate = false;
  String? _apiError;

  @override
  void initState() {
    super.initState();
    _note = widget.initialNote;
    _statusValue = _note.status.toDouble();
    _titleController = TextEditingController(text: _note.title);
    _descController = TextEditingController(text: _note.description);
    _latController = TextEditingController(text: _note.latitude);
    _lngController = TextEditingController(text: _note.longitude);
    _fetchLatestById(notifyBeforeFetch: false);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _fetchLatestById({bool notifyBeforeFetch = true}) async {
    if (notifyBeforeFetch) {
      setState(() {
        _isRefreshing = true;
        _apiError = null;
      });
    }
    try {
      final fresh = await widget.apiClient.getNoteById(
        userId: widget.user.userId,
        noteId: _note.id,
      );
      if (!mounted) return;
      setState(() {
        _note = fresh;
        _statusValue = fresh.status.toDouble();
        _titleController.text = fresh.title;
        _descController.text = fresh.description;
        _latController.text = fresh.latitude;
        _lngController.text = fresh.longitude;
      });
    } on MockApiException catch (e) {
      if (!mounted) return;
      setState(() => _apiError = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _apiError = 'Gagal menyegarkan data catatan: $e');
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _saveUpdates() async {
    setState(() {
      _autoValidate = true;
      _apiError = null;
    });
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final updated = await widget.apiClient.updateNote(
        userId: widget.user.userId,
        note: _note.copyWith(
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          latitude: _latController.text.trim(),
          longitude: _lngController.text.trim(),
          status: _statusValue.round(),
        ),
      );
      if (!mounted) return;
      setState(() => _note = updated);
      widget.onNoteUpdated(updated);
      showNoteSnapToast(context, 'Catatan #${updated.id} berhasil diperbarui!');
    } on MockApiException catch (e) {
      if (!mounted) return;
      setState(() => _apiError = e.message);
      showNoteSnapToast(context, e.message);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _confirmDeleteDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: AppColors.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.margin),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.secondaryFixed,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    size: 24,
                    color: AppColors.onSecondaryFixed,
                  ),
                ),
                const SizedBox(height: 14),
                Text('Hapus Catatan?', style: AppTypography.headlineSm),
                const SizedBox(height: 6),
                Text(
                  'Catatan "#${_note.id} - ${_titleController.text.trim()}" akan dihapus dari MockAPI.',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: TextButton(
                          onPressed: () => Navigator.of(dialogCtx).pop(),
                          style: TextButton.styleFrom(
                            backgroundColor: AppColors.surfaceContainer,
                            foregroundColor: AppColors.onSurface,
                            shape: const StadiumBorder(),
                          ),
                          child: Text('Batal', style: AppTypography.labelMd),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(dialogCtx).pop();
                            _performDelete();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: AppColors.onSecondary,
                            shape: const StadiumBorder(),
                          ),
                          child: Text(
                            'Ya, Hapus',
                            style: AppTypography.labelMd.copyWith(
                              color: AppColors.onSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _performDelete() async {
    setState(() {
      _isDeleting = true;
      _apiError = null;
    });
    try {
      await widget.apiClient.deleteNote(
        userId: widget.user.userId,
        noteId: _note.id,
      );
      if (!mounted) return;
      widget.onNoteDeleted(_note.id);
      Navigator.of(context).pop();
      showNoteSnapToast(context, 'Catatan #${_note.id} berhasil dihapus');
    } on MockApiException catch (e) {
      if (!mounted) return;
      setState(() => _apiError = e.message);
      showNoteSnapToast(context, e.message);
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            NoteSnapStackHeader(
              title: 'Detail Catatan #${_note.id}',
              username: widget.user.name,
              avatarUrl: widget.user.avatar,
              onBack: () => Navigator.of(context).pop(),
            ),
            if (_isRefreshing)
              const LinearProgressIndicator(
                minHeight: 2,
                color: AppColors.primary,
                backgroundColor: AppColors.surfaceContainer,
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.margin,
                  AppSpacing.sm,
                  AppSpacing.margin,
                  AppSpacing.xl,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: _autoValidate
                          ? AutovalidateMode.onUserInteraction
                          : AutovalidateMode.disabled,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildMetaBar(),
                          if (_apiError != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            _buildApiErrorBanner(),
                          ],
                          const SizedBox(height: AppSpacing.md),
                          _buildTitleSection(),
                          const SizedBox(height: AppSpacing.md),
                          _buildDescriptionCard(),
                          const SizedBox(height: AppSpacing.lg),
                          _buildStatusCard(),
                          const SizedBox(height: AppSpacing.lg),
                          _buildSpatialInfoCard(),
                          const SizedBox(height: AppSpacing.margin),
                          _buildPrimaryActions(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              _apiError!,
              style: AppTypography.bodySm.copyWith(
                color: AppColors.onErrorContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: _isRefreshing ? null : _fetchLatestById,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaBar() {
    final dateText = _note.updatedAt.isNotEmpty
        ? _note.updatedAt
        : _note.createdAt;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Diperbarui: ${dateText.isEmpty ? '-' : dateText}',
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: (_isSaving || _isDeleting) ? null : _confirmDeleteDialog,
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondaryFixed,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: AppColors.onSecondaryFixed,
                ),
                const SizedBox(width: 5),
                Text(
                  'Hapus',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSecondaryFixed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleSection() {
    return TextFormField(
      controller: _titleController,
      validator: NoteValidators.title,
      style: AppTypography.headlineLg.copyWith(color: AppColors.onSurface),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
        border: InputBorder.none,
        errorStyle: AppTypography.bodySm.copyWith(color: AppColors.error),
        hintText: 'Judul catatan...',
        hintStyle: AppTypography.headlineLg.copyWith(
          color: AppColors.outline.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.margin),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DESKRIPSI',
            style: AppTypography.labelSm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _descController,
            validator: NoteValidators.description,
            maxLines: null,
            minLines: 4,
            style: AppTypography.bodyLg.copyWith(
              color: AppColors.onSurface,
              height: 1.55,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              errorStyle: AppTypography.bodySm.copyWith(color: AppColors.error),
              hintText: 'Tuliskan deskripsi catatan...',
              hintStyle: AppTypography.bodyLg.copyWith(
                color: AppColors.outline.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final pct = _statusValue.round();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.margin),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status Penyelesaian',
                style: AppTypography.headlineSm.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.tertiaryFixed,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '$pct% Selesai',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onTertiaryFixed,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.surfaceContainerHigh,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.12),
              trackHeight: 6,
            ),
            child: Slider(
              value: _statusValue,
              min: 0,
              max: 100,
              onChanged: (v) => setState(() => _statusValue = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpatialInfoCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.margin),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.pin_drop_outlined,
                size: 20,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Data Spasial & Info',
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.headlineSm.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _CoordinateInfoTile(
                  label: 'Latitude',
                  controller: _latController,
                  validator: (v) =>
                      NoteValidators.latitude(v, requireNumeric: false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CoordinateInfoTile(
                  label: 'Longitude',
                  controller: _lngController,
                  validator: (v) =>
                      NoteValidators.longitude(v, requireNumeric: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      UserAvatarCircle(
                        avatarUrl: widget.user.avatar,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '${widget.user.name} (user_id: ${_note.userId})',
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelMd.copyWith(
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'ID: #${_note.id}',
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: (_isSaving || _isDeleting) ? null : _saveUpdates,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              elevation: 4,
              shape: const StadiumBorder(),
            ),
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.onPrimary,
                    ),
                  )
                : const Icon(Icons.check_circle_outline_rounded, size: 22),
            label: Text(
              _isSaving ? 'Menyimpan...' : 'Perbarui Catatan',
              style: AppTypography.headlineSm.copyWith(
                color: AppColors.onPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: (_isSaving || _isDeleting) ? null : _confirmDeleteDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryFixed,
              foregroundColor: AppColors.onSecondaryFixed,
              elevation: 0,
              shape: const StadiumBorder(),
            ),
            icon: _isDeleting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.onSecondaryFixed,
                    ),
                  )
                : const Icon(Icons.delete_forever_outlined, size: 20),
            label: Text(
              _isDeleting ? 'Menghapus...' : 'Hapus Catatan',
              style: AppTypography.headlineSm.copyWith(
                color: AppColors.onSecondaryFixed,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CoordinateInfoTile extends StatelessWidget {
  const _CoordinateInfoTile({
    required this.label,
    required this.controller,
    required this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.labelSm.copyWith(color: AppColors.outline),
          ),
          const SizedBox(height: 2),
          TextFormField(
            controller: controller,
            validator: validator,
            style: AppTypography.labelMd.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              errorStyle: AppTypography.bodySm.copyWith(
                color: AppColors.error,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
