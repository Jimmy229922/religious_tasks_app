# Project Structure Map

## Scope

This document is the source-of-truth map for the current repository layout and
the recommended structure for future work.

Included:
- tracked source files
- tracked config files
- tracked platform files
- tracked assets and web files

Excluded on purpose:
- `.dart_tool/`
- `build/`
- `.idea/`
- temporary Flutter log files
- generated Android plugin registrant files

## Current Repository Map

Tracked files only:

```text
religious_tasks_app/
|-- .gitignore
|-- .metadata
|-- CHANGELOG.md
|-- README.md
|-- analysis_options.yaml
|-- pubspec.lock
|-- pubspec.yaml
|-- android/
|   |-- .gitignore
|   |-- build.gradle.kts
|   |-- gradle.properties
|   |-- settings.gradle.kts
|   |-- gradle/
|   |   `-- wrapper/
|   |       `-- gradle-wrapper.properties
|   `-- app/
|       |-- build.gradle.kts
|       `-- src/
|           |-- debug/
|           |   `-- AndroidManifest.xml
|           |-- profile/
|           |   `-- AndroidManifest.xml
|           `-- main/
|               |-- AndroidManifest.xml
|               |-- kotlin/
|               |   `-- com/
|               |       `-- jimmy/
|               |           `-- religiousapp/
|               |               |-- EngineCacheKeys.kt
|               |               |-- LaunchActivity.kt
|               |               `-- MainActivity.kt
|               `-- res/
|                   |-- drawable/
|                   |   |-- background.png
|                   |   |-- launch_background.xml
|                   |   |-- splash_empty.xml
|                   |   `-- splash_gradient.xml
|                   |-- drawable-hdpi/
|                   |   `-- splash.png
|                   |-- drawable-mdpi/
|                   |   `-- splash.png
|                   |-- drawable-v21/
|                   |   |-- background.png
|                   |   `-- launch_background.xml
|                   |-- drawable-xhdpi/
|                   |   `-- splash.png
|                   |-- drawable-xxhdpi/
|                   |   `-- splash.png
|                   |-- drawable-xxxhdpi/
|                   |   `-- splash.png
|                   |-- layout/
|                   |   `-- activity_launch.xml
|                   |-- mipmap-hdpi/
|                   |   |-- ic_launcher.png
|                   |   `-- ic_launcher_round.png
|                   |-- mipmap-mdpi/
|                   |   |-- ic_launcher.png
|                   |   `-- ic_launcher_round.png
|                   |-- mipmap-xhdpi/
|                   |   |-- ic_launcher.png
|                   |   `-- ic_launcher_round.png
|                   |-- mipmap-xxhdpi/
|                   |   |-- ic_launcher.png
|                   |   `-- ic_launcher_round.png
|                   |-- mipmap-xxxhdpi/
|                   |   |-- ic_launcher.png
|                   |   `-- ic_launcher_round.png
|                   |-- raw/
|                   |   |-- adhan_asr.mp3
|                   |   |-- adhan_dhuhr.mp3
|                   |   |-- adhan_fajr.mp3
|                   |   |-- adhan_isha.mp3
|                   |   |-- adhan_maghrib.mp3
|                   |   |-- dhikr_chime.wav
|                   |   `-- prayer_reminder.wav
|                   |-- values/
|                   |   |-- colors.xml
|                   |   |-- strings.xml
|                   |   `-- styles.xml
|                   |-- values-night/
|                   |   |-- colors.xml
|                   |   `-- styles.xml
|                   |-- values-night-v31/
|                   |   `-- styles.xml
|                   `-- values-v31/
|                       `-- styles.xml
|-- assets/
|   `-- icon/
|       `-- app_icon.png
|-- lib/
|   |-- main.dart
|   |-- app/
|   |   |-- religious_app.dart
|   |   `-- bootstrap/
|   |       |-- app_startup.dart
|   |       `-- dependency_setup.dart
|   |-- core/
|   |   |-- constants/
|   |   |   |-- app_constants.dart
|   |   |   `-- strings.dart
|   |   |-- services/
|   |   |   |-- ad_service.dart
|   |   |   |-- athkar_tracking_service.dart
|   |   |   |-- audio_service.dart
|   |   |   |-- location_service.dart
|   |   |   |-- notifications_service.dart
|   |   |   `-- storage_service.dart
|   |   |-- theme/
|   |   |   `-- theme_provider.dart
|   |   `-- widgets/
|   |       `-- calendar_explorer_dialog.dart
|   `-- features/
|       |-- athkar/
|       |   |-- data/
|       |   |   `-- athkar_data.dart
|       |   |-- models/
|       |   |   `-- dhikr_item.dart
|       |   |-- providers/
|       |   |   `-- athkar_view_model.dart
|       |   |-- screens/
|       |   |   |-- athkar_details_screen.dart
|       |   |   |-- daily_athkar_screen.dart
|       |   |   |-- halqat_dhikr_screen.dart
|       |   |   |-- prophet_prayers_screen.dart
|       |   |   `-- surah_kahf_screen.dart
|       |   `-- widgets/
|       |       |-- dhikr_card.dart
|       |       |-- daily/
|       |       |   |-- athkar_encouragement_card.dart
|       |       |   |-- athkar_streak_card.dart
|       |       |   `-- daily_athkar_card.dart
|       |       `-- details/
|       |           |-- athkar_controls.dart
|       |           |-- athkar_empty_state.dart
|       |           |-- athkar_focus_navigator.dart
|       |           `-- athkar_header.dart
|       |-- onboarding/
|       |   `-- presentation/
|       |       `-- screens/
|       |           `-- permissions_onboarding_screen.dart
|       |-- qibla/
|       |   `-- screens/
|       |       `-- qibla_screen.dart
|       |-- quran/
|       |   `-- screens/
|       |       `-- khatmah_screen.dart
|       |-- settings/
|       |   `-- screens/
|       |       `-- settings_screen.dart
|       |-- statistics/
|       |   `-- screens/
|       |       `-- statistics_screen.dart
|       |-- tasbeeh/
|       |   |-- providers/
|       |   |   `-- tasbeeh_view_model.dart
|       |   |-- screens/
|       |   |   |-- custom_tasbeeh_screen.dart
|       |   |   `-- guided_tasbeeh_screen.dart
|       |   `-- widgets/
|       |       `-- custom/
|       |           |-- tasbeeh_counter.dart
|       |           |-- tasbeeh_display.dart
|       |           `-- tasbeeh_selector.dart
|       `-- tasks/
|           |-- models/
|           |   `-- task_item.dart
|           |-- providers/
|           |   `-- tasks_view_model.dart
|           |-- screens/
|           |   `-- tasks_screen.dart
|           `-- widgets/
|               |-- clock_dialog.dart
|               |-- daily_inspiration_card.dart
|               |-- header_section.dart
|               |-- motivational_stats_dialog.dart
|               |-- prayer_countdown_card.dart
|               |-- quick_access_section.dart
|               `-- task_item_widget.dart
|-- test/
|   `-- widget_test.dart
`-- web/
    |-- favicon.png
    |-- manifest.json
    `-- icons/
        |-- Icon-192.png
        |-- Icon-512.png
        |-- Icon-maskable-192.png
        `-- Icon-maskable-512.png
