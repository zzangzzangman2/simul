import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'game_engine.dart';
import 'game_state.dart';

class GameSaveSlot {
  const GameSaveSlot({
    required this.slot,
    this.state,
    this.savedAt,
    this.isCorrupt = false,
  });

  final int slot;
  final GameState? state;
  final DateTime? savedAt;
  final bool isCorrupt;

  bool get isEmpty => state == null && !isCorrupt;
  bool get canContinue => state != null && !isCorrupt;
}

class GamePersistence {
  GamePersistence({
    this.preferences,
    GameEngine? engine,
    this.saveString,
    DateTime Function()? now,
  }) : _engine = engine ?? const GameEngine(),
       _now = now ?? DateTime.now;

  static const slotCount = 5;
  static const saveKey = 'simul-millennium-capital-v1';
  static const backupSaveKey = '$saveKey-backup';
  static const corruptSaveKey = '$saveKey-corrupt';
  static const activeSlotKey = '$saveKey-active-slot';

  SharedPreferences? preferences;
  final GameEngine _engine;
  final Future<bool> Function(String key, String value)? saveString;
  final DateTime Function() _now;

  Future<SharedPreferences> get _prefs async =>
      preferences ??= await SharedPreferences.getInstance();

  static String saveKeyFor(int slot) {
    _validateSlot(slot);
    return slot == 1 ? saveKey : '$saveKey-slot-$slot';
  }

  static String backupSaveKeyFor(int slot) {
    _validateSlot(slot);
    return slot == 1 ? backupSaveKey : '${saveKeyFor(slot)}-backup';
  }

  static String corruptSaveKeyFor(int slot) {
    _validateSlot(slot);
    return slot == 1 ? corruptSaveKey : '${saveKeyFor(slot)}-corrupt';
  }

  static String savedAtKeyFor(int slot) {
    _validateSlot(slot);
    return '${saveKeyFor(slot)}-saved-at';
  }

  static void _validateSlot(int slot) {
    if (slot < 1 || slot > slotCount) {
      throw RangeError.range(slot, 1, slotCount, 'slot');
    }
  }

  Future<int> getActiveSlot() async {
    final stored = (await _prefs).getInt(activeSlotKey) ?? 1;
    return stored.clamp(1, slotCount);
  }

  Future<void> setActiveSlot(int slot) async {
    _validateSlot(slot);
    if (!await (await _prefs).setInt(activeSlotKey, slot)) {
      throw StateError('Active save slot could not be selected');
    }
  }

  Future<List<GameSaveSlot>> listSlots() async {
    final prefs = await _prefs;
    final slots = <GameSaveSlot>[];
    for (var slot = 1; slot <= slotCount; slot++) {
      final raw = prefs.getString(saveKeyFor(slot));
      if (raw == null) {
        slots.add(GameSaveSlot(slot: slot));
        continue;
      }
      final savedAtRaw = prefs.getString(savedAtKeyFor(slot));
      final savedAt = savedAtRaw == null ? null : DateTime.tryParse(savedAtRaw);
      try {
        slots.add(
          GameSaveSlot(
            slot: slot,
            state: _decodeSave(raw).state,
            savedAt: savedAt,
          ),
        );
      } catch (_) {
        final backupRaw = prefs.getString(backupSaveKeyFor(slot));
        if (backupRaw != null) {
          try {
            slots.add(
              GameSaveSlot(
                slot: slot,
                state: _decodeSave(backupRaw).state,
                savedAt: savedAt,
              ),
            );
            continue;
          } catch (_) {
            // The primary and its backup are both unreadable.
          }
        }
        slots.add(GameSaveSlot(slot: slot, savedAt: savedAt, isCorrupt: true));
      }
    }
    return slots;
  }

  Future<GameState?> load() async {
    return loadSlot(await getActiveSlot());
  }

  Future<GameState?> loadSlot(int slot) async {
    _validateSlot(slot);
    final prefs = await _prefs;
    final raw = prefs.getString(saveKeyFor(slot));
    if (raw == null) return null;
    late _DecodedSave decoded;
    try {
      decoded = _decodeSave(raw);
    } catch (error, stackTrace) {
      final recovered = await _recoverBackup(prefs, raw, slot);
      if (recovered != null) {
        await setActiveSlot(slot);
        return recovered;
      }
      Error.throwWithStackTrace(
        StateError('Stored game data is corrupt: $error'),
        stackTrace,
      );
    }
    if (decoded.version != GameState.schemaVersion) {
      await saveToSlot(decoded.state, slot);
    }
    await setActiveSlot(slot);
    return decoded.state;
  }

