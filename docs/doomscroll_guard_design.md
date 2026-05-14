# DESIGN.md

# Doomscroll Guard Design System

## 1. Design Philosophy

Doomscroll Guard dirancang sebagai aplikasi digital wellbeing yang terasa tenang, ringan, dan tidak menghakimi pengguna.

Aplikasi tidak boleh terasa seperti parental control, productivity police, atau aplikasi motivasi yang terlalu agresif.

Tujuan desain adalah menciptakan pengalaman yang:

- calm
- clean
- breathable
- modern
- emotionally neutral
- distraction-free

Visual aplikasi harus membantu pengguna merasa lebih sadar terhadap kebiasaan digital mereka tanpa menciptakan tekanan tambahan.

---

# 2. Core Design Principles

## 2.1 Calm Technology

Aplikasi harus hadir seperlunya.

UI tidak boleh terlalu ramai, terlalu penuh warna, atau terlalu banyak elemen visual yang bersaing.

Pengguna sudah lelah dengan stimulasi visual berlebihan dari media sosial.

Karena itu Doomscroll Guard justru harus menjadi “ruang dingin” di tengah aplikasi modern yang hiperaktif.

---

## 2.2 Functional Minimalism

Setiap elemen UI harus memiliki tujuan jelas.

Tidak ada:

- dekorasi berlebihan
- glow effect
- neon effect
- random gradients
- glassmorphism berlebihan
- animated overload
- typography eksperimental

Interface harus sederhana namun tetap terasa premium.

---

## 2.3 Soft Intervention

Intervensi tidak boleh terasa seperti alarm darurat.

Popup warning harus terasa seperti:

- gentle interruption
- subtle awareness
- mindful reminder

Bukan:

- hukuman
- ancaman
- guilt-tripping

Aplikasi tidak boleh membuat pengguna merasa dimarahi.

---

## 2.4 Information Clarity

Statistik dan informasi harus mudah dipahami dalam sekali lihat.

Prioritas:

- readability
- hierarchy
- spacing
- visual breathing room

---

# 3. Visual Identity

## Brand Personality

Doomscroll Guard memiliki identitas visual:

- calm
- mature
- modern
- intelligent
- soft
- quiet
- grounded

Bukan:

- gamer aesthetic
- cyberpunk
- startup gradient culture
- flashy productivity app
- hyper motivational

---

# 4. Color System

## Design Direction

Warna utama harus terasa:

- natural
- grounded
- soft
- non-corporate
- non-techbro

Hindari:

- pure blue SaaS style
- purple gradient startup style
- neon colors
- overly saturated palettes

---

## Primary Palette

### Background

- Warm Off White
- Hex: `#F6F4EF`

Digunakan sebagai background utama.

Tujuan:

- mengurangi fatigue
- terasa hangat
- lebih nyaman dibanding pure white

---

### Surface

- Soft Sand
- Hex: `#ECE7DE`

Digunakan untuk:

- cards
- popup
- elevated surfaces

---

### Primary Accent

- Muted Olive
- Hex: `#6B705C`

Digunakan untuk:

- primary buttons
- active state
- highlights
- charts

Warna ini dipilih karena terasa lebih grounded dibanding biru modern yang terlalu “template startup”.

---

### Secondary Accent

- Dusty Clay
- Hex: `#CB997E`

Digunakan secara terbatas untuk:

- warnings
- session alerts
- subtle emphasis

Tidak digunakan sebagai warna dominan.

---

### Text Primary

- Deep Charcoal
- Hex: `#2B2B2B`

---

### Text Secondary

- Warm Gray
- Hex: `#6E6A63`

---

## Dark Mode Palette

### Background

- Charcoal Brown
- Hex: `#1F1D1A`

### Surface

- Soft Graphite
- Hex: `#2A2723`

### Accent

- Muted Olive Light
- Hex: `#A5A58D`

Dark mode harus terasa hangat dan lembut.

Bukan hitam pekat OLED gamer mode.

---

# 5. Typography

## Typography Philosophy

Typography harus:

- highly readable
- modern
- neutral
- mature
- non-decorative

Tidak menggunakan:

- italic-heavy typography
- aesthetic handwritten fonts
- condensed fonts
- futuristic fonts
- ultra rounded fonts

---

## Recommended Fonts

### Primary Option

- Inter

### Alternative Options

- Manrope
- Plus Jakarta Sans
- SF Pro (iOS style inspiration)

---

## Typography Hierarchy

### Heading Large

- Weight: SemiBold
- Size: 28-32

### Heading Medium

- Weight: SemiBold
- Size: 22-24

### Body Text

