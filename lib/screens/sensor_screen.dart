import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../models/user_model.dart';
import '../services/sensor_math.dart';
import '../theme/app_theme.dart';
import '../widgets/notesnap_widgets.dart';

/// Halaman Modul 6: penghitung guncangan, kompas, dan giroskop.
///
/// Memakai paket sensor perangkat. Bila sensor tidak tersedia (mis. browser
/// tanpa magnetometer), halaman tetap tampil dan menampilkan catatan singkat.
class SensorScreen extends StatefulWidget {
  const SensorScreen({super.key, required this.user});

  final UserModel user;

  @override
  State<SensorScreen> createState() => _SensorScreenState();
}

class _SensorScreenState extends State<SensorScreen> {
  final PendeteksiGuncangan _pendeteksi = PendeteksiGuncangan(
    ambang: 2,
    jedaMs: 800,
  );

  // Langganan sensor dihentikan di dispose, saat layar ditutup.
  StreamSubscription<AccelerometerEvent>? _akselerometer;
  StreamSubscription<GyroscopeEvent>? _giroskop;
  StreamSubscription<MagnetometerEvent>? _magnetometer;

  Vektor _percepatanG = const Vektor(0, 0, 0);
  Vektor _rotasi = const Vektor(0, 0, 0);
  double _derajat = 0;
  int _jumlahGuncangan = 0;

  bool _akselerometerTersedia = true;
  bool _giroskopTersedia = true;
  bool _magnetometerTersedia = true;

  @override
  void initState() {
    super.initState();
    _mulaiAkselerometer();
    _mulaiGiroskop();
    _mulaiMagnetometer();
  }

  @override
  void dispose() {
    _akselerometer?.cancel();
    _giroskop?.cancel();
    _magnetometer?.cancel();
    super.dispose();
  }

  void _mulaiAkselerometer() {
    try {
      _akselerometer = accelerometerEventStream().listen(
        (AccelerometerEvent e) {
          final v = Vektor(e.x / gravitasi, e.y / gravitasi, e.z / gravitasi);
          final guncang = _pendeteksi.masukkan(
            v,
            DateTime.now().millisecondsSinceEpoch,
          );
          if (!mounted) return;
          setState(() {
            _percepatanG = v;
            _akselerometerTersedia = true;
            if (guncang) _jumlahGuncangan++;
          });
        },
        onError: (Object _) {
          if (!mounted) return;
          setState(() => _akselerometerTersedia = false);
        },
      );
    } catch (_) {
      _akselerometerTersedia = false;
    }
  }

  void _mulaiGiroskop() {
    try {
      _giroskop = gyroscopeEventStream().listen(
        (GyroscopeEvent e) {
          if (!mounted) return;
          setState(() {
            _rotasi = Vektor(e.x, e.y, e.z);
            _giroskopTersedia = true;
          });
        },
        onError: (Object _) {
          if (!mounted) return;
          setState(() => _giroskopTersedia = false);
        },
      );
    } catch (_) {
      _giroskopTersedia = false;
    }
  }

  void _mulaiMagnetometer() {
    try {
      _magnetometer = magnetometerEventStream().listen(
        (MagnetometerEvent e) {
          if (!mounted) return;
          setState(() {
            _derajat = arahKompas(e.x, e.y);
            _magnetometerTersedia = true;
          });
        },
        onError: (Object _) {
          if (!mounted) return;
          setState(() => _magnetometerTersedia = false);
        },
      );
    } catch (_) {
      _magnetometerTersedia = false;
    }
  }

  void _resetHitungan() {
    _pendeteksi.reset();
    setState(() => _jumlahGuncangan = 0);
  }

  String _f(double n) => n.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            NoteSnapStackHeader(
              title: 'Guncangan & Kompas',
              username: widget.user.name,
              avatarUrl: widget.user.avatar,
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.margin,
                  AppSpacing.md,
                  AppSpacing.margin,
                  AppSpacing.xl,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildGuncanganCard(),
                        const SizedBox(height: AppSpacing.lg),
                        _buildKompasCard(),
                        const SizedBox(height: AppSpacing.lg),
                        _buildGiroskopCard(),
                      ],
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

