import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Pastel card color variants supported in the bento vault.
enum NoteCardPalette {
  coral,
  sunlight,
  sage,
  sky;

  Color get backgroundColor {
    switch (this) {
      case NoteCardPalette.coral:
        return AppColors.secondaryContainer;
      case NoteCardPalette.sunlight:
        return AppColors.tertiaryFixed;
      case NoteCardPalette.sage:
        return AppColors.sageMeadow;
      case NoteCardPalette.sky:
        return AppColors.periwinkleSky;
    }
  }

  Color get foregroundColor {
    switch (this) {
      case NoteCardPalette.coral:
        return AppColors.onSecondaryContainer;
      case NoteCardPalette.sunlight:
        return AppColors.onTertiaryFixed;
      case NoteCardPalette.sage:
        return AppColors.onSageMeadow;
      case NoteCardPalette.sky:
        return AppColors.onPeriwinkleSky;
    }
  }

  static NoteCardPalette fromNoteId(String id) {
    final numeric = int.tryParse(id) ?? 1;
    final index = (numeric > 0 ? numeric - 1 : 0) % values.length;
    return values[index];
  }
}

/// Note model matching https://6b07948d58419b87a4385752.mockapi.io/users/{user_id}/notes.
class NoteItem {
  const NoteItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String title;
  final String description;
  final String latitude;
  final String longitude;
  final int status;
  final String createdAt;
  final String updatedAt;

  NoteCardPalette get palette => NoteCardPalette.fromNoteId(id);

  factory NoteItem.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'];
    final parsedStatus = rawStatus is num
        ? rawStatus.toInt()
        : int.tryParse(rawStatus?.toString() ?? '') ?? 0;

    return NoteItem(
      id: (json['id'] ?? json['note_id'] ?? '').toString(),
      userId: (json['user_id'] ?? json['userId'] ?? '1').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      latitude: (json['latitude'] ?? '').toString(),
      longitude: (json['longitude'] ?? '').toString(),
      status: parsedStatus.clamp(0, 100),
      createdAt: (json['created_at'] ?? json['createdAt'] ?? '').toString(),
      updatedAt: (json['updated_at'] ?? json['updatedAt'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'title': title,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  NoteItem copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? latitude,
    String? longitude,
    int? status,
    String? createdAt,
    String? updatedAt,
  }) {
    return NoteItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Shared form validators for Note CRUD screens.
class NoteValidators {
  const NoteValidators._();

  static String? title(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Judul catatan wajib diisi.';
    if (trimmed.length < 3) return 'Judul minimal 3 karakter.';
    return null;
  }

  static String? description(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Deskripsi catatan wajib diisi.';
    if (trimmed.length < 3) return 'Deskripsi minimal 3 karakter.';
    return null;
  }

  static String? latitude(String? value, {bool requireNumeric = true}) {
    return _coordinate(
      value,
      label: 'Latitude',
      min: -90,
      max: 90,
      requireNumeric: requireNumeric,
    );
  }

  static String? longitude(String? value, {bool requireNumeric = true}) {
    return _coordinate(
      value,
      label: 'Longitude',
      min: -180,
      max: 180,
      requireNumeric: requireNumeric,
    );
  }

  static String? _coordinate(
    String? value, {
    required String label,
    required double min,
    required double max,
    required bool requireNumeric,
  }) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return '$label wajib diisi.';

    final parsed = double.tryParse(trimmed);
    if (parsed == null) {
      if (requireNumeric) {
        return '$label harus berupa angka (${min.toInt()} s.d. ${max.toInt()}).';
      }
      return null;
    }

    if (parsed < min || parsed > max) {
      return '$label harus di antara ${min.toInt()} hingga ${max.toInt()}.';
    }
    return null;
  }
}

