# Product Requirements Document (PRD)

# Doomscroll Guard

## 1. Product Overview

Doomscroll Guard adalah aplikasi Android berbasis Flutter yang dirancang untuk membantu pengguna mengurangi perilaku doomscrolling pada aplikasi media sosial dan aplikasi hiburan berbasis infinite scrolling.

Aplikasi bekerja dengan memonitor durasi penggunaan aplikasi tertentu secara kontinu di background, lalu memberikan intervensi berupa popup atau peringatan ketika pengguna terdeteksi telah menggunakan aplikasi tersebut melewati batas waktu tertentu.

Tujuan utama aplikasi bukan untuk melarang penggunaan media sosial, melainkan membantu pengguna menyadari pola penggunaan yang berlebihan dan mendorong kebiasaan digital yang lebih sehat.

---

# 2. Problem Statement

Perkembangan platform media sosial modern menyebabkan meningkatnya perilaku doomscrolling, yaitu aktivitas scrolling konten digital secara terus-menerus tanpa tujuan jelas dalam durasi yang panjang.

Infinite scrolling, short-form content, personalized recommendation algorithm, dan autoplay content membuat pengguna sering kehilangan kesadaran terhadap waktu penggunaan.

Dampak yang sering muncul antara lain:

- Penurunan fokus belajar dan produktivitas
- Gangguan pola tidur
- Mental fatigue
- Penggunaan waktu yang tidak terkontrol
- Penurunan kemampuan attention span

Sebagian besar pengguna menyadari kebiasaan tersebut setelah durasi penggunaan sudah terlalu lama.

Saat ini fitur bawaan Digital Wellbeing pada Android cenderung bersifat pasif dan kurang memberikan intervensi real-time yang terasa langsung ketika doomscrolling sedang terjadi.

---

# 3. Product Goals

## Primary Goals

- Membantu pengguna menyadari perilaku doomscrolling secara real-time
- Memberikan intervensi ringan sebelum penggunaan menjadi berlebihan
- Mengurangi durasi penggunaan aplikasi tertentu
- Meningkatkan kesadaran digital habit pengguna

## Secondary Goals

- Memberikan insight statistik penggunaan aplikasi
- Membantu pengguna membangun kebiasaan digital yang lebih sehat
- Menjadi alternatif lightweight dari aplikasi digital wellbeing yang kompleks

---

# 4. Target Users

## Primary Users

- Mahasiswa
- Pelajar
- Remote worker
- Pengguna aktif media sosial
- Pengguna yang sering kehilangan fokus akibat scrolling berlebihan

## User Characteristics

- Menggunakan media sosial dalam intensitas tinggi
- Sering menggunakan short-form content apps
- Menyadari kebiasaan doomscrolling namun kesulitan mengontrolnya
- Membutuhkan reminder ringan tanpa terasa terlalu restriktif

---

# 5. Product Scope

## In Scope

### Monitoring System

- Memonitor aplikasi foreground
- Menghitung durasi penggunaan aplikasi tertentu
- Mendeteksi sesi penggunaan kontinu
- Mendukung monitoring aplikasi pilihan pengguna

### Intervention System

- Menampilkan popup warning
- Menampilkan notifikasi fallback
- Memberikan opsi snooze
- Memberikan opsi dismiss warning
- Memberikan reminder break

### Statistics System

- Menampilkan statistik penggunaan harian
- Menampilkan statistik penggunaan mingguan
- Menyimpan histori penggunaan sederhana

### Configuration System

- Mengatur threshold waktu penggunaan
- Memilih aplikasi yang dimonitor
- Mengatur quiet hours
- Mengatur whitelist atau exception

### Android Integration

- Accessibility Service integration
- Overlay permission handling
- Usage stats permission handling
- Background service monitoring

---

## Out of Scope

Fitur berikut tidak termasuk dalam versi awal aplikasi:

- iOS support
- Cloud synchronization
- Account system
- AI recommendation system
- Machine learning behavior prediction
- Cross-device synchronization
- Social sharing
- Gamification system
- Full parental control
- Internet blocking system
- VPN-based monitoring

---

# 6. Core Features

## 6.1 Foreground App Monitoring

Sistem dapat mendeteksi aplikasi yang sedang aktif digunakan oleh pengguna.

### Functional Requirements

- Sistem harus dapat mendeteksi aplikasi foreground
- Sistem harus dapat membedakan aplikasi target dan non-target
- Sistem harus berjalan di background
- Sistem harus tetap berjalan ketika aplikasi utama ditutup

---

## 6.2 Usage Session Tracking

Sistem menghitung durasi penggunaan aplikasi secara kontinu.

### Functional Requirements

- Sistem harus mencatat waktu mulai penggunaan
- Sistem harus menghitung durasi penggunaan secara real-time
- Sistem harus melakukan reset session ketika aplikasi berpindah
- Sistem harus menghentikan tracking ketika layar mati

