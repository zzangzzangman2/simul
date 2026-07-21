import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'game_engine.dart';
import 'game_state.dart';

class GamePersistence {
  GamePersistence({this.preferences, GameEngine? engine, this.saveString})
    : _engine = engine ?? const GameEngine();

  static const saveKey = 'simul-millennium-capital-v1';

  SharedPreferences? preferences;
  final GameEngine _engine;
  final Future<bool> Function(String key, String value)? saveString;

  Future<SharedPreferences> get _prefs async =>
      preferences ??= await SharedPreferences.getInstance();

  Future<GameState?> load() async {
    final raw = (await _prefs).getString(saveKey);
    if (raw == null) return null;
    late Map<String, dynamic> json;
    late GameState state;
    try {
      json = (jsonDecode(raw) as Map).cast<String, dynamic>();
      state = _engine.migrate(json);
      if (state.companyName.trim().isEmpty) return null;
    } catch (_) {
      return null;
    }
    if ((json['version'] as num?)?.toInt() != GameState.schemaVersion) {
      await save(state);
    }
    return state;
  }

  Future<void> save(GameState state) async {
    final json = state.toJson();
    if (json['version'] != GameState.schemaVersion ||
        state.companyName.trim().isEmpty) {
      throw StateError('Invalid game state');
    }
    final encoded = jsonEncode(json);
    final writer = saveString;
    final saved = writer == null
        ? await (await _prefs).setString(saveKey, encoded)
        : await writer(saveKey, encoded);
    if (!saved) {
      throw StateError('Game state could not be saved');
    }
  }
}
