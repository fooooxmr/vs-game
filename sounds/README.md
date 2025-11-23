# Звуки для игры

## ⚠️ ВАЖНО: Автоматическое скачивание не работает

Многие сайты с открытыми звуками требуют регистрацию или используют защиту от прямого скачивания, поэтому автоматическое скачивание не работает.

## Рекомендуемое решение: Kenney Audio Pack

**Самый простой способ** - скачать готовый набор звуков Kenney Audio Pack:

1. Перейдите на https://kenney.nl/assets/audio-pack
2. Нажмите "Download" (бесплатно, не требует регистрации)
3. Распакуйте архив
4. Скопируйте нужные файлы из папки `Audio/` в эту папку `sounds/` с правильными именами:

### Необходимые звуки и их имена:

- `attack.wav` - можно использовать `impactGeneric_light_000.ogg` (конвертировать в WAV)
- `enemy_hit.wav` - можно использовать `impactGeneric_medium_000.ogg`
- `enemy_death.wav` - можно использовать `impactGeneric_heavy_000.ogg`
- `pickup.wav` - можно использовать `pickupCoin_000.ogg`
- `level_up.wav` - можно использовать `powerUp_000.ogg`
- `chest_open.wav` - можно использовать `impactGeneric_light_001.ogg`
- `player_hit.wav` - можно использовать `impactGeneric_medium_001.ogg`
- `projectile_shoot.wav` - можно использовать `laserShoot_000.ogg`
- `barrel_explode.wav` - можно использовать `explosion_000.ogg`
- `boss_spawn.wav` - можно использовать `impactGeneric_heavy_001.ogg`
- `elite_attack.wav` - можно использовать `magic_000.ogg`
- `upgrade_select.wav` - можно использовать `powerUp_001.ogg`

### Конвертация OGG в WAV:

Если файлы в формате OGG, конвертируйте их в WAV:
```bash
ffmpeg -i input.ogg output.wav
```

## Альтернативные источники:

1. **OpenGameArt.org** - https://opengameart.org/content/rpg-sound-pack
2. **Freesound.org** - https://freesound.org (требуется регистрация)
3. **Pixabay** - https://pixabay.com/sound-effects/

## Фоновая музыка:

Для фоновой музыки добавьте файл `music.ogg` или `music.wav` в папку `sounds/`.

**Рекомендуемые источники фоновой музыки:**
- **OpenGameArt.org** - https://opengameart.org/content/rpg-sound-pack (ищите файлы с тегом "music" или "background")
- **Freesound.org** - https://freesound.org (требуется регистрация, ищите "background music" или "ambient")
- **Pixabay** - https://pixabay.com/music/ (бесплатная музыка)
- **Incompetech** - https://incompetech.com/music/royalty-free/ (музыка Kevin MacLeod)

**Временное решение:**
Если у вас нет музыки, вы можете использовать один из существующих OGG файлов:
```bash
cp sounds/kenney_rpg-audio/Preview.ogg sounds/music.ogg
```

## После добавления файлов:

После того как вы добавите звуковые файлы в эту папку, они автоматически загрузятся при запуске игры.
