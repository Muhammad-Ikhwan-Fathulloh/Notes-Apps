import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Displays the stylized NoteSnap sticky note icon inside an obsidian badge.
class NoteSnapLogoMark extends StatelessWidget {
  const NoteSnapLogoMark({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        Icons.sticky_note_2_rounded,
        color: AppColors.onPrimary,
        size: size * 0.52,
      ),
    );
  }
}

/// Circular user avatar that loads the photo from [avatarUrl] when it points
/// to a usable http(s) URL, otherwise falls back to a person icon.
class UserAvatarCircle extends StatelessWidget {
  const UserAvatarCircle({
    super.key,
    required this.avatarUrl,
    required this.size,
    this.backgroundColor = AppColors.primary,
    this.foregroundColor = AppColors.onPrimary,
  });

  final String? avatarUrl;
  final double size;
  final Color backgroundColor;
  final Color foregroundColor;

  /// Returns the URL only when it is a real http(s) link; "-" or empty means
  /// the account has no custom photo.
  String? get _resolvedUrl {
    final raw = avatarUrl?.trim() ?? '';
    if (raw.isEmpty || raw == '-') return null;
    final uri = Uri.tryParse(raw);
    if (uri == null ||
        !(uri.isScheme('http') || uri.isScheme('https'))) {
      return null;
    }
    return raw;
  }

  Widget _fallbackIcon() {
    return Icon(
      Icons.person_outline_rounded,
      color: foregroundColor,
      size: size * 0.56,
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = _resolvedUrl;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      child: url == null
          ? _fallbackIcon()
          : Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _fallbackIcon(),
            ),
    );
  }
}

/// Top-right user badge pill + obsidian avatar circle.
class UserProfileActionCluster extends StatelessWidget {
  const UserProfileActionCluster({
    super.key,
    required this.username,
    this.avatarUrl,
    this.showNamePill = true,
  });

  final String username;
  final String? avatarUrl;
  final bool showNamePill;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showNamePill) ...[
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        UserAvatarCircle(avatarUrl: avatarUrl, size: 32),
      ],
    );
  }
}

/// Stack navigation header shared by Detail and Tambah Catatan screens.
class NoteSnapStackHeader extends StatelessWidget {
  const NoteSnapStackHeader({
    super.key,
    required this.title,
    required this.username,
    required this.onBack,
    this.avatarUrl,
  });

  final String title;
  final String username;
  final String? avatarUrl;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                InkWell(
                  onTap: onBack,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      size: 20,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const NoteSnapLogoMark(size: 28),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    title,
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
          UserProfileActionCluster(
            username: username,
            avatarUrl: avatarUrl,
            showNamePill: false,
          ),
        ],
      ),
    );
  }
}

/// Decorative dashed circle + check stamp in the bottom-right of bento note cards.
class NoteStampPainter extends CustomPainter {
  const NoteStampPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.43;

    final circlePaint = Paint()
      ..color = color.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.095;

    const dashCount = 18;
    const step = (2 * math.pi) / dashCount;
    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * step,
        step * 0.56,
        false,
        circlePaint,
      );
    }

    final checkPaint = Paint()
      ..color = color.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.30, size.height * 0.50)
      ..lineTo(size.width * 0.45, size.height * 0.65)
      ..lineTo(size.width * 0.70, size.height * 0.35);

    canvas.drawPath(path, checkPaint);
  }

  @override
  bool shouldRepaint(covariant NoteStampPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Helper to show a consistent Warm Pastel Bento floating pill toast.
void showNoteSnapToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 2400),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: const StadiumBorder(),
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 18,
              color: AppColors.tertiaryFixed,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
}
