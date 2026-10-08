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
