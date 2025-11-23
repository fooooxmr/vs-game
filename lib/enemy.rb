require_relative 'sprite_renderer'

class Enemy
  attr_accessor :x, :y, :health, :max_health, :speed, :attack_range, :attack_cooldown, :last_attack_time

  def initialize(x, y)
    @x = x
    @y = y
    @max_health = 30
    @health = @max_health
    @speed = 60 # пикселей в секунду
    @attack_range = 25
    @attack_cooldown = 1.0
    @last_attack_time = 0
    @size = 15
    @sprite = nil
    @is_moving = false
    @is_attacking = false
    @took_damage = false
    @last_x = x
    @last_y = y
    @was_alive = true
    @just_died = false
    @experience_value = 2 # Опыт за убийство
  end

  def initialize_shapes
    # Переопределяем для совместимости, но используем ensure_shapes
    ensure_shapes
  end

  def ensure_shapes
    unless @sprite
      @sprite = SpriteRenderer.new(@x, @y, @size, :enemy)
    end
  end

  def update(delta_time, player, map = nil)
    return unless player.alive?

    @last_x = @x
    @last_y = @y
    @is_moving = false
    @is_attacking = false
    @took_damage = false

    # Двигаемся к игроку (с учетом карты и коллизий)
    move_towards(player.x, player.y, delta_time, map)

    # Проверяем, двигается ли враг
    @is_moving = (@x != @last_x || @y != @last_y)

    # Определяем направление взгляда
    if @is_moving
      if @x > @last_x
        @sprite&.set_facing_direction(:right)
      elsif @x < @last_x
        @sprite&.set_facing_direction(:left)
      end
    end

    # Атакуем игрока, если близко
    old_attack_time = @last_attack_time
    if distance_to(player.x, player.y) <= @attack_range
      attack_player(player)
      # Проверяем, произошла ли атака (время изменилось)
      @is_attacking = (@last_attack_time != old_attack_time && Time.now.to_f - @last_attack_time < 0.2)
    end

    # Обновляем спрайт (позиция будет обновлена в draw с учетом камеры)
    if @sprite
      @sprite.update(delta_time, @is_moving, @is_attacking, @took_damage)
    end
  end

  def move_towards(target_x, target_y, delta_time, map = nil)
    dx = target_x - @x
    dy = target_y - @y
    distance = Math.sqrt(dx**2 + dy**2)

    return if distance < 1

    # Нормализуем вектор направления
    dx /= distance
    dy /= distance

    # Вычисляем новую позицию
    move_distance = @speed * delta_time
    new_x = @x + dx * move_distance
    new_y = @y + dy * move_distance

    # Проверяем коллизии с картой
    if map
      # Проверяем коллизию по X
      test_x = new_x
      test_y = @y
      collisions_x = map.get_collisions(test_x, test_y, @size)
      solid_collision_x = collisions_x.find { |obj| obj.solid }
      
      if solid_collision_x
        # Не двигаемся по X
        new_x = @x
      end
      
      # Проверяем коллизию по Y
      test_x = @x
      test_y = new_y
      collisions_y = map.get_collisions(test_x, test_y, @size)
      solid_collision_y = collisions_y.find { |obj| obj.solid }
      
      if solid_collision_y
        # Не двигаемся по Y
        new_y = @y
      end
      
      # Если оба направления заблокированы, пробуем двигаться только по одному
      if new_x == @x && new_y == @y
        # Пробуем только X
        test_x = new_x + dx * move_distance
        test_y = @y
        collisions = map.get_collisions(test_x, test_y, @size)
        unless collisions.find { |obj| obj.solid }
          new_x = test_x
        end
        
        # Пробуем только Y
        test_x = @x
        test_y = new_y + dy * move_distance
        collisions = map.get_collisions(test_x, test_y, @size)
        unless collisions.find { |obj| obj.solid }
          new_y = test_y
        end
      end
    end

    # Применяем движение
    @x = new_x
    @y = new_y
  end

  def attack_player(player)
    current_time = Time.now.to_f
    return if current_time - @last_attack_time < @attack_cooldown

    player.take_damage(5)
    @last_attack_time = current_time
  end

  def distance_to(x, y)
    Math.sqrt((@x - x)**2 + (@y - y)**2)
  end

  def take_damage(amount)
    @health -= amount
    @health = 0 if @health < 0
    @took_damage = true
    @just_died = @health <= 0 && @was_alive
    @was_alive = @health > 0
  end

  def just_died?
    @just_died || false
  end

  def experience_value
    @experience_value || 2
  end

  def alive?
    @health > 0
  end

  def draw(camera = nil)
    return unless alive?

    # Обновляем позицию спрайта с учетом камеры
    if @sprite
      if camera
        screen_x, screen_y = camera.world_to_screen(@x, @y)
        @sprite.x = screen_x
        @sprite.y = screen_y
      else
        @sprite.x = @x
        @sprite.y = @y
      end
    end

    # Спрайт рисуется автоматически через Ruby2D
    # Рисуем полоску здоровья (с учетом камеры)
    draw_health_bar(camera)
  end

  def draw_health_bar(camera = nil)
    health_percent = @health.to_f / @max_health
    bar_width = @size
    bar_height = 3
    
    # Преобразуем мировые координаты в экранные
    if camera
      bar_x, bar_y = camera.world_to_screen(@x, @y - @size / 2 - 8)
    else
      bar_x = @x - bar_width / 2
      bar_y = @y - @size / 2 - 8
    end
    bar_x -= bar_width / 2

    # Фон полоски здоровья
    unless @health_bar_bg
      @health_bar_bg = Rectangle.new(
        x: bar_x,
        y: bar_y,
        width: bar_width,
        height: bar_height,
        color: '#8B0000'
      )
    end

    # Здоровье
    unless @health_bar
      @health_bar = Rectangle.new(
        x: bar_x,
        y: bar_y,
        width: bar_width,
        height: bar_height,
        color: 'orange'
      )
    end

    # Обновляем позиции и размеры
    @health_bar_bg.x = bar_x
    @health_bar_bg.y = bar_y
    @health_bar_bg.width = bar_width

    @health_bar.x = bar_x
    @health_bar.y = bar_y
    @health_bar.width = bar_width * health_percent
  end

  def remove
    @sprite&.remove
    @health_bar_bg&.remove
    @health_bar&.remove
  end
end

