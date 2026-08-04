# Project Decimal audio assets

The dialogue scene director stores BGM, sound-effect, and voice cues below this
directory. Use `/play/assets/assets/audio/...` in the editor; Flutter converts
that public path back to an `AssetSource` at runtime.

- `bgm/`: looping scene music
- `sfx/`: one-shot scene sound effects
- `voice/`: optional dialogue voice clips

Only committed files are available to the game build. The editor build API
rejects missing audio paths before replacing the canonical dialogue file.
