# NoteSnap

Aplikasi catatan lintas platform (Flutter) dengan **penyimpanan lokal SQLite**, **sinkronisasi cloud offline-first**, dan halaman sensor perangkat (penghitung guncangan & kompas) untuk Modul 6 Associate Mobile Programmer.

## Fitur

- **Autentikasi pengguna** — login & daftar dengan nama, password, dan URL avatar.
- **Kelola catatan (CRUD)** — tambah, lihat, ubah, dan hapus catatan berisi judul, deskripsi, serta koordinat (latitude/longitude).
- **Lihat catatan berdasarkan ID** — pencarian langsung memakai ID remote.
- **Pencarian catatan** — filter Judul/Deskripsi di daftar catatan.
- **Avatar pengguna** — dimuat dari URL pada MockAPI dengan fallback ikon jika gambar gagal dimuat.
- **Guncangan & Kompas** — memakai akselerometer, magnetometer, dan giroskop perangkat:
  - Penghitung guncangan (menambah hitungan saat ponsel diguncang).
  - Kompas dengan arah mata angin (U/T/TG/S/BD/B/BL).
  - Deteksi giroskop yang tidak tersedia di perangkat.
- **Offline-first** — semua perubahan disimpan lokal dulu, lalu disinkronkan ke cloud.

## Arsitektur

```
lib/
├── main.dart                       # Bootstrap: buat LocalStore, jalankan NoteSnapApp
├── models/                         # UserModel, NoteItem
├── services/
│   ├── mock_api_service.dart       # NotesApiClient (kontrak) + MockApiService (HTTP)
│   └── sensor_math.dart            # Fungsi murni: pendeteksi guncangan, arah kompas
├── data/                           # Lapisan penyimpanan lokal + sinkronisasi
│   ├── local_store.dart            # Kontrak LocalStore, SyncState, PendingOp
│   ├── sqlite_local_store.dart     # Implementasi SQLite (Android/desktop)
│   ├── memory_local_store.dart     # Implementasi in-memory (web & unit test)
│   ├── local_store_factory*.dart   # Conditional import: io vs web
│   └── sync_notes_repository.dart  # Wrapper offline-first atas NotesApiClient
├── screens/                        # AuthScreen, NotesListScreen, CreateNoteScreen,
│                                   # NoteInspectorScreen, SensorScreen
├── widgets/notesnap_widgets.dart   # Komponen UI bersama (avatar, kartu, dsb.)
└── theme/app_theme.dart            # Warna, tipografi, spasi (Warm Pastel Bento)
```

### Alur data

Seluruh layar bergantung pada interface `NotesApiClient`. Di production, interface itu di-implementasikan oleh `SyncNotesRepository` yang membungkus `MockApiService` (cloud) dan `LocalStore` (lokal), sehingga layar tidak perlu tahu asal datanya.

Alur offline-first:

1. **Tulis lokal dahulu** — `upsertNote` menyimpan catatan dengan status `SyncState.pending`, lalu operasi dimasukkan ke antrean `pending_ops` (FIFO).
2. **Sinkronisasi** — `sync(userId)` mengosongkan antrean ke cloud (create → update → delete sesuai urutan), lalu menarik data terbaru dari cloud.
3. **Rekonsiliasi** — `replaceSyncedNotes` menyamakan data lokal dengan cloud, tetapi **tidak menimpa** baris berstatus `pending`. Pemetaan identitas memakai `remote_id` supaya catatan yang dibuat offline tetap konsisten.

Jika jaringan gagal, aplikasi otomatis memakai data lokal; bila belum ada data lokal sama sekali, error cloud tetap diteruskan ke UI.

## Penyimpanan data

| Tabel | Isi |
| --- | --- |
| `users` | `user_id` (PK), `name`, `avatar`, `password`, `created_at`, `updated_at` |
| `notes` | `id` (PK lokal), `remote_id`, `user_id`, `title`, `description`, `latitude`, `longitude`, `status`, `created_at`, `updated_at`, `sync_state` |
| `pending_ops` | `id` (auto-increment), `user_id`, `note_id`, `operation` (create/update/delete), `payload` |

Catatan penting:

- **SQLite berjalan di Android, iOS, dan desktop.** Untuk web `dart:io` tidak tersedia, sehingga aplikasi memakai penyimpanan in-memory (data hilang saat reload).
- Password pengguna disimpan sebagai teks asli di database lokal sesuai ketentuan proyek.

## Dependensi utama

| Paket | Kegunaan |
| --- | --- |
| `http` | Klien HTTP lintas platform (pengganti `dart:io` agar jalan di web) |
| `sensors_plus` | Akses akselerometer, magnetometer, dan giroskop |
| `sqflite` | SQLite untuk Android/iOS |
| `sqflite_common_ffi` | Driver SQLite untuk desktop dan unit test |
| `path` | Menentukan lokasi berkas database |

## Menjalankan

```bash
flutter pub get
flutter run                 # perangkat/emulator pilihan
flutter run -d chrome       # target web (penyimpanan in-memory)
```

## Build

```bash
flutter build apk --debug   # Android
flutter build web           # Web
```

## Pengujian

```bash
flutter analyze
flutter test
```

Cakupan pengujian (45 tes):

- `test/local_store_test.dart` — 9 skenario dijalankan pada **dua** implementasi (`InMemoryLocalStore` dan `SqliteLocalStore`): simpan/baca user, upsert user, round-trip catatan pending, daftar catatan per user, antrean FIFO, `markSynced`, dan rekonsiliasi `replaceSyncedNotes` (tambah/ubah/hapus, serta melindungi baris pending).
- `test/sync_notes_repository_test.dart` — 12 tes sinkronisasi: cache user, fallback offline, penolakan password salah, sinkronisasi create/update/delete di antrean, dan prioritas catatan lokal yang masih pending.
- `test/sensor_test.dart` — 13 tes fungsi murni pada `sensor_math.dart` (gravitasi, deteksi guncangan, arah & mata angin kompas).
- `test/widget_test.dart` — 2 widget test alur utama aplikasi.

## Catatan platform & konfigurasi

- **Sensor magnetometer tidak didukung di browser (Chrome)** — halaman sensor menampilkan fallback UI, bukan nilai kompas.
- **`android/gradle.properties`** memuat:
  - `kotlin.compiler.execution.strategy=in-process` dan `kotlin.incremental=false` untuk mengatasi kegagalan *incremental cache* Kotlin saat build plugin.
  - `android.newDsl=false` dan `android.builtInKotlin=false` dari template Flutter.
- Android memakai AGP 9.0.1, Gradle 9.1.0, dan Kotlin 2.3.20 (Built-in Kotlin). `sensors_plus` dipatok ke `^7.1.1` agar tidak memunculkan peringatan migrasi KGP.

## Sumber data cloud

MockAPI: `https://6b07948d58419b87a4385752.mockapi.io`
