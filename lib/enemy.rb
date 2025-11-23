require_relative 'sprite_renderer'
require_relative 'enemy_types'

class Enemy
  attr_accessor :x, :y, :health, :max_health, :speed, :attack_range, :attack_cooldown, :last_attack_time,
                :enemy_type, :ranged, :elite, :boss, :area_attack, :special_attacks, :sprite, :size

  def initialize(x, y, enemy_type = :skeleton, difficulty_multiplier = 1.0)
    @x = x
    @y = y
    @enemy_type = enemy_type
    @type_data = EnemyTypes.get_type(enemy_type)
    
    # Применяем характеристики типа с учетом сложности
    base_health = @type_data[:health] || 30
    base_speed = @type_data[:speed] || 60
    base_damage = @type_data[:damage] || 5
    
    # Плавное усиление мобов со временем
    # Здоровье и урон увеличиваются постепенно
    health_multiplier = difficulty_multiplier * 1.1 # +10% к здоровью за множитель
    damage_multiplier = difficulty_multiplier * 1.12 # +12% к урону за множитель (немного снижено для баланса)
    speed_multiplier = 1.0 + (difficulty_multiplier - 1.0) * 0.3 # Скорость увеличивается медленнее
    
    # Дополнительное усиление для бандита и мага (немного)
    if @enemy_type == :knight || @enemy_type == :mage
      damage_multiplier *= 1.05  # +5% дополнительно к урону
    end
    
    @max_health = (base_health * health_multiplier).round
    @health = @max_health
    @speed = (base_speed * speed_multiplier).round
    @damage = (base_damage * damage_multiplier).round
    @attack_range = @type_data[:attack_range] || 25
    @attack_cooldown = @type_data[:attack_cooldown] || 1.0
    @last_attack_time = 0
    # Размер зависит от типа: элитные и боссы крупнее
    base_size = 15
    if @type_data[:boss]
      @size = 30
    elsif @type_data[:elite]
      @size = 22
    else
      @size = base_size
    end
    @sprite = nil
    @is_moving = false
    @is_attacking = false
    @took_damage = false
    @last_x = x
    @last_y = y
    @was_alive = true
    @just_died = false
    @experience_value = @type_data[:experience] || 2
    
    # Специальные свойства
    @ranged = @type_data[:ranged] || false
    @elite = @type_data[:elite] || false
    @boss = @type_data[:boss] || false
    @area_attack = @type_data[:area_attack] || false
    @special_attacks = @type_data[:special_attacks] || false
    
    # Для специальных атак
    @special_attack_cooldown = 5.0 # 5 секунд между специальными атаками
    @last_special_attack = 0
    @last_contact_damage_time = 0 # Время последнего урона при контакте
    @contact_damage_cooldown = 0.5 # Кулдаун урона при контакте (0.5 секунды)
  end

  def initialize_shapes
    # Переопределяем для совместимости, но используем ensure_shapes
    ensure_shapes
  end

  def ensure_shapes
    unless @sprite
      # Определяем тип спрайта на основе типа врага
      sprite_type = case @enemy_type
      when :skeleton
        :skeleton_enemy
      when :bat
        :bat_enemy
      when :ghost
        :ghost_enemy
      when :zombie
        :zombie_enemy
      when :knight
        :knight_enemy
      when :mage
        :mage_enemy
      when :elite_knight
        :elite_knight_enemy
      when :elite_mage
        :elite_mage_enemy
      when :final_boss
        :boss_enemy
      else
        :enemy
      end
      @sprite = SpriteRenderer.new(@x, @y, @size, sprite_type)
    end
  end
  
  def name
    @type_data[:name] || "Враг"
  end

  def update(delta_time, player, map = nil)
    return unless player.alive?

    @last_x = @x
    @last_y = @y
    @is_moving = false
    @is_attacking = false
    @took_damage = false

    # Для боссов и элитных монстров - специальные атаки
    if (@boss || @elite) && @special_attacks
      current_time = Time.now.to_f
      if can_use_special_attack?(current_time)
        use_special_attack(player, current_time)
      end
    end

    # Двигаемся к игроку (с учетом карты и коллизий с игроком)
    move_towards(player.x, player.y, delta_time, map, player)

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

    # Атакуем игрока, если близко (для элитных монстров атака обрабатывается в game.rb)
    old_attack_time = @last_attack_time
    if distance_to(player.x, player.y) <= @attack_range
      if @elite
        # Для элитных монстров атака обрабатывается в game.rb с индикацией
        # Здесь только проверяем, что мы в радиусе атаки
        @is_attacking = true
      else
        # Обычные монстры атакуют сразу
        attack_result = attack_player(player)
        # Проверяем, произошла ли атака (время изменилось)
        @is_attacking = (@last_attack_time != old_attack_time && Time.now.to_f - @last_attack_time < 0.2)
      end
    end

    # Обновляем спрайт (позиция будет обновлена в draw с учетом камеры)
    # НЕ обновляем здесь, так как позиции должны обновляться с экранными координатами в draw
    # Анимация обновляется в update_sprite_animation, который вызывается из update_sprite_animation
    if @sprite
      # Обновляем только анимацию, но НЕ позиции (они обновятся в draw)
      @sprite.update(delta_time, @is_moving, @is_attacking, @took_damage)
    end
  end

  def move_towards(target_x, target_y, delta_time, map = nil, player = nil)
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

    # Проверяем коллизии с картой и игроком
    if map
      # Проверяем коллизию по X
      test_x = new_x
      test_y = @y
      collisions_x = map.get_collisions(test_x, test_y, @size)
      solid_collision_x = collisions_x.find { |obj| obj.solid }
      
      # Проверяем коллизию с игроком по X
      player_collision_x = false
      if player && player.alive?
        player_distance = Math.sqrt((test_x - player.x)**2 + (test_y - player.y)**2)
        collision_distance = (@size + player.size) * 0.8
        player_collision_x = player_distance < collision_distance
      end
      
      if solid_collision_x || player_collision_x
        # Не двигаемся по X, но толкаем игрока если это коллизия с ним
        if player_collision_x && !solid_collision_x
          push_player(player, dx * move_distance * 0.5, 0)
          # Наносим урон при контакте (если прошло достаточно времени)
          apply_contact_damage(player, delta_time)
        end
        new_x = @x
      end
      
      # Проверяем коллизию по Y
      test_x = @x
      test_y = new_y
      collisions_y = map.get_collisions(test_x, test_y, @size)
      solid_collision_y = collisions_y.find { |obj| obj.solid }
      
      # Проверяем коллизию с игроком по Y
      player_collision_y = false
      if player && player.alive?
        player_distance = Math.sqrt((test_x - player.x)**2 + (test_y - player.y)**2)
        collision_distance = (@size + player.size) * 0.8
        player_collision_y = player_distance < collision_distance
      end
      
      if solid_collision_y || player_collision_y
        # Не двигаемся по Y, но толкаем игрока если это коллизия с ним
        if player_collision_y && !solid_collision_y
          push_player(player, 0, dy * move_distance * 0.5)
          # Наносим урон при контакте (если прошло достаточно времени)
          apply_contact_damage(player, delta_time)
        end
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
  
  def push_player(player, push_x, push_y)
    # Враг толкает игрока
    player.x += push_x
    player.y += push_y
  end
  
  def apply_contact_damage(player, delta_time)
    # Наносим урон при контакте с игроком
    # ВСЕ враги (и ближние, и дальнобойные) наносят урон при толкании игрока
    return unless player.alive?
    
    current_time = Time.now.to_f
    # Проверяем кулдаун урона при контакте
    if current_time - @last_contact_damage_time >= @contact_damage_cooldown
      # Проверяем, что игрок действительно в контакте
      distance = Math.sqrt((@x - player.x)**2 + (@y - player.y)**2)
      contact_distance = (@size + player.size) * 0.9
      
      if distance < contact_distance
        # Наносим урон при толкании (85% от обычного урона для всех врагов - увеличено с 70%)
        contact_damage = @damage * 0.85 # 85% от обычного урона
        player.take_damage(contact_damage) if player.respond_to?(:take_damage)
        @last_contact_damage_time = current_time
      end
    end
  end

  def attack_player(player)
    current_time = Time.now.to_f
    return if current_time - @last_attack_time < @attack_cooldown

    # Для боссов используем специальную систему атак
    if @boss
      distance = distance_to(player.x, player.y)
      
      # Ближняя атака босса - только вплотную
      if distance <= @attack_range
        # Ближняя атака наносит урон сразу
        player.take_damage(@damage)
        @last_attack_time = current_time
        return nil
      else
        # Дальняя атака босса - с огромной дальностью
        # Для финального босса - особые паттерны
        if @enemy_type == :final_boss
          # Финальный босс использует сложные паттерны дальних атак
          return nil  # Специальные атаки обрабатываются в use_special_attack
        else
          # Обычный босс - простая дальняя атака
          player_dx = player.x - (player.instance_variable_get(:@last_x) || player.x)
          player_dy = player.y - (player.instance_variable_get(:@last_y) || player.y)
          predicted_x = player.x + player_dx * 1.8
          predicted_y = player.y + player_dy * 1.8
          
          return {
            type: :boss_ranged_attack,
            damage: @damage * 1.5,  # Дальняя атака сильнее
            radius: 80,
            delay: 4.0,  # Задержка перед ударом (увеличено с 1.5 до 4.0 - в 2.67 раза)
            x: predicted_x,
            y: predicted_y,
            enemy: self
          }
        end
      end
    end

    # Для элитных монстров используем специальную систему индикации
    if @elite
      # Элитные монстры атакуют с индикацией
      if @ranged
        # Дальнобойная атака элитного мага - предсказываем позицию игрока
        # Вычисляем направление движения игрока
        player_last_x = player.instance_variable_get(:@last_x) || player.x
        player_last_y = player.instance_variable_get(:@last_y) || player.y
        player_dx = player.x - player_last_x
        player_dy = player.y - player_last_y
        
        # Предсказываем позицию игрока через delay секунд (атакуем впереди него)
        prediction_factor = 2.0  # Увеличено для лучшего предсказания
        predicted_x = player.x + player_dx * prediction_factor
        predicted_y = player.y + player_dy * prediction_factor
        
        # Возвращаем информацию для создания индикации
        # Может быть несколько атак за раз (2-3 рядом или по направлению)
        attacks = []
        attack_count = rand(2..3)  # 2-3 атаки за раз
        
        attack_count.times do |i|
          # Смещаем позицию для каждой атаки
          offset_angle = (i - attack_count / 2.0) * 0.3  # Разброс по углу
          offset_distance = i * 30  # Расстояние между атаками
          
          attack_x = predicted_x + Math.cos(offset_angle) * offset_distance
          attack_y = predicted_y + Math.sin(offset_angle) * offset_distance
          
          attacks << {
            type: :elite_ranged_attack,
            damage: @damage,
            radius: 35,  # Немного уменьшено
            delay: 3.5,  # Увеличена задержка для возможности уклонения
            x: attack_x,
            y: attack_y,
            enemy: self
          }
        end
        
        # Возвращаем первую атаку (остальные будут созданы в game.rb)
        return attacks.first.merge(attacks: attacks)  # Передаем все атаки
      else
        # Ближняя атака элитного рыцаря - создаем индикацию вокруг врага
        return {
          type: :elite_melee_attack,
          damage: @damage,
          radius: [@attack_range / 3.0, 10].max,  # Уменьшено в 3 раза, минимум 10
          delay: 1.5,  # Увеличена задержка (было 0.8)
          x: @x,
          y: @y,
          enemy: self
        }
      end
    end

    # Обычные монстры атакуют сразу без индикации
    if @ranged
      # Дальнобойная атака (создает проектиль)
      player.take_damage(@damage)
    else
      # Ближний бой
      if @area_attack
        # Атака по области - наносим урон всем в радиусе
        player.take_damage(@damage)
      else
        player.take_damage(@damage)
      end
    end
    
    @last_attack_time = current_time
    nil  # Обычные монстры не возвращают информацию об атаке
  end
  
  def can_use_special_attack?(current_time)
    return false unless @special_attacks
    current_time - @last_special_attack >= @special_attack_cooldown
  end
  
  def use_special_attack(player, current_time)
    return nil unless can_use_special_attack?(current_time)
    @last_special_attack = current_time
    
    # Уникальные атаки боссов с паттернами
    if @boss
      # Финальный босс имеет более сложные и уникальные паттерны
      if @enemy_type == :final_boss
        # Выбираем случайный паттерн для финального босса (более сложные)
        attack_pattern = rand(5)
        
        case attack_pattern
        when 0
          # Паттерн 1: Спираль из кругов вокруг игрока
          player_dx = player.x - (player.instance_variable_get(:@last_x) || player.x)
          player_dy = player.y - (player.instance_variable_get(:@last_y) || player.y)
          predicted_x = player.x + player_dx * 2.0
          predicted_y = player.y + player_dy * 2.0
          
          return {
            type: :final_boss_spiral,
            damage: @damage * 1.3,
            radius: 60,
            delay: 15.0,  # Увеличено с 12.0 до 15.0 (еще в 1.25 раза)
            center_x: predicted_x,
            center_y: predicted_y,
            count: 5,  # 5 кругов в спирали
            enemy: self
          }
        when 1
          # Паттерн 2: Крест из больших кругов
          player_dx = player.x - (player.instance_variable_get(:@last_x) || player.x)
          player_dy = player.y - (player.instance_variable_get(:@last_y) || player.y)
          predicted_x = player.x + player_dx * 1.8
          predicted_y = player.y + player_dy * 1.8
          
          return {
            type: :final_boss_cross,
            damage: @damage * 1.4,
            radius: 90,
            delay: 18.0,  # Увеличено с 15.0 до 18.0 (еще в 1.2 раза)
            center_x: predicted_x,
            center_y: predicted_y,
            enemy: self
          }
        when 2
          # Паттерн 3: Кольцо из кругов вокруг игрока
          player_dx = player.x - (player.instance_variable_get(:@last_x) || player.x)
          player_dy = player.y - (player.instance_variable_get(:@last_y) || player.y)
          predicted_x = player.x + player_dx * 2.0
          predicted_y = player.y + player_dy * 2.0
          
          return {
            type: :final_boss_ring,
            damage: @damage * 1.2,
            radius: 70,
            delay: 15.0,  # Увеличено с 12.0 до 15.0 (еще в 1.25 раза)
            center_x: predicted_x,
            center_y: predicted_y,
            count: 8,  # 8 кругов в кольце
            enemy: self
          }
        when 3
          # Паттерн 4: Волна из кругов в направлении игрока
          player_dx = player.x - (player.instance_variable_get(:@last_x) || player.x)
          player_dy = player.y - (player.instance_variable_get(:@last_y) || player.y)
          predicted_x = player.x + player_dx * 2.0
          predicted_y = player.y + player_dy * 2.0
          
          return {
            type: :final_boss_wave,
            damage: @damage * 1.3,
            radius: 80,
            delay: 15.0,  # Увеличено с 12.0 до 15.0 (еще в 1.25 раза)
            center_x: predicted_x,
            center_y: predicted_y,
            count: 4,  # 4 круга в волне
            enemy: self
          }
        when 4
          # Паттерн 5: Огромный взрыв вокруг босса
          return {
            type: :final_boss_explosion,
            damage: @damage * 1.5,
            radius: 200,
            delay: 18.0,  # Увеличено с 15.0 до 18.0 (еще в 1.2 раза)
            x: @x,
            y: @y,
            enemy: self
          }
        end
      else
        # Обычный босс - простые паттерны
        attack_pattern = rand(3)
        
        case attack_pattern
        when 0
          # Паттерн 1: Несколько кругов вокруг игрока (веерная атака)
          player_dx = player.x - (player.instance_variable_get(:@last_x) || player.x)
          player_dy = player.y - (player.instance_variable_get(:@last_y) || player.y)
          predicted_x = player.x + player_dx * 2.0
          predicted_y = player.y + player_dy * 2.0
          
          return {
            type: :boss_pattern_circles,
            damage: @damage * 1.2,
            radius: 70,
            delay: 4.5,  # Увеличено с 1.8 до 4.5 (в 2.5 раза)
            center_x: predicted_x,
            center_y: predicted_y,
            count: 3,  # 3 круга
            enemy: self
          }
        when 1
          # Паттерн 2: Большой круг на позиции игрока с предсказанием
          player_dx = player.x - (player.instance_variable_get(:@last_x) || player.x)
          player_dy = player.y - (player.instance_variable_get(:@last_y) || player.y)
          predicted_x = player.x + player_dx * 1.8
          predicted_y = player.y + player_dy * 1.8
          
          return {
            type: :boss_pattern_large_circle,
            damage: @damage * 1.5,
            radius: 100,
            delay: 15.0,  # Увеличено с 12.0 до 15.0 (еще в 1.25 раза)
            x: predicted_x,
            y: predicted_y,
            enemy: self
          }
        when 2
          # Паттерн 3: Атака по области вокруг босса (ближняя)
          return {
            type: :boss_pattern_nearby,
            damage: @damage * 1.3,
            radius: 120,
            delay: 3.5,  # Увеличено с 1.5 до 3.5 (в 2.33 раза)
            x: @x,
            y: @y,
            enemy: self
          }
        end
      end
    end
    
    # Уникальные атаки элитных монстров
    if @elite
      case @enemy_type
      when :elite_mage
        # Дальняя атака элитного мага - индикация красным кругом на позиции игрока
        attack_radius = 80
        attack_damage = @damage * 1.2
        # Возвращаем информацию для индикации атаки
        return { 
          type: :ranged_attack, 
          damage: attack_damage, 
          radius: attack_radius, 
          x: player.x, 
          y: player.y,
          delay: 1.5  # Задержка перед ударом (время показа индикации)
        }
      when :elite_knight
        # Ближняя атака элитного рыцаря - обычная атака, но с индикацией
        # Ближний бой, радиус как у обычных мобов (30)
        return nil  # Ближний бой без специальной индикации
      end
    end
    
    nil
  end

  def distance_to(x, y)
    Math.sqrt((@x - x)**2 + (@y - y)**2)
  end

  def take_damage(amount)
    old_health = @health
    @health -= amount
    @health = 0 if @health < 0
    @took_damage = true
    @just_died = @health <= 0 && @was_alive
    @was_alive = @health > 0
    # Возвращаем реально нанесенный урон
    [old_health - @health, 0].max
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
    return unless @sprite # Не рисуем, если спрайт не создан

    # Обновляем позицию спрайта с учетом камеры
    if camera
      screen_x, screen_y = camera.world_to_screen(@x, @y)
      @sprite.x = screen_x
      @sprite.y = screen_y
    else
      @sprite.x = @x
      @sprite.y = @y
    end
    
    # ВАЖНО: Обновляем позиции всех фигур спрайта с учетом экранных координат
    @sprite.update_all_positions if @sprite.respond_to?(:update_all_positions)

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
    # Удаляем спрайт и все его фигуры
    if @sprite
      @sprite.remove if @sprite.respond_to?(:remove)
      @sprite = nil
    end
    # Удаляем полоску здоровья
    @health_bar_bg&.remove
    @health_bar&.remove
    @health_bar_bg = nil
    @health_bar = nil
  end
end

