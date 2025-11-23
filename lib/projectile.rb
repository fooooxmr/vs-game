class Projectile
  attr_accessor :x, :y, :angle, :speed, :damage, :range, :traveled_distance, :type, :active, :last_damage_dealt

  def initialize(type, x, y, angle, damage, speed = 0, range = 100, options = {})
    @type = type
    @x = x # Мировые координаты
    @y = y # Мировые координаты
    @start_x = x
    @start_y = y
    @angle = angle
    @damage = damage
    @speed = speed
    @range = range
    @traveled_distance = 0
    @active = true
    @options = options
    @shapes = []
    @time_alive = 0
    @shape_offsets = [] # Смещения фигур от центра проектиля
    @last_damage_dealt = 0 # Урон, нанесенный этим проектилем (для вампиризма)
    create_shapes
  end

  def create_shapes
    case @type
    when :whip
      # Кнут не создает визуальный проектиль, урон наносится напрямую
      # Но создаем временную линию для визуализации
      line_length = 30
      @shapes << Line.new(
        x1: @x, y1: @y,
        x2: @x + Math.cos(@angle) * line_length, y2: @y + Math.sin(@angle) * line_length,
        width: 5,
        color: '#FFD700'
      )
      @shape_offsets << { x1: 0, y1: 0, x2: Math.cos(@angle) * line_length, y2: Math.sin(@angle) * line_length }
    when :magic_wand
      @shapes << Circle.new(
        x: @x, y: @y,
        radius: 5,
        color: '#00FFFF'
      )
      @shape_offsets << { x: 0, y: 0 }
    when :knife
      # Сохраняем смещения для треугольника
      @shapes << Triangle.new(
        x1: @x, y1: @y - 5,
        x2: @x + 10, y2: @y,
        x3: @x, y3: @y + 5,
        color: '#C0C0C0'
      )
      @shape_offsets << { x1: 0, y1: -5, x2: 10, y2: 0, x3: 0, y3: 5 }
    when :axe
      @shapes << Rectangle.new(
        x: @x - 5, y: @y - 5,
        width: 10, height: 10,
        color: '#8B4513'
      )
      @shape_offsets << { x: -5, y: -5 }
    when :cross
      @shapes << Text.new(
        '✝️',
        x: @x, y: @y,
        size: 20,
        color: 'white'
      )
      @shape_offsets << { x: 0, y: 0 }
    when :garlic
      @shapes << Circle.new(
        x: @x, y: @y,
        radius: @options[:area] || 50,
        color: [139, 69, 19, 0.3] # Полупрозрачный коричневый
      )
      @shape_offsets << { x: 0, y: 0 }
    end
  end

  def update(delta_time, enemies = [], map = nil)
    return unless @active

    @time_alive += delta_time

    case @type
    when :whip
      update_whip(enemies)
    when :magic_wand, :knife, :axe
      update_projectile(delta_time, map)
    when :cross
      update_cross(delta_time, map)
    when :garlic
      update_garlic(enemies, delta_time)
    end

    # Проверяем дальность
    distance = Math.sqrt((@x - @start_x)**2 + (@y - @start_y)**2)
    if distance >= @range
      @active = false
    end
  end

  def update_whip(enemies)
    # Кнут - мгновенная атака в направлении, наносим урон всем врагам в радиусе
    return unless @active
    
    # Сбрасываем урон перед расчетом
    @last_damage_dealt = 0
    
    # Находим всех врагов в радиусе атаки
    enemies.each do |enemy|
      next unless enemy.alive?
      distance = Math.sqrt((enemy.x - @x)**2 + (enemy.y - @y)**2)
      if distance <= @range
        # Проверяем, что враг в направлении атаки
        angle_to_enemy = Math.atan2(enemy.y - @y, enemy.x - @x)
        angle_diff = (angle_to_enemy - @angle).abs
        angle_diff = [angle_diff, 2 * Math::PI - angle_diff].min
        
        if angle_diff <= Math::PI / 3 # 60 градусов
          damage_dealt = enemy.take_damage(@damage)
          @last_damage_dealt += damage_dealt if damage_dealt > 0
        end
      end
    end
    
    @active = false
  end

  def update_projectile(delta_time, map = nil)
    # Вычисляем новую позицию
    new_x = @x + Math.cos(@angle) * @speed * delta_time
    new_y = @y + Math.sin(@angle) * @speed * delta_time
    
    # Проверяем коллизии с картой
    if map
      collisions = map.get_collisions(new_x, new_y, 5) # Радиус проектиля примерно 5
      solid_collision = collisions.find { |obj| obj.solid }
      
      if solid_collision
        # Проектиль столкнулся с непроходимым объектом - деактивируем
        @active = false
        return
      end
    end
    
    # Применяем движение
    @x = new_x
    @y = new_y
    @traveled_distance += @speed * delta_time
    # Позиции фигур будут обновлены в update_positions с учетом камеры
  end

  def update_cross(delta_time, map = nil)
    # Крест вращается вокруг начальной позиции
    radius = 50
    new_x = @start_x + Math.cos(@time_alive * 2) * radius
    new_y = @start_y + Math.sin(@time_alive * 2) * radius
    
    # Проверяем коллизии с картой (для креста это менее критично, но проверим)
    if map
      collisions = map.get_collisions(new_x, new_y, 10)
      solid_collision = collisions.find { |obj| obj.solid }
      
      if solid_collision
        # Крест столкнулся с непроходимым объектом - деактивируем
        @active = false
        return
      end
    end
    
    @x = new_x
    @y = new_y
    # Позиции фигур будут обновлены в update_positions с учетом камеры
  end

  def update_garlic(enemies, delta_time)
    # Чеснок наносит урон всем врагам в радиусе
    area = @options[:area] || 50
    @garlic_damage_timer ||= 0
    @garlic_damage_timer += delta_time
    
    # Наносим урон раз в 0.1 секунды
    if @garlic_damage_timer >= 0.1
      enemies.each do |enemy|
        next unless enemy.alive?
        distance = Math.sqrt((enemy.x - @x)**2 + (enemy.y - @y)**2)
        if distance <= area
          enemy.take_damage(@damage)
        end
      end
      @garlic_damage_timer = 0
    end
  end

  def check_collision(enemy)
    return false unless @active

    case @type
    when :whip
      # Кнут уже обработан
      false
    when :magic_wand, :knife, :axe
      distance = Math.sqrt((enemy.x - @x)**2 + (enemy.y - @y)**2)
      if distance < 15
        @active = false
        true
      else
        false
      end
    when :cross
      distance = Math.sqrt((enemy.x - @x)**2 + (enemy.y - @y)**2)
      distance < 20
    when :garlic
      # Обрабатывается в update_garlic
      false
    end
  end

  def update_positions(camera)
    # Обновляем позиции фигур с учетом камеры
    screen_x, screen_y = camera.world_to_screen(@x, @y)
    
    @shapes.each_with_index do |shape, index|
      case shape
      when Circle
        if @shape_offsets[index]
          offset = @shape_offsets[index]
          shape.x = screen_x + offset[:x]
          shape.y = screen_y + offset[:y]
        else
          shape.x = screen_x
          shape.y = screen_y
        end
      when Rectangle
        if @shape_offsets[index]
          offset = @shape_offsets[index]
          shape.x = screen_x + offset[:x]
          shape.y = screen_y + offset[:y]
        else
          # Вычисляем смещение динамически
          offset_x = shape.x - @x
          offset_y = shape.y - @y
          @shape_offsets[index] = { x: offset_x, y: offset_y }
          shape.x = screen_x + offset_x
          shape.y = screen_y + offset_y
        end
      when Triangle
        if @shape_offsets[index]
          offset = @shape_offsets[index]
          shape.x1 = screen_x + offset[:x1]
          shape.y1 = screen_y + offset[:y1]
          shape.x2 = screen_x + offset[:x2]
          shape.y2 = screen_y + offset[:y2]
          shape.x3 = screen_x + offset[:x3]
          shape.y3 = screen_y + offset[:y3]
        else
          # Вычисляем смещения динамически
          offset_x1 = shape.x1 - @x
          offset_y1 = shape.y1 - @y
          offset_x2 = shape.x2 - @x
          offset_y2 = shape.y2 - @y
          offset_x3 = shape.x3 - @x
          offset_y3 = shape.y3 - @y
          @shape_offsets[index] = { x1: offset_x1, y1: offset_y1, x2: offset_x2, y2: offset_y2, x3: offset_x3, y3: offset_y3 }
          shape.x1 = screen_x + offset_x1
          shape.y1 = screen_y + offset_y1
          shape.x2 = screen_x + offset_x2
          shape.y2 = screen_y + offset_y2
          shape.x3 = screen_x + offset_x3
          shape.y3 = screen_y + offset_y3
        end
      when Text
        shape.x = screen_x
        shape.y = screen_y
      when Line
        if @shape_offsets[index]
          offset = @shape_offsets[index]
          shape.x1 = screen_x + offset[:x1]
          shape.y1 = screen_y + offset[:y1]
          shape.x2 = screen_x + offset[:x2]
          shape.y2 = screen_y + offset[:y2]
        else
          # Вычисляем смещения динамически
          offset_x1 = shape.x1 - @x
          offset_y1 = shape.y1 - @y
          offset_x2 = shape.x2 - @x
          offset_y2 = shape.y2 - @y
          @shape_offsets[index] = { x1: offset_x1, y1: offset_y1, x2: offset_x2, y2: offset_y2 }
          shape.x1 = screen_x + offset_x1
          shape.y1 = screen_y + offset_y1
          shape.x2 = screen_x + offset_x2
          shape.y2 = screen_y + offset_y2
        end
      end
    end
  end

  def remove
    @shapes.each(&:remove)
  end
end