- Weight: Regular
- Size: 15-16

### Caption

- Weight: Medium
- Size: 12-13

---

# 6. Layout System

## Spacing Philosophy

UI harus memiliki banyak breathing room.

Jangan membuat layar terasa padat.

Gunakan:

- large padding
- consistent spacing
- clean alignment

---

## Recommended Spacing Scale

- 4
- 8
- 12
- 16
- 24
- 32

---

## Corner Radius

Gunakan rounded corner lembut.

### Recommended Radius

- Cards: 18-22
- Buttons: 14-18
- Popup: 24

Rounded corner membantu aplikasi terasa lebih soft dan tidak agresif.

---

# 7. Component Design

## 7.1 Buttons

### Primary Button

- Filled muted olive
- White text
- Medium weight
- No gradient
- No shadow berlebihan

### Secondary Button

- Soft outline
- Neutral surface
- Minimal contrast

---

## 7.2 Cards

Cards harus:

- flat
- soft
- subtle
- readable

Gunakan:

- low contrast shadow
- soft elevation
- generous padding

---

## 7.3 Popup Warning

Popup adalah elemen paling penting.

Popup tidak boleh terasa seperti:

- error dialog
- malware popup
- punishment alert

Popup harus terasa:

- reflective
- calm
- interruptive but respectful

---

## Popup Content Example

### Title

"You’ve been scrolling for a while"

### Supporting Text

"Take a short break before continuing."

### Actions

- Take a Break
<<<<<<< HEAD
=======
- Snooze
- Continue Anyway

Tone harus netral.

Tidak menghakimi.

---

# 8. Dashboard Design

## Dashboard Priorities

Dashboard harus fokus pada:

- clarity
- simplicity
- quick understanding

Bukan dashboard penuh angka dan chart seperti cockpit pesawat.

---

## Recommended Sections

### Today Usage Summary

Menampilkan:

- total screen time
- warning count
- longest session

---

### App Usage Cards

Menampilkan:

- app icon
- app name
- usage duration
- progress indicator

---

### Weekly Trend

Gunakan chart sederhana.

Hindari:

- chart overload
- terlalu banyak warna
- visual noise

---

# 9. Motion & Animation

## Animation Philosophy

Animasi harus subtle.

Tujuan animasi:

- membantu transisi
- memberikan feedback
- memperhalus experience

Bukan untuk pamer.

---

## Recommended Motion

- soft fade
- slight scale
- smooth slide
- duration 150ms - 300ms

Hindari:

- bounce berlebihan
- flashy transition
- physics animation berlebihan
- parallax aneh

---

# 10. UX Principles

## 10.1 Low Friction

Setup awal harus sesingkat mungkin.

Permission flow harus:

- jelas
- step-by-step
- tidak overwhelming

---

## 10.2 Non-Judgmental UX

Jangan gunakan wording seperti:

- “You are addicted”
- “Stop wasting time”
- “Too much screen time!”

Gunakan tone yang lebih mindful dan netral.

---

## 10.3 Respect User Autonomy

User tetap memiliki kontrol.

Aplikasi tidak boleh terasa memaksa.

Selalu berikan:

- dismiss option
- snooze option
- customizable threshold

---

# 11. Accessibility

## Readability

- kontras cukup tinggi
- font tidak terlalu kecil
- spacing nyaman

---

## Touch Target

Semua button minimal:

- 44x44dp

---

## Color Dependency

Jangan mengandalkan warna saja untuk menyampaikan informasi.

---

# 12. Design Inspirations

## Inspiration Sources

Vibe visual yang dijadikan referensi:

- modern mindfulness apps
- premium reading apps
- clean habit trackers
- minimalist journaling apps
- editorial-style mobile UI

---

## Non-Inspirations

Yang sengaja dihindari:

- crypto app aesthetics
- gamer UI
- overly futuristic UI
- glowing SaaS dashboards
- productivity bro aesthetics

---

# 13. Design Keywords

Kata kunci utama desain:

- calm
- grounded
- breathable
- mindful
- warm
- quiet
- clean
- mature
- modern
- intentional

---

# 14. Conclusion

Design Doomscroll Guard dirancang untuk menjadi antitesis dari aplikasi media sosial modern yang penuh stimulasi visual.

Aplikasi harus terasa seperti ruang tenang yang membantu pengguna berhenti sejenak dari endless scrolling.

Pendekatan visual yang clean, warm, dan restrained dipilih agar pengalaman menggunakan aplikasi terasa nyaman dalam jangka panjang tanpa menciptakan visual fatigue tambahan.

>>>>>>> 0f27eb3 (git init)
