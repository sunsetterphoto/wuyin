# Fortschritt

## Phase 0: LLM-Prototyp

| Meilenstein | Stand | Notiz |
| --- | --- | --- |
| M0.1 Projektgerüst | fast fertig | Godot 4.7.2, Mobile-Renderer. Tests 3/3, Boot headless (macOS) ok. Exporte Android, Linux arm64/x86_64, Windows ok. Android-Emulator (AVD `wuyin_test`, GLES3-Preset) startet. **Offen:** Start unter Linux (Fedora-VM braucht Zugang), echtes Android-Gerät (Vulkan) |
| M0.2 Kampfkern | offen | |
| M0.3 LLM-Dienst | offen | |
| M0.4 Ruf | offen | |
| M0.5 Stimme | offen | |
| M0.6 Kameramodi | offen | |

## Entscheidungen

- 2026-10-27: Erst Emulator, echtes Testgerät später (Samuel). Latenz-Abnahme von M0.3 bleibt bis dahin offen.
- 2026-10-27: Eigener Testrunner (`game/tests/run_tests.gd`) statt Add-on, keine Fremdabhängigkeit.
- 2026-10-27: Android-Emulatoren auf dem Mac können Godots Vulkan-Ausgabe nicht anzeigen (schwarzer Bildschirm). Preset „Android Emulator“ setzt das Feature-Tag `emulator` und nutzt GLES3; das echte Android-Build bleibt bei Vulkan.
- 2026-10-27: Paketname vorläufig `com.wuyin.game`, vor dem Store-Eintrag festlegen.
