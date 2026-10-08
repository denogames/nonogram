// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PuzzleProgressEntriesTable extends PuzzleProgressEntries
    with TableInfo<$PuzzleProgressEntriesTable, PuzzleProgressEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PuzzleProgressEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _puzzleIdMeta = const VerificationMeta(
    'puzzleId',
  );
  @override
  late final GeneratedColumn<String> puzzleId = GeneratedColumn<String>(
    'puzzle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _starsMeta = const VerificationMeta('stars');
  @override
  late final GeneratedColumn<int> stars = GeneratedColumn<int>(
    'stars',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _bestTimeSecondsMeta = const VerificationMeta(
    'bestTimeSeconds',
  );
  @override
  late final GeneratedColumn<int> bestTimeSeconds = GeneratedColumn<int>(
    'best_time_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastPlayedMeta = const VerificationMeta(
    'lastPlayed',
  );
  @override
  late final GeneratedColumn<DateTime> lastPlayed = GeneratedColumn<DateTime>(
    'last_played',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _savedBoardStateMeta = const VerificationMeta(
    'savedBoardState',
  );
  @override
  late final GeneratedColumn<String> savedBoardState = GeneratedColumn<String>(
    'saved_board_state',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _savedMistakesMeta = const VerificationMeta(
    'savedMistakes',
  );
  @override
  late final GeneratedColumn<int> savedMistakes = GeneratedColumn<int>(
    'saved_mistakes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _savedHintsUsedMeta = const VerificationMeta(
    'savedHintsUsed',
  );
  @override
  late final GeneratedColumn<int> savedHintsUsed = GeneratedColumn<int>(
    'saved_hints_used',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _savedElapsedSecondsMeta =
      const VerificationMeta('savedElapsedSeconds');
  @override
  late final GeneratedColumn<int> savedElapsedSeconds = GeneratedColumn<int>(
    'saved_elapsed_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    puzzleId,
    isCompleted,
    stars,
    bestTimeSeconds,
    lastPlayed,
    savedBoardState,
    savedMistakes,
    savedHintsUsed,
    savedElapsedSeconds,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'puzzle_progress_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<PuzzleProgressEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('puzzle_id')) {
      context.handle(
        _puzzleIdMeta,
        puzzleId.isAcceptableOrUnknown(data['puzzle_id']!, _puzzleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_puzzleIdMeta);
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('stars')) {
      context.handle(
        _starsMeta,
        stars.isAcceptableOrUnknown(data['stars']!, _starsMeta),
      );
    }
    if (data.containsKey('best_time_seconds')) {
      context.handle(
        _bestTimeSecondsMeta,
        bestTimeSeconds.isAcceptableOrUnknown(
          data['best_time_seconds']!,
          _bestTimeSecondsMeta,
        ),
      );
    }
    if (data.containsKey('last_played')) {
      context.handle(
        _lastPlayedMeta,
        lastPlayed.isAcceptableOrUnknown(data['last_played']!, _lastPlayedMeta),
      );
    } else if (isInserting) {
      context.missing(_lastPlayedMeta);
    }
    if (data.containsKey('saved_board_state')) {
      context.handle(
        _savedBoardStateMeta,
        savedBoardState.isAcceptableOrUnknown(
          data['saved_board_state']!,
          _savedBoardStateMeta,
        ),
      );
    }
    if (data.containsKey('saved_mistakes')) {
      context.handle(
        _savedMistakesMeta,
        savedMistakes.isAcceptableOrUnknown(
          data['saved_mistakes']!,
          _savedMistakesMeta,
        ),
      );
    }
    if (data.containsKey('saved_hints_used')) {
      context.handle(
        _savedHintsUsedMeta,
        savedHintsUsed.isAcceptableOrUnknown(
          data['saved_hints_used']!,
          _savedHintsUsedMeta,
        ),
      );
    }
    if (data.containsKey('saved_elapsed_seconds')) {
      context.handle(
        _savedElapsedSecondsMeta,
        savedElapsedSeconds.isAcceptableOrUnknown(
          data['saved_elapsed_seconds']!,
          _savedElapsedSecondsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {puzzleId};
  @override
  PuzzleProgressEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PuzzleProgressEntry(
      puzzleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}puzzle_id'],
      )!,
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      stars: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stars'],
      )!,
      bestTimeSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}best_time_seconds'],
      )!,
      lastPlayed: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_played'],
      )!,
      savedBoardState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}saved_board_state'],
      ),
      savedMistakes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}saved_mistakes'],
      )!,
      savedHintsUsed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}saved_hints_used'],
      )!,
      savedElapsedSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}saved_elapsed_seconds'],
      )!,
    );
  }

  @override
  $PuzzleProgressEntriesTable createAlias(String alias) {
    return $PuzzleProgressEntriesTable(attachedDatabase, alias);
  }
}

