# Travel Safety

A passive journey-monitoring mobile application built with Flutter.

> **Phase 2 complete.** Full trip monitoring, GPS tracking, safety timer, emergency contact, and trip history are implemented and verified. Ready for demonstration.

---

## Table of Contents

- [Overview](#overview)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Features — Phase 1](#features--phase-1)
- [Features — Phase 2](#features--phase-2)
- [Screens](#screens)
- [Architecture](#architecture)
- [Design System](#design-system)
- [Running the App](#running-the-app)
- [Running Tests](#running-tests)
- [Verification Status](#verification-status)
- [Known Limitations](#known-limitations)
- [Phase 3 Roadmap](#phase-3-roadmap)

---

## Overview

Travel Safety monitors a user's journey and detects potentially unsafe situations, alerting a designated trusted person. The app is designed to be passive — the user starts a trip, and the app watches over them silently.

**Phase 1** delivered the complete app foundation: registration, login, trusted-person setup, and a polished branded UI.

**Phase 2** delivers live trip monitoring: GPS tracking, countdown timer, delayed-trip detection, safety check dialogs, emergency contact, and trip history — all without any cloud backend.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.47.0 (stable) |
| Language | Dart 3.7 |
| UI system | Material 3 |
| Local persistence | `shared_preferences ^2.2.3` |
| GPS / Location | `geolocator ^13.0.2` |
| Phone calls | `url_launcher ^6.3.1` |
| Android SDK | 36.1.0 |
| SDK constraint | Dart `>=3.5.0 <4.0.0` |

**No cloud backend.** No Firebase, Supabase, or REST APIs — everything runs on-device.

---

## Project Structure

```
lib/
├── main.dart                          # App entry point
│
├── core/
│   ├── constants/app_constants.dart   # App name, tagline, all 9 route names
│   └── theme/app_theme.dart           # Material 3 theme + brand palette
│
├── models/
│   ├── user_model.dart                # User account model
│   ├── trusted_person_model.dart      # Trusted contact model
│   └── trip_model.dart                # ★ NEW — Trip data, status, serialization
│
├── services/
│   ├── storage_service.dart           # SharedPreferences wrapper (user/auth data)
│   ├── auth_service.dart              # Register / login / logout / update
│   ├── service_locator.dart           # Singleton DI (storage, auth, trip, location)
│   ├── trip_service.dart              # ★ NEW — Start/end trips, active trip, history
│   └── location_service.dart          # ★ NEW — Geolocator wrapper, graceful fallback
│
├── routing/
│   └── app_router.dart                # Named route factory (9 routes)
│
├── widgets/
│   ├── app_text_field.dart            # Reusable validated input field
│   └── section_header.dart            # ALL CAPS themed section label
│
└── screens/
    ├── splash/splash_screen.dart      # Brand entry + session-aware routing
    ├── auth/login_screen.dart         # Phone + password login
    ├── auth/registration_screen.dart  # Two-step account creation
    ├── home/home_screen.dart          # Dashboard (dynamic trip state)
    ├── trusted_person/trusted_person_screen.dart  # View + edit trusted contact
    ├── profile/profile_screen.dart    # Account info + logout
    ├── trip/trip_setup_screen.dart    # ★ NEW — Destination + duration form
    ├── trip/active_trip_screen.dart   # ★ NEW — Live countdown + safety monitor
    └── trip/emergency_screen.dart     # ★ NEW — Emergency contact screen

test/
└── widget_test.dart                   # Splash screen widget tests (3 tests)
```

---

## Features — Phase 1

### Authentication
- **Registration** — Two-step form (user details + trusted person)
- **Login** — Phone + password with inline error display
- **Logout** — Clears session only; account data preserved
- **Session persistence** — Login state survives app restarts

### Trusted Person
- Name, phone, and relationship stored locally
- Editable at any time
- **Phone is always user-entered** — never hardcoded

### Home Dashboard (Phase 1 baseline)
- Time-aware greeting
- SAFE status indicator
- Profile navigation

### Profile & Settings
- Account info display
- Sign out with confirmation

---

## Features — Phase 2

### Start a Trip
- Destination text field
- Visual chip picker: 15 min / 30 min / 45 min / 1 hr / 1.5 hr / 2 hr / 3 hr
- Requests GPS permission on trip start (non-blocking — trip proceeds regardless)

### Active Trip Screen
- **Live countdown** updated every second
- Destination, start time, expected duration displayed
- GPS distance-travelled tracking (when permission granted)
- `⚠️ TRIP DELAYED` status when expected time is exceeded
- **End Trip** button with confirmation dialog

### Safety Timer
- Monitors elapsed vs. expected trip duration
- When delayed: shows **"Are you safe?"** dialog automatically
  - **"I'm Safe"** → continues trip, next check in 15 minutes
  - **"Need Help"** → opens Emergency screen
  - Dismissed → next check in 5 minutes

### Emergency Screen
- Displays stored trusted person: name, relationship, phone
- **Requires confirmation** before initiating a call
- On web/desktop: shows phone number in a copyable dialog for manual dialing
- **Cancel** option always available — no automatic calls

### Home Dashboard (Phase 2 — dynamic)

| State | Banner | Button |
|---|---|---|
| No active trip | 🟢 **SAFE** — No active trip | Start a Trip |
| Trip running | 🔵 **TRIP ACTIVE** — Destination · time left | View Trip |
| Trip delayed | 🟠 **TRIP DELAYED** — Exceeded expected time | View Trip |

### Trip History
- Completed trips saved automatically on End Trip
- Displayed under **Recent Trips** on the dashboard
- Shows destination, date/time, and status pill (Done / Active / Cancelled)
- Capped at 20 entries, most recent first

### Location Tracking
- Permission requested gracefully — denied permission is handled without crashing
- Displays GPS status: "Location tracked" / "Location unavailable" / "Getting location…"
- Shows distance travelled from trip start
- Location refreshed every 60 seconds during active trip

---

## Screens

| Screen | Route | Purpose |
|---|---|---|
| Splash | `/` | Brand entry, session-aware routing |
| Registration | `/register` | Two-step account creation |
| Login | `/login` | Returning user sign-in |
| Home | `/home` | Dynamic dashboard |
| Trusted Person | `/trusted-person` | View and edit trusted contact |
| Profile | `/profile` | Account summary and logout |
| Trip Setup | `/trip-setup` | ★ Destination + duration form |
| Active Trip | `/active-trip` | ★ Live monitoring screen |
| Emergency | `/emergency` | ★ Contact trusted person |

### Navigation flow

```
App launch → Splash (1.8 s)
  ├── logged in             → /home
  ├── registered, not in    → /login
  └── no account            → /register

Home (no trip) → /trip-setup → start trip → pop → /active-trip
Home (active)  → /active-trip
Active Trip    → End Trip → pop → Home reloads (SAFE state)
Active Trip    → Need Help → /emergency
```

---

## Architecture

### Layer diagram

```
Screens
   │
   ├──▶ AuthService   ──▶ StorageService ──▶ SharedPreferences (user/auth keys)
   │
   └──▶ TripService   ──────────────────▶ SharedPreferences (ts_ trip keys)
   │
   └──▶ LocationService ─▶ Geolocator (device GPS)
              ▲
        ServiceLocator (global singletons)
```

### Key architectural decisions

- **`StorageService`** owns `su_` prefixed keys (user auth data only)
- **`TripService`** owns `ts_` prefixed keys (trip data only) — separate domain, no coupling
- **`LocationService`** wraps geolocator with try/catch at every boundary — GPS failure never crashes the app
- All `ServiceLocator` singletons are plain Dart objects — no framework overhead

### Models

```
UserModel
  ├── name, phone, passwordHash
  └── trustedPerson: TrustedPersonModel { name, phone, relationship }

TripModel
  ├── id (epoch ms string)
  ├── destination (user-entered text)
  ├── durationMinutes
  ├── startTime, endTime?
  ├── status: active | completed | cancelled
  └── computed: isDelayed, remainingMinutes, elapsed
```

---

## Design System

### Brand palette

| Token | Hex | Usage |
|---|---|---|
| `primaryNavy` | `#1B3A6B` | Primary actions, labels, focus rings |
| `backgroundBlue` | `#F5F7FB` | Scaffold / page background |
| `surfaceWhite` | `#FFFFFF` | Cards, input fields |
| `charcoal` | `#1C2536` | Primary body text |
| `mutedGray` | `#64748B` | Secondary / hint text |
| `borderLight` | `#E2E8F0` | Borders and dividers |
| `safeColor` | `#166534` | SAFE text |
| `safeIcon` | `#16A34A` | SAFE indicator dot |
| `safeContainer` | `#F0FDF4` | SAFE background |
| `warningColor` | `#F57F17` | DELAYED status, safety dialog icon |
| `dangerColor` | `#C62828` | Emergency screen, Need Help button |

---

## Running the App

### Prerequisites
- Flutter 3.47.0 or later
- Android SDK **or** Windows Developer Mode enabled (for native plugins)

### Run on Chrome (quickest — no setup needed)
```bash
flutter run -d chrome
```
> On Chrome, GPS uses the browser's Geolocation API. Phone calls show the number for manual dialing.

### Run on Android
```bash
flutter run
```

### Run on Windows desktop
Enable Developer Mode first: **Settings → Privacy & Security → Developer Mode → On**
```bash
flutter run -d windows
```

### Hot reload
| Key | Action |
|---|---|
| `r` | Hot reload |
| `R` | Hot restart |
| `q` | Quit |

---

## Running Tests

```bash
flutter analyze   # Static analysis — 0 issues
flutter test      # Unit & widget tests — 8/8 pass
```

### Test suite

| Test File | Test | Verifies |
|---|---|---|
| `widget_test.dart` | Splash screen shows app name | `Travel Safety` title renders |
| `widget_test.dart` | Splash screen shows tagline | Tagline text renders |
| `widget_test.dart` | Splash navigates to registration | Routes to `/register` when no account exists |
| `trip_test.dart` | Serialization and deserialization | `TripModel` `toJson()` and `fromJson()` consistency |
| `trip_test.dart` | Delayed trip calculation | `isDelayed` computed property when start time + duration is exceeded |
| `trip_test.dart` | Completed trip calculation | `elapsed` and status handling for completed trips |
| `trip_test.dart` | Empty trip history handling | `TripService.getHistory()` returns clean empty list |
| `trip_test.dart` | Active trip management | `startTrip()`, `getActiveTrip()`, and `endTrip()` persistence flow |

---

## Verification Status

| Check | Phase 1 | Phase 2 |
|---|---|---|
| `flutter analyze` | ✅ | ✅ No issues |
| `flutter test` | ✅ | ✅ 8/8 passed |
| Login / Registration / Logout | ✅ | ✅ Preserved |
| Trusted person (user-entered phone) | ✅ | ✅ No hardcoded numbers |
| Start Trip enabled | — | ✅ |
| Trip setup (destination + duration) | — | ✅ |
| Active trip live countdown | — | ✅ |
| Delayed trip detection | — | ✅ |
| Safety check dialog | — | ✅ |
| "I'm Safe" / "Need Help" | — | ✅ |
| Emergency screen with confirmation | — | ✅ |
| Phone call (with fallback) | — | ✅ |
| GPS permission handled gracefully | — | ✅ |
| Trip history saved and displayed | — | ✅ |
| Home screen dynamic state | — | ✅ |
| GitHub push | ✅ | ✅ |

---

## Known Limitations

> **⚠️ Password storage — prototype only.**
> Passwords are Base64-encoded before storage. Base64 is encoding, not hashing.
> Replace `AuthService` with proper server-side auth (Firebase Auth, Supabase, bcrypt) before any real deployment.

- **One account per device** — single user in SharedPreferences
- **Destination is text-only** — no geocoding or map route (Phase 3)
- **Background tracking not implemented** — GPS only updates when app is open (Phase 3)
- **No SMS/push alerts** — emergency is a manual phone call (Phase 3)
- **Web phone calls** — `tel:` links don't auto-dial on desktop; phone number is shown for manual dialing

---

## Phase 3 Roadmap

- [ ] Background location tracking (when app is minimised)
- [ ] Google Maps integration — route visualisation and real-time position
- [ ] Geocoding — destination text → coordinates for distance-to-destination
- [ ] Route deviation detection — alert if user strays from expected path
- [ ] SMS alert to trusted person when "Need Help" is pressed
- [ ] Push notifications for delayed trip warnings
- [ ] Multi-account support
- [ ] Proper server-side authentication (replace Base64 prototype)
- [ ] Cloud sync and trip history backup
- [ ] Trip sharing (share live location with trusted person)
