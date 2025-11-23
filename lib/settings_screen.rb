class SettingsScreen
  attr_accessor :selected_category, :selected_index, :settings, :categories, :shapes, :texts

  def initialize(window_width, window_height, settings)
    @window_width = window_width
    @window_height = window_height
    @settings = settings
    @selected_category = 0
    @selected_index = 0
    @categories = ['Звук', 'Графика', 'Игровые', 'Назад']
    @shapes = {}
    @texts = {}
    @current_category_items = []
    initialize_shapes
    update_category_items
  end

  def initialize_shapes
    # Заголовок
    @title_text = Text.new(
      'НАСТРОЙКИ',
      x: @window_width / 2,
      y: 50,
      size: 50,
      color: 'white',
      font: nil
    )
    @title_text.x = @window_width / 2 - @title_text.width / 2

    # Создаем тексты для категорий
    @categories.each_with_index do |category, index|
      y_pos = 120 + index * 50
      @texts["category_#{index}"] = Text.new(
        category,
        x: 50,
        y: y_pos,
        size: 30,
        color: 'white',
        font: nil
      )
    end

    # Область для настроек (справа)
    @settings_start_x = 300
    @settings_start_y = 120
    
    # Подсказка внизу экрана
    @hint_text = Text.new(
      'Используйте A/D или ←/→ для изменения значений. ESC - назад',
      x: @window_width / 2,
      y: @window_height - 30,
      size: 18,
      color: 'gray',
      font: nil
    )
    @hint_text.x = @window_width / 2 - @hint_text.width / 2
  end

  def update_category_items
    case @categories[@selected_category]
    when 'Звук'
      @current_category_items = [
        { name: 'Громкость музыки', value: @settings.music_volume, type: :slider, min: 0, max: 100 },
        { name: 'Громкость звуков', value: @settings.sfx_volume, type: :slider, min: 0, max: 100 }
      ]
    when 'Графика'
      @current_category_items = [
        { name: 'Разрешение', value: "#{@settings.resolution_width}x#{@settings.resolution_height}", type: :select, options: ['640x480', '800x600', '1024x768', '1280x720', '1920x1080'] },
        { name: 'Полноэкранный', value: @settings.fullscreen, type: :toggle }
      ]
    when 'Игровые'
      @current_category_items = [
        { name: 'Сложность', value: @settings.difficulty, type: :select, options: ['easy', 'normal', 'hard'] },
        { name: 'Скорость спавна', value: @settings.spawn_rate, type: :slider, min: 0.5, max: 5.0, step: 0.5 },
        { name: 'Макс. врагов', value: @settings.max_enemies, type: :slider, min: 10, max: 50, step: 5 }
      ]
    when 'Назад'
      @current_category_items = []
    end

    @selected_index = 0
    update_settings_texts
  end

  def update_settings_texts
    # Удаляем старые тексты настроек
    @texts.select { |k, _| k.start_with?('setting_') }.each do |_, text|
      text.remove
    end
    @texts.reject! { |k, _| k.start_with?('setting_') }

    # Создаем новые тексты
    @current_category_items.each_with_index do |item, index|
      y_pos = @settings_start_y + index * 50
      display_value = format_setting_value(item)
      
      @texts["setting_#{index}"] = Text.new(
        "#{item[:name]}: #{display_value}",
        x: @settings_start_x,
        y: y_pos,
        size: 25,
        color: index == @selected_index ? 'yellow' : 'white',
        font: nil
      )
    end
  end

  def format_setting_value(item)
    case item[:type]
    when :slider
      if item[:name].include?('Громкость')
        "#{item[:value]}%"
      elsif item[:name].include?('Скорость спавна')
        "#{item[:value]}с"
      else
        item[:value].to_s
      end
    when :toggle
      item[:value] ? 'Вкл' : 'Выкл'
    when :select
      item[:value].to_s.capitalize
    else
      item[:value].to_s
    end
  end

  def update
    # Обновляем цвета категорий
    @categories.each_with_index do |_, index|
      text = @texts["category_#{index}"]
      if index == @selected_category
        text.color = 'yellow'
        text.size = 35
      else
        text.color = 'white'
        text.size = 30
      end
    end

    update_settings_texts
  end

  def draw
    # Все рисуется через тексты
  end

  def handle_key_down(key)
    case key
    when 'left', 'a'
      if @selected_category > 0
        @selected_category -= 1
        update_category_items
      end
    when 'right', 'd'
      if @selected_category < @categories.length - 1
        @selected_category += 1
        update_category_items
      end
    when 'up', 'w'
      if @current_category_items.length > 0
        @selected_index = (@selected_index - 1) % @current_category_items.length
      end
    when 'down', 's'
      if @current_category_items.length > 0
        @selected_index = (@selected_index + 1) % @current_category_items.length
      end
    when 'return', 'enter'
      return select_item
    when 'escape'
      return :back
    end

    # Изменение значений (только если не навигация по категориям)
    if @current_category_items.length > 0 && @selected_index < @current_category_items.length
      item = @current_category_items[@selected_index]
      # Изменяем значения только если не переключаем категории
      if key == 'left' && @selected_category > 0
        # Это навигация по категориям, не меняем значение
      elsif key == 'right' && @selected_category < @categories.length - 1
        # Это навигация по категориям, не меняем значение
      elsif ['left', 'right', 'a', 'd'].include?(key)
        # Изменяем значение настройки
        direction = (key == 'right' || key == 'd') ? 1 : -1
        change_setting(direction)
      end
    end

    nil
  end

  def change_setting(direction)
    return if @current_category_items.empty?

    item = @current_category_items[@selected_index]
    return if item[:name] == 'Назад'

    case item[:type]
    when :slider
      step = item[:step] || 1
      new_value = item[:value] + (direction * step)
      new_value = [[new_value, item[:min]].max, item[:max]].min
      item[:value] = new_value
      
      # Применяем к настройкам
      case item[:name]
      when 'Громкость музыки'
        @settings.music_volume = new_value.to_i
      when 'Громкость звуков'
        @settings.sfx_volume = new_value.to_i
      when 'Скорость спавна'
        @settings.spawn_rate = new_value
      when 'Макс. врагов'
        @settings.max_enemies = new_value.to_i
      end
    when :toggle
      item[:value] = !item[:value]
      @settings.fullscreen = item[:value] if item[:name] == 'Полноэкранный'
    when :select
      options = item[:options]
      current_index = options.index(item[:value].to_s)
      if current_index
        new_index = (current_index + direction) % options.length
        item[:value] = options[new_index]
        
        # Применяем к настройкам
        case item[:name]
        when 'Разрешение'
          width, height = options[new_index].split('x').map(&:to_i)
          @settings.resolution_width = width
          @settings.resolution_height = height
          # Примечание: изменение размера окна требует перезапуска игры
          # Настройки сохраняются и применятся при следующем запуске
        when 'Сложность'
          @settings.difficulty = options[new_index]
          @settings.apply_difficulty
          # Обновляем значения в других настройках
          update_category_items
        end
      end
    end
  end

  def select_item
    return :back if @categories[@selected_category] == 'Назад'
    nil
  end

  def remove
    @title_text&.remove
    @hint_text&.remove
    @texts.values.each(&:remove)
  end
end