  _DecodedSave _decodeSave(String raw) {
    final json = (jsonDecode(raw) as Map).cast<String, dynamic>();
    final state = _engine.migrate(json);
    if (state.companyName.trim().isEmpty) {
      throw StateError('Stored game data has no company name.');
    }
    return _DecodedSave(
      state: state,
      version: (json['version'] as num?)?.toInt() ?? 1,
    );
  }

  Future<GameState?> _recoverBackup(
    SharedPreferences prefs,
    String corruptRaw,
    int slot,
  ) async {
    final backupRaw = prefs.getString(backupSaveKeyFor(slot));
    if (backupRaw == null) return null;
    late GameState recovered;
    try {
      recovered = _decodeSave(backupRaw).state;
    } catch (_) {
      return null;
    }
    if (!await prefs.setString(corruptSaveKeyFor(slot), corruptRaw)) {
      throw StateError('Corrupt game data could not be preserved');
    }
    final encoded = jsonEncode(recovered.toJson());
    final writer = saveString;
    final saved = writer == null
        ? await prefs.setString(saveKeyFor(slot), encoded)
        : await writer(saveKeyFor(slot), encoded);
    if (!saved) throw StateError('Backup game state could not be restored');
    await _stampSavedAt(prefs, slot);
    return recovered;
  }

  Future<void> save(GameState state) async {
    await saveToSlot(state, await getActiveSlot());
  }

  Future<void> saveToSlot(GameState state, int slot) async {
    _validateSlot(slot);
    final json = state.toJson();
    if (json['version'] != GameState.schemaVersion ||
        state.companyName.trim().isEmpty) {
      throw StateError('Invalid game state');
    }
    final encoded = jsonEncode(json);
    final prefs = await _prefs;
    final primaryKey = saveKeyFor(slot);
    final previousRaw = prefs.getString(primaryKey);
    if (previousRaw != null && previousRaw != encoded) {
      var previousIsValid = false;
      try {
        _decodeSave(previousRaw);
        previousIsValid = true;
      } catch (_) {
        previousIsValid = false;
      }
      if (previousIsValid &&
          !await prefs.setString(backupSaveKeyFor(slot), previousRaw)) {
        throw StateError('Previous game state could not be backed up');
      }
    }
    final writer = saveString;
    final saved = writer == null
        ? await prefs.setString(primaryKey, encoded)
        : await writer(primaryKey, encoded);
    if (!saved) {
      throw StateError('Game state could not be saved');
    }
    await _stampSavedAt(prefs, slot);
  }

  Future<int> createSlot(GameState state) async {
    final prefs = await _prefs;
    for (var slot = 1; slot <= slotCount; slot++) {
      if (prefs.getString(saveKeyFor(slot)) == null) {
        await saveToSlot(state, slot);
        await setActiveSlot(slot);
        return slot;
      }
    }
    throw StateError('All $slotCount save slots are occupied');
  }

  Future<void> deleteSlot(int slot) async {
    _validateSlot(slot);
    final prefs = await _prefs;
    for (final key in <String>[
      saveKeyFor(slot),
      backupSaveKeyFor(slot),
      corruptSaveKeyFor(slot),
      savedAtKeyFor(slot),
    ]) {
      if (prefs.containsKey(key) && !await prefs.remove(key)) {
        throw StateError('Save slot $slot could not be deleted');
      }
    }
    if (await getActiveSlot() == slot) {
      var replacement = 1;
      for (var candidate = 1; candidate <= slotCount; candidate++) {
        if (prefs.getString(saveKeyFor(candidate)) != null) {
          replacement = candidate;
          break;
        }
      }
      await setActiveSlot(replacement);
    }
  }

  Future<void> _stampSavedAt(SharedPreferences prefs, int slot) async {
    if (!await prefs.setString(savedAtKeyFor(slot), _now().toIso8601String())) {
      throw StateError('Save timestamp could not be written');
    }
  }
}

class _DecodedSave {
  const _DecodedSave({required this.state, required this.version});

  final GameState state;
  final int version;
}
