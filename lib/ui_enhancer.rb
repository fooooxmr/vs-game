class UIEnhancer
  def self.create_upgrade_window(window_width, window_height)
    # Создаем красивое окно для улучшений в стиле выбора персонажа
    shapes = {}
    
    # Темный фон с градиентом - высокий z-индекс, чтобы перекрывать все UI
    shapes[:bg] = Rectangle.new(
      x: 0,
      y: 0,
      width: window_width,
      height: window_height,
      color: [5, 5, 15, 0.95],
      z: 2000
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
      color: [25, 25, 30, 0.98],
      z: 2001
    )
    
    # Черная внешняя рамка
    shapes[:outer_border] = Rectangle.new(
      x: window_x - 2,
      y: window_y - 2,
      width: window_w + 4,
      height: window_h + 4,
      color: [0, 0, 0, 1.0],
      z: 2001
    )
    
    # Внутренняя рамка - золотая, более яркая
    shapes[:border] = Rectangle.new(
      x: window_x + 5,
      y: window_y + 5,
      width: window_w - 10,
      height: window_h - 10,
      color: [255, 200, 0, 0.95],
      z: 2002
    )
    
    # Черная внутренняя рамка для контраста
    shapes[:inner_border] = Rectangle.new(
      x: window_x + 8,
      y: window_y + 8,
      width: window_w - 16,
      height: window_h - 16,
      color: [0, 0, 0, 1.0],
      z: 2003
    )
    
    # Внутренний фон - более светлый для контраста с текстом
    shapes[:inner_bg] = Rectangle.new(
      x: window_x + 10,
      y: window_y + 10,
      width: window_w - 20,
      height: window_h - 20,
      color: [35, 35, 40, 0.98],
      z: 2004
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
          color: [255, 100 + i * 20, 0, alpha],
          z: 2004 + i
        )
      end
    end
    
    # Черная внешняя рамка
    shapes[:outer_border] = Rectangle.new(
      x: x - 2,
      y: y_pos - 2,
      width: card_width + 4,
      height: card_height + 4,
      color: [0, 0, 0, 1.0],
      z: 2006
    )
    
    # Основной фон карточки - более светлый для лучшей читаемости
    bg_color = selected ? [50, 40, 30, 0.95] : [40, 40, 45, 0.9]
    shapes[:bg] = Rectangle.new(
      x: x,
      y: y_pos,
      width: card_width,
      height: card_height,
      color: bg_color,
      z: 2007
    )
    
    # Внутренняя рамка - более контрастная
    border_color = selected ? [255, 200, 0, 0.9] : [120, 120, 140, 0.8]
    shapes[:border] = Rectangle.new(
      x: x + 3,
      y: y_pos + 3,
      width: card_width - 6,
      height: card_height - 6,
      color: border_color,
      z: 2008
    )
    
    # Черная внутренняя рамка для контраста
    shapes[:inner_border] = Rectangle.new(
      x: x + 6,
      y: y_pos + 6,
      width: card_width - 12,
      height: card_height - 12,
      color: [0, 0, 0, 1.0],
      z: 2009
    )
    
    # Внутренний фон - более светлый для контраста с текстом
    inner_bg = selected ? [60, 50, 40, 0.95] : [45, 45, 50, 0.9]
    shapes[:inner] = Rectangle.new(
      x: x + 8,
      y: y_pos + 8,
      width: card_width - 16,
      height: card_height - 16,
      color: inner_bg,
      z: 2010
    )
    
    shapes
  end

  def self.create_classic_upgrade_card(window_width, window_height, y_pos, selected = false)
    # Классическая карточка в стиле VS - большая, горизонтальная
    card_width = 800
    card_height = 120
    x = window_width / 2 - card_width / 2
    
    shapes = {}
    
    # Эффект свечения для выбранной карточки
    if selected
      3.times do |i|
        glow_size = 15 + i * 5
        alpha = 0.4 - i * 0.1
        shapes["glow_#{i}".to_sym] = Rectangle.new(
          x: x - glow_size,
          y: y_pos - glow_size,
          width: card_width + glow_size * 2,
          height: card_height + glow_size * 2,
          color: [255, 215, 0, alpha]
        )
      end
    end
    
    # Черная внешняя рамка
    shapes[:outer_border] = Rectangle.new(
      x: x - 3,
      y: y_pos - 3,
      width: card_width + 6,
      height: card_height + 6,
      color: [0, 0, 0, 1.0],
      z: 2004
    )
    
    # Основной фон карточки - более светлый для читаемости
    bg_color = selected ? [55, 45, 35, 0.98] : [35, 35, 40, 0.95]
    shapes[:bg] = Rectangle.new(
      x: x,
      y: y_pos,
      width: card_width,
      height: card_height,
      color: bg_color,
      z: 2005
    )
    
    # Внутренняя рамка
    border_color = selected ? [255, 215, 0, 1.0] : [100, 100, 120, 0.9]
    shapes[:border] = Rectangle.new(
      x: x + 3,
      y: y_pos + 3,
      width: card_width - 6,
      height: card_height - 6,
      color: border_color,
      z: 2006
    )
    
    # Черная внутренняя рамка для контраста
    shapes[:inner_border] = Rectangle.new(
      x: x + 6,
      y: y_pos + 6,
      width: card_width - 12,
      height: card_height - 12,
      color: [0, 0, 0, 1.0],
      z: 2007
    )
    
    # Внутренний фон - более светлый для читаемости
    inner_bg = selected ? [65, 55, 45, 0.98] : [40, 40, 45, 0.95]
    shapes[:inner] = Rectangle.new(
      x: x + 8,
      y: y_pos + 8,
      width: card_width - 16,
      height: card_height - 16,
      color: inner_bg,
      z: 2008
    )
    
    # Разделительная линия между иконкой/названием и описанием
    shapes[:divider] = Line.new(
      x1: x + card_width / 2 - 50,
      y1: y_pos + 10,
      x2: x + card_width / 2 - 50,
      y2: y_pos + card_height - 10,
      width: 2,
      color: selected ? [255, 215, 0, 0.5] : [100, 100, 120, 0.5],
      z: 2009
    )
    
    shapes
  end
end

