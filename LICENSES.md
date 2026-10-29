# Lizenzen

Jedes Modell, jede LoRA, Schrift und jedes fremde Asset, das ins Spiel oder in die Asset-Pipeline eingeht. Kommerzielle Nutzung muss erlaubt sein (siehe GDD, Lizenzen und Rechte).

| Bestandteil | Verwendung | Lizenz | Kommerziell erlaubt | Quelle | Geprüft am |
| --- | --- | --- | --- | --- | --- |
| Godot Engine | Engine | MIT | ja | godotengine.org | offen |
| llama.cpp v0.7.0 | LLM-Laufzeit, statisch in `addons/wuyin_llama` | MIT | ja | github.com/ggml-org/llama.cpp | 2026-10-28 |
| godot-cpp | C++-Bindings der GDExtension | MIT | ja | github.com/godotengine/godot-cpp | 2026-10-28 |
| Gemma 4 E2B QAT UD-Q4_K_XL (unsloth) | Sprachmodell im Spiel (Kandidat) | Apache 2.0 | ja | huggingface.co/unsloth/gemma-4-E2B-it-qat-GGUF | 2026-10-28 (Model-Card-Metadaten) |
| Sprachmodell für Release (GGUF) | Dialoge, Ruf-Übersetzer | offen | offen | offen | offen |
| Z-Image Turbo (Tongyi-MAI), mit Text-Encoder Qwen3 4B und VAE `ae.safetensors` (FLUX.1-schnell-VAE) | Sprites, Hintergründe, Titelbild, Icon (ComfyUI) | Apache 2.0 (Modell); Qwen3: Apache 2.0; FLUX.1-schnell-VAE: Apache 2.0 | ja (Apache 2.0 schränkt Ausgaben nicht ein) | huggingface.co/Tongyi-MAI/Z-Image-Turbo | 2026-10-28 (Model-Card-Metadaten) |
| ACE-Step 1.5 turbo (mit Qwen-ace15-Text-Encodern, ace_1.5_vae) | Musik (ComfyUI) | MIT | ja; Model Card: generierte Musik darf kommerziell genutzt werden | huggingface.co/ACE-Step/Ace-Step1.5 | 2026-10-28 (Model Card) |
| Generierte Beta-Assets (`game/assets/sprites/`, `backgrounds/`, `ui/`, `audio/music/`) | Spiel | eigene Erzeugung mit den Modellen oben, Prompts und Seeds in `tools/comfyui/beta_assets.json` | ja (keine fremden Vorlagen, keine Marken- oder Franchise-Namen in Prompts) | lokal erzeugt | 2026-10-28 |
| Generierte Umgebungs-Assets (`game/assets/tiles/`, `props/`, `portraits/`) | Spiel | Tiles und `wind_chime`, `prayer_flags` prozedural (eigener Code, `tools/postprocess/env_tiles_proc.py`, `env_handmade.py`); übrige Props und Porträts eigene Erzeugung mit Z-Image Turbo, Prompts und Seeds in `tools/comfyui/env_assets.json` | ja (keine fremden Vorlagen, keine Marken- oder Franchise-Namen in Prompts, keine LoRAs) | lokal erzeugt | 2026-10-29 |
| Noto Sans CJK SC Regular, Teilmenge (`game/assets/fonts/NotoSansCJKsc-Subset.otf`) | Ersatzschrift für chinesische Zeichen (Autoload `Fonts`) | SIL Open Font License 1.1, Copyright Adobe, Reserved Font Name „Source“; Lizenztext in `game/assets/fonts/LICENSE_OFL.txt` | ja (OFL erlaubt Einbetten und Teilmengen; Name „Source“ nicht verwendet) | Noto CJK (github.com/notofonts/noto-cjk); lokale Kopie, Teilmenge mit fontTools | 2026-10-29 |
| Generierte Voll-Assets (restliche Lingshou, Bosse, Figuren, Hintergründe, Regionsmusik) | Spiel | eigene Erzeugung mit Z-Image Turbo und ACE-Step 1.5, Prompts und Seeds in `tools/comfyui/full_assets.json` | ja (keine fremden Vorlagen, keine LoRAs) | lokal erzeugt | 2026-10-29 |
