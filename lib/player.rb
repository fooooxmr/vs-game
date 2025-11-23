require 'set'
require_relative 'sprite_renderer'
require_relative 'weapon'
require_relative 'passive'

class Player
  attr_accessor :x, :y, :health, :max_health, :attack_range, :attack_cooldown, :last_attack_time, :speed, :keys_pressed,
                :base_damage, :health_regen_rate, :crit_chance, :armor, :level, :experience, :experience_to_next_level,
                :enemies_killed, :time_alive, :weapons, :passives, :experience_magnet_range, :is_attacking, :gold

  def initialize(x, y, hero_data = nil)
    @x = x
    @y = y
    @size = 20
    @keys_pressed = Set.new
    @sprite = nil
    @is_moving = false
    @is_attacking = false
    @took_damage = false
    @last_x = x
    @last_y = y
    
    # Применяем характеристики героя
    if hero_data && hero_data[:stats]
      stats = hero_data[:stats]
      @max_health = stats[:health] || 100
      @health = @max_health
      @speed = stats[:speed] || 120
      @base_damage = stats[:damage] || 10
      @armor = stats[:armor] || 0
      @sprite_type = hero_data[:sprite_type] || :player
      @starting_weapon = hero_data[:starting_weapon] || :whip
    else
      # Значения по умолчанию
      @max_health = 100
      @health = @max_health
      @speed = 120
      @base_damage = 10
      @armor = 0
      @sprite_type = :player
      @starting_weapon = :whip
    end
    
    @attack_range = 50
    @attack_cooldown = 0.5 # секунды между атаками
    @last_attack_time = 0
    
    # Система прокачки
    @level = 1
    @experience = 0
    
    # Система золота
    @gold = 0 # Начальное количество золота
    @experience_to_next_level = 10
    @health_regen_rate = 0
    @crit_chance = 0
    @last_regen_time = Time.now.to_f
    @enemies_killed = 0
    @time_alive = 0
    
    # Система оружия и пассивов (как в VS)
    @weapons = []
    @passives = []
    @experience_magnet_range = 50 # Радиус сбора опыта
    
    # Начинаем с стартового оружия героя
    add_weapon(@starting_weapon)
  end

  def add_weapon(type)
    weapon = Weapon.new(type)
    @weapons << weapon
    weapon
  end

  def add_passive(type)
    existing = @passives.find { |p| p.type == type }
    if existing
      existing.upgrade
    else
      passive = Passive.new(type)
      @passives << passive
      passive
    end
  end

  def apply_passives
    @passives.each do |passive|
      case passive.type
      when :move_speed
        @speed = (120 * (1.0 + passive.get_bonus)).round
      when :max_health
        bonus_health = (100 * passive.get_bonus).round
        if bonus_health > 0
          @max_health = 100 + bonus_health
          @health = [@health, @max_health].min
        end
      when :armor
        @armor = passive.get_bonus
      when :magnet
        @experience_magnet_range = 50 + (passive.get_bonus * 20).round
      end
    end
  end

  def ensure_shapes
    unless @sprite
      sprite_type = @sprite_type || :player
      @sprite = SpriteRenderer.new(@x, @y, @size, sprite_type)
    end
  end

  def add_experience(amount)
    @experience += amount
    # Проверяем повышение уровня
    while @experience >= @experience_to_next_level
      @experience -= @experience_to_next_level
      @level += 1
      @experience_to_next_level = (10 + @level * 5).round
      return true # Уровень повышен
    end
    false
  end

  def update(delta_time, enemies, map = nil, camera = nil)
    @time_alive += delta_time
    
    # Регенерация здоровья
    if @health_regen_rate > 0 && @health < @max_health
      current_time = Time.now.to_f
      if current_time - @last_regen_time >= 1.0
        @health = [@health + @health_regen_rate, @max_health].min
        @last_regen_time = current_time
      end
    end
    @last_x = @x
    @last_y = @y
    @is_moving = false
    @is_attacking = false
    @took_damage = false

    # Применяем пассивные улучшения
    apply_passives

    # Движение (теперь с учетом карты и коллизий)
    handle_movement(delta_time, map)
    
    # Проверяем, двигается ли персонаж
    @is_moving = (@x != @last_x || @y != @last_y)
    
    # Определяем направление взгляда
    if @is_moving
      if @x > @last_x
        @sprite&.set_facing_direction(:right)
      elsif @x < @last_x
        @sprite&.set_facing_direction(:left)
      end
    end
    
    # Автоатака ближайшего врага
    old_attack_time = @last_attack_time
    target_enemy = find_nearest_enemy(enemies)
    auto_attack(enemies, delta_time)
    # Проверяем, произошла ли атака (время изменилось)
    @is_attacking = (@last_attack_time != old_attack_time && Time.now.to_f - @last_attack_time < 0.2)
    
    # Обновляем спрайт (с учетом камеры)
    if @sprite
      if camera
        screen_x, screen_y = camera.world_to_screen(@x, @y)
        @sprite.x = screen_x
        @sprite.y = screen_y
      else
        @sprite.x = @x
        @sprite.y = @y
      end
      # Обновляем дальность атаки для слеша
      whip = @weapons.find { |w| w.type == :whip }
      @sprite.attack_range = whip ? whip.range : 80
      # Передаем направление к врагу для слеша
      attack_angle = nil
      if @is_attacking && target_enemy
        dx = target_enemy.x - @x
        dy = target_enemy.y - @y
        attack_angle = Math.atan2(dy, dx)
      end
      @sprite.update(delta_time, @is_moving, @is_attacking, @took_damage, attack_angle)
    end
  end

  def handle_movement(delta_time, map = nil)
    move_x = 0
    move_y = 0

    move_x -= 1 if @keys_pressed.include?('a') || @keys_pressed.include?('left')
    move_x += 1 if @keys_pressed.include?('d') || @keys_pressed.include?('right')
    move_y -= 1 if @keys_pressed.include?('w') || @keys_pressed.include?('up')
    move_y += 1 if @keys_pressed.include?('s') || @keys_pressed.include?('down')

    return if move_x == 0 && move_y == 0

    # Нормализуем диагональное движение
    if move_x != 0 && move_y != 0
      move_x *= 0.707
      move_y *= 0.707
    end

    # Вычисляем новую позицию
    new_x = @x + move_x * @speed * delta_time
    new_y = @y + move_y * @speed * delta_time

    # Проверяем коллизии с картой
    if map
      # Проверяем коллизию по X
      test_x = new_x
      test_y = @y
      collisions_x = map.get_collisions(test_x, test_y, @size)
      if collisions_x.empty? || collisions_x.none? { |obj| obj.solid }
        @x = test_x
      end
      
      # Проверяем коллизию по Y
      test_x = @x
      test_y = new_y
      collisions_y = map.get_collisions(test_x, test_y, @size)
      if collisions_y.empty? || collisions_y.none? { |obj| obj.solid }
        @y = test_y
      end
    else
      # Старое поведение (ограничение границами экрана) для обратной совместимости
      @x = new_x
      @y = new_y
    end
  end

  def key_down(key)
    @keys_pressed.add(key)
  end

  def key_up(key)
    @keys_pressed.delete(key)
  end

  def auto_attack(enemies, delta_time)
    current_time = Time.now.to_f
    projectiles = []
    attacked = false
    
    # Атакуем всеми оружиями
    @weapons.each do |weapon|
      # Для кнута - прямая атака
      if weapon.type == :whip
        nearest_enemy = find_nearest_enemy(enemies)
        if nearest_enemy && weapon.can_attack?(current_time)
          distance = distance_to(nearest_enemy.x, nearest_enemy.y)
          if distance <= weapon.range
            # Наносим урон всем врагам в радиусе и направлении
            attack_angle = Math.atan2(nearest_enemy.y - @y, nearest_enemy.x - @x)
            enemies.each do |enemy|
              next unless enemy.alive?
              enemy_distance = distance_to(enemy.x, enemy.y)
              if enemy_distance <= weapon.range
                # Проверяем, что враг в направлении атаки (конус 60 градусов)
                angle_to_enemy = Math.atan2(enemy.y - @y, enemy.x - @x)
                angle_diff = (angle_to_enemy - attack_angle).abs
                angle_diff = [angle_diff, 2 * Math::PI - angle_diff].min
                
                if angle_diff <= Math::PI / 3 # 60 градусов
                  enemy.take_damage(weapon.damage)
                end
              end
            end
            weapon.attack(@x, @y, enemies, current_time) # Обновляем время атаки оружия
            attacked = true
            @last_attack_time = current_time
          end
        end
      else
        # Для дальнобойного оружия
        weapon_projectiles = weapon.attack(@x, @y, enemies, current_time)
        if weapon_projectiles && !weapon_projectiles.empty?
          attacked = true
          projectiles.concat(weapon_projectiles)
          @last_attack_time = current_time
        end
      end
    end
    
    projectiles
  end

  def find_nearest_enemy(enemies)
    return nil if enemies.empty?

    enemies.min_by { |enemy| distance_to(enemy.x, enemy.y) }
  end

  def distance_to(x, y)
    Math.sqrt((@x - x)**2 + (@y - y)**2)
  end

  def take_damage(amount)
    # Применяем броню
    actual_damage = amount * (1.0 - @armor)
    @health -= actual_damage
    @health = 0 if @health < 0
    @took_damage = true
  end

  def alive?
    @health > 0
  end

  def draw(camera = nil)
    return unless alive?

    # Спрайт рисуется автоматически через Ruby2D (позиция уже обновлена в update)
    # Рисуем полоску здоровья (с учетом камеры)
    draw_health_bar(camera)
  end

  def draw_health_bar(camera = nil)
    health_percent = @health.to_f / @max_health
    bar_width = @size
    bar_height = 4
    
    # Преобразуем мировые координаты в экранные
    if camera
      bar_x, bar_y = camera.world_to_screen(@x, @y - @size / 2 - 12)
    else
      bar_x = @x - bar_width / 2
      bar_y = @y - @size / 2 - 12
    end
    bar_x -= bar_width / 2

    # Фон полоски здоровья
    unless @health_bar_bg
      @health_bar_bg = Rectangle.new(
        x: bar_x,
        y: bar_y,
        width: bar_width,
        height: bar_height,
        color: 'red'
      )
    end

    # Здоровье
    unless @health_bar
      @health_bar = Rectangle.new(
        x: bar_x,
        y: bar_y,
        width: bar_width,
        height: bar_height,
        color: 'green'
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

  def remove_shapes
    @sprite&.remove
    @health_bar_bg&.remove
    @health_bar&.remove
  end
end

