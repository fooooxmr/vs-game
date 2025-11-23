require_relative 'sprite_renderer'

class MapObject
  attr_accessor :x, :y, :type, :solid, :interactive, :shapes, :size, :opened, :destroyed, :highlighted, :interaction_progress

  OBJECT_TYPES = {
    # Непроходимые объекты
    tree: { solid: true, interactive: false, size: 30 },
    big_tree: { solid: true, interactive: false, size: 40 },
    rock: { solid: true, interactive: false, size: 25 },
    big_rock: { solid: true, interactive: false, size: 35 },
    wall: { solid: true, interactive: false, size: 20 },
    tombstone: { solid: true, interactive: false, size: 20 },
    
    # Интерактивные объекты
    chest: { solid: false, interactive: true, size: 25 },
    free_chest: { solid: false, interactive: true, size: 25 },
    lamp: { solid: false, interactive: false, size: 15 },
    barrel: { solid: true, interactive: true, size: 20 },
    
    # Декоративные (проходимые)
    grass_patch: { solid: false, interactive: false, size: 15 },
    flower: { solid: false, interactive: false, size: 10 },
    bush: { solid: false, interactive: false, size: 20 }
  }.freeze

  def initialize(x, y, type)
    @x = x
    @y = y
    @type = type
    @object_data = OBJECT_TYPES[type] || OBJECT_TYPES[:tree]
    @solid = @object_data[:solid]
    @interactive = @object_data[:interactive]
    @size = @object_data[:size]
    @shapes = []
    @sprite = nil
    @shape_offsets = [] # Сохраняем смещения фигур от центра объекта
    @opened = false
    @destroyed = false
    @destroying = false # Флаг начала разрушения (для ящиков)
    @highlighted = false
    @highlight_shape = nil
    @interaction_progress = 0.0 # Прогресс взаимодействия (0.0 - 1.0)
    @interaction_time = 0.0 # Время, которое игрок стоит рядом
    @interaction_required_time = 3.5 # Время, необходимое для открытия (секунды) - увеличено с 2.0
    @progress_shapes = [] # Фигуры для отображения прогресса
    create_shapes
  end

  def create_shapes
    case @type
    when :tree
      create_tree_shapes
    when :big_tree
      create_big_tree_shapes
    when :rock
      create_rock_shapes
    when :big_rock
      create_big_rock_shapes
    when :wall
      create_wall_shapes
    when :tombstone
      create_tombstone_shapes
    when :chest
      create_chest_shapes
    when :free_chest
      create_free_chest_shapes
    when :lamp
      create_lamp_shapes
    when :barrel
      create_barrel_shapes
    when :grass_patch
      create_grass_patch_shapes
    when :flower
      create_flower_shapes
    when :bush
      create_bush_shapes
    when :altar
      create_altar_shapes
    when :portal
      create_portal_shapes
    end
  end

  def create_tree_shapes
    # Ствол - создаем с нулевыми координатами, позиция будет установлена в update_positions
    @shapes << Rectangle.new(
      x: 0,
      y: 0,
      width: 8,
      height: 20,
      color: '#8B4513'
    )
    @shape_offsets << { x: -4, y: -5 }
    
    # Крона (зеленая)
    @shapes << Circle.new(
      x: 0,
      y: 0,
      radius: 15,
      color: '#228B22'
    )
    @shape_offsets << { x: 0, y: -15 }
    
    # Детали кроны
    @shapes << Circle.new(
      x: 0,
      y: 0,
      radius: 10,
      color: '#32CD32'
    )
    @shape_offsets << { x: -8, y: -18 }
    
    @shapes << Circle.new(
      x: 0,
      y: 0,
      radius: 10,
      color: '#32CD32'
    )
    @shape_offsets << { x: 8, y: -18 }
  end

  def create_big_tree_shapes
    # Большой ствол
    @shapes << Rectangle.new(
      x: 0,
      y: 0,
      width: 12,
      height: 25,
      color: '#654321'
    )
    @shape_offsets << { x: -6, y: -5 }
    
    # Большая крона
    @shapes << Circle.new(
      x: 0,
      y: 0,
      radius: 20,
      color: '#228B22'
    )
    @shape_offsets << { x: 0, y: -20 }
    
    @shapes << Circle.new(
      x: 0,
      y: 0,
      radius: 15,
      color: '#32CD32'
    )
    @shape_offsets << { x: -12, y: -25 }
    
    @shapes << Circle.new(
      x: 0,
      y: 0,
      radius: 15,
      color: '#32CD32'
    )
    @shape_offsets << { x: 12, y: -25 }
    
    @shapes << Circle.new(
      x: 0,
      y: 0,
      radius: 12,
      color: '#228B22'
    )
    @shape_offsets << { x: 0, y: -30 }
  end

  def create_rock_shapes
    # Камень (неправильной формы)
    @shapes << Circle.new(
      x: 0,
      y: 0,
      radius: 12,
      color: '#696969'
    )
    @shape_offsets << { x: 0, y: 0 }
    
    @shapes << Circle.new(
      x: 0,
      y: 0,
      radius: 8,
      color: '#808080'
    )
    @shape_offsets << { x: -5, y: -3 }
    
    @shapes << Circle.new(
      x: 0,
      y: 0,
      radius: 8,
      color: '#A9A9A9'
    )
    @shape_offsets << { x: 5, y: 3 }
  end

  def create_big_rock_shapes
    # Большой камень
    @shapes << Circle.new(
      x: 0,
      y: 0,
      radius: 18,
      color: '#696969'
    )
    @shape_offsets << { x: 0, y: 0 }
    
    @shapes << Circle.new(
      x: 0,
      y: 0,
      radius: 12,
      color: '#808080'
    )
    @shape_offsets << { x: -8, y: -5 }
    
    @shapes << Circle.new(
      x: 0,
      y: 0,
      radius: 12,
      color: '#A9A9A9'
    )
    @shape_offsets << { x: 8, y: 5 }
    
    @shapes << Circle.new(
      x: 0,
      y: 0,
      radius: 10,
      color: '#778899'
    )
    @shape_offsets << { x: 0, y: -8 }
  end

  def create_wall_shapes
    # Стена (кирпичная)
    @shapes << Rectangle.new(
      x: 0,
      y: 0,
      width: 20,
      height: 20,
      color: '#8B7355'
    )
    @shape_offsets << { x: -10, y: -10 }
    
    # Кирпичи
    @shapes << Rectangle.new(
      x: 0,
      y: 0,
      width: 20,
      height: 6,
      color: '#A0826D'
    )
    @shape_offsets << { x: -10, y: -10 }
    
    @shapes << Rectangle.new(
      x: 0,
      y: 0,
      width: 20,
      height: 6,
      color: '#A0826D'
    )
    @shape_offsets << { x: -10, y: -2 }
    
    @shapes << Rectangle.new(
      x: 0,
      y: 0,
      width: 20,
      height: 6,
      color: '#A0826D'
    )
    @shape_offsets << { x: -10, y: 6 }
  end

  def create_tombstone_shapes
    # Основание
    @shapes << Rectangle.new(
      x: 0,
      y: 0,
      width: 12,
      height: 8,
      color: '#708090'
    )
    @shape_offsets << { x: -6, y: 5 }
    
    # Плита
    @shapes << Rectangle.new(
      x: 0,
      y: 0,
      width: 16,
      height: 12,
      color: '#778899'
    )
    @shape_offsets << { x: -8, y: -5 }
    
    # Крест
    @shapes << Rectangle.new(
      x: 0,
      y: 0,
      width: 2,
      height: 8,
      color: '#696969'
    )
    @shape_offsets << { x: -1, y: -10 }
    
    @shapes << Rectangle.new(
      x: 0,
      y: 0,
      width: 8,
      height: 2,
      color: '#696969'
    )
    @shape_offsets << { x: -4, y: -7 }
  end

  def create_chest_shapes
    # Основание сундука
    @shapes << Rectangle.new(
      x: 0,
      y: 0,
      width: 24,
      height: 8,
      color: '#8B4513'
    )
    @shape_offsets << { x: -12, y: 3 }
    
    # Крышка
    @shapes << Rectangle.new(
      x: 0,
      y: 0,
      width: 24,
      height: 10,
      color: '#A0522D'
    )
    @shape_offsets << { x: -12, y: -5 }
    
    # Металлические обручи
    @shapes << Rectangle.new(
      x: 0,
      y: 0,
      width: 24,
      height: 2,
      color: '#C0C0C0'
    )
    @shape_offsets << { x: -12, y: -2 }
    
    @shapes << Rectangle.new(
      x: 0,
      y: 0,
      width: 24,
      height: 2,
      color: '#C0C0C0'
    )
    @shape_offsets << { x: -12, y: 5 }
    
    # Замок
    @shapes << Circle.new(
      x: 0,
      y: 0,
      radius: 3,
      color: '#FFD700'
    )
    @shape_offsets << { x: 0, y: 0 }
    
    # Желтая обводка (1 пиксель) вокруг сундука, если интерактивный и не открыт
    unless @opened
      # Размеры сундука: ширина 24, высота 10 (крышка) + 8 (основание) = 18
      chest_width = 24
      chest_height = 18
      border_width = 1
      
      # Верхняя линия
      @shapes.unshift(Rectangle.new(
        x: 0,
        y: 0,
        width: chest_width + border_width * 2,
        height: border_width,
        color: [255, 255, 0, 1.0], # Желтая обводка
        z: 502
      ))
      @shape_offsets.unshift({ x: -(chest_width / 2 + border_width), y: -(chest_height / 2) })
      
      # Нижняя линия
      @shapes.unshift(Rectangle.new(
        x: 0,
        y: 0,
        width: chest_width + border_width * 2,
        height: border_width,
        color: [255, 255, 0, 1.0],
        z: 502
      ))
      @shape_offsets.unshift({ x: -(chest_width / 2 + border_width), y: chest_height / 2 })
      
      # Левая линия
      @shapes.unshift(Rectangle.new(
        x: 0,
        y: 0,
        width: border_width,
        height: chest_height,
        color: [255, 255, 0, 1.0],
        z: 502
      ))
      @shape_offsets.unshift({ x: -(chest_width / 2 + border_width), y: 0 })
      
      # Правая линия
      @shapes.unshift(Rectangle.new(
        x: 0,
        y: 0,
        width: border_width,
        height: chest_height,
        color: [255, 255, 0, 1.0],
        z: 502
      ))
      @shape_offsets.unshift({ x: chest_width / 2 + border_width, y: 0 })
    end
  end

  def create_lamp_shapes
    # Основание
    @shapes << Rectangle.new(
      x: 0,
      y: 0,
      width: 4,
      height: 8,
      color: '#8B4513'
    )
    @shape_offsets << { x: -2, y: 5 }
    
    # Столб
    @shapes << Rectangle.new(
      x: 0,
      y: 0,
      width: 2,
      height: 10,
      color: '#654321'
    )
    @shape_offsets << { x: -1, y: -3 }
    
    # Фонарь
    @shapes << Circle.new(
      x: 0,
      y: 0,
      radius: 5,
      color: '#FFD700'
    )
    @shape_offsets << { x: 0, y: -5 }
    
    # Свет
    @shapes << Circle.new(
      x: 0,
      y: 0,
      radius: 3,
      color: '#FFFF00'
    )
    @shape_offsets << { x: 0, y: -5 }
  end

  def create_free_chest_shapes
    # Бесплатный сундук - золотой, выглядит по-другому
    # Основание
    @shapes << Rectangle.new(
      x: 0, y: 0,
      width: 24, height: 8,
      color: '#FFD700' # Золотой
    )
    @shape_offsets << { x: -12, y: 3 }
    
    # Крышка (открыта)
    @shapes << Rectangle.new(
      x: 0, y: 0,
      width: 24, height: 6,
      color: '#FFA500' # Оранжево-золотой
    )
    @shape_offsets << { x: -12, y: -3 }
    
    # Светящийся эффект
    @shapes << Circle.new(
      x: 0, y: 0,
      radius: 15,
      color: [255, 215, 0, 0.3] # Полупрозрачный золотой
    )
    @shape_offsets << { x: 0, y: 0 }
    
    # Желтая обводка
    unless @opened
      chest_width = 24
      chest_height = 14
      border_width = 1
      
      4.times do |i|
        case i
        when 0 # Верх
          @shapes.unshift(Rectangle.new(x: 0, y: 0, width: chest_width + border_width * 2, height: border_width, color: [255, 255, 0, 1.0], z: 502))
          @shape_offsets.unshift({ x: -(chest_width / 2 + border_width), y: -(chest_height / 2) })
        when 1 # Низ
          @shapes.unshift(Rectangle.new(x: 0, y: 0, width: chest_width + border_width * 2, height: border_width, color: [255, 255, 0, 1.0], z: 502))
          @shape_offsets.unshift({ x: -(chest_width / 2 + border_width), y: chest_height / 2 })
        when 2 # Лево
          @shapes.unshift(Rectangle.new(x: 0, y: 0, width: border_width, height: chest_height, color: [255, 255, 0, 1.0], z: 502))
          @shape_offsets.unshift({ x: -(chest_width / 2 + border_width), y: 0 })
        when 3 # Право
          @shapes.unshift(Rectangle.new(x: 0, y: 0, width: border_width, height: chest_height, color: [255, 255, 0, 1.0], z: 502))
          @shape_offsets.unshift({ x: chest_width / 2 + border_width, y: 0 })
        end
      end
    end
    
    @interactive = true
    @solid = false
    @size = 24
  end

  def create_barrel_shapes
    # Бочка
    @shapes << Rectangle.new(
      x: 0,
      y: 0,
      width: 20,
      height: 16,
      color: '#8B4513'
    )
    @shape_offsets << { x: -10, y: -8 }
    
    # Обручи
    @shapes << Rectangle.new(
      x: 0,
      y: 0,
      width: 20,
      height: 2,
      color: '#654321'
    )
    @shape_offsets << { x: -10, y: -4 }
    
    @shapes << Rectangle.new(
      x: 0,
      y: 0,
      width: 20,
      height: 2,
      color: '#654321'
    )
    @shape_offsets << { x: -10, y: 2 }
    
    # Желтая обводка (1 пиксель) вокруг ящика, если интерактивный и не разрушен
    unless @destroyed
      # Размеры ящика: ширина 20, высота 16
      barrel_width = 20
      barrel_height = 16
      border_width = 1
      
      # Верхняя линия
      @shapes.unshift(Rectangle.new(
        x: 0,
        y: 0,
        width: barrel_width + border_width * 2,
        height: border_width,
        color: [255, 255, 0, 1.0], # Желтая обводка
        z: 502
      ))
      @shape_offsets.unshift({ x: -(barrel_width / 2 + border_width), y: -(barrel_height / 2) })
      
      # Нижняя линия
      @shapes.unshift(Rectangle.new(
        x: 0,
        y: 0,
        width: barrel_width + border_width * 2,
        height: border_width,
        color: [255, 255, 0, 1.0],
        z: 502
      ))
      @shape_offsets.unshift({ x: -(barrel_width / 2 + border_width), y: barrel_height / 2 })
      
      # Левая линия
      @shapes.unshift(Rectangle.new(
        x: 0,
        y: 0,
        width: border_width,
        height: barrel_height,
        color: [255, 255, 0, 1.0],
        z: 502
      ))
      @shape_offsets.unshift({ x: -(barrel_width / 2 + border_width), y: 0 })
      
      # Правая линия
      @shapes.unshift(Rectangle.new(
        x: 0,
        y: 0,
        width: border_width,
        height: barrel_height,
        color: [255, 255, 0, 1.0],
        z: 502
      ))
      @shape_offsets.unshift({ x: barrel_width / 2 + border_width, y: 0 })
    end
  end

  def create_grass_patch_shapes
    # Пучок травы
    3.times do |i|
      angle = i * Math::PI * 2 / 3
      
      @shapes << Triangle.new(
        x1: 0,
        y1: 0,
        x2: 0,
        y2: 0,
        x3: 0,
        y3: 0,
        color: '#228B22'
      )
      @shape_offsets << { x1: 0, y1: 0, x2: Math.cos(angle) * 8, y2: Math.sin(angle) * 8, x3: Math.cos(angle + 0.3) * 6, y3: Math.sin(angle + 0.3) * 6 }
    end
  end

  def create_flower_shapes
    # Лепестки
    5.times do |i|
      angle = i * Math::PI * 2 / 5
      @shapes << Circle.new(
        x: 0,
        y: 0,
        radius: 3,
        color: ['#FF69B4', '#FF1493', '#FFB6C1'].sample
      )
      @shape_offsets << { x: Math.cos(angle) * 4, y: Math.sin(angle) * 4 }
    end
    # Центр
    @shapes << Circle.new(
      x: 0,
      y: 0,
      radius: 2,
      color: '#FFD700'
    )
    @shape_offsets << { x: 0, y: 0 }
  end

  def create_bush_shapes
    # Куст
    @shapes << Circle.new(
      x: 0,
      y: 0,
      radius: 10,
      color: '#228B22'
    )
    @shape_offsets << { x: 0, y: 0 }
    
    @shapes << Circle.new(
      x: 0,
      y: 0,
      radius: 7,
      color: '#32CD32'
    )
    @shape_offsets << { x: -5, y: -3 }
    
    @shapes << Circle.new(
      x: 0,
      y: 0,
      radius: 7,
      color: '#32CD32'
    )
    @shape_offsets << { x: 5, y: -3 }
  end

  def update_positions(camera)
    # Обновляем позиции фигур с учетом камеры
    # ВАЖНО: объекты карты статичны в мировых координатах, только их отображение меняется
    screen_x, screen_y = camera.world_to_screen(@x, @y)
    
    @shapes.each_with_index do |shape, index|
      # ВСЕГДА используем сохраненные смещения - они были установлены при создании
      offset = @shape_offsets[index]
      next unless offset # Пропускаем, если смещение не сохранено (не должно происходить)
      
      if shape.is_a?(Circle)
        shape.x = screen_x + offset[:x]
        shape.y = screen_y + offset[:y]
      elsif shape.is_a?(Rectangle)
        shape.x = screen_x + offset[:x]
        shape.y = screen_y + offset[:y]
      elsif shape.is_a?(Triangle)
        shape.x1 = screen_x + offset[:x1]
        shape.y1 = screen_y + offset[:y1]
        shape.x2 = screen_x + offset[:x2]
        shape.y2 = screen_y + offset[:y2]
        shape.x3 = screen_x + offset[:x3]
        shape.y3 = screen_y + offset[:y3]
      end
    end
  end

  def remove
    @shapes.each(&:remove)
    @shapes.clear
  end

  def collides_with?(x, y, size)
    return false unless @solid
    return false if @destroyed # Разрушенные объекты не блокируют
    
    distance = Math.sqrt((@x - x)**2 + (@y - y)**2)
    distance < (@size + size) / 2
  end

  def can_interact?(player_x, player_y, interaction_range = 40)
    return false unless @interactive
    return false if @opened || @destroyed
    
    distance = Math.sqrt((@x - player_x)**2 + (@y - player_y)**2)
    distance <= interaction_range
  end

  def open!
    return if @opened || @destroyed
    @opened = true
    update_opened_visuals
  end

  def destroying?
    @destroying && !@destroyed
  end

  def start_destruction
    return if @destroyed || @destroying
    @destroying = true
    @interaction_time = 0.0
    @interaction_progress = 0.0
  end

  def destroy!
    return if @destroyed
    @destroyed = true
    @destroying = false
    @solid = false # Разрушенные объекты больше не блокируют
    update_destroyed_visuals
  end

  def set_highlight(highlighted, camera = nil, interaction_range = nil)
    @highlighted = highlighted
    @interaction_range = interaction_range # Сохраняем радиус взаимодействия для подсветки
    update_highlight(camera)
  end

  def update_interaction_progress(delta_time, camera, chest_cost = nil, player_gold = nil)
    return if @opened || @destroyed
    
    # Для ящиков - прогресс увеличивается только если начато разрушение
    if @type == :barrel && !@destroying
      return
    end
    
    # Для сундуков - всегда показываем стоимость, даже если прогресс = 0
    if @type == :chest && chest_cost
      # Обновляем визуальную индикацию (включая стоимость)
      update_progress_indicator(camera, chest_cost, player_gold)
    end
    
    # Увеличиваем прогресс только если достаточно золота (для сундуков)
    if @type == :chest && chest_cost && player_gold && player_gold < chest_cost
      # Недостаточно золота - не увеличиваем прогресс
      @interaction_time = 0.0
      @interaction_progress = 0.0
      return # Выходим, но стоимость уже показана выше
    else
      # Увеличиваем прогресс
      @interaction_time += delta_time
      @interaction_progress = [@interaction_time / @interaction_required_time, 1.0].min
    end
    
    # Обновляем визуальную индикацию прогресса (если еще не обновили для сундука)
    if @type != :chest || !chest_cost
      update_progress_indicator(camera, chest_cost, player_gold)
    else
      # Для сундука обновляем еще раз, чтобы показать прогресс-бар
      update_progress_indicator(camera, chest_cost, player_gold)
    end
  end

  def reset_interaction_progress
    return if @opened || @destroyed
    
    @interaction_time = 0.0
    @interaction_progress = 0.0
    @destroying = false if @type == :barrel # Сбрасываем флаг разрушения для ящиков
    # Удаляем индикатор прогресса
    @progress_shapes.each(&:remove) if @progress_shapes
    @progress_shapes.clear
  end

  def update_progress_indicator(camera, chest_cost = nil, player_gold = nil)
    return if @opened || @destroyed
    # Для ящиков показываем прогресс только если начато разрушение
    return if @type == :barrel && !@destroying
    
    # Для сундуков показываем стоимость всегда, даже если прогресс = 0
    show_cost_only = (@type == :chest && chest_cost && @interaction_progress <= 0.0)
    return if @interaction_progress <= 0.0 && !show_cost_only
    
    # Удаляем старые фигуры прогресса
    @progress_shapes.each(&:remove) if @progress_shapes
    @progress_shapes.clear
    
    screen_x, screen_y = camera.world_to_screen(@x, @y)
    
    # Создаем прогресс-бар под объектом
    bar_width = @size * 2
    bar_height = 3
    bar_x = screen_x - bar_width / 2
    bar_y = screen_y + @size + 5
    
    # Фон прогресс-бара (темный)
    @progress_shapes << Rectangle.new(
      x: bar_x,
      y: bar_y,
      width: bar_width,
      height: bar_height,
      color: [50, 50, 50, 0.8],
      z: 1000
    )
    
    # Заполнение прогресс-бара (зеленый, меняется на желтый при приближении к завершению)
    # Если недостаточно золота - красный цвет
    progress_width = bar_width * @interaction_progress
    if progress_width > 0
      if @type == :chest && chest_cost && player_gold && player_gold < chest_cost
        # Недостаточно золота - красный цвет
        progress_color = [255, 0, 0, 0.9]
      else
        progress_color = @interaction_progress < 0.7 ? [0, 255, 0, 0.9] : [255, 255, 0, 0.9]
      end
      @progress_shapes << Rectangle.new(
        x: bar_x,
        y: bar_y,
        width: progress_width,
        height: bar_height,
        color: progress_color,
        z: 1001
      )
    end
    
    # Показываем стоимость открытия сундука (если указана)
    # Показываем всегда для сундуков, даже если прогресс = 0
    if @type == :chest && chest_cost
      cost_text_y = bar_y + bar_height + 8
      cost_color = (player_gold && player_gold >= chest_cost) ? [255, 255, 255, 1.0] : [255, 0, 0, 1.0]
      cost_text = Text.new(
        "#{chest_cost}G",
        x: screen_x,
        y: cost_text_y,
        size: 14,
        color: cost_color,
        z: 1002
      )
      cost_text.x = screen_x - cost_text.width / 2 # Центрируем текст
      @progress_shapes << cost_text
    end
  end
  
  def show_chest_cost(camera, chest_cost, player_gold)
    # Показываем стоимость сундука даже когда игрок не рядом
    return if @opened || @destroyed || @type != :chest || !chest_cost
    
    # Удаляем старые фигуры
    @progress_shapes.each(&:remove) if @progress_shapes
    @progress_shapes.clear
    
    screen_x, screen_y = camera.world_to_screen(@x, @y)
    
    # Показываем только стоимость
    cost_text_y = screen_y + @size + 5
    cost_color = (player_gold && player_gold >= chest_cost) ? [255, 255, 255, 1.0] : [255, 0, 0, 1.0]
    cost_text = Text.new(
      "#{chest_cost}G",
      x: screen_x,
      y: cost_text_y,
      size: 14,
      color: cost_color,
      z: 1002
    )
    cost_text.x = screen_x - cost_text.width / 2
    @progress_shapes << cost_text
  end

  def update_opened_visuals
    # Удаляем желтую обводку (ВАЖНО: делаем это в первую очередь)
    remove_yellow_border
    
    # Удаляем индикатор прогресса
    if @progress_shapes
      @progress_shapes.each(&:remove)
      @progress_shapes.clear
    end
    @interaction_progress = 0.0
    @interaction_time = 0.0
    
    # Удаляем подсветку (желтый круг)
    if @highlight_shape
      @highlight_shape.remove
      @highlight_shape = nil
    end
    @highlighted = false
    
    # Изменяем визуал открытого сундука
    if @type == :chest
      # Меняем цвет на более темный/открытый
      @shapes.each do |shape|
        if shape.is_a?(Rectangle) && shape.color == '#8B4513'
          shape.color = '#654321' # Более темный коричневый
        elsif shape.is_a?(Rectangle) && shape.color == '#A0522D'
          shape.color = '#5C3317' # Еще темнее
        elsif shape.is_a?(Circle) && shape.color == '#FFD700'
          shape.color = '#808080' # Серый замок (открыт)
        end
      end
      
      # Делаем объект полупрозрачным
      @shapes.each do |shape|
        if shape.respond_to?(:opacity)
          shape.opacity = 0.5
        end
      end
    end
  end

  def update_destroyed_visuals
    # Удаляем желтую обводку (если была) - ВАЖНО: делаем это в первую очередь
    remove_yellow_border
    
    # Удаляем подсветку (желтый круг)
    if @highlight_shape
      @highlight_shape.remove
      @highlight_shape = nil
    end
    @highlighted = false
    
    # Делаем объект темным и полупрозрачным
    @shapes.each do |shape|
      if shape.respond_to?(:opacity)
        shape.opacity = 0.3
      end
      # Затемняем цвета
      if shape.respond_to?(:color) && shape.color.is_a?(String)
        # Преобразуем hex в более темный цвет
        case shape.color
        when '#8B4513', '#654321'
          shape.color = '#3D2817' # Очень темный коричневый
        when '#A0522D'
          shape.color = '#4A2C17' # Очень темный
        when '#C0C0C0', '#654321'
          shape.color = '#505050' # Темно-серый
        end
      end
    end
  end

  def update_highlight(camera = nil)
    if @highlighted && !@opened && !@destroyed
      # Определяем радиус подсветки на основе радиуса взаимодействия
      highlight_radius = @interaction_range || (@size + 5)
      
      # Создаем подсветку, если её нет
      if @highlight_shape.nil?
        if camera
          screen_x, screen_y = camera.world_to_screen(@x, @y)
        else
          screen_x, screen_y = @shapes.first ? [@shapes.first.x, @shapes.first.y] : [0, 0]
        end
        @highlight_shape = Circle.new(
          x: screen_x,
          y: screen_y,
          radius: highlight_radius,
          color: [255, 255, 0, 0.3],
          z: 1000
        )
      elsif camera && @highlight_shape
        # Обновляем позицию и радиус подсветки
        screen_x, screen_y = camera.world_to_screen(@x, @y)
        @highlight_shape.x = screen_x
        @highlight_shape.y = screen_y
        # Обновляем радиус, если он изменился
        if @highlight_shape.radius != highlight_radius
          @highlight_shape.remove
          @highlight_shape = Circle.new(
            x: screen_x,
            y: screen_y,
            radius: highlight_radius,
            color: [255, 255, 0, 0.3],
            z: 1000
          )
        end
      end
    else
      # Удаляем подсветку
      if @highlight_shape
        @highlight_shape.remove
        @highlight_shape = nil
      end
    end
  end

  def update_positions(camera, delta_time = 0.0)
    # Обновляем позиции фигур с учетом камеры
    # ВАЖНО: объекты карты статичны в мировых координатах, только их отображение меняется
    screen_x, screen_y = camera.world_to_screen(@x, @y)
    
    @shapes.each_with_index do |shape, index|
      # ВСЕГДА используем сохраненные смещения - они были установлены при создании
      offset = @shape_offsets[index]
      next unless offset # Пропускаем, если смещение не сохранено (не должно происходить)
      
      if shape.is_a?(Circle)
        shape.x = screen_x + offset[:x]
        shape.y = screen_y + offset[:y]
      elsif shape.is_a?(Rectangle)
        shape.x = screen_x + offset[:x]
        shape.y = screen_y + offset[:y]
      elsif shape.is_a?(Triangle)
        shape.x1 = screen_x + offset[:x1]
        shape.y1 = screen_y + offset[:y1]
        shape.x2 = screen_x + offset[:x2]
        shape.y2 = screen_y + offset[:y2]
        shape.x3 = screen_x + offset[:x3]
        shape.y3 = screen_y + offset[:y3]
      end
    end

    # Обновляем подсветку
    update_highlight(camera)
    
    # Обновляем позиции прогресс-бара, если он есть
    if @interactive && !@opened && !@destroyed && @interaction_progress > 0.0 && @progress_shapes && !@progress_shapes.empty?
      update_progress_indicator(camera)
    end
  end

  def remove_yellow_border
    # Удаляем желтую обводку (первые 4 фигуры - 4 линии обводки)
    # Обводка добавляется через unshift, поэтому она в начале массива
    removed_count = 0
    
    # Ищем и удаляем желтые прямоугольники в начале массива
    while @shapes.length > 0 && removed_count < 4
      first_shape = @shapes.first
      
      # Проверяем, что это прямоугольник с желтым цветом (обводка)
      is_yellow_border = false
      if first_shape.is_a?(Rectangle)
        if first_shape.color.is_a?(Array) && first_shape.color.length >= 3
          # Цвет в формате [R, G, B, A]
          if first_shape.color[0] == 255 && first_shape.color[1] == 255 && first_shape.color[2] == 0
            is_yellow_border = true
          end
        end
      end
      
      if is_yellow_border
        @shapes.shift.remove
        @shape_offsets.shift
        removed_count += 1
      else
        # Больше нет обводки
        break
      end
    end
  end

  def create_altar_shapes
    # Алтарь - каменная плита с символами
    # Основание
    @shapes << Rectangle.new(
      x: 0, y: 0,
      width: 40, height: 40,
      color: '#696969',
      z: 500
    )
    @shape_offsets << { x: -20, y: -20 }
    
    # Символы на алтаре
    @shapes << Circle.new(
      x: 0, y: 0,
      radius: 8,
      color: '#FFD700',
      z: 501
    )
    @shape_offsets << { x: 0, y: 0 }
    
    # Желтая обводка для интерактивности
    4.times do |i|
      case i
      when 0 # Верх
        @shapes.unshift(Rectangle.new(x: 0, y: 0, width: 40, height: 1, color: '#FFFF00', z: 502))
        @shape_offsets.unshift({ x: -20, y: -20 })
      when 1 # Низ
        @shapes.unshift(Rectangle.new(x: 0, y: 0, width: 40, height: 1, color: '#FFFF00', z: 502))
        @shape_offsets.unshift({ x: -20, y: 19 })
      when 2 # Лево
        @shapes.unshift(Rectangle.new(x: 0, y: 0, width: 1, height: 40, color: '#FFFF00', z: 502))
        @shape_offsets.unshift({ x: -20, y: -20 })
      when 3 # Право
        @shapes.unshift(Rectangle.new(x: 0, y: 0, width: 1, height: 40, color: '#FFFF00', z: 502))
        @shape_offsets.unshift({ x: 19, y: -20 })
      end
    end
    
    @interactive = true
    @solid = false
    @size = 40
  end
  
  def create_portal_shapes
    # Портал - вращающийся круг с эффектом
    # Внешний круг
    @shapes << Circle.new(
      x: 0, y: 0,
      radius: 30,
      color: '#8B00FF',
      z: 500
    )
    @shape_offsets << { x: 0, y: 0 }
    
    # Внутренний круг
    @shapes << Circle.new(
      x: 0, y: 0,
      radius: 20,
      color: '#4B0082',
      z: 501
    )
    @shape_offsets << { x: 0, y: 0 }
    
    # Центр
    @shapes << Circle.new(
      x: 0, y: 0,
      radius: 10,
      color: '#000000',
      z: 502
    )
    @shape_offsets << { x: 0, y: 0 }
    
    # Желтая обводка для интерактивности
    4.times do |i|
      angle = i * Math::PI / 2
      x_offset = Math.cos(angle) * 30
      y_offset = Math.sin(angle) * 30
      @shapes.unshift(Circle.new(x: 0, y: 0, radius: 2, color: '#FFFF00', z: 503))
      @shape_offsets.unshift({ x: x_offset, y: y_offset })
    end
    
    @interactive = true
    @solid = false
    @size = 60
  end

  def remove
    @highlight_shape&.remove
    @progress_shapes.each(&:remove) if @progress_shapes
    @progress_shapes.clear
    @shapes.each(&:remove)
    @shapes.clear
  end
end