---

## 6.3 Doomscrolling Detection

Aplikasi mendefinisikan doomscrolling sebagai penggunaan kontinu aplikasi media sosial melewati threshold tertentu tanpa jeda signifikan.

### Default Rules

- Default threshold: 20 menit
- Session dianggap berakhir ketika:
  - pengguna keluar aplikasi
  - layar mati
  - aplikasi berpindah
  - user pause monitoring

---

## 6.4 Intervention Popup

Ketika threshold tercapai, sistem menampilkan popup intervensi.

### Functional Requirements

- Popup harus muncul di atas aplikasi target
- Popup harus memiliki opsi:
  - Snooze
  - Dismiss
  - Take a Break
- Popup tidak boleh menyebabkan aplikasi crash
- Sistem harus fallback ke notification jika overlay gagal

---

## 6.5 Statistics Dashboard

Sistem menampilkan statistik penggunaan aplikasi.

### Functional Requirements

- Menampilkan total penggunaan harian
- Menampilkan total penggunaan mingguan
- Menampilkan aplikasi paling sering digunakan
- Menampilkan jumlah warning yang muncul

---

# 7. Non-Functional Requirements

## Performance

- Background monitoring harus lightweight
- Penggunaan baterai harus minimal
- Popup harus muncul kurang dari 2 detik setelah threshold tercapai

## Reliability

- Service harus dapat recover ketika killed by OS
- Data penggunaan harus tetap tersimpan setelah aplikasi restart

## Usability

- Setup permission harus jelas
- Intervensi tidak boleh terlalu mengganggu
- UI harus sederhana dan mudah dipahami

## Compatibility

- Android 10+
- Support berbagai screen size

---

# 8. Technical Requirements

## Frontend

- Flutter
- Material Design 3

## Native Android

- Kotlin
- Accessibility Service
- UsageStatsManager
- Foreground Service
- Overlay Window System

## Local Storage

- Hive atau SharedPreferences

## State Management

- Riverpod atau Provider

---

# 9. User Flow

## Initial Setup Flow

1. User membuka aplikasi
2. User membaca onboarding
3. User memberikan permission
4. User memilih aplikasi target
5. User mengatur threshold
6. Monitoring service dimulai

---

## Monitoring Flow

1. Service berjalan di background
2. Sistem mendeteksi aplikasi aktif
3. Sistem menghitung durasi penggunaan
4. Threshold tercapai
5. Popup warning muncul
6. User memilih tindakan

---

# 10. Edge Cases

## Permission Issues

- User mencabut permission
- Overlay permission gagal
- Accessibility service dimatikan

## System Issues

- Background service killed by OS
- Device battery optimization aktif
- Device vendor restrictions

## Usage Issues

- User berpindah aplikasi cepat
- Screen mati saat tracking
- Unsupported application

---

# 11. Risks & Challenges

## Technical Risks

- Android vendor restrictions
- Background service limitations
- Overlay compatibility issues
- Accessibility service instability

## UX Risks

- Popup terlalu mengganggu
- User mematikan permission
- User mengabaikan warning terus-menerus

## Scope Risks

- Feature creep
- Overengineering
- Terlalu banyak fitur non-esensial

---

# 12. Success Metrics

Aplikasi dianggap berhasil jika:

- Monitoring service berjalan stabil
- Popup muncul sesuai threshold
- User dapat melihat statistik penggunaan
- Penggunaan aplikasi target berkurang
- User dapat menyelesaikan onboarding tanpa kebingungan

---

# 13. Future Improvements

Fitur potensial untuk pengembangan berikutnya:

- Smart adaptive threshold
- Mood tracking
- Focus mode integration
- AI behavior analysis
- Cross-device sync
- Wearable integration
- Habit streak system
- Weekly productivity insights

---

# 14. Development Priority

## Phase 1 (MVP)

- Permission system
- Background monitoring
- Usage tracking
- Popup warning
- Basic statistics

## Phase 2

- Better analytics
- Improved UI/UX
- Quiet hours
- Exception system

## Phase 3

- Adaptive reminders
- Advanced insights
- Personalization

---

# 15. Conclusion

Doomscroll Guard dirancang sebagai aplikasi lightweight digital wellbeing yang fokus pada intervensi real-time terhadap perilaku doomscrolling.

Aplikasi tidak bertujuan melarang penggunaan media sosial, melainkan membantu pengguna meningkatkan kesadaran terhadap pola penggunaan digital mereka melalui monitoring dan reminder yang ringan namun efektif.

Dengan pendekatan Android-native integration dan Flutter frontend, aplikasi diharapkan dapat memberikan solusi praktis terhadap masalah penggunaan media sosial berlebihan pada era modern.
<<<<<<< HEAD
=======

>>>>>>> 0f27eb3 (git init)
