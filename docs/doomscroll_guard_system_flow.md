# System Flow Diagram Set

Dokumen ini berisi tiga diagram utama untuk Doomscroll Guard: Activity Diagram, Sequence Diagram, dan State Diagram.

---

## 1. Activity Diagram

```plantuml
@startuml
start

:User membuka aplikasi;
:Check onboarding status;

if (First launch?) then (Yes)
  :Tampilkan onboarding;
  :Minta permission akses;
  :Minta permission overlay;
  :Minta permission usage access;
  :Minta exclude battery optimization;
  :User memilih target apps;
  :User mengatur threshold;
  :Simpan konfigurasi awal;
else (No)
  :Load konfigurasi tersimpan;
endif

:Start protection service;

while (Service aktif?) is (Yes)

  :Monitor foreground app;

  if (App target aktif?) then (Yes)

    :Mulai / lanjutkan session timer;
    :Cek duration terhadap threshold;

    if (Threshold tercapai?) then (Yes)

      :Cek quiet hours dan exception;

      if (Allowed to interrupt?) then (Yes)

        :Tampilkan popup warning;

        if (Overlay gagal?) then (Yes)
          :Kirim fallback notification;
        endif

        :User pilih snooze / dismiss / break;

        if (Snooze?) then (Yes)
          :Simpan snooze timer;
        else (No)

          if (Break?) then (Yes)
            :Reset session;
          else (Dismiss)
            :Lanjut monitoring;
          endif

        endif

      else (No)
        :Skip warning;
      endif

    else (No)
      :Lanjut tracking;
    endif

  else (No)
    :Reset atau pause session;
  endif

endwhile

stop
@enduml
```

---

## 2. Sequence Diagram

```plantuml
@startuml
skinparam shadowing false
skinparam sequence {
  ArrowColor #444444
  ParticipantBorderColor #444444
  ParticipantBackgroundColor #F8F8F8
}

actor User
participant "Flutter UI" as UI
participant "Permission Handler" as PH
participant "Android Service" as AS
participant "Accessibility / Usage API" as API
participant "Overlay Manager" as OM
participant "Notification Manager" as NM
participant "Local Storage" as LS

User -> UI : Open app
UI -> LS : Load config
LS --> UI : Config data

alt First launch / permission not granted
  UI -> PH : Request required permissions
  PH -> User : Show permission prompts
  User --> PH : Grant / deny permissions
  PH --> UI : Permission result
  UI -> LS : Save permission state
end

UI -> AS : Start protection service
AS -> API : Observe foreground app
API --> AS : App package / usage state

loop While service active
  AS -> AS : Check target app & timer
  AS -> LS : Read threshold / exceptions
  LS --> AS : Settings

  alt Threshold reached and allowed
    AS -> OM : Show warning popup
    alt Overlay available
      OM --> User : Display popup
      User -> OM : Snooze / Dismiss / Break
      OM -> LS : Save action and session state
      OM --> AS : Result
    else Overlay failed
      OM -> NM : Send fallback notification
      NM --> User : Notification warning
      User -> NM : Open app / dismiss
      NM -> LS : Save fallback event
    end
  else Not yet reached
    AS -> LS : Update session duration
  end
end

@enduml
```

---

## 3. State Diagram

```plantuml
@startuml
skinparam shadowing false
skinparam state {
  BackgroundColor #F8F8F8
  BorderColor #444444
}

[*] --> Idle

Idle --> Onboarding : first launch
Onboarding --> PermissionSetup : continue
PermissionSetup --> Ready : all permissions granted
PermissionSetup --> PermissionBlocked : permission denied
PermissionBlocked --> PermissionSetup : retry
Ready --> Monitoring : start protection service

Monitoring --> TrackingSession : target app detected
TrackingSession --> WarningTriggered : threshold reached
TrackingSession --> Idle : app switched / screen off
TrackingSession --> Paused : user pause protection

WarningTriggered --> Snoozed : user snooze
WarningTriggered --> Dismissed : user dismiss
WarningTriggered --> BreakTaken : user take break
WarningTriggered --> FallbackNotification : overlay failed

Snoozed --> Monitoring : snooze timer ends
Dismissed --> Monitoring : continue monitoring
BreakTaken --> Idle : session reset
FallbackNotification --> Monitoring : user returns / notification handled

Paused --> Monitoring : resume protection
Monitoring --> ErrorState : service killed / OS restriction
ErrorState --> Ready : service recovered
Monitoring --> EmergencyDisabled : user disable protection
EmergencyDisabled --> Idle : protection off

@enduml
```

