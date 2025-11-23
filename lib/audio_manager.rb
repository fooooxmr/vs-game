class AudioManager
  def initialize
    @music_volume = 50
    @sfx_volume = 70
    @sounds = {}
    @music = nil
    load_sounds
  end

  def load_sounds
    # В Ruby2D можно использовать звуки, но для простоты создадим заглушки
    # В реальной реализации здесь будут загружаться звуковые файлы
    @sounds[:attack] = nil # Звук атаки
    @sounds[:enemy_hit] = nil # Звук попадания по врагу
    @sounds[:enemy_death] = nil # Звук смерти врага
    @sounds[:level_up] = nil # Звук повышения уровня
    @sounds[:pickup] = nil # Звук сбора опыта
  end

  def play_sound(sound_name)
    # Заглушка для звуков
    # В реальной реализации: @sounds[sound_name]&.play
  end

  def play_music
    # Заглушка для музыки
    # В реальной реализации: @music&.play(loop: true)
  end

  def stop_music
    # @music&.stop
  end

  def set_music_volume(volume)
    @music_volume = volume
    # @music&.volume = volume / 100.0 if @music
  end

  def set_sfx_volume(volume)
    @sfx_volume = volume
  end
end

