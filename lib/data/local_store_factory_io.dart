import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'local_store.dart';
import 'sqlite_local_store.dart';

/// Di Android/iOS memakai sqflite bawaan; di desktop memakai driver FFI.
Future<LocalStore> createLocalStore() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    return SqliteLocalStore(factory: databaseFactoryFfi);
  }
  return SqliteLocalStore();
}
