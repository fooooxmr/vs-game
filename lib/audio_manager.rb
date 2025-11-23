require 'ruby2d'

class AudioManager
  def initialize(settings = nil)
    @settings = settings
    @music_volume = settings ? settings.music_volume : 50
    @sfx_volume = settings ? settings.sfx_volume : 70
    @sounds = {}
    @music = nil
    @sound_enabled = true
    
    # Проверяем, что громкость не равна 0
    if @sfx_volume == 0
      puts "⚠️  ВНИМАНИЕ: Громкость звуковых эффектов установлена в 0!"
      puts "   Установите sfx_volume > 0 в настройках для воспроизведения звуков"
    end
    
    puts "🔊 Инициализация AudioManager (SFX: #{@sfx_volume}%, Music: #{@music_volume}%)"
    # ВАЖНО: В Ruby2D звуки нужно загружать ПОСЛЕ создания и показа окна
    # Загружаем звуки сразу, но если не получится - перезагрузим при первом воспроизведении
    @sounds_loaded = false
    load_sounds
    @sounds_loaded = true
  end

  def load_sounds
    # Загружаем звуковые эффекты (если файлы существуют)
    sound_files = {
      attack: 'sounds/attack.wav',
      enemy_hit: 'sounds/enemy_hit.wav',
      enemy_death: 'sounds/enemy_death.wav',
      level_up: 'sounds/level_up.wav',
      pickup: 'sounds/pickup.wav',
      chest_open: 'sounds/chest_open.wav',
      upgrade_select: 'sounds/upgrade_select.wav',
      player_hit: 'sounds/player_hit.wav',
      boss_spawn: 'sounds/boss_spawn.wav',
      elite_attack: 'sounds/elite_attack.wav',
      projectile_shoot: 'sounds/projectile_shoot.wav',
      barrel_explode: 'sounds/barrel_explode.wav'
    }
    
    loaded_count = 0
    sound_files.each do |key, path|
      if File.exist?(path)
        begin
          @sounds[key] = Sound.new(path)
          loaded_count += 1
          puts "  ✓ #{key}: #{path}" if ENV['DEBUG']
        rescue => e
          puts "  ❌ Не удалось загрузить звук #{path}: #{e.message}"
          puts "     #{e.backtrace.first}" if ENV['DEBUG']
          @sounds[key] = nil
        end
      else
        puts "  ⚠️  Файл не найден: #{path}" if ENV['DEBUG']
        @sounds[key] = nil
      end
    end
    
    if loaded_count == 0
      puts "⚠️  ВНИМАНИЕ: Звуковые файлы не найдены в папке sounds/"
      puts "   Скачайте звуки согласно инструкции в sounds/README.md"
    else
      puts "✓ Загружено звуков: #{loaded_count}/#{sound_files.size}"
      # Выводим список загруженных звуков для отладки
      loaded_sounds = @sounds.select { |k, v| v != nil }.keys
      puts "   Загруженные звуки: #{loaded_sounds.join(', ')}"
    end
    
    # Загружаем фоновую музыку (если есть)
    if File.exist?('sounds/music.ogg') || File.exist?('sounds/music.wav')
      music_path = File.exist?('sounds/music.ogg') ? 'sounds/music.ogg' : 'sounds/music.wav'
      begin
        @music = Music.new(music_path)
        @music.loop = true
        @music.volume = @music_volume / 100.0
        puts "Фоновая музыка загружена: #{music_path}" if ENV['DEBUG']
      rescue => e
        puts "Не удалось загрузить музыку: #{e.message}"
        @music = nil
      end
    else
      puts "⚠️  Фоновая музыка не найдена (ищем sounds/music.ogg или sounds/music.wav)"
      puts "   Добавьте файл music.ogg или music.wav в папку sounds/ для фоновой музыки"
    end
  end

  def play_sound(sound_name, volume_override = nil)
    return unless @sound_enabled
    
    # Перезагружаем звук, если он не загружен или если была ошибка при первой загрузке
    # Это нужно, потому что в Ruby2D звуки могут не загрузиться до показа окна
    unless @sounds[sound_name] && @sounds[sound_name].respond_to?(:play)
      # Пробуем загрузить звук заново
      sound_files = {
        attack: 'sounds/attack.wav',
        enemy_hit: 'sounds/enemy_hit.wav',
        enemy_death: 'sounds/enemy_death.wav',
        level_up: 'sounds/level_up.wav',
        pickup: 'sounds/pickup.wav',
        chest_open: 'sounds/chest_open.wav',
        upgrade_select: 'sounds/upgrade_select.wav',
        player_hit: 'sounds/player_hit.wav',
        boss_spawn: 'sounds/boss_spawn.wav',
        elite_attack: 'sounds/elite_attack.wav',
        projectile_shoot: 'sounds/projectile_shoot.wav',
        barrel_explode: 'sounds/barrel_explode.wav'
      }
      
      path = sound_files[sound_name]
      if path && File.exist?(path)
        begin
          @sounds[sound_name] = Sound.new(path)
          puts "  ✓ Перезагружен звук: #{sound_name}" if ENV['DEBUG']
        rescue => e
          puts "  ❌ Не удалось перезагрузить звук #{path}: #{e.message}"
          return
        end
      else
        puts "⚠️  Звук #{sound_name} не загружен (файл не найден: #{path})"
        return
      end
    end
    
    begin
      sound = @sounds[sound_name]
      volume = volume_override || @sfx_volume
      
      # Проверяем, что звук валиден
      unless sound.respond_to?(:play)
        puts "❌ Звук #{sound_name} не является валидным объектом Sound"
        return
      end
      
      sound.volume = [volume / 100.0, 1.0].min  # Ограничиваем громкость до 1.0
      sound.play
      puts "🔊 Воспроизведен звук: #{sound_name} (громкость: #{volume}%)" if ENV['DEBUG']
    rescue => e
      # Выводим ошибки воспроизведения звука для отладки
      puts "❌ Ошибка воспроизведения звука #{sound_name}: #{e.message}"
      puts "   #{e.backtrace.first}" if ENV['DEBUG']
    end
  end
    # Выводим ошибки воспроизведения звука для отладки
    puts "❌ Ошибка воспроизведения звука #{sound_name}: #{e.message}"
    puts "   #{e.backtrace.first}" if ENV['DEBUG']
  end

  def play_music
    return unless @music
    @music.play
    puts "🎵 Фоновая музыка запущена (громкость: #{@music_volume}%)"
  rescue => e
    puts "❌ Ошибка воспроизведения музыки: #{e.message}"
    puts "   #{e.backtrace.first}" if ENV['DEBUG']
  end

  def stop_music
    @music&.stop
  end

  def set_music_volume(volume)
    @music_volume = volume
    @music.volume = volume / 100.0 if @music
  end

  def set_sfx_volume(volume)
    @sfx_volume = volume
  end
  
  def update_settings(settings)
    @settings = settings
    set_music_volume(settings.music_volume) if settings
    set_sfx_volume(settings.sfx_volume) if settings
  end
end

