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
    @texts.values.each(&:remove)
  end
end

