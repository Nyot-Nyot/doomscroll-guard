# ARCHITECTURE.md

# Doomscroll Guard Architecture

## 1. Architecture Overview

Doomscroll Guard menggunakan arsitektur hybrid antara Flutter dan native Android.

Flutter digunakan untuk:

- UI rendering
- State management
- Settings management
- Statistics dashboard
- User interaction

Sedangkan native Android digunakan untuk:

- Background monitoring
- Accessibility integration
- Usage stats monitoring
- Overlay popup system
- Foreground service management

Pendekatan hybrid dipilih karena Flutter tidak memiliki akses langsung terhadap beberapa fitur Android system-level yang dibutuhkan untuk monitoring aplikasi lintas foreground.

---

# 2. High Level Architecture

```text
+------------------------------------------------+
|                 Flutter Layer                  |
|------------------------------------------------|
| UI Screens                                     |
| Dashboard                                      |
| Statistics                                     |
| Settings                                       |
| Onboarding                                     |
|------------------------------------------------|
| State Management                               |
| Riverpod / Provider                            |
|------------------------------------------------|
| Local Business Logic                           |
+------------------------------------------------+
                |
                | Method Channel
                v
+------------------------------------------------+
|              Native Android Layer              |
|------------------------------------------------|
| Accessibility Service                          |
| UsageStatsManager                              |
| Foreground Service                             |
| Overlay Manager                                |
| Notification Manager                           |
|------------------------------------------------|
| Session Tracking Engine                        |
| Threshold Engine                               |
| Permission Handler                             |
+------------------------------------------------+
                |
                v
+------------------------------------------------+
|                 Local Storage                  |
|------------------------------------------------|
| Hive / SharedPreferences                       |
| Usage History                                  |
| Settings                                       |
| Session Data                                   |
+------------------------------------------------+
```

---

# 3. Architectural Principles

## 3.1 Lightweight Background Monitoring

Background monitoring harus tetap ringan dan tidak menghabiskan baterai secara berlebihan.

Karena aplikasi berjalan secara terus-menerus di background, efisiensi resource menjadi prioritas utama.

---

## 3.2 Separation of Concerns

Setiap layer memiliki tanggung jawab yang jelas.

### Flutter Layer

Bertanggung jawab terhadap:

- visual interface
- user interaction
- configuration
- presentation logic

### Native Android Layer

Bertanggung jawab terhadap:

- system-level integration
- foreground app monitoring
- overlay rendering
- background services

---

## 3.3 Resilience Against OS Restrictions

Android modern memiliki banyak pembatasan terhadap background service.

Arsitektur harus mempertimbangkan:

- battery optimization
- service kill behavior
- vendor-specific restrictions
- permission revocation

Sistem harus dapat melakukan recovery ketika service dihentikan sistem.

---

# 4. Core Components

## 4.1 Flutter UI Layer

Flutter menjadi presentation layer utama aplikasi.

### Responsibilities

- Menampilkan dashboard
- Menampilkan statistik
- Menampilkan onboarding
- Menampilkan settings
- Menampilkan permission guide

### Main Screens

- Splash Screen
- Onboarding Screen
- Dashboard Screen
- Statistics Screen
- Settings Screen
- Permission Setup Screen

---

## 4.2 State Management Layer

State management digunakan untuk mengelola:

- app state
- permission state
- monitoring state
- settings state
- statistics state

### Recommended Option

- Riverpod

### Alternative

- Provider

Riverpod dipilih karena:

- scalable
- mudah dipelihara
- reactive
- cocok untuk aplikasi asynchronous dan service-heavy

---

# 5. Native Android Layer

## 5.1 Accessibility Service

Accessibility Service digunakan untuk membantu mendeteksi aktivitas aplikasi foreground.

### Responsibilities

- mendeteksi perubahan aplikasi aktif
- memonitor aktivitas aplikasi tertentu
- membantu tracking session

### Risks

- user dapat menonaktifkan service
- beberapa device memiliki behavior berbeda
- permission sangat sensitif

---

## 5.2 UsageStatsManager

Digunakan untuk membaca statistik penggunaan aplikasi.

### Responsibilities

- membaca usage duration
- membaca foreground app usage
- membantu session tracking

### Limitations

- bergantung pada permission usage access
- beberapa vendor Android memiliki pembatasan tambahan

---

## 5.3 Foreground Service

Foreground service menjadi inti monitoring engine.

### Responsibilities

- menjalankan monitoring background
- menjaga service tetap hidup
- menjalankan timer session
- mengatur threshold checking

### Important Notes

Foreground service wajib memiliki notification aktif sesuai aturan Android modern.

---

## 5.4 Overlay Manager

Overlay Manager bertanggung jawab menampilkan popup di atas aplikasi lain.

### Responsibilities

- render popup warning
- handle overlay lifecycle
- handle popup interaction

### Fallback

Jika overlay gagal:

- gunakan notification fallback

---

## 5.5 Notification Manager

Digunakan sebagai fallback communication channel.

### Responsibilities

- menampilkan warning notification
- menampilkan service notification
- menampilkan recovery notification

---

# 6. Monitoring Engine

Monitoring Engine adalah inti logic aplikasi.

## Responsibilities

- mendeteksi app aktif
- memulai session
- menghitung durasi penggunaan
- mengecek threshold
- mengirim trigger intervensi

---

## Session Lifecycle

```text
App Detected
    ↓
Session Started
    ↓
Duration Tracking
    ↓
Threshold Check
    ↓
Warning Triggered
    ↓
User Action Handling
    ↓
Session Reset / Continue
```

---

# 7. Data Architecture

## 7.1 Local Storage

Aplikasi menggunakan local storage karena:

- lightweight
- offline-first
- tidak membutuhkan backend
- cocok untuk MVP

---

## 7.2 Stored Data

### Settings Data

- target apps
- threshold duration
- quiet hours
- whitelist apps
- snooze settings

### Usage Data

- daily usage duration
- weekly usage duration
- warning count
- session history

### System State

- onboarding completed
- permissions granted
- service state

---

# 8. Communication Flow

## Flutter to Native

Flutter berkomunikasi dengan native Android menggunakan Method Channel.

### Example Operations

- start service
- stop service
- request current monitoring state
- request usage statistics

---

## Native to Flutter

Native layer mengirim data ke Flutter untuk:

- statistics updates
- monitoring state
- permission state
- warning logs

---

# 9. Folder Structure

## Flutter Structure

```text
/lib
 ├── core
 │    ├── constants
 │    ├── services
 │    ├── utils
 │    └── themes
 │
 ├── features
 │    ├── onboarding
 │    ├── dashboard
 │    ├── statistics
 │    ├── settings
 │    └── monitoring
 │
 ├── shared
 │    ├── widgets
 │    ├── models
 │    └── providers
 │
 └── main.dart
```

---

## Android Native Structure

```text
/android/app/src/main/kotlin
 ├── services
 │    ├── MonitoringService
 │    ├── OverlayService
 │    └── PermissionService
 │
 ├── managers
 │    ├── SessionManager
 │    ├── NotificationManager
 │    └── OverlayManager
```