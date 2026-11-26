import 'package:flutter/material.dart';
import '../models/note_model.dart';
import '../models/user_model.dart';
import '../services/mock_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/notesnap_widgets.dart';

class CreateNoteScreen extends StatefulWidget {
  const CreateNoteScreen({
    super.key,
    required this.user,
    required this.apiClient,
    required this.onNoteCreated,
  });

  final UserModel user;
  final NotesApiClient apiClient;
  final ValueChanged<NoteItem> onNoteCreated;

  @override
  State<CreateNoteScreen> createState() => _CreateNoteScreenState();
}

class _CreateNoteScreenState extends State<CreateNoteScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;

  double _statusValue = 67;
  bool _isSaving = false;
  bool _autoValidate = false;
  String? _apiError;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descController = TextEditingController();
    _latController = TextEditingController();
    _lngController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _submitNote() async {
    setState(() {
      _autoValidate = true;
      _apiError = null;
    });

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final today = MockApiService.formatTodayDate();
      final created = await widget.apiClient.createNote(
        userId: widget.user.userId,
        note: NoteItem(
          id: '',
          userId: widget.user.userId,
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          latitude: _latController.text.trim(),
          longitude: _lngController.text.trim(),
          status: _statusValue.round(),
          createdAt: today,
          updatedAt: today,
        ),
      );
      if (!mounted) return;
      widget.onNoteCreated(created);
      Navigator.of(context).pop();
      showNoteSnapToast(context, 'Catatan #${created.id} berhasil disimpan!');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            NoteSnapStackHeader(
              title: 'Tambah Catatan',
              username: widget.user.name,
              avatarUrl: widget.user.avatar,
              onBack: () => Navigator.of(context).pop(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.margin,
                AppSpacing.sm,
                AppSpacing.margin,
                AppSpacing.sm,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: _buildActionMetaRow(),
                ),
              ),
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
                          if (_apiError != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.errorContainer,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.standard,
                                ),
                              ),
                              child: Text(
                                _apiError!,
                                style: AppTypography.bodySm.copyWith(
                                  color: AppColors.onErrorContainer,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          _buildTitleSection(),
                          const SizedBox(height: AppSpacing.lg),
                          _buildDescriptionEditorCard(),
                          const SizedBox(height: AppSpacing.lg),
                          _buildCompletionCard(),
                          const SizedBox(height: AppSpacing.lg),
                          _buildGeolocationCard(),
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

  Widget _buildActionMetaRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: _isSaving ? null : () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              'Batal',
              style: AppTypography.labelMd.copyWith(color: AppColors.onSurface),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  'user_id: ${widget.user.userId} • ${widget.user.name}',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _submitNote,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  shape: const StadiumBorder(),
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.onPrimary,
                        ),
                      )
                    : const Icon(Icons.check_rounded, size: 16),
                label: Text(
                  _isSaving ? 'Menyimpan...' : 'Simpan Catatan',
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'JUDUL CATATAN',
          style: AppTypography.labelSm.copyWith(
            color: AppColors.onSurfaceVariant,
            letterSpacing: 0.9,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _titleController,
          validator: NoteValidators.title,
          style: AppTypography.headlineLg.copyWith(color: AppColors.onSurface),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 4),
            border: InputBorder.none,
            errorStyle: AppTypography.bodySm.copyWith(color: AppColors.error),
            hintText: 'Masukkan judul catatan...',
            hintStyle: AppTypography.headlineLg.copyWith(
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.35),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionEditorCard() {
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'DESKRIPSI',
            style: AppTypography.labelSm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
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
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionCard() {
    final pct = _statusValue.round();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.margin),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: AppColors.tertiaryFixed,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.flag_outlined,
                        size: 16,
                        color: AppColors.onTertiaryFixed,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Status Penyelesaian',
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.headlineSm.copyWith(
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '$pct%',
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _StatusPresetButton(
                  label: '25%',
                  isSelected: pct == 25,
                  onTap: () => setState(() => _statusValue = 25),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _StatusPresetButton(
                  label: '67%',
                  isSelected: pct == 67,
                  onTap: () => setState(() => _statusValue = 67),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _StatusPresetButton(
                  label: '100%',
                  isSelected: pct == 100,
                  onTap: () => setState(() => _statusValue = 100),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGeolocationCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.margin),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.near_me_outlined,
                  size: 16,
                  color: AppColors.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Lokasi Geografis',
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.headlineSm.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _GeoInputBox(
                  dotColor: AppColors.secondary,
                  label: 'Latitude',
                  controller: _latController,
                  hint: '-6.2088',
                  validator: NoteValidators.latitude,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _GeoInputBox(
                  dotColor: AppColors.tertiary,
                  label: 'Longitude',
                  controller: _lngController,
                  hint: '106.8456',
                  validator: NoteValidators.longitude,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPresetButton extends StatelessWidget {
  const _StatusPresetButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.labelSm.copyWith(
            color: isSelected ? AppColors.onPrimary : AppColors.onSurface,
          ),
        ),
      ),
    );
  }
}

class _GeoInputBox extends StatelessWidget {
  const _GeoInputBox({
    required this.dotColor,
    required this.label,
    required this.controller,
    required this.hint,
    required this.validator,
  });

  final Color dotColor;
  final String label;
  final TextEditingController controller;
  final String hint;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: const TextInputType.numberWithOptions(
              signed: true,
              decimal: true,
            ),
            style: AppTypography.labelMd.copyWith(color: AppColors.onSurface),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              hintText: hint,
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