  Widget _buildGuncanganCard() {
    const fg = AppColors.onSecondaryContainer;
    return _SensorCard(
      background: AppColors.secondaryContainer,
      icon: Icons.sensors_rounded,
      iconColor: fg,
      title: 'Penghitung Guncangan',
      titleColor: fg,
      trailing: Text(
        '${_f(besarVektor(_percepatanG))} g',
        style: AppTypography.labelSm.copyWith(
          color: fg.withValues(alpha: 0.85),
          fontWeight: FontWeight.w700,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$_jumlahGuncangan',
            style: AppTypography.headlineXl.copyWith(
              fontSize: 56,
              height: 1,
              color: fg,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Guncang ponsel untuk menambah hitungan. '
            'Satu guncangan dihitung sekali.',
            style: AppTypography.bodySm.copyWith(color: fg),
          ),
          if (!_akselerometerTersedia) ...[
            const SizedBox(height: 10),
            _SensorUnavailableNote(
              message: 'Akselerometer tidak tersedia di perangkat ini.',
              color: fg,
            ),
          ],
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _resetHitungan,
            style: ElevatedButton.styleFrom(
              backgroundColor: fg,
              foregroundColor: AppColors.secondaryContainer,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
            ),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text(
              'Reset hitungan',
              style: AppTypography.labelMd.copyWith(
                color: AppColors.secondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKompasCard() {
    const fg = AppColors.onPeriwinkleSky;
    return _SensorCard(
      background: AppColors.periwinkleSky,
      icon: Icons.explore_rounded,
      iconColor: fg,
      title: 'Kompas',
      titleColor: fg,
      child: _magnetometerTersedia
          ? Row(
              children: [
                _buildKompasDial(fg),
                const SizedBox(width: AppSpacing.margin),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_derajat.round()}°',
                        style: AppTypography.headlineXl.copyWith(
                          fontSize: 40,
                          height: 1,
                          color: fg,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        mataAngin(_derajat),
                        style: AppTypography.headlineSm.copyWith(color: fg),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Letakkan ponsel datar agar arah akurat.',
                        style: AppTypography.bodySm.copyWith(color: fg),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : _SensorUnavailableNote(
              message: 'Magnetometer tidak tersedia di perangkat ini.',
              color: fg,
            ),
    );
  }

  Widget _buildKompasDial(Color fg) {
    return SizedBox(
      width: 104,
      height: 104,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceContainerLowest.withValues(alpha: 0.55),
              border: Border.all(color: fg.withValues(alpha: 0.3)),
            ),
          ),
          _buildDialLabel('U', const Alignment(0, -0.72), fg),
          _buildDialLabel('T', const Alignment(0.72, 0), fg),
          _buildDialLabel('S', const Alignment(0, 0.72), fg),
          _buildDialLabel('B', const Alignment(-0.72, 0), fg),
          Transform.rotate(
            angle: _derajat * math.pi / 180,
            child: Icon(Icons.navigation_rounded, size: 40, color: fg),
          ),
        ],
      ),
    );
  }

  Widget _buildDialLabel(String label, Alignment alignment, Color fg) {
    return Align(
      alignment: alignment,
      child: Text(
        label,
        style: AppTypography.labelSm.copyWith(
          color: fg.withValues(alpha: 0.8),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildGiroskopCard() {
    const fg = AppColors.onSageMeadow;
    return _SensorCard(
      background: AppColors.sageMeadow,
      icon: Icons.screen_rotation,
      iconColor: fg,
      title: 'Giroskop',
      titleColor: fg,
      trailing: Text(
        'rad/s',
        style: AppTypography.labelSm.copyWith(color: fg),
      ),
      child: _giroskopTersedia
          ? Row(
              children: [
                Expanded(child: _buildAxisTile('X', _rotasi.x, fg)),
                const SizedBox(width: 8),
                Expanded(child: _buildAxisTile('Y', _rotasi.y, fg)),
                const SizedBox(width: 8),
                Expanded(child: _buildAxisTile('Z', _rotasi.z, fg)),
              ],
            )
          : _SensorUnavailableNote(
              message: 'Giroskop tidak tersedia di perangkat ini.',
              color: fg,
            ),
    );
  }

  Widget _buildAxisTile(String axis, double value, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.standard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            axis,
            style: AppTypography.labelSm.copyWith(
              color: fg.withValues(alpha: 0.8),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _f(value),
            style: AppTypography.labelMd.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}

/// Kartu bento dengan header ikon + judul, konsisten dengan gaya NoteSnap.
class _SensorCard extends StatelessWidget {
  const _SensorCard({
    required this.background,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.titleColor,
    required this.child,
    this.trailing,
  });

  final Color background;
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color titleColor;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.margin),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.headlineSm.copyWith(color: titleColor),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SensorUnavailableNote extends StatelessWidget {
  const _SensorUnavailableNote({required this.message, required this.color});

  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.info_outline_rounded, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: AppTypography.bodySm.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
