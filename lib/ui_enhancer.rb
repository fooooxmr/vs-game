class UIEnhancer
  def self.create_upgrade_window(window_width, window_height)
    # Создаем красивое окно для улучшений в стиле выбора персонажа
    shapes = {}
    
    # Темный фон с градиентом
    shapes[:bg] = Rectangle.new(
      x: 0,
      y: 0,
      width: window_width,
      height: window_height,
      color: [5, 5, 15, 0.95]
    )
    
    # Основное окно
    window_x = window_width / 2 - 350
    window_y = window_height / 2 - 200
    window_w = 700
    window_h = 400
    
    # Основной фон окна - более светлый для лучшей читаемости
    shapes[:bg_main] = Rectangle.new(
      x: window_x,
      y: window_y,
      width: window_w,
      height: window_h,
      color: [25, 25, 30, 0.98]
    )
    
    # Внутренняя рамка - золотая, более яркая
    shapes[:border] = Rectangle.new(
      x: window_x + 5,
      y: window_y + 5,
      width: window_w - 10,
      height: window_h - 10,
      color: [255, 200, 0, 0.95]
    )
    
    # Внутренний фон - более светлый для контраста с текстом
    shapes[:inner_bg] = Rectangle.new(
      x: window_x + 10,
      y: window_y + 10,
      width: window_w - 20,
      height: window_h - 20,
      color: [20, 20, 25, 0.98]
    )
    
    shapes
  end

  def self.create_upgrade_card(window_width, window_height, y_pos, selected = false)
    card_width = 650
    card_height = 90
    x = window_width / 2 - card_width / 2
    
    shapes = {}
    
    # Эффект свечения для выбранной карточки
    if selected
      # Множественные слои для эффекта свечения
      3.times do |i|
        glow_size = 10 + i * 5
        alpha = 0.3 - i * 0.1
        shapes["glow_#{i}".to_sym] = Rectangle.new(
          x: x - glow_size,
          y: y_pos - glow_size,
          width: card_width + glow_size * 2,
          height: card_height + glow_size * 2,
          color: [255, 100 + i * 20, 0, alpha]
        )
      end
    end
    
    # Основной фон карточки - более светлый для лучшей читаемости
    bg_color = selected ? [40, 30, 20, 0.95] : [30, 30, 35, 0.9]
    shapes[:bg] = Rectangle.new(
      x: x,
      y: y_pos,
      width: card_width,
      height: card_height,
      color: bg_color
    )
    
    # Внутренняя рамка - более контрастная
    border_color = selected ? [255, 200, 0, 0.9] : [120, 120, 140, 0.8]
    shapes[:border] = Rectangle.new(
      x: x + 5,
      y: y_pos + 5,
      width: card_width - 10,
      height: card_height - 10,
      color: border_color
    )
    
    # Внутренний фон - более светлый для контраста с текстом
    inner_bg = selected ? [50, 40, 30, 0.95] : [35, 35, 40, 0.9]
    shapes[:inner] = Rectangle.new(
      x: x + 10,
      y: y_pos + 10,
      width: card_width - 20,
      height: card_height - 20,
      color: inner_bg
    )
    
    shapes
  end
end