```

## What Each Top-Level Area Owns

| Area | Current responsibility |
| --- | --- |
| `lib/main.dart` | minimal entrypoint that delegates startup and provider wiring |
| `lib/app/` | app shell, bootstrap, and root theme wiring |
| `lib/core/` | shared constants, services, theme, and reusable widgets |
| `lib/features/` | feature-first UI modules |
| `android/` | Android launch flow, resources, notification sounds, Gradle config |
| `assets/` | Flutter-managed assets only |
| `web/` | web/PWA manifest and icons |
| `test/` | widget tests |

## Feature Ownership Map

### `features/tasks`

Current responsibility:
- main home dashboard
- daily tasks state
- prayer times
- location refresh
- random inspiration and banners
- progress and quick actions

Current pressure points:
- `tasks_view_model.dart` is the biggest state file in the project and mixes
  UI state, persistence, prayer logic, location logic, streak logic, random
  content, and pseudo-weather content
- `tasks_screen.dart` still contains navigation rules and feature branching

### `features/athkar`

Current responsibility:
- daily athkar data
- athkar progress state
- detail screens and cards
- Prophet prayers and Surah Al-Kahf related screens

Current pressure points:
- static seed data and UI state live close together
- `athkar` already has the strongest feature-local structure and should become
  the template for the rest of the app

### `features/tasbeeh`

Current responsibility:
- tasbeeh flow
- counter widgets
- one dedicated view model

Current pressure points:
- feature is lightweight and clean, but naming should match the same structure
  used by the other features

### `features/onboarding`

Current responsibility:
- first-run permission onboarding
- startup permission explanation flow

Current pressure points:
- still depends directly on `TasksScreen` navigation after completion
- should later navigate through app routing/bootstrap instead of direct screen
  construction

### `features/qibla`

Current responsibility:
- one screen only

Current pressure points:
- if this feature grows, it will need its own widgets and state folders

### `features/quran`

Current responsibility:
- one screen for Khatmah progress

Current pressure points:
- currently underspecified as a module
- should either remain a simple feature or be expanded into a full feature
  folder with state and widgets

### `features/settings`

Current responsibility:
- settings screen

Current pressure points:
- settings still reads and writes some preferences directly instead of going
  through a dedicated settings state/service

### `features/statistics`

Current responsibility:
- one statistics screen

Current pressure points:
- same growth risk as `qibla` and `quran`

## Shared Infrastructure Map

### `core/constants`

Current files:
- `app_constants.dart`
- `strings.dart`

Current issue:
- naming and responsibility are mixed
- `kAppName` and `AppStrings.appName` do not represent a clean single source
  of truth

Recommendation:
- keep brand/app identity in one file
- split UI strings by domain later if string volume grows

### `core/services`

Current files:
- `ad_service.dart`
- `athkar_tracking_service.dart`
- `audio_service.dart`
- `location_service.dart`
- `notifications_service.dart`
- `storage_service.dart`

Current issue:
- these are not all "core" in the same sense
- they are cross-feature infrastructure services and should be treated as
  shared platform/application services

Recommendation:
- move them later into a `shared/services/` or `app/services/` area
- keep `core/` for framework-level shared UI and constants

### `core/widgets`

Current files:
- `calendar_explorer_dialog.dart`

Current issue:
- only one shared widget exists
- this is fine, but `core/widgets` should remain reserved for truly reusable,
  feature-agnostic UI only

## Android Structure Map

The Android folder is now carrying three different responsibilities:

1. Flutter host activities
2. launch/splash resources
3. notification audio resources

Current notes:
- `LaunchActivity.kt` owns the native launch screen and engine prewarm
- `MainActivity.kt` owns the Flutter host activity
- `res/raw/` is correct for Android notification sounds
- `res/drawable*` and `res/layout/` currently mix launch assets and general
  image assets

Recommendation:
- keep notification sounds in `res/raw/`
- keep launcher icons in `mipmap*`
- keep launch-only assets documented as launch assets
- if future in-app media is needed, store it in Flutter `assets/` instead of
  Android `raw/`

## Structural Issues Blocking Long-Term Maintainability

1. `lib/features/tasks/providers/tasks_view_model.dart`
   owns too many responsibilities and will keep growing in multiple directions.

2. `lib/core/services/notifications_service.dart`
   owns initialization, channel migration, timezone setup, prayer schedules,
   athkar schedules, content generation, and test notifications in one class.

3. `lib/features/tasks/screens/tasks_screen.dart`
   still contains routing decisions and cross-feature behavior instead of only
   composing UI.

4. `lib/core/constants/app_constants.dart` and
   `lib/core/constants/strings.dart`
   overlap in responsibility and create duplication risk.

5. `test/widget_test.dart`
   should remain focused on shell-level smoke coverage until more application
   services are isolated for testing.

6. `android/app/src/main/kotlin/com/example/religious_tasks_app/`
   still exists as an empty/legacy package directory in the workspace even
   though the tracked app code now lives under `com/jimmy/religiousapp/`.

7. settings, onboarding, and startup responsibilities are cleaner now, but
   routing still lives partly inside widgets instead of a dedicated app routing
   layer.

## Recommended Target Structure

This is the pragmatic target for the next phase. It keeps the current
Provider/ViewModel approach, but makes responsibilities obvious.

```text
lib/
|-- main.dart
|-- app/
|   |-- bootstrap/
|   |   |-- app_startup.dart
|   |   `-- dependency_setup.dart
|   |-- routing/
|   |   `-- app_router.dart
|   `-- religious_app.dart
|-- core/
|   |-- constants/
|   |-- theme/
|   `-- widgets/
|-- shared/
|   |-- services/
|   |   |-- ads/
|   |   |   `-- ad_service.dart
|   |   |-- audio/
|   |   |   `-- audio_service.dart
|   |   |-- location/
|   |   |   `-- location_service.dart
|   |   |-- notifications/
|   |   |   `-- notifications_service.dart
|   |   `-- storage/
|   |       `-- storage_service.dart
|   `-- utils/
`-- features/
    |-- onboarding/
    |   `-- presentation/
    |       `-- screens/
    |           `-- permissions_onboarding_screen.dart
    |-- tasks/
    |   |-- application/
    |   |   `-- tasks_view_model.dart
    |   |-- data/
    |   |   |-- models/
    |   |   |   `-- task_item.dart
    |   |   |-- local/
    |   |   |   `-- tasks_local_source.dart
    |   |   `-- mappers/
    |   `-- presentation/
    |       |-- screens/
    |       |   `-- tasks_screen.dart
    |       `-- widgets/
    |           |-- header_section.dart
    |           |-- prayer_countdown_card.dart
    |           `-- ...
    |-- athkar/
    |   |-- application/
    |   |   `-- athkar_view_model.dart
    |   |-- data/
    |   |   |-- models/
    |   |   |   `-- dhikr_item.dart
    |   |   `-- seeds/
    |   |       `-- athkar_data.dart
    |   `-- presentation/
    |       |-- screens/
    |       `-- widgets/
    |-- tasbeeh/
    |   |-- application/
    |   |   `-- tasbeeh_view_model.dart
    |   `-- presentation/
    |       |-- screens/
    |       `-- widgets/
    |-- qibla/
    |   `-- presentation/
    |       `-- screens/
    |           `-- qibla_screen.dart
    |-- quran/
    |   `-- presentation/
    |       `-- screens/
    |           `-- khatmah_screen.dart
    |-- statistics/
    |   `-- presentation/
    |       `-- screens/
    |           `-- statistics_screen.dart
    `-- settings/
        `-- presentation/
            `-- screens/
                `-- settings_screen.dart
```