class PuzzleProgressEntry extends DataClass
    implements Insertable<PuzzleProgressEntry> {
  final String puzzleId;
  final bool isCompleted;
  final int stars;
  final int bestTimeSeconds;
  final DateTime lastPlayed;
  final String? savedBoardState;
  final int savedMistakes;
  final int savedHintsUsed;
  final int savedElapsedSeconds;
  const PuzzleProgressEntry({
    required this.puzzleId,
    required this.isCompleted,
    required this.stars,
    required this.bestTimeSeconds,
    required this.lastPlayed,
    this.savedBoardState,
    required this.savedMistakes,
    required this.savedHintsUsed,
    required this.savedElapsedSeconds,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['puzzle_id'] = Variable<String>(puzzleId);
    map['is_completed'] = Variable<bool>(isCompleted);
    map['stars'] = Variable<int>(stars);
    map['best_time_seconds'] = Variable<int>(bestTimeSeconds);
    map['last_played'] = Variable<DateTime>(lastPlayed);
    if (!nullToAbsent || savedBoardState != null) {
      map['saved_board_state'] = Variable<String>(savedBoardState);
    }
    map['saved_mistakes'] = Variable<int>(savedMistakes);
    map['saved_hints_used'] = Variable<int>(savedHintsUsed);
    map['saved_elapsed_seconds'] = Variable<int>(savedElapsedSeconds);
    return map;
  }

  PuzzleProgressEntriesCompanion toCompanion(bool nullToAbsent) {
    return PuzzleProgressEntriesCompanion(
      puzzleId: Value(puzzleId),
      isCompleted: Value(isCompleted),
      stars: Value(stars),
      bestTimeSeconds: Value(bestTimeSeconds),
      lastPlayed: Value(lastPlayed),
      savedBoardState: savedBoardState == null && nullToAbsent
          ? const Value.absent()
          : Value(savedBoardState),
      savedMistakes: Value(savedMistakes),
      savedHintsUsed: Value(savedHintsUsed),
      savedElapsedSeconds: Value(savedElapsedSeconds),
    );
  }

  factory PuzzleProgressEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PuzzleProgressEntry(
      puzzleId: serializer.fromJson<String>(json['puzzleId']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      stars: serializer.fromJson<int>(json['stars']),
      bestTimeSeconds: serializer.fromJson<int>(json['bestTimeSeconds']),
      lastPlayed: serializer.fromJson<DateTime>(json['lastPlayed']),
      savedBoardState: serializer.fromJson<String?>(json['savedBoardState']),
      savedMistakes: serializer.fromJson<int>(json['savedMistakes']),
      savedHintsUsed: serializer.fromJson<int>(json['savedHintsUsed']),
      savedElapsedSeconds: serializer.fromJson<int>(
        json['savedElapsedSeconds'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'puzzleId': serializer.toJson<String>(puzzleId),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'stars': serializer.toJson<int>(stars),
      'bestTimeSeconds': serializer.toJson<int>(bestTimeSeconds),
      'lastPlayed': serializer.toJson<DateTime>(lastPlayed),
      'savedBoardState': serializer.toJson<String?>(savedBoardState),
      'savedMistakes': serializer.toJson<int>(savedMistakes),
      'savedHintsUsed': serializer.toJson<int>(savedHintsUsed),
      'savedElapsedSeconds': serializer.toJson<int>(savedElapsedSeconds),
    };
  }

  PuzzleProgressEntry copyWith({
    String? puzzleId,
    bool? isCompleted,
    int? stars,
    int? bestTimeSeconds,
    DateTime? lastPlayed,
    Value<String?> savedBoardState = const Value.absent(),
    int? savedMistakes,
    int? savedHintsUsed,
    int? savedElapsedSeconds,
  }) => PuzzleProgressEntry(
    puzzleId: puzzleId ?? this.puzzleId,
    isCompleted: isCompleted ?? this.isCompleted,
    stars: stars ?? this.stars,
    bestTimeSeconds: bestTimeSeconds ?? this.bestTimeSeconds,
    lastPlayed: lastPlayed ?? this.lastPlayed,
    savedBoardState: savedBoardState.present
        ? savedBoardState.value
        : this.savedBoardState,
    savedMistakes: savedMistakes ?? this.savedMistakes,
    savedHintsUsed: savedHintsUsed ?? this.savedHintsUsed,
    savedElapsedSeconds: savedElapsedSeconds ?? this.savedElapsedSeconds,
  );
  PuzzleProgressEntry copyWithCompanion(PuzzleProgressEntriesCompanion data) {
    return PuzzleProgressEntry(
      puzzleId: data.puzzleId.present ? data.puzzleId.value : this.puzzleId,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      stars: data.stars.present ? data.stars.value : this.stars,
      bestTimeSeconds: data.bestTimeSeconds.present
          ? data.bestTimeSeconds.value
          : this.bestTimeSeconds,
      lastPlayed: data.lastPlayed.present
          ? data.lastPlayed.value
          : this.lastPlayed,
      savedBoardState: data.savedBoardState.present
          ? data.savedBoardState.value
          : this.savedBoardState,
      savedMistakes: data.savedMistakes.present
          ? data.savedMistakes.value
          : this.savedMistakes,
      savedHintsUsed: data.savedHintsUsed.present
          ? data.savedHintsUsed.value
          : this.savedHintsUsed,
      savedElapsedSeconds: data.savedElapsedSeconds.present
          ? data.savedElapsedSeconds.value
          : this.savedElapsedSeconds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PuzzleProgressEntry(')
          ..write('puzzleId: $puzzleId, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('stars: $stars, ')
          ..write('bestTimeSeconds: $bestTimeSeconds, ')
          ..write('lastPlayed: $lastPlayed, ')
          ..write('savedBoardState: $savedBoardState, ')
          ..write('savedMistakes: $savedMistakes, ')
          ..write('savedHintsUsed: $savedHintsUsed, ')
          ..write('savedElapsedSeconds: $savedElapsedSeconds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    puzzleId,
    isCompleted,
    stars,
    bestTimeSeconds,
    lastPlayed,
    savedBoardState,
    savedMistakes,
    savedHintsUsed,
    savedElapsedSeconds,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PuzzleProgressEntry &&
          other.puzzleId == this.puzzleId &&
          other.isCompleted == this.isCompleted &&
          other.stars == this.stars &&
          other.bestTimeSeconds == this.bestTimeSeconds &&
          other.lastPlayed == this.lastPlayed &&
          other.savedBoardState == this.savedBoardState &&
          other.savedMistakes == this.savedMistakes &&
          other.savedHintsUsed == this.savedHintsUsed &&
          other.savedElapsedSeconds == this.savedElapsedSeconds);
}

class PuzzleProgressEntriesCompanion
    extends UpdateCompanion<PuzzleProgressEntry> {
  final Value<String> puzzleId;
  final Value<bool> isCompleted;
  final Value<int> stars;
  final Value<int> bestTimeSeconds;
  final Value<DateTime> lastPlayed;
  final Value<String?> savedBoardState;
  final Value<int> savedMistakes;
  final Value<int> savedHintsUsed;
  final Value<int> savedElapsedSeconds;
  final Value<int> rowid;
  const PuzzleProgressEntriesCompanion({
    this.puzzleId = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.stars = const Value.absent(),
    this.bestTimeSeconds = const Value.absent(),
    this.lastPlayed = const Value.absent(),
    this.savedBoardState = const Value.absent(),
    this.savedMistakes = const Value.absent(),
    this.savedHintsUsed = const Value.absent(),
    this.savedElapsedSeconds = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PuzzleProgressEntriesCompanion.insert({
    required String puzzleId,
    this.isCompleted = const Value.absent(),
    this.stars = const Value.absent(),
    this.bestTimeSeconds = const Value.absent(),
    required DateTime lastPlayed,
    this.savedBoardState = const Value.absent(),
    this.savedMistakes = const Value.absent(),
    this.savedHintsUsed = const Value.absent(),
    this.savedElapsedSeconds = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : puzzleId = Value(puzzleId),
       lastPlayed = Value(lastPlayed);
  static Insertable<PuzzleProgressEntry> custom({
    Expression<String>? puzzleId,
    Expression<bool>? isCompleted,
    Expression<int>? stars,
    Expression<int>? bestTimeSeconds,
    Expression<DateTime>? lastPlayed,
    Expression<String>? savedBoardState,
    Expression<int>? savedMistakes,
    Expression<int>? savedHintsUsed,
    Expression<int>? savedElapsedSeconds,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (puzzleId != null) 'puzzle_id': puzzleId,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (stars != null) 'stars': stars,
      if (bestTimeSeconds != null) 'best_time_seconds': bestTimeSeconds,
      if (lastPlayed != null) 'last_played': lastPlayed,
      if (savedBoardState != null) 'saved_board_state': savedBoardState,
      if (savedMistakes != null) 'saved_mistakes': savedMistakes,
      if (savedHintsUsed != null) 'saved_hints_used': savedHintsUsed,
      if (savedElapsedSeconds != null)
        'saved_elapsed_seconds': savedElapsedSeconds,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PuzzleProgressEntriesCompanion copyWith({
    Value<String>? puzzleId,
    Value<bool>? isCompleted,
    Value<int>? stars,
    Value<int>? bestTimeSeconds,
    Value<DateTime>? lastPlayed,
    Value<String?>? savedBoardState,
    Value<int>? savedMistakes,
    Value<int>? savedHintsUsed,
    Value<int>? savedElapsedSeconds,
    Value<int>? rowid,
  }) {
    return PuzzleProgressEntriesCompanion(
      puzzleId: puzzleId ?? this.puzzleId,
      isCompleted: isCompleted ?? this.isCompleted,
      stars: stars ?? this.stars,
      bestTimeSeconds: bestTimeSeconds ?? this.bestTimeSeconds,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      savedBoardState: savedBoardState ?? this.savedBoardState,
      savedMistakes: savedMistakes ?? this.savedMistakes,
      savedHintsUsed: savedHintsUsed ?? this.savedHintsUsed,
      savedElapsedSeconds: savedElapsedSeconds ?? this.savedElapsedSeconds,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (puzzleId.present) {
      map['puzzle_id'] = Variable<String>(puzzleId.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (stars.present) {
      map['stars'] = Variable<int>(stars.value);
    }
    if (bestTimeSeconds.present) {
      map['best_time_seconds'] = Variable<int>(bestTimeSeconds.value);
    }
    if (lastPlayed.present) {
      map['last_played'] = Variable<DateTime>(lastPlayed.value);
    }
    if (savedBoardState.present) {
      map['saved_board_state'] = Variable<String>(savedBoardState.value);
    }
    if (savedMistakes.present) {
      map['saved_mistakes'] = Variable<int>(savedMistakes.value);
    }
    if (savedHintsUsed.present) {
      map['saved_hints_used'] = Variable<int>(savedHintsUsed.value);
    }
    if (savedElapsedSeconds.present) {
      map['saved_elapsed_seconds'] = Variable<int>(savedElapsedSeconds.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PuzzleProgressEntriesCompanion(')
          ..write('puzzleId: $puzzleId, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('stars: $stars, ')
          ..write('bestTimeSeconds: $bestTimeSeconds, ')
          ..write('lastPlayed: $lastPlayed, ')
          ..write('savedBoardState: $savedBoardState, ')
          ..write('savedMistakes: $savedMistakes, ')
          ..write('savedHintsUsed: $savedHintsUsed, ')
          ..write('savedElapsedSeconds: $savedElapsedSeconds, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailyPuzzleEntriesTable extends DailyPuzzleEntries
    with TableInfo<$DailyPuzzleEntriesTable, DailyPuzzleEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyPuzzleEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateKeyMeta = const VerificationMeta(
    'dateKey',
  );
  @override
  late final GeneratedColumn<String> dateKey = GeneratedColumn<String>(
    'date_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _puzzleIdMeta = const VerificationMeta(
    'puzzleId',
  );
  @override
  late final GeneratedColumn<String> puzzleId = GeneratedColumn<String>(
    'puzzle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _timeSecondsMeta = const VerificationMeta(
    'timeSeconds',
  );
  @override
  late final GeneratedColumn<int> timeSeconds = GeneratedColumn<int>(
    'time_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    dateKey,
    puzzleId,
    isCompleted,
    timeSeconds,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_puzzle_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyPuzzleEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date_key')) {
      context.handle(
        _dateKeyMeta,
        dateKey.isAcceptableOrUnknown(data['date_key']!, _dateKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_dateKeyMeta);
    }
    if (data.containsKey('puzzle_id')) {
      context.handle(
        _puzzleIdMeta,
        puzzleId.isAcceptableOrUnknown(data['puzzle_id']!, _puzzleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_puzzleIdMeta);
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('time_seconds')) {
      context.handle(
        _timeSecondsMeta,
        timeSeconds.isAcceptableOrUnknown(
          data['time_seconds']!,
          _timeSecondsMeta,
        ),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {dateKey};
  @override
  DailyPuzzleEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyPuzzleEntry(
      dateKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date_key'],
      )!,
      puzzleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}puzzle_id'],
      )!,
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      timeSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_seconds'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
    );
  }

  @override
  $DailyPuzzleEntriesTable createAlias(String alias) {
    return $DailyPuzzleEntriesTable(attachedDatabase, alias);
  }
}

class DailyPuzzleEntry extends DataClass
    implements Insertable<DailyPuzzleEntry> {
  final String dateKey;
  final String puzzleId;
  final bool isCompleted;
  final int timeSeconds;
  final DateTime? completedAt;
  const DailyPuzzleEntry({
    required this.dateKey,
    required this.puzzleId,
    required this.isCompleted,
    required this.timeSeconds,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date_key'] = Variable<String>(dateKey);
    map['puzzle_id'] = Variable<String>(puzzleId);
    map['is_completed'] = Variable<bool>(isCompleted);
    map['time_seconds'] = Variable<int>(timeSeconds);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    return map;
  }

  DailyPuzzleEntriesCompanion toCompanion(bool nullToAbsent) {
    return DailyPuzzleEntriesCompanion(
      dateKey: Value(dateKey),
      puzzleId: Value(puzzleId),
      isCompleted: Value(isCompleted),
      timeSeconds: Value(timeSeconds),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory DailyPuzzleEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyPuzzleEntry(
      dateKey: serializer.fromJson<String>(json['dateKey']),
      puzzleId: serializer.fromJson<String>(json['puzzleId']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      timeSeconds: serializer.fromJson<int>(json['timeSeconds']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'dateKey': serializer.toJson<String>(dateKey),
      'puzzleId': serializer.toJson<String>(puzzleId),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'timeSeconds': serializer.toJson<int>(timeSeconds),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
    };
  }

  DailyPuzzleEntry copyWith({
    String? dateKey,
    String? puzzleId,
    bool? isCompleted,
    int? timeSeconds,
    Value<DateTime?> completedAt = const Value.absent(),
  }) => DailyPuzzleEntry(
    dateKey: dateKey ?? this.dateKey,
    puzzleId: puzzleId ?? this.puzzleId,
    isCompleted: isCompleted ?? this.isCompleted,
    timeSeconds: timeSeconds ?? this.timeSeconds,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  DailyPuzzleEntry copyWithCompanion(DailyPuzzleEntriesCompanion data) {
    return DailyPuzzleEntry(
      dateKey: data.dateKey.present ? data.dateKey.value : this.dateKey,
      puzzleId: data.puzzleId.present ? data.puzzleId.value : this.puzzleId,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      timeSeconds: data.timeSeconds.present
          ? data.timeSeconds.value
          : this.timeSeconds,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyPuzzleEntry(')
          ..write('dateKey: $dateKey, ')
          ..write('puzzleId: $puzzleId, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('timeSeconds: $timeSeconds, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(dateKey, puzzleId, isCompleted, timeSeconds, completedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyPuzzleEntry &&
          other.dateKey == this.dateKey &&
          other.puzzleId == this.puzzleId &&
          other.isCompleted == this.isCompleted &&
          other.timeSeconds == this.timeSeconds &&
          other.completedAt == this.completedAt);
}

class DailyPuzzleEntriesCompanion extends UpdateCompanion<DailyPuzzleEntry> {
  final Value<String> dateKey;
  final Value<String> puzzleId;
  final Value<bool> isCompleted;
  final Value<int> timeSeconds;
  final Value<DateTime?> completedAt;
  final Value<int> rowid;
  const DailyPuzzleEntriesCompanion({
    this.dateKey = const Value.absent(),
    this.puzzleId = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.timeSeconds = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyPuzzleEntriesCompanion.insert({
    required String dateKey,
    required String puzzleId,
    this.isCompleted = const Value.absent(),
    this.timeSeconds = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : dateKey = Value(dateKey),
       puzzleId = Value(puzzleId);
  static Insertable<DailyPuzzleEntry> custom({
    Expression<String>? dateKey,
    Expression<String>? puzzleId,
    Expression<bool>? isCompleted,
    Expression<int>? timeSeconds,
    Expression<DateTime>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (dateKey != null) 'date_key': dateKey,
      if (puzzleId != null) 'puzzle_id': puzzleId,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (timeSeconds != null) 'time_seconds': timeSeconds,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyPuzzleEntriesCompanion copyWith({
    Value<String>? dateKey,
    Value<String>? puzzleId,
    Value<bool>? isCompleted,
    Value<int>? timeSeconds,
    Value<DateTime?>? completedAt,
    Value<int>? rowid,
  }) {
    return DailyPuzzleEntriesCompanion(
      dateKey: dateKey ?? this.dateKey,
      puzzleId: puzzleId ?? this.puzzleId,
      isCompleted: isCompleted ?? this.isCompleted,
      timeSeconds: timeSeconds ?? this.timeSeconds,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (dateKey.present) {
      map['date_key'] = Variable<String>(dateKey.value);
    }
    if (puzzleId.present) {
      map['puzzle_id'] = Variable<String>(puzzleId.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (timeSeconds.present) {
      map['time_seconds'] = Variable<int>(timeSeconds.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyPuzzleEntriesCompanion(')
          ..write('dateKey: $dateKey, ')
          ..write('puzzleId: $puzzleId, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('timeSeconds: $timeSeconds, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlayerEconomyEntriesTable extends PlayerEconomyEntries
    with TableInfo<$PlayerEconomyEntriesTable, PlayerEconomyEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayerEconomyEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coinsMeta = const VerificationMeta('coins');
  @override
  late final GeneratedColumn<int> coins = GeneratedColumn<int>(
    'coins',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(50),
  );
  static const VerificationMeta _hintsRemainingMeta = const VerificationMeta(
    'hintsRemaining',
  );
  @override
  late final GeneratedColumn<int> hintsRemaining = GeneratedColumn<int>(
    'hints_remaining',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(5),
  );
  static const VerificationMeta _lastDailyRewardDateMeta =
      const VerificationMeta('lastDailyRewardDate');
  @override
  late final GeneratedColumn<String> lastDailyRewardDate =
      GeneratedColumn<String>(
        'last_daily_reward_date',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _streakDaysMeta = const VerificationMeta(
    'streakDays',
  );
  @override
  late final GeneratedColumn<int> streakDays = GeneratedColumn<int>(
    'streak_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    coins,
    hintsRemaining,
    lastDailyRewardDate,
    streakDays,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'player_economy_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlayerEconomyEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('coins')) {
      context.handle(
        _coinsMeta,
        coins.isAcceptableOrUnknown(data['coins']!, _coinsMeta),
      );
    }
    if (data.containsKey('hints_remaining')) {
      context.handle(
        _hintsRemainingMeta,
        hintsRemaining.isAcceptableOrUnknown(
          data['hints_remaining']!,
          _hintsRemainingMeta,
        ),
      );
    }
    if (data.containsKey('last_daily_reward_date')) {
      context.handle(
        _lastDailyRewardDateMeta,
        lastDailyRewardDate.isAcceptableOrUnknown(
          data['last_daily_reward_date']!,
          _lastDailyRewardDateMeta,
        ),
      );
    }
    if (data.containsKey('streak_days')) {
      context.handle(
        _streakDaysMeta,
        streakDays.isAcceptableOrUnknown(data['streak_days']!, _streakDaysMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlayerEconomyEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlayerEconomyEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      coins: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}coins'],
      )!,
      hintsRemaining: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hints_remaining'],
      )!,
      lastDailyRewardDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_daily_reward_date'],
      ),
      streakDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}streak_days'],
      )!,
    );
  }

  @override
  $PlayerEconomyEntriesTable createAlias(String alias) {
    return $PlayerEconomyEntriesTable(attachedDatabase, alias);
  }
}

class PlayerEconomyEntry extends DataClass
    implements Insertable<PlayerEconomyEntry> {
  final String id;
  final int coins;
  final int hintsRemaining;
  final String? lastDailyRewardDate;
  final int streakDays;
  const PlayerEconomyEntry({
    required this.id,
    required this.coins,
    required this.hintsRemaining,
    this.lastDailyRewardDate,
    required this.streakDays,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['coins'] = Variable<int>(coins);
    map['hints_remaining'] = Variable<int>(hintsRemaining);
    if (!nullToAbsent || lastDailyRewardDate != null) {
      map['last_daily_reward_date'] = Variable<String>(lastDailyRewardDate);
    }
    map['streak_days'] = Variable<int>(streakDays);
    return map;
  }

  PlayerEconomyEntriesCompanion toCompanion(bool nullToAbsent) {
    return PlayerEconomyEntriesCompanion(
      id: Value(id),
      coins: Value(coins),
      hintsRemaining: Value(hintsRemaining),
      lastDailyRewardDate: lastDailyRewardDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastDailyRewardDate),
      streakDays: Value(streakDays),
    );
  }

  factory PlayerEconomyEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlayerEconomyEntry(
      id: serializer.fromJson<String>(json['id']),
      coins: serializer.fromJson<int>(json['coins']),
      hintsRemaining: serializer.fromJson<int>(json['hintsRemaining']),
      lastDailyRewardDate: serializer.fromJson<String?>(
        json['lastDailyRewardDate'],
      ),
      streakDays: serializer.fromJson<int>(json['streakDays']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'coins': serializer.toJson<int>(coins),
      'hintsRemaining': serializer.toJson<int>(hintsRemaining),
      'lastDailyRewardDate': serializer.toJson<String?>(lastDailyRewardDate),
      'streakDays': serializer.toJson<int>(streakDays),
    };
  }

  PlayerEconomyEntry copyWith({
    String? id,
    int? coins,
    int? hintsRemaining,
    Value<String?> lastDailyRewardDate = const Value.absent(),
    int? streakDays,
  }) => PlayerEconomyEntry(
    id: id ?? this.id,
    coins: coins ?? this.coins,
    hintsRemaining: hintsRemaining ?? this.hintsRemaining,
    lastDailyRewardDate: lastDailyRewardDate.present
        ? lastDailyRewardDate.value
        : this.lastDailyRewardDate,
    streakDays: streakDays ?? this.streakDays,
  );
  PlayerEconomyEntry copyWithCompanion(PlayerEconomyEntriesCompanion data) {
    return PlayerEconomyEntry(
      id: data.id.present ? data.id.value : this.id,
      coins: data.coins.present ? data.coins.value : this.coins,
      hintsRemaining: data.hintsRemaining.present
          ? data.hintsRemaining.value
          : this.hintsRemaining,
      lastDailyRewardDate: data.lastDailyRewardDate.present
          ? data.lastDailyRewardDate.value
          : this.lastDailyRewardDate,
      streakDays: data.streakDays.present
          ? data.streakDays.value
          : this.streakDays,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlayerEconomyEntry(')
          ..write('id: $id, ')
          ..write('coins: $coins, ')
          ..write('hintsRemaining: $hintsRemaining, ')
          ..write('lastDailyRewardDate: $lastDailyRewardDate, ')
          ..write('streakDays: $streakDays')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, coins, hintsRemaining, lastDailyRewardDate, streakDays);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayerEconomyEntry &&
          other.id == this.id &&
          other.coins == this.coins &&
          other.hintsRemaining == this.hintsRemaining &&
          other.lastDailyRewardDate == this.lastDailyRewardDate &&
          other.streakDays == this.streakDays);
}

class PlayerEconomyEntriesCompanion
    extends UpdateCompanion<PlayerEconomyEntry> {
  final Value<String> id;
  final Value<int> coins;
  final Value<int> hintsRemaining;
  final Value<String?> lastDailyRewardDate;
  final Value<int> streakDays;
  final Value<int> rowid;
  const PlayerEconomyEntriesCompanion({
    this.id = const Value.absent(),
    this.coins = const Value.absent(),
    this.hintsRemaining = const Value.absent(),
    this.lastDailyRewardDate = const Value.absent(),
    this.streakDays = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlayerEconomyEntriesCompanion.insert({
    required String id,
    this.coins = const Value.absent(),
    this.hintsRemaining = const Value.absent(),
    this.lastDailyRewardDate = const Value.absent(),
    this.streakDays = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<PlayerEconomyEntry> custom({
    Expression<String>? id,
    Expression<int>? coins,
    Expression<int>? hintsRemaining,
    Expression<String>? lastDailyRewardDate,
    Expression<int>? streakDays,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (coins != null) 'coins': coins,
      if (hintsRemaining != null) 'hints_remaining': hintsRemaining,
      if (lastDailyRewardDate != null)
        'last_daily_reward_date': lastDailyRewardDate,
      if (streakDays != null) 'streak_days': streakDays,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlayerEconomyEntriesCompanion copyWith({
    Value<String>? id,
    Value<int>? coins,
    Value<int>? hintsRemaining,
    Value<String?>? lastDailyRewardDate,
    Value<int>? streakDays,
    Value<int>? rowid,
  }) {
    return PlayerEconomyEntriesCompanion(
      id: id ?? this.id,
      coins: coins ?? this.coins,
      hintsRemaining: hintsRemaining ?? this.hintsRemaining,
      lastDailyRewardDate: lastDailyRewardDate ?? this.lastDailyRewardDate,
      streakDays: streakDays ?? this.streakDays,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (coins.present) {
      map['coins'] = Variable<int>(coins.value);
    }
    if (hintsRemaining.present) {
      map['hints_remaining'] = Variable<int>(hintsRemaining.value);
    }
    if (lastDailyRewardDate.present) {
      map['last_daily_reward_date'] = Variable<String>(
        lastDailyRewardDate.value,
      );
    }
    if (streakDays.present) {
      map['streak_days'] = Variable<int>(streakDays.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayerEconomyEntriesCompanion(')
          ..write('id: $id, ')
          ..write('coins: $coins, ')
          ..write('hintsRemaining: $hintsRemaining, ')
          ..write('lastDailyRewardDate: $lastDailyRewardDate, ')
          ..write('streakDays: $streakDays, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EntitlementEntriesTable extends EntitlementEntries
    with TableInfo<$EntitlementEntriesTable, EntitlementEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntitlementEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entitlementIdMeta = const VerificationMeta(
    'entitlementId',
  );
  @override
  late final GeneratedColumn<String> entitlementId = GeneratedColumn<String>(
    'entitlement_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _acquiredAtMeta = const VerificationMeta(
    'acquiredAt',
  );
  @override
  late final GeneratedColumn<DateTime> acquiredAt = GeneratedColumn<DateTime>(
    'acquired_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _signatureMeta = const VerificationMeta(
    'signature',
  );
  @override
  late final GeneratedColumn<String> signature = GeneratedColumn<String>(
    'signature',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    entitlementId,
    isActive,
    source,
    acquiredAt,
    signature,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entitlement_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<EntitlementEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entitlement_id')) {
      context.handle(
        _entitlementIdMeta,
        entitlementId.isAcceptableOrUnknown(
          data['entitlement_id']!,
          _entitlementIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_entitlementIdMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('acquired_at')) {
      context.handle(
        _acquiredAtMeta,
        acquiredAt.isAcceptableOrUnknown(data['acquired_at']!, _acquiredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_acquiredAtMeta);
    }
    if (data.containsKey('signature')) {
      context.handle(
        _signatureMeta,
        signature.isAcceptableOrUnknown(data['signature']!, _signatureMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entitlementId};
  @override
  EntitlementEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntitlementEntry(
      entitlementId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entitlement_id'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      acquiredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}acquired_at'],
      )!,
      signature: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}signature'],
      ),
    );
  }

  @override
  $EntitlementEntriesTable createAlias(String alias) {
    return $EntitlementEntriesTable(attachedDatabase, alias);
  }
}

class EntitlementEntry extends DataClass
    implements Insertable<EntitlementEntry> {
  final String entitlementId;
  final bool isActive;
  final String source;
  final DateTime acquiredAt;
  final String? signature;
  const EntitlementEntry({
    required this.entitlementId,
    required this.isActive,
    required this.source,
    required this.acquiredAt,
    this.signature,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entitlement_id'] = Variable<String>(entitlementId);
    map['is_active'] = Variable<bool>(isActive);
    map['source'] = Variable<String>(source);
    map['acquired_at'] = Variable<DateTime>(acquiredAt);
    if (!nullToAbsent || signature != null) {
      map['signature'] = Variable<String>(signature);
    }
    return map;
  }

  EntitlementEntriesCompanion toCompanion(bool nullToAbsent) {
    return EntitlementEntriesCompanion(
      entitlementId: Value(entitlementId),
      isActive: Value(isActive),
      source: Value(source),
      acquiredAt: Value(acquiredAt),
      signature: signature == null && nullToAbsent
          ? const Value.absent()
          : Value(signature),
    );
  }

  factory EntitlementEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntitlementEntry(
      entitlementId: serializer.fromJson<String>(json['entitlementId']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      source: serializer.fromJson<String>(json['source']),
      acquiredAt: serializer.fromJson<DateTime>(json['acquiredAt']),
      signature: serializer.fromJson<String?>(json['signature']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entitlementId': serializer.toJson<String>(entitlementId),
      'isActive': serializer.toJson<bool>(isActive),
      'source': serializer.toJson<String>(source),
      'acquiredAt': serializer.toJson<DateTime>(acquiredAt),
      'signature': serializer.toJson<String?>(signature),
    };
  }

  EntitlementEntry copyWith({
    String? entitlementId,
    bool? isActive,
    String? source,
    DateTime? acquiredAt,
    Value<String?> signature = const Value.absent(),
  }) => EntitlementEntry(
    entitlementId: entitlementId ?? this.entitlementId,
    isActive: isActive ?? this.isActive,
    source: source ?? this.source,
    acquiredAt: acquiredAt ?? this.acquiredAt,
    signature: signature.present ? signature.value : this.signature,
  );
  EntitlementEntry copyWithCompanion(EntitlementEntriesCompanion data) {
    return EntitlementEntry(
      entitlementId: data.entitlementId.present
          ? data.entitlementId.value
          : this.entitlementId,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      source: data.source.present ? data.source.value : this.source,
      acquiredAt: data.acquiredAt.present
          ? data.acquiredAt.value
          : this.acquiredAt,
      signature: data.signature.present ? data.signature.value : this.signature,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntitlementEntry(')
          ..write('entitlementId: $entitlementId, ')
          ..write('isActive: $isActive, ')
          ..write('source: $source, ')
          ..write('acquiredAt: $acquiredAt, ')
          ..write('signature: $signature')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(entitlementId, isActive, source, acquiredAt, signature);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntitlementEntry &&
          other.entitlementId == this.entitlementId &&
          other.isActive == this.isActive &&
          other.source == this.source &&
          other.acquiredAt == this.acquiredAt &&
          other.signature == this.signature);
}

class EntitlementEntriesCompanion extends UpdateCompanion<EntitlementEntry> {
  final Value<String> entitlementId;
  final Value<bool> isActive;
  final Value<String> source;
  final Value<DateTime> acquiredAt;
  final Value<String?> signature;
  final Value<int> rowid;
  const EntitlementEntriesCompanion({
    this.entitlementId = const Value.absent(),
    this.isActive = const Value.absent(),
    this.source = const Value.absent(),
    this.acquiredAt = const Value.absent(),
    this.signature = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntitlementEntriesCompanion.insert({
    required String entitlementId,
    this.isActive = const Value.absent(),
    required String source,
    required DateTime acquiredAt,
    this.signature = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : entitlementId = Value(entitlementId),
       source = Value(source),
       acquiredAt = Value(acquiredAt);
  static Insertable<EntitlementEntry> custom({
    Expression<String>? entitlementId,
    Expression<bool>? isActive,
    Expression<String>? source,
    Expression<DateTime>? acquiredAt,
    Expression<String>? signature,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entitlementId != null) 'entitlement_id': entitlementId,
      if (isActive != null) 'is_active': isActive,
      if (source != null) 'source': source,
      if (acquiredAt != null) 'acquired_at': acquiredAt,
      if (signature != null) 'signature': signature,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntitlementEntriesCompanion copyWith({
    Value<String>? entitlementId,
    Value<bool>? isActive,
    Value<String>? source,
    Value<DateTime>? acquiredAt,
    Value<String?>? signature,
    Value<int>? rowid,
  }) {
    return EntitlementEntriesCompanion(
      entitlementId: entitlementId ?? this.entitlementId,
      isActive: isActive ?? this.isActive,
      source: source ?? this.source,
      acquiredAt: acquiredAt ?? this.acquiredAt,
      signature: signature ?? this.signature,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entitlementId.present) {
      map['entitlement_id'] = Variable<String>(entitlementId.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (acquiredAt.present) {
      map['acquired_at'] = Variable<DateTime>(acquiredAt.value);
    }
    if (signature.present) {
      map['signature'] = Variable<String>(signature.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntitlementEntriesCompanion(')
          ..write('entitlementId: $entitlementId, ')
          ..write('isActive: $isActive, ')
          ..write('source: $source, ')
          ..write('acquiredAt: $acquiredAt, ')
          ..write('signature: $signature, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PuzzleProgressEntriesTable puzzleProgressEntries =
      $PuzzleProgressEntriesTable(this);
  late final $DailyPuzzleEntriesTable dailyPuzzleEntries =
      $DailyPuzzleEntriesTable(this);
  late final $PlayerEconomyEntriesTable playerEconomyEntries =
      $PlayerEconomyEntriesTable(this);
  late final $EntitlementEntriesTable entitlementEntries =
      $EntitlementEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    puzzleProgressEntries,
    dailyPuzzleEntries,
    playerEconomyEntries,
    entitlementEntries,
  ];
}

typedef $$PuzzleProgressEntriesTableCreateCompanionBuilder =
    PuzzleProgressEntriesCompanion Function({
      required String puzzleId,
      Value<bool> isCompleted,
      Value<int> stars,
      Value<int> bestTimeSeconds,
      required DateTime lastPlayed,
      Value<String?> savedBoardState,
      Value<int> savedMistakes,
      Value<int> savedHintsUsed,
      Value<int> savedElapsedSeconds,
      Value<int> rowid,
    });
typedef $$PuzzleProgressEntriesTableUpdateCompanionBuilder =
    PuzzleProgressEntriesCompanion Function({
      Value<String> puzzleId,
      Value<bool> isCompleted,
      Value<int> stars,
      Value<int> bestTimeSeconds,
      Value<DateTime> lastPlayed,
      Value<String?> savedBoardState,
      Value<int> savedMistakes,
      Value<int> savedHintsUsed,
      Value<int> savedElapsedSeconds,
      Value<int> rowid,
    });

class $$PuzzleProgressEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $PuzzleProgressEntriesTable> {
  $$PuzzleProgressEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get puzzleId => $composableBuilder(
    column: $table.puzzleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stars => $composableBuilder(
    column: $table.stars,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bestTimeSeconds => $composableBuilder(
    column: $table.bestTimeSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPlayed => $composableBuilder(
    column: $table.lastPlayed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get savedBoardState => $composableBuilder(
    column: $table.savedBoardState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get savedMistakes => $composableBuilder(
    column: $table.savedMistakes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get savedHintsUsed => $composableBuilder(
    column: $table.savedHintsUsed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get savedElapsedSeconds => $composableBuilder(
    column: $table.savedElapsedSeconds,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PuzzleProgressEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $PuzzleProgressEntriesTable> {
  $$PuzzleProgressEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get puzzleId => $composableBuilder(
    column: $table.puzzleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stars => $composableBuilder(
    column: $table.stars,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bestTimeSeconds => $composableBuilder(
    column: $table.bestTimeSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPlayed => $composableBuilder(
    column: $table.lastPlayed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get savedBoardState => $composableBuilder(
    column: $table.savedBoardState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get savedMistakes => $composableBuilder(
    column: $table.savedMistakes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get savedHintsUsed => $composableBuilder(
    column: $table.savedHintsUsed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get savedElapsedSeconds => $composableBuilder(
    column: $table.savedElapsedSeconds,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PuzzleProgressEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PuzzleProgressEntriesTable> {
  $$PuzzleProgressEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get puzzleId =>
      $composableBuilder(column: $table.puzzleId, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stars =>
      $composableBuilder(column: $table.stars, builder: (column) => column);

  GeneratedColumn<int> get bestTimeSeconds => $composableBuilder(
    column: $table.bestTimeSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastPlayed => $composableBuilder(
    column: $table.lastPlayed,
    builder: (column) => column,
  );

  GeneratedColumn<String> get savedBoardState => $composableBuilder(
    column: $table.savedBoardState,
    builder: (column) => column,
  );

  GeneratedColumn<int> get savedMistakes => $composableBuilder(
    column: $table.savedMistakes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get savedHintsUsed => $composableBuilder(
    column: $table.savedHintsUsed,
    builder: (column) => column,
  );

  GeneratedColumn<int> get savedElapsedSeconds => $composableBuilder(
    column: $table.savedElapsedSeconds,
    builder: (column) => column,
  );
}

class $$PuzzleProgressEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PuzzleProgressEntriesTable,
          PuzzleProgressEntry,
          $$PuzzleProgressEntriesTableFilterComposer,
          $$PuzzleProgressEntriesTableOrderingComposer,
          $$PuzzleProgressEntriesTableAnnotationComposer,
          $$PuzzleProgressEntriesTableCreateCompanionBuilder,
          $$PuzzleProgressEntriesTableUpdateCompanionBuilder,
          (
            PuzzleProgressEntry,
            BaseReferences<
              _$AppDatabase,
              $PuzzleProgressEntriesTable,
              PuzzleProgressEntry
            >,
          ),
          PuzzleProgressEntry,
          PrefetchHooks Function()
        > {
  $$PuzzleProgressEntriesTableTableManager(
    _$AppDatabase db,
    $PuzzleProgressEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PuzzleProgressEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$PuzzleProgressEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PuzzleProgressEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> puzzleId = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<int> stars = const Value.absent(),
                Value<int> bestTimeSeconds = const Value.absent(),
                Value<DateTime> lastPlayed = const Value.absent(),
                Value<String?> savedBoardState = const Value.absent(),
                Value<int> savedMistakes = const Value.absent(),
                Value<int> savedHintsUsed = const Value.absent(),
                Value<int> savedElapsedSeconds = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PuzzleProgressEntriesCompanion(
                puzzleId: puzzleId,
                isCompleted: isCompleted,
                stars: stars,
                bestTimeSeconds: bestTimeSeconds,
                lastPlayed: lastPlayed,
                savedBoardState: savedBoardState,
                savedMistakes: savedMistakes,
                savedHintsUsed: savedHintsUsed,
                savedElapsedSeconds: savedElapsedSeconds,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String puzzleId,
                Value<bool> isCompleted = const Value.absent(),
                Value<int> stars = const Value.absent(),
                Value<int> bestTimeSeconds = const Value.absent(),
                required DateTime lastPlayed,
                Value<String?> savedBoardState = const Value.absent(),
                Value<int> savedMistakes = const Value.absent(),
                Value<int> savedHintsUsed = const Value.absent(),
                Value<int> savedElapsedSeconds = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PuzzleProgressEntriesCompanion.insert(
                puzzleId: puzzleId,
                isCompleted: isCompleted,
                stars: stars,
                bestTimeSeconds: bestTimeSeconds,
                lastPlayed: lastPlayed,
                savedBoardState: savedBoardState,
                savedMistakes: savedMistakes,
                savedHintsUsed: savedHintsUsed,
                savedElapsedSeconds: savedElapsedSeconds,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PuzzleProgressEntriesTable, PuzzleProgressEntry>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $PuzzleProgressEntriesTable,
                    PuzzleProgressEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PuzzleProgressEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PuzzleProgressEntriesTable,
      PuzzleProgressEntry,
      $$PuzzleProgressEntriesTableFilterComposer,
      $$PuzzleProgressEntriesTableOrderingComposer,
      $$PuzzleProgressEntriesTableAnnotationComposer,
      $$PuzzleProgressEntriesTableCreateCompanionBuilder,
      $$PuzzleProgressEntriesTableUpdateCompanionBuilder,
      (
        PuzzleProgressEntry,
        BaseReferences<
          _$AppDatabase,
          $PuzzleProgressEntriesTable,
          PuzzleProgressEntry
        >,
      ),
      PuzzleProgressEntry,
      PrefetchHooks Function()
    >;
typedef $$DailyPuzzleEntriesTableCreateCompanionBuilder =
    DailyPuzzleEntriesCompanion Function({
      required String dateKey,
      required String puzzleId,
      Value<bool> isCompleted,
      Value<int> timeSeconds,
      Value<DateTime?> completedAt,
      Value<int> rowid,
    });
typedef $$DailyPuzzleEntriesTableUpdateCompanionBuilder =
    DailyPuzzleEntriesCompanion Function({
      Value<String> dateKey,
      Value<String> puzzleId,
      Value<bool> isCompleted,
      Value<int> timeSeconds,
      Value<DateTime?> completedAt,
      Value<int> rowid,
    });

class $$DailyPuzzleEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $DailyPuzzleEntriesTable> {
  $$DailyPuzzleEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get dateKey => $composableBuilder(
    column: $table.dateKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get puzzleId => $composableBuilder(
    column: $table.puzzleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeSeconds => $composableBuilder(
    column: $table.timeSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyPuzzleEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyPuzzleEntriesTable> {
  $$DailyPuzzleEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get dateKey => $composableBuilder(
    column: $table.dateKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get puzzleId => $composableBuilder(
    column: $table.puzzleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeSeconds => $composableBuilder(
    column: $table.timeSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyPuzzleEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyPuzzleEntriesTable> {
  $$DailyPuzzleEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get dateKey =>
      $composableBuilder(column: $table.dateKey, builder: (column) => column);

  GeneratedColumn<String> get puzzleId =>
      $composableBuilder(column: $table.puzzleId, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get timeSeconds => $composableBuilder(
    column: $table.timeSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );
}

class $$DailyPuzzleEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyPuzzleEntriesTable,
          DailyPuzzleEntry,
          $$DailyPuzzleEntriesTableFilterComposer,
          $$DailyPuzzleEntriesTableOrderingComposer,
          $$DailyPuzzleEntriesTableAnnotationComposer,
          $$DailyPuzzleEntriesTableCreateCompanionBuilder,
          $$DailyPuzzleEntriesTableUpdateCompanionBuilder,
          (
            DailyPuzzleEntry,
            BaseReferences<
              _$AppDatabase,
              $DailyPuzzleEntriesTable,
              DailyPuzzleEntry
            >,
          ),
          DailyPuzzleEntry,
          PrefetchHooks Function()
        > {
  $$DailyPuzzleEntriesTableTableManager(
    _$AppDatabase db,
    $DailyPuzzleEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyPuzzleEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyPuzzleEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyPuzzleEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> dateKey = const Value.absent(),
                Value<String> puzzleId = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<int> timeSeconds = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyPuzzleEntriesCompanion(
                dateKey: dateKey,
                puzzleId: puzzleId,
                isCompleted: isCompleted,
                timeSeconds: timeSeconds,
                completedAt: completedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String dateKey,
                required String puzzleId,
                Value<bool> isCompleted = const Value.absent(),
                Value<int> timeSeconds = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyPuzzleEntriesCompanion.insert(
                dateKey: dateKey,
                puzzleId: puzzleId,
                isCompleted: isCompleted,
                timeSeconds: timeSeconds,
                completedAt: completedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DailyPuzzleEntriesTable, DailyPuzzleEntry>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $DailyPuzzleEntriesTable,
                    DailyPuzzleEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyPuzzleEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyPuzzleEntriesTable,
      DailyPuzzleEntry,
      $$DailyPuzzleEntriesTableFilterComposer,
      $$DailyPuzzleEntriesTableOrderingComposer,
      $$DailyPuzzleEntriesTableAnnotationComposer,
      $$DailyPuzzleEntriesTableCreateCompanionBuilder,
      $$DailyPuzzleEntriesTableUpdateCompanionBuilder,
      (
        DailyPuzzleEntry,
        BaseReferences<
          _$AppDatabase,
          $DailyPuzzleEntriesTable,
          DailyPuzzleEntry
        >,
      ),
      DailyPuzzleEntry,
      PrefetchHooks Function()
    >;
typedef $$PlayerEconomyEntriesTableCreateCompanionBuilder =
    PlayerEconomyEntriesCompanion Function({
      required String id,
      Value<int> coins,
      Value<int> hintsRemaining,
      Value<String?> lastDailyRewardDate,
      Value<int> streakDays,
      Value<int> rowid,
    });
typedef $$PlayerEconomyEntriesTableUpdateCompanionBuilder =
    PlayerEconomyEntriesCompanion Function({
      Value<String> id,
      Value<int> coins,
      Value<int> hintsRemaining,
      Value<String?> lastDailyRewardDate,
      Value<int> streakDays,
      Value<int> rowid,
    });

class $$PlayerEconomyEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $PlayerEconomyEntriesTable> {
  $$PlayerEconomyEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get coins => $composableBuilder(
    column: $table.coins,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hintsRemaining => $composableBuilder(
    column: $table.hintsRemaining,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastDailyRewardDate => $composableBuilder(
    column: $table.lastDailyRewardDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get streakDays => $composableBuilder(
    column: $table.streakDays,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlayerEconomyEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $PlayerEconomyEntriesTable> {
  $$PlayerEconomyEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get coins => $composableBuilder(
    column: $table.coins,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hintsRemaining => $composableBuilder(
    column: $table.hintsRemaining,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastDailyRewardDate => $composableBuilder(
    column: $table.lastDailyRewardDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get streakDays => $composableBuilder(
    column: $table.streakDays,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlayerEconomyEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlayerEconomyEntriesTable> {
  $$PlayerEconomyEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get coins =>
      $composableBuilder(column: $table.coins, builder: (column) => column);

  GeneratedColumn<int> get hintsRemaining => $composableBuilder(
    column: $table.hintsRemaining,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastDailyRewardDate => $composableBuilder(
    column: $table.lastDailyRewardDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get streakDays => $composableBuilder(
    column: $table.streakDays,
    builder: (column) => column,
  );
}

class $$PlayerEconomyEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlayerEconomyEntriesTable,
          PlayerEconomyEntry,
          $$PlayerEconomyEntriesTableFilterComposer,
          $$PlayerEconomyEntriesTableOrderingComposer,
          $$PlayerEconomyEntriesTableAnnotationComposer,
          $$PlayerEconomyEntriesTableCreateCompanionBuilder,
          $$PlayerEconomyEntriesTableUpdateCompanionBuilder,
          (
            PlayerEconomyEntry,
            BaseReferences<
              _$AppDatabase,
              $PlayerEconomyEntriesTable,
              PlayerEconomyEntry
            >,
          ),
          PlayerEconomyEntry,
          PrefetchHooks Function()
        > {
  $$PlayerEconomyEntriesTableTableManager(
    _$AppDatabase db,
    $PlayerEconomyEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlayerEconomyEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlayerEconomyEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PlayerEconomyEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> coins = const Value.absent(),
                Value<int> hintsRemaining = const Value.absent(),
                Value<String?> lastDailyRewardDate = const Value.absent(),
                Value<int> streakDays = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlayerEconomyEntriesCompanion(
                id: id,
                coins: coins,
                hintsRemaining: hintsRemaining,
                lastDailyRewardDate: lastDailyRewardDate,
                streakDays: streakDays,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<int> coins = const Value.absent(),
                Value<int> hintsRemaining = const Value.absent(),
                Value<String?> lastDailyRewardDate = const Value.absent(),
                Value<int> streakDays = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlayerEconomyEntriesCompanion.insert(
                id: id,
                coins: coins,
                hintsRemaining: hintsRemaining,
                lastDailyRewardDate: lastDailyRewardDate,
                streakDays: streakDays,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlayerEconomyEntriesTable, PlayerEconomyEntry>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $PlayerEconomyEntriesTable,
                    PlayerEconomyEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlayerEconomyEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlayerEconomyEntriesTable,
      PlayerEconomyEntry,
      $$PlayerEconomyEntriesTableFilterComposer,
      $$PlayerEconomyEntriesTableOrderingComposer,
      $$PlayerEconomyEntriesTableAnnotationComposer,
      $$PlayerEconomyEntriesTableCreateCompanionBuilder,
      $$PlayerEconomyEntriesTableUpdateCompanionBuilder,
      (
        PlayerEconomyEntry,
        BaseReferences<
          _$AppDatabase,
          $PlayerEconomyEntriesTable,
          PlayerEconomyEntry
        >,
      ),
      PlayerEconomyEntry,
      PrefetchHooks Function()
    >;
typedef $$EntitlementEntriesTableCreateCompanionBuilder =
    EntitlementEntriesCompanion Function({
      required String entitlementId,
      Value<bool> isActive,
      required String source,
      required DateTime acquiredAt,
      Value<String?> signature,
      Value<int> rowid,
    });
typedef $$EntitlementEntriesTableUpdateCompanionBuilder =
    EntitlementEntriesCompanion Function({
      Value<String> entitlementId,
      Value<bool> isActive,
      Value<String> source,
      Value<DateTime> acquiredAt,
      Value<String?> signature,
      Value<int> rowid,
    });

class $$EntitlementEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $EntitlementEntriesTable> {
  $$EntitlementEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entitlementId => $composableBuilder(
    column: $table.entitlementId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get acquiredAt => $composableBuilder(
    column: $table.acquiredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get signature => $composableBuilder(
    column: $table.signature,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EntitlementEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $EntitlementEntriesTable> {
  $$EntitlementEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entitlementId => $composableBuilder(
    column: $table.entitlementId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get acquiredAt => $composableBuilder(
    column: $table.acquiredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get signature => $composableBuilder(
    column: $table.signature,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EntitlementEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntitlementEntriesTable> {
  $$EntitlementEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entitlementId => $composableBuilder(
    column: $table.entitlementId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get acquiredAt => $composableBuilder(
    column: $table.acquiredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get signature =>
      $composableBuilder(column: $table.signature, builder: (column) => column);
}

class $$EntitlementEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EntitlementEntriesTable,
          EntitlementEntry,
          $$EntitlementEntriesTableFilterComposer,
          $$EntitlementEntriesTableOrderingComposer,
          $$EntitlementEntriesTableAnnotationComposer,
          $$EntitlementEntriesTableCreateCompanionBuilder,
          $$EntitlementEntriesTableUpdateCompanionBuilder,
          (
            EntitlementEntry,
            BaseReferences<
              _$AppDatabase,
              $EntitlementEntriesTable,
              EntitlementEntry
            >,
          ),
          EntitlementEntry,
          PrefetchHooks Function()
        > {
  $$EntitlementEntriesTableTableManager(
    _$AppDatabase db,
    $EntitlementEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntitlementEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntitlementEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntitlementEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> entitlementId = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime> acquiredAt = const Value.absent(),
                Value<String?> signature = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntitlementEntriesCompanion(
                entitlementId: entitlementId,
                isActive: isActive,
                source: source,
                acquiredAt: acquiredAt,
                signature: signature,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entitlementId,
                Value<bool> isActive = const Value.absent(),
                required String source,
                required DateTime acquiredAt,
                Value<String?> signature = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntitlementEntriesCompanion.insert(
                entitlementId: entitlementId,
                isActive: isActive,
                source: source,
                acquiredAt: acquiredAt,
                signature: signature,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EntitlementEntriesTable, EntitlementEntry>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $EntitlementEntriesTable,
                    EntitlementEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EntitlementEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EntitlementEntriesTable,
      EntitlementEntry,
      $$EntitlementEntriesTableFilterComposer,
      $$EntitlementEntriesTableOrderingComposer,
      $$EntitlementEntriesTableAnnotationComposer,
      $$EntitlementEntriesTableCreateCompanionBuilder,
      $$EntitlementEntriesTableUpdateCompanionBuilder,
      (
        EntitlementEntry,
        BaseReferences<
          _$AppDatabase,
          $EntitlementEntriesTable,
          EntitlementEntry
        >,
      ),
      EntitlementEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PuzzleProgressEntriesTableTableManager get puzzleProgressEntries =>
      $$PuzzleProgressEntriesTableTableManager(_db, _db.puzzleProgressEntries);
  $$DailyPuzzleEntriesTableTableManager get dailyPuzzleEntries =>
      $$DailyPuzzleEntriesTableTableManager(_db, _db.dailyPuzzleEntries);
  $$PlayerEconomyEntriesTableTableManager get playerEconomyEntries =>
      $$PlayerEconomyEntriesTableTableManager(_db, _db.playerEconomyEntries);
  $$EntitlementEntriesTableTableManager get entitlementEntries =>
      $$EntitlementEntriesTableTableManager(_db, _db.entitlementEntries);
}
