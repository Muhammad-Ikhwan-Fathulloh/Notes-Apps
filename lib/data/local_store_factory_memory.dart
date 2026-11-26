import 'local_store.dart';
import 'memory_local_store.dart';

/// Di web (tanpa `dart:io`) penyimpanan lokal memakai memori; data bertahan
/// selama sesi berjalan dan hilang saat halaman dimuat ulang.
Future<LocalStore> createLocalStore() async => InMemoryLocalStore();