---

## 4. Use Case Diagram

```
@startuml
left to right direction
skinparam linetype ortho
skinparam packageStyle rectangle
skinparam actorStyle modern

skinparam usecase {
  BackgroundColor #F8F8F8
  BorderColor #444444
}

actor User
actor "Android OS" as OS

rectangle "Doomscroll Guard System" {

  package "Setup & Configuration" {

    usecase UC1 as "First Launch /\nOnboarding"
    usecase UC2 as "Grant Accessibility\nPermission"
    usecase UC3 as "Grant Usage Access\nPermission"
    usecase UC4 as "Grant Overlay\nPermission"
    usecase UC5 as "Disable Battery\nOptimization"

    usecase UC6 as "Select Target Apps"
    usecase UC7 as "Set Threshold &\nQuiet Hours"
    usecase UC8 as "Manage Whitelist /\nExceptions"
  }

  package "Monitoring Engine" {

    usecase UC9 as "Start Protection\nService"
    usecase UC10 as "Monitor Foreground\nApplication"
    usecase UC11 as "Detect Continuous\nUsage Session"
    usecase UC12 as "Check Rules &\nExceptions"
  }

  package "Intervention System" {

    usecase UC13 as "Trigger Warning\nPopup"
    usecase UC14 as "Send Fallback\nNotification"
    usecase UC15 as "Snooze Warning"
    usecase UC16 as "Dismiss Warning"
    usecase UC17 as "Take Break /\nClose App"
  }

  package "Statistics & Data" {

    usecase UC18 as "View Usage\nStatistics"
    usecase UC19 as "View Daily /\nWeekly Summary"
    usecase UC20 as "Export Usage Data"
    usecase UC21 as "Reset Usage Data"
  }

  package "Control System" {

    usecase UC22 as "Pause Protection"
    usecase UC23 as "Resume Protection"
    usecase UC24 as "Emergency Disable"
  }

  package "Edge Case Handling" {

    usecase UC25 as "Handle Permission\nRevoked"
    usecase UC26 as "Handle Service\nKilled by OS"
    usecase UC27 as "Handle Overlay\nFailure"
    usecase UC28 as "Handle Unsupported\nApplication"
    usecase UC29 as "Handle Screen Off /\nBackground State"
    usecase UC30 as "Handle App Switch /\nSession Reset"
  }
}

' USER RELATIONS
User --> UC1
User --> UC6
User --> UC7
User --> UC8

User --> UC15
User --> UC16
User --> UC17

User --> UC18
User --> UC19
User --> UC20
User --> UC21

User --> UC22
User --> UC23
User --> UC24

' OS RELATIONS
OS --> UC25
OS --> UC26
OS --> UC27
OS --> UC28
OS --> UC29
OS --> UC30

' INCLUDE RELATIONS
UC1 ..> UC2 : <<include>>
UC1 ..> UC3 : <<include>>
UC1 ..> UC4 : <<include>>
UC1 ..> UC5 : <<include>>

UC9 ..> UC10 : <<include>>
UC9 ..> UC11 : <<include>>
UC9 ..> UC12 : <<include>>

UC18 ..> UC19 : <<include>>

' EXTEND RELATIONS
UC13 ..> UC14 : <<extend>>
UC13 ..> UC15 : <<extend>>
UC13 ..> UC16 : <<extend>>
UC13 ..> UC17 : <<extend>>

UC22 ..> UC9 : <<extend>>
UC23 ..> UC9 : <<extend>>

UC24 ..> UC22 : <<extend>>

UC25 ..> UC1 : <<extend>>
UC26 ..> UC9 : <<extend>>
UC27 ..> UC13 : <<extend>>
UC28 ..> UC12 : <<extend>>
UC29 ..> UC11 : <<extend>>
UC30 ..> UC11 : <<extend>>

@enduml
```



## Catatan Alur

- **Activity Diagram** menjelaskan alur proses dari onboarding sampai monitoring dan intervensi.
- **Sequence Diagram** menjelaskan interaksi antar komponen saat aplikasi berjalan.
- **State Diagram** menjelaskan perubahan status utama sistem selama aplikasi aktif.

Diagram ini bisa langsung dipakai sebagai basis laporan atau disesuaikan lagi untuk versi final implementasi.
<<<<<<< HEAD
=======

>>>>>>> 0f27eb3 (git init)
