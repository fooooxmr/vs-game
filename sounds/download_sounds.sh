#!/bin/bash
# Скрипт для скачивания звуков с открытых источников

echo "Скачиваю звуки для игры..."

# Используем прямые ссылки на файлы
curl -L "https://www.soundjay.com/misc/sounds/swish-1.wav" -o attack.wav
curl -L "https://www.soundjay.com/misc/sounds/punch-1.wav" -o enemy_hit.wav  
curl -L "https://www.soundjay.com/misc/sounds/death-1.wav" -o enemy_death.wav
curl -L "https://www.soundjay.com/misc/sounds/coin-1.wav" -o pickup.wav
curl -L "https://www.soundjay.com/misc/sounds/level-up-1.wav" -o level_up.wav
curl -L "https://www.soundjay.com/misc/sounds/chest-1.wav" -o chest_open.wav
curl -L "https://www.soundjay.com/misc/sounds/hurt-1.wav" -o player_hit.wav
curl -L "https://www.soundjay.com/misc/sounds/shoot-1.wav" -o projectile_shoot.wav
curl -L "https://www.soundjay.com/misc/sounds/explosion-1.wav" -o barrel_explode.wav
curl -L "https://www.soundjay.com/misc/sounds/boss-1.wav" -o boss_spawn.wav
curl -L "https://www.soundjay.com/misc/sounds/magic-1.wav" -o elite_attack.wav
curl -L "https://www.soundjay.com/misc/sounds/powerup-1.wav" -o upgrade_select.wav

echo "Проверяю скачанные файлы..."
for file in *.wav; do
    if [ -f "$file" ] && [ -s "$file" ]; then
        size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo 0)
        if [ "$size" -gt 1000 ]; then
            echo "✓ $file ($size байт)"
        else
            echo "✗ $file (слишком маленький, удаляю)"
            rm "$file"
        fi
    fi
done