## Placement Rules For Future Files

1. A screen file may compose widgets and trigger navigation, but heavy business
   logic must not stay inside the screen.

2. A feature view model may orchestrate state, but persistence, prayer-time
   calculation, and notification scheduling should be delegated into smaller
   services or sources.

3. Static data belongs in `data/` and not inside large view model files.

4. A feature that has more than one screen should always get:
   `application/`, `data/`, and `presentation/`.

5. Feature widgets must stay inside the owning feature unless they are reused
   by at least two different features.

6. `core/` should stay small and stable:
   constants, theme, shared UI primitives.

7. Shared infrastructure belongs in `shared/services/` and not mixed with UI
   concerns.

8. Android `res/raw/` should stay reserved for notification and platform audio
   resources.

9. Flutter visual/media assets should live under `assets/` and be declared in
   `pubspec.yaml`.

10. Every feature should gain matching tests under `test/features/...` once the
    folder structure is normalized.

## Suggested Migration Order

### Phase 1: zero-risk structure cleanup

- completed:
- create `docs/`
- update `README.md`
- fix `test/widget_test.dart`
- move onboarding out of `features/settings`
- remove legacy `features/splash`

### Phase 2: startup and shared infrastructure cleanup

- completed:
- extract app startup helpers from `main.dart`
- move provider wiring into `app/bootstrap/dependency_setup.dart`

- next:
- introduce `shared/services/`

### Phase 3: split the heaviest modules

- split `tasks_view_model.dart` into:
  - task persistence
  - prayer timing
  - location refresh
  - daily content
- split `notifications_service.dart` into:
  - initialization
  - channel management
  - prayer scheduler
  - athkar scheduler

### Phase 4: normalize all features

- migrate each feature to:
  - `application/`
  - `data/`
  - `presentation/`
- keep naming consistent across the entire codebase

## Immediate Next Moves

If you want the actual reorganization to start, the safest order is:

1. create the new folder skeleton without moving runtime code yet
2. move onboarding and splash-related files first
3. split tasks and notifications modules
4. update tests and docs after each move

This keeps refactors controlled and reduces the chance of breaking startup.
