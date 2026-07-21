import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'game_engine.dart';
import 'game_state.dart';

class GamePersistence {
  GamePersistence({this.preferences, GameEngine? engine})
    : _engine = engine ?? const GameEngine();

  static const saveKey = 'simul-millennium-capital-v1';

  SharedPreferences? preferences;
  final GameEngine _engine;

  Future<SharedPreferences> get _prefs async =>
      preferences ??= await SharedPreferences.getInstance();

  Future<GameState?> load() async {
    final raw = (await _prefs).getString(saveKey);
    if (raw == null) return null;
    try {
      final json = (jsonDecode(raw) as Map).cast<String, dynamic>();
      final state = _engine.migrate(json);
      if (state.companyName.trim().isEmpty) return null;
      if ((json['version'] as num?)?.toInt() != GameState.schemaVersion) {
        await save(state);
      }
      return state;
    } catch (_) {
      return null;
    }
  }

  Future<void> save(GameState state) async {
    final json = state.toJson();
    if (json['version'] != GameState.schemaVersion ||
        state.companyName.trim().isEmpty) {
      throw StateError('Invalid game state');
    }
    await (await _prefs).setString(saveKey, jsonEncode(json));
  }
}
