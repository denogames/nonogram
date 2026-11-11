# Content Format & Validation Pipeline

## JSON Schema Specification

Puzzles are stored as versioned JSON definitions. Each level contains metadata, board dimensions, row/column hints, encoded pixel solution, difficulty rating, reveal color palette, and a SHA-256 integrity checksum.

```json
{
  "puzzleId": "cat_5x5",
  "revision": 1,
  "title": "Cat",
  "category": "animals",
  "categoryTitles": {
    "en": "Animals"
  },
  "width": 5,
  "height": 5,
  "rowHints": [
    [1, 1],
    [5],
    [2, 2],
    [3],
    [1]
  ],
  "columnHints": [
    [3],
    [4],
    [2, 1],
    [4],
    [3]
  ],
  "encodedSolution": "1000111111110110111000100",
  "difficulty": "easy",
  "contentVersion": 1,
  "publicationStatus": "published",
  "author": "Antigravity Studio",
  "license": "Proprietary",
  "tags": ["starter", "easy", "cat"],
  "checksum": "f4ca18a7c1341ba07c0a9fc6c5fe2374e5ce6f9660ca03ef382b6b55850980ff",
  "colorPalette": ["#E67E22", "#D35400"]
}
```

### Field Definitions

| Field | Type | Description |
| :--- | :--- | :--- |
| `puzzleId` | String | Globally unique identifier (e.g. `cat_5x5`, `penguin_10x10`) |
| `revision` | Integer | Incremental revision number for content edits |
| `title` | String | User-facing puzzle title revealed on completion |
| `category` | String | Category slug (`animals`, `nature`, `food`, `objects`, `symbols`) |
| `categoryTitles` | Map | Localized category title mappings |
| `width` | Integer | Grid column count ($5 \le \text{width} \le 25$) |
| `height` | Integer | Grid row count ($5 \le \text{height} \le 25$) |
| `rowHints` | Array<Array<int>> | Clue numbers for each row (top-to-bottom) |
| `columnHints` | Array<Array<int>> | Clue numbers for each column (left-to-right) |
| `encodedSolution` | String | Row-major string of `'1'` (filled) and `'0'` (empty) of length `width * height` |
| `difficulty` | String | One of `"easy"`, `"medium"`, `"hard"`, `"expert"` |
| `contentVersion` | Integer | Format schema version (currently `1`) |
| `publicationStatus` | String | `"published"`, `"draft"`, `"archived"` |
| `tags` | Array<String> | Searchable tags and metadata keywords |
| `checksum` | String | SHA-256 hash of `id:width:height:rowHints:colHints:encodedSolution` |
| `colorPalette` | Array<String> | Hex color strings (`#RRGGBB`) used for reveal animations |

---

## Canonical Checksum Calculation

Integrity is verified by hashing canonical fields:
```dart
final canonical = '$id:$width:$height:${jsonEncode(rowHints)}:${jsonEncode(columnHints)}:$encodedSolution';
final checksum = sha256.convert(utf8.encode(canonical)).toString();
```

If a downloaded pack or bundled file is tampered with or corrupted, `verifyChecksum()` fails and prevents bad content from reaching players.

---

## Content Pipeline CLI Tool

The tool in `bin/content_tool.dart` validates, tests, and builds puzzle packs:

### 1. Validate Existing Packs
```bash
dart run bin/content_tool.dart validate assets/puzzles/animals.json
```
Runs `PuzzleValidator` on each entry:
- Validates dimensions and clue consistency
- Verifies row clue sum equals column clue sum
- Validates solution against clues
- Solves clues with `NonogramSolver` to verify uniqueness (rejects puzzles with multiple solutions)
- Verifies SHA-256 checksum

### 2. Build and Verify Starter Packs
```bash
dart run bin/content_tool.dart build-packs
```
Compiles curated ASCII pixel-art collections into verified JSON files in `assets/puzzles/`.

## Remote content from Content Studio (opt-in, PLATFORM-V1-009)

The game can additionally load published `nonogram` content packs from a studio-core-backend Content
Studio. It is **off by default**; a default build makes no network request for content, creates no
`remote_content` directory and never starts a guest session. Decision: [D-007](decisions.md#d-007--content-studio-uzaktan-içerik-entegrasyonu-opt-in).

Enable it only in a debug or profile build, with explicit build defines (release builds are
always off, [D-008](decisions.md#d-008--üretim-misafir-kimliği-güvenliği-ve-kayıtlı-tahta-uyumu)):

```bash
flutter run \
  --dart-define=NONOGRAM_REMOTE_CONTENT=true \
  --dart-define=NONOGRAM_CONTENT_BACKEND_URL=http://127.0.0.1:3920
```

The game takes **no backend secret**. Guest sign-in and the content reads are not HMAC-verified by
studio-core-backend, so the reader signs with a public constant
(`RemoteContentConfig.contentReaderSigningKey`). Never put the backend's `HMAC_SHARED_SECRET` in a
mobile build: it can be extracted, and it protects sync, purchases, ad rewards and leaderboards for
every game on that backend.

Behaviour when enabled (`lib/core/content/`):

- Before the first frame, cached packs from `<app support>/remote_content/` are registered (disk only).
- After the first frame, one background refresh signs in as a guest (random per-install device id),
  reads `GET /v1/content/packs?content_type=nonogram`, then fetches each listed pack with ETag/304.
  An expired session (401) triggers one fresh sign-in.
- Each entry goes through the same parser as bundled puzzles (`puzzleId` = `content_id`), the checksum
  check and the `PuzzleValidator` quality gate. Malformed, unsolvable, tampered, duplicate or
  conflicting entries are skipped; a bundled puzzle id always wins, and between packs the first wins.
- Remote puzzles appear in Collections under their `category`; they never change the daily puzzle.
- Offline or failed refresh: the last valid cached pack stays; with no cache, only bundled puzzles show.
  A pack the catalog no longer lists is removed from the catalog and its cache is cleared.
- Player progress (`PuzzleProgressEntries`, game-state vault, wallet) is never written or deleted by
  this feature; progress of a withdrawn puzzle stays in the database and returns if it is republished.

Saved boards and content changes:

- An unfinished board is stored as `fp1:<fingerprint>:<cells>`; the fingerprint is the puzzle's
  content checksum (id, size, clues, solution; not the title). It is restored only on the same
  content, so a renamed puzzle keeps the board, a puzzle whose solution changed starts clean.
  Completion, stars, best time and the wallet are separate records and are never changed; the old
  attempt is replaced by the next save, not deleted. Older saves without a fingerprint restore as
  before when their size fits.
- Authoring rule: a materially different picture gets a **new `content_id`**. Reusing an id for a
  different solution is handled safely (no stale marks), but the old completion and stars stay on
  that id, so the new picture would appear already solved.

Live check against a throwaway local backend (temporary PostgreSQL, nothing deployed); the game is
given no backend secret:

```bash
tool/run_remote_content_live.sh /path/to/studio-core-backend
```
