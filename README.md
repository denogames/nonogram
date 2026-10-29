# Nonogram — Production-Ready Flutter Puzzle Game

> **Recovery note — 18–19 October 2026:** The original title, badges, feature guarantees and quality claims below are historical documentation claims, not current execution or release evidence. M0 documents the baseline; application tests, analysis, builds, content validation and installed SDK versions were not verified in this recovery. See [current status](docs/project_status.md) and [evidence limits](docs/test_report.md).

[![Flutter](https://img.shields.io/badge/Flutter-3.47.5-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13.4-0175C2.svg)](https://dart.dev)
[![Tests](https://img.shields.io/badge/Tests-35%20Passed-success.svg)]()
[![Analyze](https://img.shields.io/badge/Analyze-0%20Issues-brightgreen.svg)]()
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey.svg)]()

A commercially viable, offline-first **Nonogram (Picross)** mobile game engineered for Android and iOS using **Flutter**, **Riverpod**, **go_router**, and **Drift SQLite**. Features responsive touch interactions, guaranteed unique puzzle logic, extensible content generation tooling, diverse themes, and clean IAP/advertising monetization abstractions.

## Project records

- [Project context and canonical document map](docs/project_context.md)
- [Current status, B1–B7 and Continuity Checkpoint](docs/project_status.md)
- [Decisions, execution authorization and delivery acceptance](docs/decisions.md)
- [Repository working principles](AGENTS.md)
- [Roadmap: M0 and Proposed M1](docs/roadmap.md)
- [Historical test report and current document checks](docs/test_report.md)

---

## Highlights & Features

- **Pure Dart Puzzle Engine**: Independent core decoupled from Flutter widgets. Implements 1D line deduction (`LineSolver`), backtracking search (`NonogramSolver`), undo/redo history stacks, mistake policies, and never-contradicting hint generation.
- **Strict Solution Uniqueness**: Every puzzle is verified to have **exactly one** valid logical solution. Ambiguous or unsolvable puzzles are automatically rejected.
- **Mobile-First UX**:
  - High-performance `CustomPainter` grid with major 5×5 line partitions.
  - Active row and column highlights across the board and clue headers.
  - Drag-to-fill with **Bresenham interpolation** (no skipped cells on fast swipes).
  - **Cardinal Axis Lock** on drags to prevent accidental diagonal jitter.
  - Smooth pinch-to-zoom and pan via `InteractiveViewer` for 15×15 grids.
  - Optional **Precision Input Mode** with enlarged row/column touch strips.
  - Tactile haptic feedback on cell toggles and milestone completions.
- **Visual Theming & Celebration**:
  - 4 themes: **Classic Paper**, **Midnight** (OLED dark), **Ocean** (indigo/teal), and **High Contrast** (accessibility).
  - Reveal animations upon solving, showcasing completed pixel art with custom color palettes.
  - Reduced Motion toggle in settings.
- **Gameplay Modes**:
  - **Collections**: Categorized level packs (Animals, Nature, Food, Objects, Symbols) across 5×5, 10×10, and 15×15 boards.
  - **Daily Nonogram**: Deterministic date-based challenge with consecutive streak tracking.
  - **Relax Mode**: Option to solve at your own pace without 3-mistake failure penalties.
  - **Interactive Tutorial**: Visual step-by-step walkthrough covering clue rules, X marks, and overlap deduction.
- **Sustainable Economy & Monetization**:
  - Permanent non-consumable **`ads_free`** IAP with offline cached entitlements and restore purchases.
  - Non-intrusive interstitial ads (capped by duration and puzzle frequency; never during gameplay).
  - Optional rewarded ads to earn bonus hints or coins.
  - Daily login rewards with streak multipliers.
- **Developer & Content Tooling**:
  - Built-in CLI tool (`bin/content_tool.dart`) for compiling and validating puzzle packs.
  - 20 starter curated pixel-art puzzles with SHA-256 integrity checksums.

---

## Architecture Overview

```
lib/
├── core/                         # Cross-cutting foundational services
│   ├── analytics/                # Structured event logging
│   ├── audio/                    # Haptic feedback system
│   ├── monetization/             # Ads, IAP, and Player Economy
│   ├── providers/                # Riverpod dependency injection
│   ├── router/                   # go_router declarative routes
│   ├── storage/                  # Drift SQLite database & SharedPreferences
│   └── theme/                    # 4 distinct visual theme palettes
├── engine/                       # Pure Dart Nonogram Engine (Zero Flutter dependencies)
│   ├── game/                     # Interactive session runtime, undo/redo, hints
│   ├── generator/                # Clue extraction and puzzle compilation
│   ├── models/                   # Immutable domain models (GridPoint, CellState, ClueData)
│   ├── solver/                   # 1D line solver & backtracking uniqueness verifier
│   └── validator/                # Solvability and SHA-256 integrity checker
└── features/                     # Feature modules (UI Presentation & Riverpod State)
    ├── collections/              # Categorized pack browsing and level selection
    ├── home/                     # Hub screen with daily challenge & quick actions
    ├── puzzle_game/              # Interactive board, control bar, and victory dialog
    ├── settings/                 # Themes, relax mode, accessibility, and haptics
    ├── shop/                     # Non-consumable ads-free IAP & hint exchange
    ├── statistics/               # Solved totals, best times, star tallies, and streaks
    └── tutorial/                 # Illustrated interactive guide with practice level
```

For the existing technical design, see [docs/architecture.md](docs/architecture.md). Design statements are not runtime verification; open differences are recorded in the project status.

---

## Getting Started

### Prerequisites

The prerequisites below are historical guidance, not an inventory of the installed environment. [pubspec.yaml](pubspec.yaml) currently declares Dart `^3.13.4`; the installed Flutter/Dart SDK was not checked. The setup, execution and content-tool examples below were not run during M0.

- Flutter SDK `^3.47.0` (Dart `^3.13.0`)
- Android Studio / Xcode for device deployment

### Installation & Execution

```bash
# Clone and enter directory
cd nonogram

# Install dependencies
flutter pub get

# Generate Drift database code (already committed)
dart run build_runner build

# Run automated test suite
flutter test

# Run application on connected device or simulator
flutter run
```

---

## Content Tool CLI

A command-line tool is included for content creation and quality validation:

```bash
# Validate an existing pack (schema, checksum, solution uniqueness)
dart run bin/content_tool.dart validate assets/puzzles/animals.json

# Compile and verify starter collections
dart run bin/content_tool.dart build-packs
```

For schema details, see [docs/content_format.md](docs/content_format.md).

---

## Monetization Setup

- **In-App Purchase**: Non-consumable product `com.antigravity.nonogram.ads_free`.
- **Offline Entitlement Cache**: Verified purchases are recorded into SQLite (`EntitlementEntries`) to ensure lifetime access without requiring continuous network connectivity.
- **Store Setup Instructions**: Existing design and setup guidance is documented in [docs/monetization.md](docs/monetization.md). Store setup and production integration were not verified during M0; see B1/B2/B6 in the project status.

---

## Automated Test Suite

Static inspection found 35 test declarations across eight Dart files. The historical pass claims are preserved in the test report; no test was run during M0, and the existing tests do not prove all startup, process-persistence or device behaviors:

```bash
flutter test
```

- **Line Solver (`test/engine/line_solver_test.dart`)**: Overlap deduction, line boundaries, contradiction detection.
- **Solver & Uniqueness (`test/engine/solver_test.dart`)**: 5×5, 10×10, ambiguous puzzle rejection, quality gate validation.
- **Engine Session (`test/engine/puzzle_engine_test.dart`)**: Tool actions, undo/redo, hints, mistake policies, serialization.
- **Touch Mapping (`test/interaction/touch_mapping_test.dart`)**: Coordinate conversion and zoom factor scaling.
- **Daily Consistency (`test/daily/daily_consistency_test.dart`)**: Deterministic daily puzzle selection.
- **Database & Offline Storage (`test/storage/database_test.dart`)**: Drift SQLite CRUD, progress, and economy.
- **Entitlements (`test/monetization/entitlement_test.dart`)**: Purchasing, offline session cache, and revocation.
- **Widgets (`test/widget_test.dart`)**: Home screen rendering and control bar interactions.

Historical results, their limits and the scope of current document checks are in [docs/test_report.md](docs/test_report.md).
