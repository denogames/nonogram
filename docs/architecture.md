# Architecture Specification

## Overview

Nonogram is built using a strict clean architecture with a pure Dart engine decoupled from the Flutter presentation layer, feature-based modularity, and an offline-first data model.

```
lib/
├── core/                         # Cross-cutting foundational infrastructure
│   ├── analytics/                # Event tracking contracts and debug console provider
│   ├── audio/                    # Haptic feedback system
│   ├── monetization/
│   │   ├── ads/                  # AdProvider interface, frequency capper, mock provider
│   │   ├── economy/              # Soft currency (coins, hints, daily streak rewards)
│   │   └── iap/                  # In-app purchase manager with offline entitlement caching
│   ├── providers/                # Global Riverpod dependency injection definitions
│   ├── router/                   # Declarative go_router route hierarchy
│   ├── storage/
│   │   ├── database/             # Drift SQLite database (progress, daily, economy, entitlements)
│   │   └── preferences/          # SharedPreferences wrappers (themes, policies, accessibility)
│   └── theme/                    # Design token palettes (Classic Paper, Midnight, Ocean, High Contrast)
├── engine/                       # Pure Dart Nonogram core (Zero Flutter dependencies)
│   ├── game/                     # Interactive game session (undo/redo, hints, mistake policies)
│   ├── generator/                # Clue calculation and pixel-art puzzle compiler
│   ├── models/                   # Immutable models (GridPoint, CellState, ClueData, PuzzleDefinition)
│   ├── solver/                   # LineSolver (1D deduction) & NonogramSolver (backtracking search)
│   └── validator/                # Quality gate ensuring solvability and uniqueness
└── features/                     # Feature modules (UI Presentation & Riverpod State)
    ├── collections/              # Categorized pack browsing and level selection
    ├── home/                     # Hub screen with daily challenge, continue play, and quick actions
    ├── puzzle_game/              # High-performance CustomPainter board, controls, precision input
    ├── settings/                 # Themes, relax mode, accessibility, and haptics
    ├── shop/                     # Non-consumable ads-free IAP and hint exchange
    ├── statistics/               # Solved totals, best times, star tallies, and streaks
    └── tutorial/                 # Illustrated interactive guide with practice level
```

---

## Pure Dart Puzzle Engine

The engine is located under `lib/engine` and contains zero references to Flutter widgets, BuildContext, or platform channels.

### 1. Data Representation
- **`CellState`**: Represents cell condition (`empty`, `filled`, `crossed`).
- **`GridPoint`**: 2D coordinate on the grid `(row, col)`.
- **`ClueData`**: Immutable collection of row and column clue number lists. Clues with no filled cells are normalized as empty lists or `[0]`.
- **`PuzzleDefinition`**: Immutable versioned puzzle model with title, category, dimensions, clues, encoded binary solution string (`'0'` and `'1'`), difficulty tier, color palette for reveal animations, and a SHA-256 integrity checksum.

### 2. Dual-Phase Nonogram Solver
- **Phase 1: Line-by-Line Deduction (`LineSolver`)**
  - Solves individual rows and columns in isolation using constraints on available spaces and clues.
  - Computes overlapping intersections: if a cell is filled in 100% of all valid placements, it is marked as `filled`. If crossed in 100%, marked as `crossed`.
  - Propagates newly deduced constraints across intersecting rows and columns until a fixed point is reached.
- **Phase 2: Branching Backtracking Search (`NonogramSolver`)**
  - If undetermined cells remain, the solver branches on the most constrained candidate cell.
  - Counts solutions up to a configurable cap (default 2).
  - Puzzles yielding 0 solutions (contradictory) or $\ge 2$ solutions (ambiguous) are rejected.
  - Evaluates difficulty rating based on sweep counts, deduction volume, and branching depth.

### 3. Runtime Engine (`PuzzleEngine`)
- Manages player board state, drag strokes, undo/redo history stacks, elapsed timer, and hints.
- **Move History**: Compound gesture moves are stored as batches, allowing multi-cell drag strokes to be undone and redone in a single click.
- **Hint Engine**: Locates player mistakes and repairs them first; otherwise reveals a logically deduced cell from the solution. Hints never contradict the solution.
- **Mistake Policies**: Configurable between **Strict Mode** (error strikes with 3-mistake limit) and **Relax Mode** (quiet solving at player's own pace with no game-over pressure).

---

## Persistence Architecture (Drift SQLite)

Offline-first local storage is provided by **Drift** (`lib/core/storage/database/app_database.dart`):

1. **`PuzzleProgressEntries`**:
   - `puzzleId` (PK)
   - `isCompleted`, `stars` (1-3 stars), `bestTimeSeconds`
   - `lastPlayed` timestamp
   - `savedBoardState` (compact encoded string allowing seamless resume of in-progress games)
   - `savedMistakes`, `savedHintsUsed`, `savedElapsedSeconds`

2. **`DailyPuzzleEntries`**:
   - `dateKey` (PK, e.g. `'2026-10-09'`)
   - `puzzleId`, `isCompleted`, `timeSeconds`, `completedAt`

3. **`PlayerEconomyEntries`**:
   - `coins`, `hintsRemaining`, `streakDays`, `lastDailyRewardDate`

4. **`EntitlementEntries`**:
   - `entitlementId` (PK, e.g. `'ads_free'`), `isActive`, `source`, `acquiredAt`, `signature`

---

## State Management & Navigation

- **Riverpod**: Used for dependency injection and state management. Top-level Singletons (database, preferences, repositories, monetization managers) are injected into the container root and overridden cleanly in unit/widget tests.
- **go_router**: Declarative router supporting clean parameter passing for puzzle IDs, category detail browsing, and deep links.
