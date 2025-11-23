require 'json'

class Settings
  SETTINGS_FILE = 'settings.json'

  attr_accessor :music_volume, :sfx_volume, :fullscreen, :resolution_width, :resolution_height,
                :spawn_rate, :max_enemies, :difficulty, :player_speed, :enemy_speed, :difficulty_multiplier_base

  def initialize
    load_defaults
    load_from_file
  end

  def load_defaults
    @music_volume = 50      # 0-100
    @sfx_volume = 70        # 0-100
    @fullscreen = false
    @resolution_width = 800
    @resolution_height = 600
    @spawn_rate = 1.8       # секунды между спавном врагов
    @max_enemies = 50       # максимальное количество врагов
    @difficulty = 'normal'  # easy, normal, hard, nightmare
    @player_speed = 120     # пикселей в секунду
    @enemy_speed = 60       # пикселей в секунду
    @difficulty_multiplier_base = 1.0  # Базовый множитель сложности
  end

  def load_from_file
    return unless File.exist?(SETTINGS_FILE)

    begin
      data = JSON.parse(File.read(SETTINGS_FILE))
      @music_volume = data['music_volume'] || @music_volume
      @sfx_volume = data['sfx_volume'] || @sfx_volume
      @fullscreen = data['fullscreen'] || @fullscreen
      @resolution_width = data['resolution_width'] || @resolution_width
      @resolution_height = data['resolution_height'] || @resolution_height
      @spawn_rate = data['spawn_rate'] || @spawn_rate
      @max_enemies = data['max_enemies'] || @max_enemies
      @difficulty = data['difficulty'] || @difficulty
      @player_speed = data['player_speed'] || @player_speed
      @enemy_speed = data['enemy_speed'] || @enemy_speed
      @difficulty_multiplier_base = data['difficulty_multiplier_base'] || @difficulty_multiplier_base
      # Применяем сложность после загрузки
      apply_difficulty
    rescue JSON::ParserError, Errno::ENOENT
      # Если файл поврежден, используем значения по умолчанию
      load_defaults
    end
  end

  def save_to_file
    data = {
      'music_volume' => @music_volume,
      'sfx_volume' => @sfx_volume,
      'fullscreen' => @fullscreen,
      'resolution_width' => @resolution_width,
      'resolution_height' => @resolution_height,
      'spawn_rate' => @spawn_rate,
      'max_enemies' => @max_enemies,
      'difficulty' => @difficulty,
      'player_speed' => @player_speed,
      'enemy_speed' => @enemy_speed,
      'difficulty_multiplier_base' => @difficulty_multiplier_base
    }

    File.write(SETTINGS_FILE, JSON.pretty_generate(data))
  end

  def apply_difficulty
    case @difficulty
    when 'easy'
      # Легкая сложность - медленный спавн, меньше врагов, игрок быстрее
      @spawn_rate = 2.5
      @max_enemies = 30
      @enemy_speed = 50
      @player_speed = 130
      @difficulty_multiplier_base = 0.8  # -20% к сложности
    when 'normal'
      # Нормальная сложность - сбалансированная
      @spawn_rate = 1.8
      @max_enemies = 50
      @enemy_speed = 60
      @player_speed = 120
      @difficulty_multiplier_base = 1.0  # Базовая сложность
    when 'hard'
      # Сложная - быстрый спавн, больше врагов
      @spawn_rate = 1.2
      @max_enemies = 80
      @enemy_speed = 70
      @player_speed = 110
      @difficulty_multiplier_base = 1.3  # +30% к сложности
    when 'nightmare'
      # Кошмар - очень сложно
      @spawn_rate = 0.8
      @max_enemies = 120
      @enemy_speed = 80
      @player_speed = 100
      @difficulty_multiplier_base = 1.6  # +60% к сложности
    else
      # По умолчанию нормальная
      @spawn_rate = 1.8
      @max_enemies = 50
      @enemy_speed = 60
      @player_speed = 120
      @difficulty_multiplier_base = 1.0
    end
  end

  def get_resolution_preset
    case "#{@resolution_width}x#{@resolution_height}"
    when '640x480'
      '640x480'
    when '800x600'
      '800x600'
    when '1024x768'
      '1024x768'
    when '1280x720'
      '1280x720'
    when '1920x1080'
      '1920x1080'
    else
      'custom'
    end
  end
end

