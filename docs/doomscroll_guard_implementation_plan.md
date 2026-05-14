# Doomscroll Guard Implementation Plan

Tanggal: 2026-05-14

Dokumen ini berisi rencana implementasi realistis berdasarkan PRD, arsitektur, desain, dan system flow. Rencana dibagi per phase. Setiap phase memiliki major task dengan daftar kerja berurutan.

---

## Phase 0 - Project Setup & Foundation

### Major Task 0.1 - Project Bootstrap (Flutter + Android)

1. Inisialisasi proyek Flutter (Material 3) dengan struktur folder sesuai arsitektur.
2. Tambahkan dependensi dasar (state management, local storage).
3. Siapkan konfigurasi Android (minSdk 29/Android 10+).
4. Buat konfigurasi channel komunikasi Flutter-Android (Method Channel) dan stub handler di Android.
5. Pastikan aplikasi bisa build dan run di emulator/device.

### Major Task 0.2 - Data Model & Storage Baseline

1. Definisikan model data: Settings, UsageSession, DailyUsage, PermissionState.
2. Tentukan storage (Hive atau SharedPreferences) dan buat adapter/serialization.
3. Buat service penyimpanan lokal untuk settings dan usage data.
4. Tambahkan seed data sederhana untuk testing.

---

## Phase 1 - Core Monitoring MVP

### Major Task 1.1 - Permission Flow (Onboarding + Setup)

1. Buat screen onboarding sederhana (multi-step) mengikuti user flow.
2. Implement permission guide screen dengan checklist.
3. Implement request permissions: Accessibility, Usage Access, Overlay, Battery Optimization.
4. Simpan status permission di local storage.
5. Tambahkan guard agar monitoring tidak aktif sebelum permission lengkap.

### Major Task 1.2 - Native Monitoring Service

1. Implement Foreground Service di Android dengan notifikasi persistent.
2. Tambahkan Accessibility Service untuk deteksi foreground app.
3. Tambahkan UsageStatsManager untuk fallback data usage.
4. Buat SessionManager untuk start/stop sesi dan menghitung durasi.
5. Buat ThresholdEngine untuk cek batas waktu default (20 menit).
6. Pastikan service restart otomatis jika killed (resilience basics).

### Major Task 1.3 - Flutter <-> Android Integration

1. Definisikan Method Channel API: startService, stopService, getMonitoringState, getUsageStats.
2. Implement method handler di Android dan wiring di Flutter.
3. Tambahkan stream/state di Flutter untuk monitoring state.
4. Uji end-to-end: mulai service dari Flutter dan dapat status balik.

### Major Task 1.4 - Intervention Popup (Overlay + Fallback)

1. Implement OverlayManager dan OverlayService.
2. Buat layout popup dengan 3 action: Snooze, Dismiss, Take a Break.
3. Pastikan popup muncul di atas aplikasi target.
4. Implement fallback Notification jika overlay gagal.
5. Kirim hasil action ke SessionManager (reset, continue, snooze).

### Major Task 1.5 - Basic Dashboard & Statistics

1. Buat Dashboard screen (status monitoring + quick stats).
2. Buat Statistics screen (daily dan weekly summary sederhana).
3. Update usage data dari native ke local storage Flutter.
4. Tampilkan total usage, warning count, top apps.

---

## Phase 2 - Configuration & Quality Improvements

### Major Task 2.1 - Target Apps & Threshold Settings

1. Implement app picker untuk memilih target apps.
2. Simpan daftar target apps di settings.
3. Implement UI pengaturan threshold (menit).
4. Update ThresholdEngine agar memakai konfigurasi user.

### Major Task 2.2 - Quiet Hours & Exceptions

1. Implement pengaturan quiet hours (start/end time).
2. Implement whitelist / exception apps.
3. Update rule engine: skip warning jika di quiet hours atau app whitelist.
4. Tambahkan state di UI untuk menampilkan status rule aktif.

### Major Task 2.3 - Monitoring Controls

1. Implement pause/resume protection di UI.
2. Tambahkan emergency disable (stop service + reset state).
3. Sync status kontrol dengan native service.

### Major Task 2.4 - Reliability & Edge Cases

1. Tangani permission revoked saat runtime.
2. Deteksi screen off dan reset session.
3. Handle app switching cepat (debounce minimal).
4. Handle overlay failure dengan fallback konsisten.
5. Uji behavior pada battery optimization aktif.

---

## Phase 3 - UX Polish & Analytics Upgrade

### Major Task 3.1 - Visual Polish (Design System)

1. Terapkan color palette dan typography dari design doc.
2. Implement spacing dan radius konsisten.
3. Perbaiki tampilan popup agar terasa soft intervention.
4. Review hierarchy dan readability di dashboard/statistics.

### Major Task 3.2 - Enhanced Analytics

1. Tambahkan ringkasan mingguan lebih detail.
2. Tambahkan histori warning per hari.
3. Tambahkan insight sederhana (misal: jam paling sering doomscroll).
4. Tambahkan opsi reset data.

### Major Task 3.3 - Onboarding & Guidance Improvements

1. Tambahkan microcopy yang lebih jelas di permission steps.
2. Tambahkan empty states untuk statistik kosong.
3. Tambahkan tips ringan di dashboard (optional).

---

## Phase 4 - Stabilization & Release Prep

### Major Task 4.1 - Testing & QA

1. Uji semua permission flow di device Android 10+.
2. Uji overlay popup di beberapa vendor (Samsung/Xiaomi jika tersedia).
3. Uji service survival setelah app ditutup.
4. Uji fallback notification pada overlay fail.
5. Uji data persistence setelah restart device.

### Major Task 4.2 - Performance & Battery Validation

1. Profiling penggunaan baterai selama monitoring.
2. Pastikan foreground service tetap ringan.
3. Kurangi polling atau interval berlebihan.

### Major Task 4.3 - Release Packaging

1. Bersihkan log debug.
2. Pastikan icon, name, dan permission description jelas.
3. Update docs ringkas untuk demo / laporan.
4. Build release APK/AAB.

---

## Deliverables per Phase

- Phase 0: proyek siap jalan + storage baseline
- Phase 1: monitoring MVP + popup warning + statistik dasar
- Phase 2: konfigurasi lengkap + reliability improvements
- Phase 3: polish UI + analytics lebih kaya
- Phase 4: stabil, siap demo/release
