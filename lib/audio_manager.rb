require 'ruby2d'

class AudioManager
  def initialize(settings = nil)
    @settings = settings
    @music_volume = settings ? settings.music_volume : 50
    @sfx_volume = settings ? settings.sfx_volume : 70
    @sounds = {}
    @music = nil
    @sound_enabled = true
    load_sounds
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
        rescue => e
          puts "Не удалось загрузить звук #{path}: #{e.message}"
          @sounds[key] = nil
        end
      else
        @sounds[key] = nil
      end
    end
    
    puts "Загружено звуков: #{loaded_count}/#{sound_files.size}" if ENV['DEBUG']
    
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
      puts "Фоновая музыка не найдена (ищем sounds/music.ogg или sounds/music.wav)" if ENV['DEBUG']
    end
  end

  def play_sound(sound_name, volume_override = nil)
    return unless @sound_enabled
    return unless @sounds[sound_name]
    
    sound = @sounds[sound_name]
    volume = volume_override || @sfx_volume
    sound.volume = volume / 100.0
    sound.play
  rescue => e
    # Игнорируем ошибки воспроизведения звука
    puts "Ошибка воспроизведения звука #{sound_name}: #{e.message}" if ENV['DEBUG']
  end

  def play_music
    return unless @music
    @music.play
  rescue => e
    puts "Ошибка воспроизведения музыки: #{e.message}" if ENV['DEBUG']
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

