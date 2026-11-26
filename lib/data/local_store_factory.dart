/// Pemilih implementasi penyimpanan lokal sesuai platform.
///
/// `dart:io` tersedia di Android/iOS/desktop (SQLite), sedangkan di web
/// jatuh ke penyimpanan in-memory.
library;

export 'local_store_factory_memory.dart'
    if (dart.library.io) 'local_store_factory_io.dart';
