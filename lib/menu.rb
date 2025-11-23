class Menu
  attr_accessor :selected_index, :menu_items, :shapes, :texts

  def initialize(window_width, window_height)
    @window_width = window_width
    @window_height = window_height
    @selected_index = 0
    @menu_items = ['Новая игра', 'Настройки', 'Выход']
    @shapes = {}
    @texts = {}
    @title_text = nil
    initialize_shapes
  end

  def initialize_shapes
    # Заголовок игры
    @title_text = Text.new(
      'VAMPIRE SURVIVAL',
      x: @window_width / 2,
      y: @window_height / 4,
      size: 60,
      color: 'red',
      font: nil
    )
    @title_text.x = @window_width / 2 - @title_text.width / 2

    # Подзаголовок
    @subtitle_text = Text.new(
      'Like Game',
      x: @window_width / 2,
      y: @window_height / 4 + 70,
      size: 30,
      color: 'white',
      font: nil
    )
    @subtitle_text.x = @window_width / 2 - @subtitle_text.width / 2

    # Загружаем и отображаем лучший рекорд
    load_and_display_high_score

    # Создаем тексты для пунктов меню
    @menu_items.each_with_index do |item, index|
      y_pos = @window_height / 2 + index * 60
      @texts[item] = Text.new(
        item,
        x: @window_width / 2,
        y: y_pos,
        size: 40,
        color: 'white',
        font: nil
      )
      @texts[item].x = @window_width / 2 - @texts[item].width / 2
    end
  end
  
  def load_and_display_high_score
    require_relative 'game'
    high_score = Game.load_high_score
    
    if high_score && high_score[:enemies_killed] > 0
      minutes = high_score[:time_alive] / 60
      seconds = high_score[:time_alive] % 60
      score_text = "Лучший результат: #{high_score[:enemies_killed]} убийств | Уровень: #{high_score[:level]} | Время: #{minutes}м #{seconds}с"
      
      @high_score_text = Text.new(
        score_text,
        x: @window_width / 2,
        y: @window_height / 4 + 120,
        size: 18,
        color: '#FFD700',
        font: nil
      )
      @high_score_text.x = @window_width / 2 - @high_score_text.width / 2
      
      @date_text = Text.new(
        "Дата: #{high_score[:date]}",
        x: @window_width / 2,
        y: @window_height / 4 + 145,
        size: 14,
        color: '#AAAAAA',
        font: nil
      )
      @date_text.x = @window_width / 2 - @date_text.width / 2
    else
      @high_score_text = Text.new(
        'Лучший результат: Нет рекордов',
        x: @window_width / 2,
        y: @window_height / 4 + 120,
        size: 18,
        color: '#888888',
        font: nil
      )
      @high_score_text.x = @window_width / 2 - @high_score_text.width / 2
      @date_text = nil
    end
  end

  def update
    # Обновляем цвета пунктов меню
    @menu_items.each_with_index do |item, index|
      if index == @selected_index
        @texts[item].color = 'yellow'
        @texts[item].size = 45
      else
        @texts[item].color = 'white'
        @texts[item].size = 40
      end
      # Пересчитываем позицию после изменения размера
      @texts[item].x = @window_width / 2 - @texts[item].width / 2
    end
  end

  def draw
    # Меню рисуется через тексты, которые уже созданы
    # Ruby2D автоматически отрисовывает их
  end

  def handle_key_down(key)
    case key
    when 'up', 'w'
      @selected_index = (@selected_index - 1) % @menu_items.length
    when 'down', 's'
      @selected_index = (@selected_index + 1) % @menu_items.length
    when 'return', 'enter', 'space'
      return select_item
    end
    nil
  end

  def select_item
    case @menu_items[@selected_index]
    when 'Новая игра'
      :new_game
    when 'Настройки'
      :settings
    when 'Выход'
      :exit
    end
  end

  def remove
    @title_text&.remove
    @subtitle_text&.remove
    @high_score_text&.remove
    @date_text&.remove
    @texts.values.each(&:remove)
  end
  
  def refresh_high_score
    # Обновляем отображение рекорда (например, после завершения игры)
    @high_score_text&.remove
    @date_text&.remove
    load_and_display_high_score
  end
end

