# Travel Safety

A passive journey-monitoring mobile application built with Flutter.

> **Phase 1 complete.** The foundation, authentication, trusted-person management, and full UI/UX polish are implemented and verified. Phase 2 (GPS, route monitoring, risk engine, alerts) is not yet started.

---

## Table of Contents

- [Overview](#overview)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Features](#features)
- [Screens](#screens)
- [Architecture](#architecture)
- [Design System](#design-system)
- [Running the App](#running-the-app)
- [Running Tests](#running-tests)
- [Verification Status](#verification-status)
- [Known Limitations](#known-limitations)
- [Phase 2 Roadmap](#phase-2-roadmap)

---

## Overview

Travel Safety monitors a user's journey and will eventually detect potentially unsafe situations and alert a designated trusted person. The app is built to be passive — the user starts a trip, and the app watches over them silently.

**Phase 1** delivers the complete application foundation:
- User registration and login (local/device-based)
- Trusted-person setup — name, phone, relationship (all user-entered, never hardcoded)
- Home dashboard with safety status placeholder
- Full profile and settings management
- Polished, production-quality UI with a custom Travel Safety brand

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.47.0 (stable) |
| Language | Dart 3.7 |
| UI system | Material 3 |
| Local persistence | `shared_preferences ^2.2.3` |
| Android SDK | 36.1.0 |
| SDK constraint | Dart `>=3.5.0 <4.0.0` |

**No additional dependencies.** No maps, Firebase, networking, or ML packages.

---

## Project Structure

```
lib/
├── main.dart                          # App entry point
│
├── core/
│   ├── constants/app_constants.dart   # App name, tagline, all route names
│   └── theme/app_theme.dart           # Material 3 theme + brand palette
│
├── models/
│   ├── user_model.dart                # User account (name, phone, password hash, trusted person)
│   └── trusted_person_model.dart      # Trusted contact (name / phone / relationship)
│
├── services/
│   ├── storage_service.dart           # Isolated SharedPreferences wrapper
│   ├── auth_service.dart              # Register / login / logout / update trusted person
│   └── service_locator.dart           # Lightweight singleton DI
│
├── routing/
│   └── app_router.dart                # Named route factory (6 routes)
│
├── widgets/
│   ├── app_text_field.dart            # Reusable validated input field
│   └── section_header.dart            # ALL CAPS themed section label
│
└── screens/
    ├── splash/splash_screen.dart      # Brand entry + session-aware routing
    ├── auth/login_screen.dart         # Phone + password login
    ├── auth/registration_screen.dart  # Two-step account creation
    ├── home/home_screen.dart          # Main dashboard
    ├── trusted_person/trusted_person_screen.dart  # View + edit trusted contact
    └── profile/profile_screen.dart    # Account info + logout

test/
└── widget_test.dart                   # Splash screen widget tests (3 tests)
```

---

## Features

### Authentication
- **Registration** — Two-step form:
  - Step 1: Full name, phone number, password (min 6 characters), confirm password
  - Step 2: Trusted person name, **phone number (user-entered — never hardcoded)**, relationship
- **Login** — Phone number + password with inline error display
- **Logout** — Clears session only; account data is preserved on device
- **Session persistence** — App remembers login state across restarts

### Trusted Person
- Name, phone, and relationship stored locally
- Editable at any time from the Trusted Person screen
- Phone number is **entirely user-entered** — no default, no hardcoded value

### Home Dashboard
- Time-aware greeting using the logged-in user's name
- **SAFE** status indicator — static Phase 1 placeholder (no risk engine yet)
- **Start a Trip** button — intentionally disabled, labelled "GPS monitoring coming in Phase 2"
- Trusted person summary tile — taps through to the edit screen
- Recent trips empty state

### Profile & Settings
- Displays account name, phone, and trusted person details
- Sign out with confirmation dialog

### Form Validation
- All fields validated on submit and on interaction
- Phone: strips formatting characters, checks digit count
- Password: minimum 6 characters, confirmation match
- Errors shown inline via the themed error container

---

## Screens

| Screen | Route | Purpose |
|---|---|---|
| Splash | `/` | Brand entry, routes based on session state |
| Registration | `/register` | Two-step account creation |
| Login | `/login` | Returning user sign-in |
| Home | `/home` | Main dashboard |
| Trusted Person | `/trusted-person` | View and edit trusted contact |
| Profile | `/profile` | Account summary and logout |

### Splash routing logic
```
App launch  →  Splash (1.8 s)
  ├── logged in             →  /home
  ├── registered, not logged in  →  /login
  └── no account            →  /register
```

---

## Architecture

### Layer diagram

```
Screens
   │
   └──▶  AuthService  ──▶  StorageService  ──▶  SharedPreferences
              ▲
        ServiceLocator
        (global singletons)
```

- **Screens** never touch `SharedPreferences` directly
- **`StorageService`** is the only file that knows about `SharedPreferences`; swapping to SQLite, secure storage, or a REST API requires changing only this class
- **`AuthService`** owns all auth logic — register, login, logout, trusted-person updates
- **`ServiceLocator`** provides singleton access; marked for replacement with Riverpod/GetIt in a later phase

### Models

```
UserModel
  ├── name         : String
  ├── phone        : String
  ├── passwordHash : String   ← Base64-encoded (prototype only — see Limitations)
  └── trustedPerson: TrustedPersonModel
        ├── name         : String
        ├── phone        : String  ← user-entered, never hardcoded
        └── relationship : String
```

Both models support `toJson` / `fromJson` and `copyWith`.

---

## Design System

### Brand palette

| Token | Hex | Usage |
|---|---|---|
| `primaryNavy` | `#1B3A6B` | Primary buttons, labels, focus rings |
| `backgroundBlue` | `#F5F7FB` | Scaffold / page background |
| `surfaceWhite` | `#FFFFFF` | Cards, input fields |
| `charcoal` | `#1C2536` | Primary body text |
| `mutedGray` | `#64748B` | Secondary / hint text |
| `borderLight` | `#E2E8F0` | Borders and dividers |
| `safeColor` | `#166534` | SAFE status text |
| `safeIcon` | `#16A34A` | SAFE indicator dot |
| `safeContainer` | `#F0FDF4` | SAFE status background |

### Key design decisions

- **Background vs. surface contrast** — cool off-white (`F5F7FB`) scaffold + pure white (`FFFFFF`) cards creates natural section grouping without borders or shadows
- **Zero-elevation cards** — white-on-tinted-background is the depth signal; no drop shadows
- **No decorative gradients** — colour is used only where it carries meaning (navy = action, green = safe)
- **ALL CAPS section labels** — communicates hierarchy at 11sp without visual weight
- **Disabled trip button** — visible but grey; communicates Phase 2 intent clearly without hiding it

### Reusable widgets

| Widget | File | Purpose |
|---|---|---|
| `AppTextField` | `widgets/app_text_field.dart` | Validated input, consistent label/hint/icon styling |
| `SectionHeader` | `widgets/section_header.dart` | ALL CAPS, themed primary colour, consistent spacing |

---

## Running the App

### Prerequisites
- Flutter 3.47.0 or later
- Android SDK **or** Windows Developer Mode enabled

### Check available devices
```bash
flutter devices
```

### Run on Chrome (recommended for quick review)
```bash
flutter run -d chrome
```

### Run on Windows desktop
Enable Developer Mode first: **Settings → Privacy & Security → Developer Mode → On**
```bash
flutter run -d windows
```

### Run on Android device / emulator
```bash
flutter run
```

### Hot reload shortcuts
| Key | Action |
|---|---|
| `r` | Hot reload (instant UI update) |
| `R` | Hot restart (resets state) |
| `q` | Quit |

---

## Running Tests

```bash
# Static analysis
flutter analyze

# Widget tests
flutter test
```

### Test suite

| Test | Verifies |
|---|---|
| Splash screen shows app name | `Travel Safety` text renders on launch |
| Splash screen shows tagline | Tagline text renders |
| Splash navigates to registration | Routes to `/register` when no account exists |

Tests reset `SharedPreferences` via `setMockInitialValues({})` in `setUp` to ensure clean state each run.

---

## Verification Status

| Check | Result |
|---|---|
| `flutter analyze` | ✅ No issues found |
| `flutter test` | ✅ 3/3 passed |
| No Phase 2 functionality added | ✅ Confirmed |
| Trusted-person phone is user-entered | ✅ Confirmed — no hardcoded values anywhere |
| `StorageService` isolated | ✅ Only class that touches `SharedPreferences` |
| Logout preserves account data | ✅ Only session flag cleared |
| Start Trip disabled | ✅ `onPressed: null` — explicitly non-functional |
| No new dependencies beyond `shared_preferences` | ✅ Confirmed |

---

## Known Limitations

> **⚠️ Password storage — prototype only.**
> Passwords are Base64-encoded in `AuthService` before storage. Base64 is *encoding*, not
> *hashing* — it provides no cryptographic security. This approach is intentional for the
> Phase 1 local prototype. Before any real-world deployment, replace `AuthService` with
> proper server-side authentication (Firebase Auth, Supabase, or a custom server using
> bcrypt/Argon2). Never log or display the raw or encoded password.

- **One account per device** — single user stored in `SharedPreferences`
- **No real GPS tracking** — trip monitoring is Phase 2
- **No notifications or SMS** — alert escalation is Phase 2
- **No cloud sync** — all data is local to the device
- **Windows Developer Mode required** to build native plugins (does not block `flutter analyze` or `flutter test`)

---

## Phase 2 Roadmap

Not yet implemented — deferred intentionally:

- [ ] Trip setup — destination, transport mode, expected duration
- [ ] GPS / location permissions and background tracking
- [ ] Google Maps integration and route visualisation
- [ ] Route deviation detection
- [ ] Stop / stall detection
- [ ] ETA monitoring and alerts
- [ ] Safety state machine (SAFE → ALERT → DANGER)
- [ ] Trusted-person alert via SMS / push notification
- [ ] Trip history with timeline and map replay
- [ ] Cloud backend (Firebase / Supabase)
- [ ] Proper server-side authentication (replaces Base64 prototype)
- [ ] Multi-account support
