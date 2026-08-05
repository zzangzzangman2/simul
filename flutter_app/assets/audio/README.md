# Project Decimal audio assets

The dialogue scene director stores BGM, sound-effect, and voice cues below this
directory. Use `/play/assets/assets/audio/...` in the editor; Flutter converts
that public path back to an `AssetSource` at runtime.

- `bgm/`: looping scene music
- `sfx/`: one-shot scene sound effects
- `voice/`: optional dialogue voice clips

Only committed files are available to the game build. The editor build API
rejects missing audio paths before replacing the canonical dialogue file.

Runtime-wide music and effects are coordinated by `lib/game_audio.dart`.
Dialogue scenes may still override BGM/SFX with their own canonical cue fields.

- `bgm/`: 9 non-8-bit piano, strings, orchestral, and jazz/fantasy loops
- `sfx/`: UI, finance, paper/book, door, impact, horse gallop/crowd, and
  complete card/chip/dice casino effects
- source and license ledger: repository root `AUDIO_LICENSES.md`

Do not add copyright, attribution, or license copy to the in-game UI. Keep that
information in `AUDIO_LICENSES.md` so it can be handled with release metadata.
